from sqlalchemy.orm import Session
from uuid import UUID
from typing import List

from app.matches.models import Match, MatchPlayerStats
from app.tournaments.models import Tournament
from app.teams.models import Team

def get_player_match_history(db: Session, player_id: UUID):
    stats = db.query(MatchPlayerStats).filter(MatchPlayerStats.player_id == player_id).all()
    
    history = []
    for s in stats:
        match = db.query(Match).filter(Match.id == s.match_id).first()
        tournament = db.query(Tournament).filter(Tournament.id == match.tournament_id).first()
        
        # Determine opponent
        opponent_id = match.away_team_id if s.team_id == match.home_team_id else match.home_team_id
        opponent = db.query(Team).filter(Team.id == opponent_id).first()
        
        history.append({
            "match_id": s.match_id,
            "tournament_name": tournament.name,
            "opponent": opponent.name,
            "goals": s.goals,
            "assists": s.assists,
            "yellow_cards": s.yellow_cards,
            "red_cards": s.red_cards,
            "is_best_player": s.is_best_player,
            "date": match.match_date
        })
    return history
