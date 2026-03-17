from sqlalchemy.orm import Session
from sqlalchemy import func, or_
from typing import List
from uuid import UUID
from app.matches.models import Match, MatchResult, MatchStatus, ResultStatus
from app.matches.schemas import StandingEntry, TournamentStandings
from app.teams.models import Team

def calculate_standings(db: Session, tournament_id: UUID) -> TournamentStandings:
    """
    Calculates the standings for a tournament based on final match results.
    """
    # 1. Fetch all finished matches with final results
    matches = db.query(Match).join(MatchResult).filter(
        Match.tournament_id == tournament_id,
        Match.status == MatchStatus.FINISHED,
        MatchResult.status == ResultStatus.FINAL
    ).all()

    # 2. Aggregate stats
    standings_map: dict[UUID, StandingEntry] = {}

    # Initialize all teams that are part of this tournament
    # We assume teams are those who played at least one match or we could fetch from registration
    # For now, let's get from matches to be sure we only include active ones in standings
    # Or better: fetch all teams registered to the tournament.
    # Since we don't have registrations fully linked here, we'll derive from matches.
    
    unique_team_ids = set()
    for m in matches:
        unique_team_ids.add(m.home_team_id)
        unique_team_ids.add(m.away_team_id)
    
    teams = db.query(Team).filter(Team.id.in_(list(unique_team_ids))).all()
    for t in teams:
        standings_map[t.id] = StandingEntry(
            team_id=t.id, 
            team_name=t.name,
            rating=t.rating
        )

    for m in matches:
        res = m.result
        home_id = m.home_team_id
        away_id = m.away_team_id
        
        home_stats = standings_map[home_id]
        away_stats = standings_map[away_id]
        
        home_stats.played += 1
        away_stats.played += 1
        
        home_stats.goals_for += res.home_score
        home_stats.goals_against += res.away_score
        
        away_stats.goals_for += res.away_score
        away_stats.goals_against += res.home_score
        
        if res.home_score > res.away_score:
            home_stats.wins += 1
            home_stats.points += 3
            away_stats.losses += 1
        elif res.away_score > res.home_score:
            away_stats.wins += 1
            away_stats.points += 3
            home_stats.losses += 1
        else:
            home_stats.draws += 1
            home_stats.points += 1
            away_stats.draws += 1
            away_stats.points += 1

    # Finalize calculations
    standings_list = list(standings_map.values())
    for s in standings_list:
        s.goal_difference = s.goals_for - s.goals_against

    # Sort by points (desc), then goal difference (desc), then goals for (desc)
    standings_list.sort(key=lambda x: (x.points, x.goal_difference, x.goals_for), reverse=True)

    return TournamentStandings(tournament_id=tournament_id, standings=standings_list)
