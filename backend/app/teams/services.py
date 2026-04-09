from sqlalchemy.orm import Session
from fastapi import HTTPException, status
from app.teams.models import Team, TeamMembership, MembershipRole, MembershipStatus, JoinStatus
from app.tournaments.models import TournamentMatch, MatchStatus
from app.teams.schemas import TeamCreate
from app.users.models import User, Role, ParentChildRelation, PlayerProfile
from uuid import UUID
from app.notifications import service as notification_service
from app.notifications.models import NotificationType, EntityType
from datetime import datetime, date

def calculate_age(dob: date) -> int:
    today = date.today()
    return today.year - dob.year - ((today.month, today.day) < (dob.month, dob.day))

def get_age_category_from_dob(dob: date) -> str:
    age = calculate_age(dob)
    if 6 <= age <= 7: return "U7"
    if 8 <= age <= 9: return "U9"
    if 10 <= age <= 11: return "U11"
    if 12 <= age <= 13: return "U13"
    if 14 <= age <= 15: return "U15"
    if 16 <= age <= 17: return "U17"
    if age > 17: return "ADULT"
    return "UNKNOWN"

def validate_player_age_for_team(player: User, team: Team):
    if not player.date_of_birth:
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST, 
            detail="Player must have a date of birth to be assigned to an age-categorized team"
        )
    
    player_category = get_age_category_from_dob(player.date_of_birth)
    
    if not team.age_category:
        # If team has no category, it inherits the first player's category
        team.age_category = player_category
        return
    
    # Strict validation mapping (Requirement Part 4)
    if player_category != team.age_category:
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST, 
            detail=f"Player age category ({player_category}) does not match team category ({team.age_category})"
        )

def create_team(db: Session, team_in: TeamCreate, current_user: User):
    new_team = Team(
        name=team_in.name,
        coach_id=current_user.id,
        academy_id=team_in.academy_id if hasattr(team_in, 'academy_id') else None,
        age_category=team_in.age_category if hasattr(team_in, 'age_category') else None
    )
    db.add(new_team)
    db.commit()
    db.refresh(new_team)
    return new_team

def get_teams(db: Session):
    return db.query(Team).all()

def get_team_rankings(db: Session):
    return db.query(Team).order_by(Team.rating.desc()).all()

def get_my_teams(db: Session, user: User):
    user_roles = [ur.role for ur in user.roles]
    if any(role in user_roles for role in [Role.COACH, Role.TEAM_OWNER, Role.CLUB_OWNER, Role.CLUB_MANAGER, Role.ADMIN]):
        return db.query(Team).filter(Team.coach_id == user.id).all()
    
    # If it's a player, find teams via TeamMembership
    profile = db.query(PlayerProfile).filter(PlayerProfile.user_id == user.id).first()
    if not profile:
        return []
        
    memberships = db.query(TeamMembership).filter(
        TeamMembership.player_profile_id == profile.id,
        TeamMembership.status == MembershipStatus.ACTIVE
    ).all()
    
    team_ids = [m.team_id for m in memberships]
    return db.query(Team).filter(Team.id.in_(team_ids)).all()

def get_team_by_id(db: Session, team_id: UUID, current_user: User = None):
    team = db.query(Team).filter(Team.id == team_id).first()
    if not team:
        raise HTTPException(status_code=status.HTTP_404_NOT_FOUND, detail="Team not found")
    
    # Fetch recent completed matches
    recent_matches = db.query(TournamentMatch).filter(
        (TournamentMatch.home_team_id == team_id) | (TournamentMatch.away_team_id == team_id),
        TournamentMatch.status == MatchStatus.FINISHED
    ).order_by(TournamentMatch.start_time.desc()).limit(5).all()
    
    # Calculate form
    form = []
    for match in recent_matches:
        if match.home_team_id == team_id:
            if match.home_score > match.away_score: form.append("W")
            elif match.home_score < match.away_score: form.append("L")
            else: form.append("D")
        else:
            if match.away_score > match.home_score: form.append("W")
            elif match.away_score < match.home_score: form.append("L")
            else: form.append("D")
    
    # Populate players (Memberships)
    # This is crucial for TeamDetailResponse
    team.players = db.query(TeamMembership).filter(
        TeamMembership.team_id == team_id, 
        TeamMembership.status == MembershipStatus.ACTIVE
    ).all()
    
    team.recent_matches = recent_matches
    team.form = form
    
    return team

