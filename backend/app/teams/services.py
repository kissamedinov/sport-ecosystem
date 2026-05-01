from sqlalchemy.orm import Session
from fastapi import HTTPException, status
from app.teams.models import Team, TeamMembership, MembershipRole, MembershipStatus, JoinStatus
from app.matches.models import Match, MatchStatus
from app.teams.schemas import TeamCreate
from app.users.models import User, Role, ParentChildRelation, PlayerProfile
from app.clubs.models import ChildProfile
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
        teams = db.query(Team).filter(Team.coach_id == user.id).all()
        # Filter out teams with 0 active members as per user request
        return [t for t in teams if db.query(TeamMembership).filter(TeamMembership.team_id == t.id, TeamMembership.status == MembershipStatus.ACTIVE).count() > 0]
    
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
    recent_matches = db.query(Match).filter(
        (Match.home_team_id == team_id) | (Match.away_team_id == team_id),
        Match.status == MatchStatus.FINISHED
    ).order_by(Match.match_date.desc()).limit(5).all()
    
    # Calculate form
    form = []
    for match in recent_matches:
        if not match.result: continue
        if match.home_team_id == team_id:
            if match.result.home_score > match.result.away_score: form.append("W")
            elif match.result.home_score < match.result.away_score: form.append("L")
            else: form.append("D")
        else:
            if match.result.away_score > match.result.home_score: form.append("W")
            elif match.result.away_score < match.result.home_score: form.append("L")
            else: form.append("D")
    
    # Populate players (Memberships)
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

def create_join_request(db: Session, team_id: UUID, current_user: User, child_profile_id: UUID = None):
    team = get_team_by_id(db, team_id)
    
    target_profile_id = None
    applicant_name = current_user.name

    if child_profile_id:
        # Parent applying for a child
        child = db.query(ChildProfile).filter(ChildProfile.id == child_profile_id).first()
        if not child:
            raise HTTPException(status_code=status.HTTP_404_NOT_FOUND, detail="Child profile not found")
        if child.created_by != current_user.id:
             raise HTTPException(status_code=status.HTTP_403_FORBIDDEN, detail="Not authorized to apply for this child")
        
        # Ensure child has a player profile
        profile = db.query(PlayerProfile).filter(PlayerProfile.user_id == child.linked_user_id).first() if child.linked_user_id else None
        if not profile:
            # Create a temporary player profile if none exists for the child
            profile = PlayerProfile(user_id=child.linked_user_id) if child.linked_user_id else PlayerProfile()
            db.add(profile)
            db.flush()
        
        target_profile_id = profile.id
        applicant_name = f"{child.first_name} {child.last_name} (Parent: {current_user.name})"
    else:
        # Player applying for themselves
        validate_player_age_for_team(current_user, team)
        profile = db.query(PlayerProfile).filter(PlayerProfile.user_id == current_user.id).first()
        if not profile:
            profile = PlayerProfile(user_id=current_user.id)
            db.add(profile)
            db.flush()
        target_profile_id = profile.id

    if current_user.id == team.coach_id:
        raise HTTPException(status_code=status.HTTP_400_BAD_REQUEST, detail="Coach cannot join their own team")
    
    existing_membership = db.query(TeamMembership).filter(
        TeamMembership.player_profile_id == target_profile_id,
        TeamMembership.team_id == team_id,
        TeamMembership.status == MembershipStatus.ACTIVE
    ).first()
    
    if existing_membership:
        if existing_membership.join_status == JoinStatus.PENDING:
            raise HTTPException(status_code=status.HTTP_400_BAD_REQUEST, detail="Join request already pending")
        raise HTTPException(status_code=status.HTTP_400_BAD_REQUEST, detail="Already actively in this team")

    new_member = TeamMembership(
        team_id=team_id,
        player_profile_id=target_profile_id,
        child_profile_id=child_profile_id,
        role=MembershipRole.PLAYER,
        status=MembershipStatus.ACTIVE,
        join_status=JoinStatus.PENDING
    )
    db.add(new_member)
    db.commit()
    db.refresh(new_member)
    
    notification_service.create_notification(
        db,
        user_ids=[team.coach_id],
        notification_type=NotificationType.JOIN_REQUEST_RECEIVED,
        title="Trial Session Request",
        message=f"{applicant_name} requested a trial with {team.name}",
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

    membership.join_status = JoinStatus.APPROVED
    db.commit()
    db.refresh(membership)

    player_user_id = membership.player_profile.user_id if membership.player_profile else None
    if player_user_id:
        notification_service.create_notification(
            db,
            user_ids=[player_user_id],
            notification_type=NotificationType.JOIN_REQUEST_ACCEPTED,
            title="Trial Approved!",
            message=f"Your trial request for {team.name} has been accepted! See you at training.",
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
    membership.join_status = JoinStatus.REJECTED
    membership.left_at = datetime.now(tz=pytz.UTC)
    db.commit()
    db.refresh(membership)
    return membership

def update_team(db: Session, team_id: UUID, team_in: any, current_user: User):
    team = db.query(Team).filter(Team.id == team_id).first()
    if not team:
        raise HTTPException(status_code=status.HTTP_404_NOT_FOUND, detail="Team not found")
    
    # Authorization check
    user_roles = {ur.role for ur in current_user.roles}
    is_owner = team.coach_id == current_user.id or Role.ADMIN in user_roles
    
    if not is_owner:
        raise HTTPException(status_code=status.HTTP_403_FORBIDDEN, detail="Not authorized to update this team")

    update_data = team_in.model_dump(exclude_unset=True)
    for field, value in update_data.items():
        setattr(team, field, value)

    # If academy_id was updated, ensure all players are in the academy registry
    if 'academy_id' in update_data and update_data['academy_id']:
        from app.academies.models import AcademyPlayer
        from app.academies.schemas import AcademyPlayerCreate
        from app.academies.services import add_player_to_academy
        
        memberships = db.query(TeamMembership).filter(
            TeamMembership.team_id == team.id,
            TeamMembership.status == MembershipStatus.ACTIVE
        ).all()
        
        for m in memberships:
            add_player_to_academy(db, team.academy_id, AcademyPlayerCreate(player_profile_id=m.player_profile_id))

    db.commit()
    db.refresh(team)
    return team
