from sqlalchemy.orm import Session
from fastapi import HTTPException, status
from uuid import UUID
from typing import List

from app.tournaments.models import Tournament, TournamentTeam, TournamentSquad
from app.teams.models import TeamMembership, JoinStatus
from app.users.models import User
from app.notifications import service as notification_service
from app.notifications.models import NotificationType, EntityType

def register_team_to_tournament(db: Session, tournament_id: UUID, team_id: UUID, user_id: UUID):
    # Check if team is approved in registration (assuming previous registration logic)
    # For now, we manually create the TournamentTeam entry
    
    existing = db.query(TournamentTeam).filter(
        TournamentTeam.tournament_id == tournament_id,
        TournamentTeam.team_id == team_id
    ).first()
    if existing:
        raise HTTPException(status_code=400, detail="Team already registered in this tournament")
        
    new_tt = TournamentTeam(
        tournament_id=tournament_id,
        team_id=team_id,
        registered_by=user_id
    )
    db.add(new_tt)
    db.commit()
    db.refresh(new_tt)
    return new_tt

def add_player_to_squad(
    db: Session, 
    tournament_team_id: UUID, 
    player_id: UUID, 
    jersey_number: int = None, 
    position: str = None
):
    from app.teams.models import TeamMembership, MembershipStatus
    from app.users.models import PlayerProfile
    
    tt = db.query(TournamentTeam).filter(TournamentTeam.id == tournament_team_id).first()
    if not tt:
        raise HTTPException(status_code=404, detail="Tournament team not found")
        
    # Validation: Player must be in the team roster and approved
    profile = db.query(PlayerProfile).filter(PlayerProfile.user_id == player_id).first()
    if not profile:
        raise HTTPException(status_code=400, detail="Player profile not found")

    membership = db.query(TeamMembership).filter(
        TeamMembership.team_id == tt.team_id,
        TeamMembership.player_profile_id == profile.id,
        TeamMembership.status == MembershipStatus.ACTIVE
    ).first()
    
    if not membership:
        raise HTTPException(status_code=400, detail="Player is not an approved member of the team")
        
    # Age validation
    tournament = db.query(Tournament).filter(Tournament.id == tt.tournament_id).first()
    player = db.query(User).filter(User.id == player_id).first()
    
    if tournament.age_category != "ADULT":
        from datetime import date
        try:
            # Simple age calculation based on years
            age_limit = int(tournament.age_category[1:]) # Extract number from U7, U9, etc.
            today = date.today()
            age = today.year - player.date_of_birth.year - ((today.month, today.day) < (player.date_of_birth.month, player.date_of_birth.day))
            
            if age > age_limit:
                raise HTTPException(status_code= status.HTTP_400_BAD_REQUEST, detail=f"Player is too old for this {tournament.age_category} tournament. Age: {age}")
        except (ValueError, IndexError):
            pass # Fallback if category is unexpected
        
    # Check if already in squad
    existing = db.query(TournamentSquad).filter(
        TournamentSquad.tournament_team_id == tournament_team_id,
        TournamentSquad.player_profile_id == profile.id
    ).first()
    if existing:
        raise HTTPException(status_code=400, detail="Player already in tournament squad")
        
    new_squad_member = TournamentSquad(
        tournament_team_id=tournament_team_id,
        player_profile_id=profile.id,
        jersey_number=jersey_number,
        position=position
    )
    db.add(new_squad_member)
    db.commit()
    db.refresh(new_squad_member)
    
    # Notify Player
    notification_service.create_notification(
        db,
        [player_id],
        NotificationType.PLAYER_SELECTED,
        "Tournament Squad Selection",
        f"You have been selected for the tournament squad in {tt.tournament_id}.",
        EntityType.TOURNAMENT,
        tt.tournament_id
    )
    return new_squad_member

def get_tournament_squad(db: Session, tournament_team_id: UUID):
    return db.query(TournamentSquad).filter(TournamentSquad.tournament_team_id == tournament_team_id).all()