def get_team_members(db: Session, team_id: UUID, current_user: User = None):
    team = get_team_by_id(db, team_id)
    
    if current_user:
        user_roles = {ur.role for ur in current_user.roles}
        is_coach = Role.COACH in user_roles and team.coach_id == current_user.id
        is_admin = Role.ADMIN in user_roles
        
        # Check if Club Owner
        is_owner = False
        if Role.CLUB_OWNER in user_roles:
            is_owner = team.academy.club.owner_id == current_user.id
            
        is_member = db.query(TeamMembership).join(PlayerProfile).filter(
            TeamMembership.team_id == team_id,
            PlayerProfile.user_id == current_user.id,
            TeamMembership.status == MembershipStatus.ACTIVE
        ).first() is not None
        
        is_parent_of_member = False
        if Role.PARENT in user_roles:
            child_ids = db.query(ParentChildRelation.child_id).filter(
                ParentChildRelation.parent_id == current_user.id
            ).all()
            child_ids = [c[0] for c in child_ids]
            is_parent_of_member = db.query(TeamMembership).join(PlayerProfile).filter(
                TeamMembership.team_id == team_id,
                PlayerProfile.user_id.in_(child_ids),
                TeamMembership.status == MembershipStatus.ACTIVE
            ).first() is not None

        if not (is_coach or is_admin or is_owner or is_member or is_parent_of_member):
            raise HTTPException(
                status_code=status.HTTP_403_FORBIDDEN, 
                detail="You are not authorized to view this team's roster"
            )

    return db.query(TeamMembership).filter(TeamMembership.team_id == team_id, TeamMembership.status == MembershipStatus.ACTIVE).all()

def add_player_to_team(db: Session, team_id: UUID, player_id: UUID, current_user: User):
    try:
        team = get_team_by_id(db, team_id)
        
        user_roles = [ur.role for ur in current_user.roles]
        is_authorized = Role.COACH in user_roles or Role.TEAM_OWNER in user_roles
        
        if not is_authorized or (Role.COACH in user_roles and team.coach_id != current_user.id):
             raise HTTPException(status_code=status.HTTP_403_FORBIDDEN, detail="Not authorized to manage this team")

        player = db.query(User).filter(User.id == player_id).first()
        if not player:
            raise HTTPException(status_code=status.HTTP_404_NOT_FOUND, detail="Player not found")

        validate_player_age_for_team(player, team)

        # Ensure player has a profile
        profile = db.query(PlayerProfile).filter(PlayerProfile.user_id == player_id).first()
        if not profile:
            profile = PlayerProfile(user_id=player_id)
            db.add(profile)
            db.flush()

        existing = db.query(TeamMembership).filter(
            TeamMembership.team_id == team_id, 
            TeamMembership.player_profile_id == profile.id, 
            TeamMembership.status == MembershipStatus.ACTIVE
        ).first()
        
        if existing:
            raise HTTPException(status_code=status.HTTP_400_BAD_REQUEST, detail="Player already has an active membership in this team")

        new_membership = TeamMembership(
            team_id=team_id,
            player_profile_id=profile.id,
            role=MembershipRole.PLAYER,
            status=MembershipStatus.ACTIVE
        )
        db.add(new_membership)
        db.commit()
        db.refresh(new_membership)
        return new_membership
    except HTTPException as e:
        raise e
    except Exception as e:
        db.rollback()
        print(f"CRITICAL ERROR in add_player_to_team: {str(e)}")
        import traceback; traceback.print_exc()
        raise HTTPException(status_code=500, detail=f"Internal Server Error during player assignment: {str(e)}")

