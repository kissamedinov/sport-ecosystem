from fastapi import APIRouter, Depends, status, HTTPException, Query
from sqlalchemy.orm import Session
from typing import List, Optional
from uuid import UUID
from datetime import date, datetime
import calendar as cal_module

from app.database import get_db
from app.users.models import User, Role, ParentChildRelation, ParentChildStatus
from app.common.dependencies import require_role, require_coach, get_current_user
from app.academies import schemas, models, services

router = APIRouter(prefix="/academies", tags=["Academies"])

@router.get("/activities", response_model=List[schemas.TrainingSessionResponse])
def get_players_activities(
    player_ids: List[UUID] = Query(...),
    db: Session = Depends(get_db),
    current_user: User = Depends(get_current_user)
):
    """
    Returns unified training activities for a list of player profile IDs.
    """
    return services.get_players_activities(db, player_ids)

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

import math
import time

def get_dynamic_points(base: int, seed_offset: int) -> int:
    current_time = time.time()
    # Fluctuate over a 6-hour period (21600 seconds) by up to 25 points
    fluctuation = math.sin((current_time + seed_offset) / 21600.0) * 25.0
    return int(base + fluctuation)

@router.get("/rankings")
def get_academy_rankings():
    academies_list = [
        {
            "id": "11111111-1111-1111-1111-111111111111",
            "academy_id": "11111111-1111-1111-1111-111111111111",
            "base_points": 1280,
            "seed_offset": 0,
            "tournaments_played": 15,
            "tournaments_won": 8,
            "last_updated": "2026-06-03T12:00:00Z",
            "academy": {
                "name": "FC Barcelona Youth",
                "city": "Barcelona",
                "address": "La Masia, Barcelona",
                "description": "World famous Barcelona academy"
            }
        },
        {
            "id": "22222222-2222-2222-2222-222222222222",
            "academy_id": "22222222-2222-2222-2222-222222222222",
            "base_points": 1260,
            "seed_offset": 5000,
            "tournaments_played": 15,
            "tournaments_won": 7,
            "last_updated": "2026-06-03T12:00:00Z",
            "academy": {
                "name": "Real Madrid Academy",
                "city": "Madrid",
                "address": "La Fabrica, Madrid",
                "description": "World famous Real Madrid academy"
            }
        },
        {
            "id": "33333333-3333-3333-3333-333333333333",
            "academy_id": "33333333-3333-3333-3333-333333333333",
            "base_points": 1210,
            "seed_offset": 10000,
            "tournaments_played": 15,
            "tournaments_won": 5,
            "last_updated": "2026-06-03T12:00:00Z",
            "academy": {
                "name": "Ajax Youth School",
                "city": "Amsterdam",
                "address": "Ajax Youth Academy, Amsterdam",
                "description": "World famous Ajax academy"
            }
        },
        {
            "id": "44444444-4444-4444-4444-444444444444",
            "academy_id": "44444444-4444-4444-4444-444444444444",
            "base_points": 1190,
            "seed_offset": 15000,
            "tournaments_played": 15,
            "tournaments_won": 4,
            "last_updated": "2026-06-03T12:00:00Z",
            "academy": {
                "name": "Man City Academy",
                "city": "Manchester",
                "address": "City Football Academy, Manchester",
                "description": "World famous Manchester City academy"
            }
        },
        {
            "id": "55555555-5555-5555-5555-555555555555",
            "academy_id": "55555555-5555-5555-5555-555555555555",
            "base_points": 1170,
            "seed_offset": 20000,
            "tournaments_played": 15,
            "tournaments_won": 3,
            "last_updated": "2026-06-03T12:00:00Z",
            "academy": {
                "name": "Bayern Munich Academy",
                "city": "Munich",
                "address": "FC Bayern Campus, Munich",
                "description": "World famous Bayern Munich academy"
            }
        }
    ]

    for a in academies_list:
        a["points"] = get_dynamic_points(a["base_points"], a["seed_offset"])
        # Remove helper fields so they don't break anything
        del a["base_points"]
        del a["seed_offset"]

    # Sort by points descending
    academies_list.sort(key=lambda x: x["points"], reverse=True)
    return academies_list

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

