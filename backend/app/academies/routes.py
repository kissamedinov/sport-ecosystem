from fastapi import APIRouter, Depends, status, HTTPException
from sqlalchemy.orm import Session
from typing import List, Optional
from uuid import UUID
from datetime import date

from app.database import get_db
from app.users.models import User, Role, ParentChildRelation, ParentChildStatus
from app.common.dependencies import require_role, require_coach, get_current_user
from app.academies import schemas, models, services

router = APIRouter(prefix="/academies", tags=["Academies"])

@router.post("", response_model=schemas.AcademyResponse, status_code=status.HTTP_201_CREATED)
def create_academy(
    academy_in: schemas.AcademyCreate,
    db: Session = Depends(get_db),
    current_user: User = Depends(require_coach)
):
    """
    Creates a new academy. Only COACH or TEAM_OWNER roles allowed.
    """
    return services.create_academy(db, academy_in, current_user.id)

@router.get("/mine", response_model=Optional[schemas.AcademyResponse])
def get_my_academy(
    db: Session = Depends(get_db),
    current_user: User = Depends(require_coach)
):
    """
    Returns the academy owned by or coached by the current user.
    """
    return services.get_user_related_academy(db, current_user.id)

@router.get("/mine-debug", response_model=Optional[schemas.AcademyResponse])
def get_my_academy_debug(
    db: Session = Depends(get_db),
    current_user: User = Depends(get_current_user)
):
    """
    DEBUG: Bypasses role checks to see if academy loads for current user.
    """
    print(f"[DEBUG-AUTH] Bypassing role check for user: {current_user.id}")
    return services.get_user_related_academy(db, current_user.id)

@router.get("/rankings", response_model=List[schemas.AcademyRankingResponse])
def get_academy_rankings(db: Session = Depends(get_db)):
    """
    Returns academy rankings sorted by points descending.
    """
    return services.get_academy_rankings(db)

@router.get("/training/{session_id}/players", response_model=List[schemas.AcademyCompositePlayerResponse])
def get_training_session_players(
    session_id: UUID,
    db: Session = Depends(get_db),
    current_user: User = Depends(get_current_user)
):
    from app.academies.models import TrainingSession
    from app.teams.models import TeamMembership
    from app.users.models import User
    
    session = db.query(TrainingSession).filter(TrainingSession.id == session_id).first()
    if not session:
        raise HTTPException(status_code=404, detail="Session not found")
    
    team_ids = [t.id for t in session.teams]
    if not team_ids:
        return []

    # Fetch all players in these teams
    memberships = db.query(TeamMembership).filter(TeamMembership.team_id.in_(team_ids)).all()
    
    # Map to composite response
    results = []
    for m in memberships:
        # Get birth year from team (since it defines the group context)
        birth_year = m.team.birth_year
        results.append({
            "id": str(m.player_id),
            "full_name": f"{m.player_profile.first_name} {m.player_profile.last_name}",
            "birth_year": birth_year,
            "team_name": m.team.name
        })
    return results

@router.get("/{id}/teams", response_model=List[schemas.AcademyTeamResponse])
def list_academy_teams(
    id: UUID,
    db: Session = Depends(get_db),
    current_user: User = Depends(get_current_user)
):
    return services.get_academy_teams(db, id, user_id=current_user.id)

@router.post("/{id}/teams", response_model=schemas.AcademyTeamResponse)
def add_academy_team(
    id: UUID,
    team_in: schemas.AcademyTeamCreate,
    db: Session = Depends(get_db),
    current_user: User = Depends(require_coach)
):
    return services.create_academy_team(db, id, team_in)

@router.get("/{id}/players", response_model=List[schemas.AcademyPlayerResponse])
def list_academy_players(
    id: UUID,
    db: Session = Depends(get_db),
    current_user: User = Depends(get_current_user)
):
    return services.get_academy_players(db, id, user_id=current_user.id)

@router.post("/{id}/players", response_model=schemas.AcademyPlayerResponse)
def add_academy_player(
    id: UUID,
    player_in: schemas.AcademyPlayerCreate,
    db: Session = Depends(get_db),
    current_user: User = Depends(get_current_user)
):
    """
    Adds a player to an academy. Allowed for COACH/ACADEMY_ADMIN or PARENT of the player.
    """
    user_roles = [r.role for r in current_user.roles]
    is_management = Role.COACH in user_roles or Role.ACADEMY_ADMIN in user_roles or Role.ADMIN in user_roles
    
    if not is_management:
        # Check if parent of the child
        relation = db.query(ParentChildRelation).filter(
            ParentChildRelation.parent_id == current_user.id,
            ParentChildRelation.child_id == player_in.player_profile_id, # This assumes player_profile_id is user_id of child for simplicity, or we need to look up
            ParentChildRelation.status == ParentChildStatus.ACCEPTED
        ).first()
        
        # If player_profile_id is actually the Profile model ID, we need to map it
        if not relation:
             # Try mapping profile_id to user_id
             from app.users.models import PlayerProfile
             profile = db.query(PlayerProfile).filter(PlayerProfile.id == player_in.player_profile_id).first()
             if profile:
                 relation = db.query(ParentChildRelation).filter(
                     ParentChildRelation.parent_id == current_user.id,
                     ParentChildRelation.child_id == profile.user_id,
                     ParentChildRelation.status == ParentChildStatus.ACCEPTED
                 ).first()

        if not relation:
            raise HTTPException(status_code=403, detail="Not authorized to manage this player")

    return services.add_player_to_academy(db, id, player_in)