def create_join_request(db: Session, team_id: UUID, current_user: User):
    team = get_team_by_id(db, team_id)
    validate_player_age_for_team(current_user, team)
    
    if current_user.id == team.coach_id:
        raise HTTPException(status_code=status.HTTP_400_BAD_REQUEST, detail="Coach cannot join their own team")
    
    # Ensure player has a profile
    profile = db.query(PlayerProfile).filter(PlayerProfile.user_id == current_user.id).first()
    if not profile:
        profile = PlayerProfile(user_id=current_user.id)
        db.add(profile)
        db.flush()

    existing_membership = db.query(TeamMembership).filter(
        TeamMembership.player_profile_id == profile.id,
        TeamMembership.status == MembershipStatus.ACTIVE
    ).first()
    
    if existing_membership:
        if existing_membership.team_id == team_id:
            raise HTTPException(status_code=status.HTTP_400_BAD_REQUEST, detail="Already actively in this team")
        else:
            raise HTTPException(status_code=status.HTTP_400_BAD_REQUEST, detail="Player cannot be active in multiple teams at once")

    new_member = TeamMembership(
        team_id=team_id,
        player_profile_id=profile.id,
        role=MembershipRole.PLAYER,
        status=MembershipStatus.ACTIVE
    )
    db.add(new_member)
    db.commit()
    db.refresh(new_member)
    
    notification_service.create_notification(
        db,
        user_ids=[team.coach_id],
        notification_type=NotificationType.JOIN_REQUEST_RECEIVED,
        title="New Join Request",
        message=f"{current_user.name} wants to join your team {team.name}",
        entity_type=EntityType.PLAYER,
        entity_id=current_user.id
    )
    return new_member

def approve_join_request(db: Session, team_id: UUID, request_id: UUID, current_user: User):
    team = get_team_by_id(db, team_id)
    if team.coach_id != current_user.id:
        raise HTTPException(status_code=status.HTTP_403_FORBIDDEN, detail="Only the coach can approve requests")

    membership = db.query(TeamMembership).filter(TeamMembership.id == request_id, TeamMembership.team_id == team_id).first()
    if not membership:
        raise HTTPException(status_code=status.HTTP_404_NOT_FOUND, detail="Request not found")

    player_user_id = membership.player_profile.user_id if membership.player_profile else None
    if player_user_id:
        notification_service.create_notification(
            db,
            user_ids=[player_user_id],
            notification_type=NotificationType.JOIN_REQUEST_ACCEPTED,
            title="Join Request Accepted",
            message=f"Your request to join {team.name} has been accepted!",
            entity_type=EntityType.PLAYER,
            entity_id=team_id
        )
    return membership

def reject_join_request(db: Session, team_id: UUID, request_id: UUID, current_user: User):
    team = get_team_by_id(db, team_id)
    if team.coach_id != current_user.id:
        raise HTTPException(status_code=status.HTTP_403_FORBIDDEN, detail="Only the coach can reject requests")

    membership = db.query(TeamMembership).filter(TeamMembership.id == request_id, TeamMembership.team_id == team_id).first()
    if not membership:
        raise HTTPException(status_code=status.HTTP_404_NOT_FOUND, detail="Request not found")

    player_user_id = membership.player_profile.user_id if membership.player_profile else None
    if player_user_id:
        notification_service.create_notification(
            db,
            user_ids=[player_user_id],
            notification_type=NotificationType.JOIN_REQUEST_REJECTED,
            title="Join Request Declined",
            message=f"Your request to join {team.name} has been declined.",
            entity_type=EntityType.PLAYER,
            entity_id=team_id
        )

    import pytz
    membership.left_at = datetime.now(tz=pytz.UTC)
    db.commit()
    db.refresh(membership)
    return membership
