from sqlalchemy.orm import Session
from fastapi import HTTPException, status
from uuid import UUID
from typing import List

from app.matches.models import Match, MatchLineup, MatchLineupPlayer
from app.tournaments.models import TournamentTeam, TournamentSquad
from app.users.models import User

def submit_lineup(
    db: Session, 
    match_id: UUID, 
    team_id: UUID, 
    player_ids: List[UUID],
    starting_ids: List[UUID]
):
    match = db.query(Match).filter(Match.id == match_id).first()
    if not match:
        raise HTTPException(status_code=404, detail="Match not found")
        
    # Verify the team is in the match
    if match.home_team_id != team_id and match.away_team_id != team_id:
        raise HTTPException(status_code=400, detail="Team is not part of this match")
        
    # Get the tournament team entry
    tt = db.query(TournamentTeam).filter(
        TournamentTeam.tournament_id == match.tournament_id,
        TournamentTeam.team_id == team_id
    ).first()
    
    if not tt:
        raise HTTPException(status_code=400, detail="Team is not registered for this tournament")
        
    # Validate players are in the TournamentSquad
    squad_player_ids = [s.player_id for s in db.query(TournamentSquad).filter(TournamentSquad.tournament_team_id == tt.id).all()]
    
    for p_id in player_ids:
        if p_id not in squad_player_ids:
            raise HTTPException(status_code=400, detail=f"Player {p_id} is not in the official tournament squad")
            
    # Create the lineup
    new_lineup = MatchLineup(match_id=match_id, team_id=team_id)
    db.add(new_lineup)
    db.flush() # Get id
    
    for p_id in player_ids:
        # Fetch squad info for jersey and position
        squad_member = db.query(TournamentSquad).filter(
            TournamentSquad.tournament_team_id == tt.id,
            TournamentSquad.player_id == p_id
        ).first()
        
        lp = MatchLineupPlayer(
            lineup_id=new_lineup.id,
            player_id=p_id,
            is_starting=(p_id in starting_ids),
            position=squad_member.position,
            jersey_number=squad_member.jersey_number
        )
        db.add(lp)
        
    db.commit()
    db.refresh(new_lineup)
    return new_lineup

def get_match_lineup(db: Session, match_id: UUID, team_id: UUID):
    return db.query(MatchLineup).filter(
        MatchLineup.match_id == match_id,
        MatchLineup.team_id == team_id
    ).first()