@router.get("/teams/{team_id}/players", response_model=List[schemas.AcademyTeamPlayerResponse])
def list_team_players(
    team_id: UUID,
    db: Session = Depends(get_db),
    current_user: User = Depends(require_coach)
):
    return services.get_academy_team_players(db, team_id)

@router.post("/teams/{team_id}/players", response_model=schemas.AcademyTeamPlayerResponse)
def add_team_player(
    team_id: UUID,
    player_in: schemas.AcademyTeamPlayerCreate,
    db: Session = Depends(get_db),
    current_user: User = Depends(require_coach)
):
    return services.add_player_to_team(db, team_id, player_in)

@router.get("/{id}/training", response_model=List[schemas.TrainingSessionResponse])
def list_training_sessions(
    id: UUID,
    team_id: Optional[UUID] = None,
    db: Session = Depends(get_db),
    current_user: User = Depends(require_coach)
):
    return services.get_training_sessions(db, id, team_id)

@router.post("/{id}/training", response_model=schemas.TrainingSessionResponse)
def add_training_session(
    id: UUID,
    session_in: schemas.TrainingSessionCreate,
    db: Session = Depends(get_db),
    current_user: User = Depends(require_coach)
):
    return services.create_training_session(db, id, current_user.id, session_in)

@router.post("/attendance", response_model=schemas.TrainingAttendanceResponse)
def record_training_attendance(
    attendance_in: schemas.TrainingAttendanceCreate,
    db: Session = Depends(get_db),
    current_user: User = Depends(require_coach)
):
    return services.record_attendance(db, attendance_in)

@router.post("/feedback", response_model=schemas.CoachFeedbackResponse)
def submit_coach_feedback(
    feedback_in: schemas.CoachFeedbackCreate,
    db: Session = Depends(get_db),
    current_user: User = Depends(require_coach)
):
    return services.submit_feedback(db, current_user.id, feedback_in)

# --- CRM Endpoints ---

@router.post("/{id}/schedules", response_model=schemas.TrainingScheduleResponse)
def create_academy_schedule(
    id: UUID,
    schedule_in: schemas.TrainingScheduleCreate,
    db: Session = Depends(get_db),
    current_user: User = Depends(require_coach)
):
    return services.create_training_schedule(db, id, schedule_in)

@router.get("/{id}/schedules", response_model=List[schemas.TrainingScheduleResponse])
def list_academy_schedules(
    id: UUID,
    team_id: Optional[UUID] = None,
    db: Session = Depends(get_db),
    current_user: User = Depends(require_coach)
):
    return services.get_academy_schedules(db, id, team_id)

@router.post("/{id}/generate-sessions")
def trigger_session_generation(
    id: UUID,
    start_date: date,
    end_date: date,
    db: Session = Depends(get_db),
    current_user: User = Depends(require_coach)
):
    count = services.generate_sessions_from_schedules(db, id, start_date, end_date)
    return {"message": f"Successfully created {count} sessions"}

@router.patch("/players/{player_profile_id}/team", response_model=schemas.AcademyTeamPlayerResponse)
def reassign_player_team(
    player_profile_id: UUID,
    target_team_id: UUID,
    db: Session = Depends(get_db),
    current_user: User = Depends(require_coach)
):
    """
    Moves a player to a different team within the academy system.
    """
    return services.move_player_between_teams(db, player_profile_id, target_team_id)

@router.get("/{id}/billing/config", response_model=Optional[schemas.AcademyBillingConfigResponse])
def get_billing_config(
    id: UUID,
    db: Session = Depends(get_db),
    current_user: User = Depends(require_coach)
):
    return services.get_billing_configuration(db, id)

@router.put("/{id}/billing/config", response_model=schemas.AcademyBillingConfigResponse)
def update_billing_config(
    id: UUID,
    config_in: schemas.AcademyBillingConfigCreate,
    db: Session = Depends(get_db),
    current_user: User = Depends(require_coach)
):
    return services.update_billing_configuration(db, id, config_in)

@router.get("/{id}/billing/report/{player_id}", response_model=schemas.BillingSummary)
def get_player_billing_report(
    id: UUID,
    player_id: UUID,
    month: int,
    year: int,
    db: Session = Depends(get_db),
    current_user: User = Depends(require_coach)
):
    return services.get_player_billing_summary(db, id, player_id, month, year)
