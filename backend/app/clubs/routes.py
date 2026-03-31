from fastapi import APIRouter, Depends, status, HTTPException
from sqlalchemy.orm import Session
from typing import List
from uuid import UUID

from app.database import get_db
from app.users.models import User, Role
from app.common.dependencies import get_current_user, require_club_owner, require_club_staff, require_role
from app.clubs import schemas, services, models

router = APIRouter(prefix="/clubs", tags=["Clubs"])

@router.get("/dashboard", response_model=schemas.ClubDashboardResponse)
def get_my_club_dashboard(
    db: Session = Depends(get_db),
    current_user: User = Depends(get_current_user)
):
    try:
        # Check if user has required role
        user_roles = {ur.role for ur in current_user.roles}
        allowed_roles = {Role.CLUB_OWNER, Role.CLUB_MANAGER, Role.ADMIN, Role.PLAYER_ADULT}
        if not allowed_roles.intersection(user_roles):
            raise HTTPException(status_code=403, detail="Not authorized to view club dashboard")

        club = services.get_my_club(db, current_user.id)
        if not club:
            raise HTTPException(status_code=404, detail="Club not found for this user")
            
        return services.get_club_dashboard(db, club.id)
    except HTTPException as e:
        raise e
    except Exception as e:
        print(f"CRITICAL ERROR in /clubs/dashboard: {str(e)}")
        import traceback
        traceback.print_exc()
        raise HTTPException(status_code=500, detail="Internal Server Error")

# --- Club Creation Request System (Part 2) ---

@router.post("/requests", response_model=schemas.ClubRequestResponse)
def create_club_request(
    request_in: schemas.ClubRequestCreate,
    db: Session = Depends(get_db),
    current_user: User = Depends(get_current_user)
):
    return services.create_club_request(db, request_in, current_user.id)

@router.get("/admin/requests", response_model=List[schemas.ClubRequestResponse])
def get_all_club_requests(
    db: Session = Depends(get_db),
    current_user: User = Depends(require_role(Role.ADMIN))
):
    return services.get_club_requests(db)

@router.post("/admin/requests/{id}/approve", response_model=schemas.ClubResponse)
def approve_club_request(
    id: UUID,
    db: Session = Depends(get_db),
    current_user: User = Depends(require_role(Role.ADMIN))
):
    return services.approve_club_request(db, id)

@router.post("/admin/requests/{id}/reject", response_model=schemas.ClubRequestResponse)
def reject_club_request(
    id: UUID,
    db: Session = Depends(get_db),
    current_user: User = Depends(require_role(Role.ADMIN))
):
    return services.reject_club_request(db, id)

# --- Invitation System (Part 3 & 7) ---

@router.post("/invitations", response_model=schemas.InvitationResponse)
def send_invitation(
    invite_in: schemas.InvitationCreate,
    db: Session = Depends(get_db),
    current_user: User = Depends(require_club_staff)
):
    # Hierarchy Enforcement (Part 7)
    club = services.get_club_by_id(db, invite_in.club_id)
    if not club:
        raise HTTPException(status_code=404, detail="Club not found")
        
    is_owner = club.owner_id == current_user.id
    user_club_membership = db.query(models.ClubStaff).filter(
        models.ClubStaff.club_id == invite_in.club_id,
        models.ClubStaff.user_id == current_user.id,
        models.ClubStaff.status == models.ClubMembershipStatus.ACTIVE
    ).first()
    
    if not is_owner and not user_club_membership:
         raise HTTPException(status_code=403, detail="Not a member of this club")

    user_role = models.ClubRole.OWNER if is_owner else user_club_membership.role
    
    if user_role == models.ClubRole.MANAGER:
        # MANAGER can invite coaches and players
        if invite_in.role in [models.ClubRole.OWNER, models.ClubRole.MANAGER]:
            raise HTTPException(status_code=403, detail="Managers cannot invite Owners or other Managers")
    elif user_role == models.ClubRole.COACH:
        # COACH can only invite players
        if invite_in.role != models.ClubRole.PLAYER:
            raise HTTPException(status_code=403, detail="Coaches can only invite Players")
    elif user_role == models.ClubRole.PLAYER:
        raise HTTPException(status_code=403, detail="Players cannot invite anyone")

    return services.create_invitation(db, invite_in, current_user.id)

@router.post("/invitations/{id}/approve")
def approve_invitation(
    id: UUID,
    db: Session = Depends(get_db),
    current_user: User = Depends(require_club_owner)
):
    return services.approve_invitation(db, id, current_user.id)