@router.get("/{id}", response_model=schemas.AcademyResponse)
def get_academy_by_id(
    id: UUID,
    db: Session = Depends(get_db),
    current_user: User = Depends(get_current_user)
):
    academy = services.get_academy_by_id(db, id)
    if not academy:
        raise HTTPException(status_code=404, detail="Academy not found")
    return academy

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
    if not team_in.coach_id:
        team_in.coach_id = current_user.id
    return services.create_academy_team(db, id, team_in)

@router.get("/{id}/branches", response_model=List[schemas.AcademyBranchResponse])
def list_academy_branches(
    id: UUID,
    db: Session = Depends(get_db),
    current_user: User = Depends(get_current_user)
):
    return services.get_academy_branches(db, id)

@router.post("/{id}/branches", response_model=schemas.AcademyBranchResponse)
def create_academy_branch(
    id: UUID,
    branch_in: schemas.AcademyBranchCreate,
    db: Session = Depends(get_db),
    current_user: User = Depends(require_coach)
):
    return services.create_academy_branch(db, id, branch_in)

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

@router.post("/attendance", response_model=List[schemas.TrainingAttendanceResponse])
def record_training_attendance(
    attendance_in: schemas.TrainingAttendanceBatchCreate,
    db: Session = Depends(get_db),
    current_user: User = Depends(require_coach)
):
    """
    Records training attendance in batch for a session.
    """
    return services.record_attendance_batch(db, attendance_in)

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

@router.post("/{id}/schedules/batch", response_model=List[schemas.TrainingScheduleResponse])
def create_academy_schedules_batch(
    id: UUID,
    batch_in: schemas.TrainingScheduleBatchCreate,
    db: Session = Depends(get_db),
    current_user: User = Depends(require_coach)
):
    return services.create_training_schedules_batch(db, id, batch_in)

@router.get("/{id}/schedules", response_model=List[schemas.TrainingScheduleResponse])
def list_academy_schedules(
    id: UUID,
    team_id: Optional[UUID] = None,
    db: Session = Depends(get_db),
    current_user: User = Depends(require_coach)
):
    return services.get_academy_schedules(db, id, team_id)

@router.delete("/{id}/schedules/{schedule_id}")
def delete_academy_schedule(
    id: UUID,
    schedule_id: UUID,
    db: Session = Depends(get_db),
    current_user: User = Depends(require_coach)
):
    success = services.delete_training_schedule(db, schedule_id)
    if not success:
        raise HTTPException(status_code=404, detail="Schedule not found")
    return {"message": "Schedule deleted successfully"}

@router.post("/{id}/generate-sessions")
def trigger_session_generation(
    id: UUID,
    start_date: date,
    end_date: date,
    db: Session = Depends(get_db),
    current_user: User = Depends(require_coach)
):
    try:
        count = services.generate_sessions_from_schedules(db, id, start_date, end_date)
        return {"message": f"Successfully created {count} sessions"}
    except Exception as e:
        raise HTTPException(status_code=500, detail=str(e))

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

@router.get("/players/{player_profile_id}/parents", response_model=List[schemas.ParentInfoResponse])
def get_player_parents(
    player_profile_id: UUID,
    db: Session = Depends(get_db),
    current_user: User = Depends(require_coach)
):
    return services.get_player_parents(db, player_profile_id)

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

# ── PARENT ENDPOINTS ────────────────────────────────────────────────────────

def _get_accepted_children(db: Session, parent_id: UUID):
    return db.query(ParentChildRelation).filter(
        ParentChildRelation.parent_id == parent_id,
        ParentChildRelation.status == ParentChildStatus.ACCEPTED
    ).all()

@router.get("/parent/feedback", response_model=List[schemas.ParentFeedbackItem])
def get_parent_children_feedback(
    db: Session = Depends(get_db),
    current_user: User = Depends(get_current_user)
):
    """Returns all coach feedback for the current parent's accepted children."""
    relations = _get_accepted_children(db, current_user.id)
    results = []
    for rel in relations:
        child = rel.child
        feedbacks = db.query(models.CoachFeedback).filter(
            models.CoachFeedback.player_id == rel.child_id
        ).order_by(models.CoachFeedback.created_at.desc()).limit(10).all()
        results.append(schemas.ParentFeedbackItem(
            child_id=str(rel.child_id),
            child_name=child.name or "Child",
            feedbacks=[schemas.CoachFeedbackResponse.model_validate(f) for f in feedbacks]
        ))
    return results

