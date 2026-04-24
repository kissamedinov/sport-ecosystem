from sqlalchemy.orm import Session
from uuid import UUID
from typing import List, Optional, Dict
from app.tournaments.models import Tournament, TournamentStandings, TournamentGroup
from app.matches.models import Match, MatchResult

def update_standings(db: Session, tournament_id: UUID, team_id: UUID, division_id: Optional[UUID] = None):
    """
    Recalculates standings for a specific team in a tournament/division.
    """
    tournament = db.query(Tournament).filter(Tournament.id == tournament_id).first()
    if not tournament:
        return

    # Get team's group and division if not provided
    match_info = db.query(Match).filter(
        Match.tournament_id == tournament_id,
        ((Match.home_team_id == team_id) | (Match.away_team_id == team_id))
    ).first()
    
    group_id = match_info.group_id if match_info else None
    if not division_id and match_info:
        division_id = match_info.division_id

    # Get or create standing entry
    standing = db.query(TournamentStandings).filter(
        TournamentStandings.tournament_id == tournament_id,
        TournamentStandings.team_id == team_id,
        TournamentStandings.division_id == division_id
    ).first()
    
    if not standing:
        standing = TournamentStandings(
            tournament_id=tournament_id, 
            division_id=division_id,
            team_id=team_id,
            group_id=group_id
        )
        db.add(standing)
    else:
        standing.group_id = group_id
        standing.division_id = division_id
        
    # Recalculate everything from finalized matches
    query = db.query(Match).join(MatchResult).filter(
        Match.tournament_id == tournament_id,
        ((Match.home_team_id == team_id) | (Match.away_team_id == team_id)),
        MatchResult.status == "FINAL"
    )
    if division_id:
        query = query.filter(Match.division_id == division_id)
        
    all_team_matches = query.all()
    
    played: int = 0
    wins: int = 0
    draws: int = 0
    losses: int = 0
    goals_for: int = 0
    goals_against: int = 0
    points: int = 0
    
    for m in all_team_matches:
        played = played + 1
        res = m.result
        if m.home_team_id == team_id:
            h_score, a_score = res.home_score, res.away_score
        else:
            h_score, a_score = res.away_score, res.home_score
            
        goals_for = goals_for + h_score
        goals_against = goals_against + a_score
        
        if h_score > a_score:
            wins = wins + 1
            points = points + tournament.points_for_win
        elif h_score == a_score:
            draws = draws + 1
            points = points + tournament.points_for_draw
        else:
            losses = losses + 1
            points = points + tournament.points_for_loss
                
    standing.played = played
    standing.wins = wins
    standing.draws = draws
    standing.losses = losses
    standing.goals_for = goals_for
    standing.goals_against = goals_against
    standing.goal_difference = goals_for - goals_against
    standing.points = points
    
    db.commit()

def get_standings(db: Session, tournament_id: UUID, group_id: Optional[UUID] = None) -> List[TournamentStandings]:
    """
    Returns sorted standings for a tournament or a specific group.
    Sorting: Points > Goal Difference > Goals For > Head-to-Head (simplified for now)
    """
    query = db.query(TournamentStandings).filter(TournamentStandings.tournament_id == tournament_id)
    if group_id:
        query = query.filter(TournamentStandings.group_id == group_id)
    
    standings = query.all()
    
    # Sort: Primary: Points DESC, Secondary: GD DESC, Tertiary: GF DESC
    # For H2H, we'd need to fetch matches between the tied teams, which is complex for a simple sort.
    # We'll implement a basic multi-key sort first.
    
    sorted_standings = sorted(
        standings,
        key=lambda s: (s.points, s.goal_difference, s.goals_for),
        reverse=True
    )
    
    # Pre-populate team name for the schema to avoid lazy loading issues
    for s in sorted_standings:
        s.team_name = s.team.name
        
    return sorted_standings