@router.post("/invitations/{id}/accept")
def accept_invitation(
    id: UUID,
    db: Session = Depends(get_db),
    current_user: User = Depends(get_current_user)
):
    return services.accept_invitation(db, id, current_user.id)

@router.post("/invitations/{id}/decline")
def decline_invitation(
    id: UUID,
    db: Session = Depends(get_db),
    current_user: User = Depends(get_current_user)
):
    return services.decline_invitation(db, id, current_user.id)

@router.get("/invitations/my", response_model=List[schemas.InvitationResponse])
def get_my_invitations(
    db: Session = Depends(get_db),
    current_user: User = Depends(get_current_user)
):
    return services.get_user_invitations(db, current_user.id)

# --- Child Profiles (Part 4) ---

@router.post("/child-profiles", response_model=schemas.ChildProfileResponse)
def create_child_profile(
    profile_in: schemas.ChildProfileCreate,
    db: Session = Depends(get_db),
    current_user: User = Depends(require_club_staff)
):
    # Verify user is staff of the specific club
    is_staff = db.query(models.ClubStaff).filter(
        models.ClubStaff.club_id == profile_in.club_id,
        models.ClubStaff.user_id == current_user.id,
        models.ClubStaff.status == models.ClubMembershipStatus.ACTIVE
    ).first()
    
    club = services.get_club_by_id(db, profile_in.club_id)
    if not is_staff and (not club or club.owner_id != current_user.id):
        raise HTTPException(status_code=403, detail="Not authorized to create child profiles for this club")
        
    return services.create_child_profile(db, profile_in, current_user.id)

# --- Original & Management Routes ---

@router.get("/coach/dashboard", response_model=schemas.CoachDashboardResponse)
def get_coach_dashboard(
    db: Session = Depends(get_db),
    current_user: User = Depends(get_current_user)
):
    user_roles = {ur.role for ur in current_user.roles}
    if Role.COACH not in user_roles and Role.ADMIN not in user_roles:
         raise HTTPException(status_code=403, detail="Access denied. Coaching role required.")
    return services.get_coach_dashboard(db, current_user.id)

@router.get("/players/{player_id}/career", response_model=schemas.PlayerCareerResponse)
def get_player_career(
    player_id: UUID,
    db: Session = Depends(get_db)
):
    return services.get_player_career_history(db, player_id)

@router.post("/matches/{match_id}/teams/{team_id}/lineup")
def submit_lineup(
    match_id: UUID,
    team_id: UUID,
    lineup_in: schemas.MatchSheetCreate,
    db: Session = Depends(get_db),
    current_user: User = Depends(get_current_user)
):
    # Authorization logic: verify user is coach of the team or owner
    team = db.query(models.Team).filter(models.Team.id == team_id).first()
    if not team: raise HTTPException(status_code=404, detail="Team not found")
    
    is_coach = team.coach_id == current_user.id
    # Also check club owner
    club = team.academy.club
    is_owner = club.owner_id == current_user.id
    
    if not is_coach and not is_owner:
        raise HTTPException(status_code=403, detail="Not authorized to submit lineup for this team")
        
    return services.submit_match_lineup(db, match_id, team_id, lineup_in, current_user.id)

@router.post("/{club_id}/academies", response_model=schemas.AcademyResponse)
def create_academy(
    club_id: UUID,
    academy_in: schemas.AcademyCreate,
    db: Session = Depends(get_db),
    current_user: User = Depends(require_club_owner)
):
    club = services.get_club_by_id(db, club_id)
    if not club or club.owner_id != current_user.id:
         raise HTTPException(status_code=403, detail="Only the club owner can create academies")
    return services.create_academy_in_club(db, club_id, academy_in)

@router.post("/academies/{academy_id}/teams") # Simplified response
def create_team(
    academy_id: UUID,
    team_in: schemas.TeamCreateInAcademy,
    db: Session = Depends(get_db),
    current_user: User = Depends(require_club_staff)
):
    # Ownership/permission check is usually handled in service or manually
    return services.create_team_in_academy(db, academy_id, team_in)

@router.patch("/teams/{team_id}/coach", response_model=schemas.TeamResponseSimplified)
def reassign_team_coach(
    team_id: UUID,
    coach_id_in: UUID,
    db: Session = Depends(get_db),
    current_user: User = Depends(require_club_owner)
):
    return services.update_team_coach(db, team_id, coach_id_in)

@router.get("/{id}", response_model=schemas.ClubResponse)
def get_club(id: UUID, db: Session = Depends(get_db)):
    club = services.get_club_by_id(db, id)
    if not club: raise HTTPException(status_code=404, detail="Club not found")
    return club