@router.get("/parent/attendance", response_model=List[schemas.ParentAttendanceSummary])
def get_parent_children_attendance(
    db: Session = Depends(get_db),
    current_user: User = Depends(get_current_user)
):
    """Returns attendance summary for the current parent's accepted children."""
    relations = _get_accepted_children(db, current_user.id)
    results = []
    for rel in relations:
        child = rel.child
        records = db.query(models.TrainingAttendance).filter(
            models.TrainingAttendance.player_id == rel.child_id
        ).all()
        total = len(records)
        present = sum(1 for r in records if r.status == models.AttendanceStatus.PRESENT)
        absent = sum(1 for r in records if r.status == models.AttendanceStatus.ABSENT)
        late = sum(1 for r in records if r.status == models.AttendanceStatus.LATE)
        injured = sum(1 for r in records if r.status == models.AttendanceStatus.INJURED)
        rate = round((present / total * 100), 1) if total > 0 else 0.0
        results.append(schemas.ParentAttendanceSummary(
            child_id=str(rel.child_id),
            child_name=child.name or "Child",
            total_sessions=total,
            present=present,
            absent=absent,
            late=late,
            injured=injured,
            attendance_rate=rate
        ))
    return results

@router.get("/parent/info", response_model=List[schemas.ParentAcademyInfo])
def get_parent_children_academy_info(
    db: Session = Depends(get_db),
    current_user: User = Depends(get_current_user)
):
    """Returns academy information for the academies that contain the parent's children."""
    relations = _get_accepted_children(db, current_user.id)
    child_ids = [rel.child_id for rel in relations]
    child_name_map = {rel.child_id: (rel.child.name or "Child") for rel in relations}

    academy_children: dict = {}
    for child_id in child_ids:
        enrollments = db.query(models.AcademyPlayer).filter(
            models.AcademyPlayer.player_id == child_id
        ).all()
        for enr in enrollments:
            if enr.academy_id not in academy_children:
                academy_children[enr.academy_id] = []
            academy_children[enr.academy_id].append(child_name_map.get(child_id, "Child"))

    results = []
    for academy_id, names in academy_children.items():
        academy = db.query(models.Academy).filter(models.Academy.id == academy_id).first()
        if not academy:
            continue
        schedules = db.query(models.TrainingSchedule).filter(
            models.TrainingSchedule.academy_id == academy_id
        ).all()
        schedule_items = [
            schemas.ParentAcademySchedule(
                day_of_week=s.day_of_week,
                start_time=str(s.start_time),
                end_time=str(s.end_time),
                location=s.location
            ) for s in schedules
        ]
        results.append(schemas.ParentAcademyInfo(
            academy_id=str(academy_id),
            name=academy.name,
            city=academy.city,
            address=academy.address,
            description=academy.description,
            child_names=list(set(names)),
            schedules=schedule_items
        ))
    return results

@router.get("/parent/billing", response_model=List[schemas.ParentBillingItem])
def get_parent_children_billing(
    db: Session = Depends(get_db),
    current_user: User = Depends(get_current_user),
    month: Optional[int] = None,
    year: Optional[int] = None
):
    """Returns billing summary for the current parent's accepted children."""
    now = datetime.now()
    month = month or now.month
    year = year or now.year

    relations = _get_accepted_children(db, current_user.id)
    results = []
    for rel in relations:
        child = rel.child
        enrollments = db.query(models.AcademyPlayer).filter(
            models.AcademyPlayer.player_id == rel.child_id
        ).first()
        if not enrollments:
            results.append(schemas.ParentBillingItem(
                child_id=str(rel.child_id),
                child_name=child.name or "Child",
                total_owed=0.0,
                base_fee=0.0,
                currency="KZT",
                total_sessions=0,
                present=0,
                absent=0
            ))
            continue
        try:
            summary = services.get_player_billing_summary(
                db, enrollments.academy_id, rel.child_id, month, year
            )
            results.append(schemas.ParentBillingItem(
                child_id=str(rel.child_id),
                child_name=child.name or "Child",
                total_owed=summary.total_owed,
                base_fee=summary.base_fee,
                currency=summary.currency,
                total_sessions=summary.attendance.total_sessions,
                present=summary.attendance.present,
                absent=summary.attendance.absent
            ))
        except Exception:
            results.append(schemas.ParentBillingItem(
                child_id=str(rel.child_id),
                child_name=child.name or "Child",
                total_owed=0.0,
                base_fee=0.0,
                currency="KZT",
                total_sessions=0,
                present=0,
                absent=0
            ))
    return results
