from sqlalchemy import func
from sqlalchemy.orm import Session
from fastapi import HTTPException, status
from uuid import UUID
from typing import List, Optional

from app.clubs import models, schemas
from app.users.models import User, Role, PlayerProfile, UserRole
from app.teams.models import Team, TeamMembership, MembershipRole, MembershipStatus
from app.clubs.models import Club, ClubStaff, ClubRole, ClubMembershipStatus

from app.academies.models import Academy
from app.notifications.service import create_notification, log_debug, mark_notifications_by_entity
from app.notifications.models import NotificationType, EntityType

def create_club(db: Session, club_in: schemas.ClubCreate, owner_id: UUID) -> Club:
    try:
        club = Club(
            name=club_in.name,
            city=club_in.city,
            owner_id=owner_id
        )
        db.add(club)
        db.flush()
        
        # Add owner as a member
        membership = ClubStaff(
            club_id=club.id,
            user_id=owner_id,
            role=ClubRole.OWNER,
            status=ClubMembershipStatus.ACTIVE
        )
        db.add(membership)
        db.commit()
        db.refresh(club)
        return club
    except Exception as e:
        db.rollback()
        print(f"CRITICAL ERROR in create_club: {str(e)}")
        import traceback; traceback.print_exc()
        raise HTTPException(status_code=500, detail=f"Internal Server Error during club creation: {str(e)}")

def get_clubs(db: Session, skip: int = 0, limit: int = 100) -> List[Club]:
    return db.query(Club).offset(skip).limit(limit).all()

def get_club_by_id(db: Session, club_id: UUID) -> Optional[Club]:
    return db.query(Club).filter(Club.id == club_id).first()

def get_my_club(db: Session, user_id: UUID) -> Optional[Club]:
    # 1. Search for club owned by user
    club = db.query(Club).filter(Club.owner_id == user_id).first()
    if club:
        return club
    
    # 2. Search for club where user is a manager or member
    membership = db.query(ClubStaff).filter(
        ClubStaff.user_id == user_id,
        ClubStaff.status == ClubMembershipStatus.ACTIVE
    ).first()
    
    if membership:
        return db.query(Club).filter(Club.id == membership.club_id).first()
    
    return None

def create_academy_in_club(db: Session, club_id: UUID, academy_in: schemas.AcademyCreate) -> Academy:
    try:
        club = get_club_by_id(db, club_id)
        if not club:
            raise HTTPException(status_code=404, detail="Club not found")
            
        academy = Academy(
            club_id=club_id,
            name=academy_in.name,
            city=academy_in.city,
            address=academy_in.address,
            owner_id=club.owner_id
        )
        db.add(academy)
        db.commit()
        db.refresh(academy)
        return academy
    except HTTPException as e:
        raise e
    except Exception as e:
        db.rollback()
        print(f"CRITICAL ERROR in create_academy_in_club: {str(e)}")
        import traceback; traceback.print_exc()
        raise HTTPException(status_code=500, detail=f"Internal Server Error during academy creation: {str(e)}")

def create_team_in_academy(db: Session, academy_id: UUID, team_in: schemas.TeamCreateInAcademy) -> Team:
    try:
        academy = db.query(Academy).filter(Academy.id == academy_id).first()
        if not academy:
            raise HTTPException(status_code=404, detail="Academy not found")
        
        team = Team(
            name=team_in.name,
            academy_id=academy_id,
            birth_year=team_in.birth_year,
            coach_id=team_in.coach_id
        )
        db.add(team)
        db.commit()
        db.refresh(team)
        return team
    except HTTPException as e:
        raise e
    except Exception as e:
        db.rollback()
        print(f"CRITICAL ERROR in create_team_in_academy: {str(e)}")
        import traceback; traceback.print_exc()
        raise HTTPException(status_code=500, detail=f"Internal Server Error during team creation: {str(e)}")

def get_club_dashboard(db: Session, club_id: UUID) -> schemas.ClubDashboardResponse:
    try:
        club = get_club_by_id(db, club_id)
        if not club:
            raise HTTPException(status_code=404, detail="Club not found")
            
        academies = db.query(Academy).filter(Academy.club_id == club.id).all()
        academy_ids = [a.id for a in academies]
        teams = db.query(Team).filter(Team.academy_id.in_(academy_ids)).all() if academy_ids else []

        academy_responses = []
        for a in academies:
            academy_responses.append(schemas.AcademyResponse(
                id=a.id,
                name=a.name,
                city=a.city,
                address=a.address,
                club_id=a.club_id,
                owner_id=a.owner_id or club.owner_id,
                logo_url=None,
                teams_count=len(a.youth_teams),
                players_count=len(a.players),
                created_at=a.created_at
            ))

        teams_responses = []
        for t in teams:
            teams_responses.append(schemas.TeamResponseSimplified(
                id=t.id,
                name=t.name,
                academy_id=t.academy_id,
                academy_name=t.academy.name,
                city=t.academy.city,
                coach_id=t.coach_id,
                rating=0,
                matches_played=0,
                wins=0,
                draws=0,
                losses=0,
                birth_year=t.birth_year,
                age_category=t.age_category
            ))

        # Get active players with their profile info
        active_players_staff = db.query(ClubStaff).filter(
            ClubStaff.club_id == club_id,
            ClubStaff.role == ClubRole.PLAYER,
            ClubStaff.status == ClubMembershipStatus.ACTIVE
        ).all()
        
        player_responses = []
        for s in active_players_staff:
             user = s.user
             profile = db.query(PlayerProfile).filter(PlayerProfile.user_id == user.id).first()
             player_responses.append(schemas.PlayerResponse(
                 user_id=user.id,
                 name=user.name,
                 profile_id=profile.id if profile else UUID('00000000-0000-0000-0000-000000000000'),
                 position=profile.preferred_position if (profile and hasattr(profile, 'preferred_position')) else None
             ))

        # Get active coaches
        active_coaches_staff = db.query(ClubStaff).filter(
            ClubStaff.club_id == club_id,
            ClubStaff.role == ClubRole.COACH,
            ClubStaff.status == ClubMembershipStatus.ACTIVE
        ).all()
        
        coach_responses = []
        for s in active_coaches_staff:
            coach_responses.append(schemas.PlayerResponse(
                user_id=s.user_id,
                name=s.user.name,
                profile_id=UUID('00000000-0000-0000-0000-000000000000'), # Staff don't have player profiles
                position="Coach"
            ))

        # Get active managers
        active_managers_staff = db.query(ClubStaff).filter(
            ClubStaff.club_id == club_id,
            ClubStaff.role == ClubRole.MANAGER,
            ClubStaff.status == ClubMembershipStatus.ACTIVE
        ).all()
        
        manager_responses = []
        for s in active_managers_staff:
            manager_responses.append(schemas.PlayerResponse(
                user_id=s.user_id,
                name=s.user.name,
                profile_id=UUID('00000000-0000-0000-0000-000000000000'),
                position="Manager"
            ))

        pending_invitations = db.query(models.Invitation).filter(
            models.Invitation.club_id == club_id,
            models.Invitation.status == models.InvitationStatus.PENDING
        ).all()
        
        child_profiles = db.query(models.ChildProfile).filter(models.ChildProfile.club_id == club_id).all()
        
        from datetime import datetime, timedelta
        thirty_days_ago = datetime.now() - timedelta(days=30)
        
        new_coaches_30d = db.query(ClubStaff).filter(
            ClubStaff.club_id == club_id,
            ClubStaff.role == ClubRole.COACH,
            ClubStaff.joined_at >= thirty_days_ago
        ).count()
        
        new_players_30d = db.query(ClubStaff).filter(
            ClubStaff.club_id == club_id,
            ClubStaff.role == ClubRole.PLAYER,
            ClubStaff.joined_at >= thirty_days_ago
        ).count()

        return schemas.ClubDashboardResponse(
            club=schemas.ClubResponse.model_validate(club),
            academies=academy_responses,
            teams=teams_responses,
            players=player_responses,
            coaches=coach_responses,
            managers=manager_responses,
            child_profiles=[schemas.ChildProfileResponse.model_validate(cp) for cp in child_profiles],
            players_count=len(player_responses),
            coaches_count=len(coach_responses),
            managers_count=len(manager_responses),
            pending_invitations=[schemas.InvitationResponse.model_validate(i) for i in pending_invitations],
            statistics={
                "academies_count": len(academies),
                "teams_count": len(teams),
                "players_count": len(player_responses),
                "coaches_count": len(coach_responses),
                "managers_count": len(manager_responses),
                "new_coaches_30d": new_coaches_30d,
                "new_players_30d": new_players_30d
            }
        )
    except Exception as e:
        print(f"Error in get_club_dashboard: {str(e)}")
        import traceback; traceback.print_exc()
        if isinstance(e, HTTPException): raise e
        raise HTTPException(status_code=500, detail=f"Internal Server Error during dashboard retrieval: {str(e)}")

def create_club_request(db: Session, request_in: schemas.ClubRequestCreate, user_id: UUID) -> models.ClubRequest:
    db_obj = models.ClubRequest(**request_in.model_dump(), created_by=user_id, status=models.RequestStatus.PENDING)
    db.add(db_obj)
    db.commit()
    db.refresh(db_obj)
    
    # Notify Admins
    try:
        admins = db.query(User).join(UserRole).filter(UserRole.role == Role.ADMIN).all()
        admin_ids = [a.id for a in admins]
        if admin_ids:
            create_notification(
                db,
                user_ids=admin_ids,
                notification_type=NotificationType.CLUB_REQUEST,
                title="New Club Registration Request",
                message=f"A new club '{request_in.name}' has been requested and is waiting for approval.",
                entity_type=EntityType.ACADEMY, # Approximate entity type
                entity_id=db_obj.id
            )
    except Exception as ne:
        print(f"Failed to notify admins of club request: {ne}")
        
    return db_obj

def get_club_requests(db: Session, skip: int = 0, limit: int = 100) -> List[models.ClubRequest]:
    return db.query(models.ClubRequest).offset(skip).limit(limit).all()

def approve_club_request(db: Session, request_id: UUID) -> models.Club:
    try:
        req = db.query(models.ClubRequest).filter(models.ClubRequest.id == request_id).first()
        if not req or req.status != models.RequestStatus.PENDING:
            raise HTTPException(status_code=400, detail="Invalid request")
        
        req.status = models.RequestStatus.APPROVED
        club = Club(name=req.name, city=req.city, owner_id=req.created_by)
        db.add(club)
        db.flush()
        
        db.add(ClubStaff(club_id=club.id, user_id=req.created_by, role=ClubRole.OWNER, status=ClubMembershipStatus.ACTIVE))
        
        # Global role
        if not db.query(UserRole).filter(UserRole.user_id == req.created_by, UserRole.role == Role.CLUB_OWNER).first():
            db.add(UserRole(user_id=req.created_by, role=Role.CLUB_OWNER))
            
        db.commit()
        
        # Notify User of Approval
        try:
            create_notification(
                db,
                user_ids=[req.created_by],
                notification_type=NotificationType.CLUB_APPROVED,
                title="Club Request Approved",
                message=f"Congratulations! Your request for '{req.name}' has been approved. You are now the owner.",
                entity_type=EntityType.ACADEMY,
                entity_id=club.id
            )
        except Exception as ne:
            print(f"Failed to notify user of club approval: {ne}")
            
        return club
    except HTTPException as e:
        raise e
    except Exception as e:
        db.rollback()
        print(f"CRITICAL ERROR in approve_club_request: {str(e)}")
        import traceback; traceback.print_exc()
        raise HTTPException(status_code=500, detail=f"Internal Server Error during club request approval: {str(e)}")

def reject_club_request(db: Session, request_id: UUID) -> models.ClubRequest:
    req = db.query(models.ClubRequest).filter(models.ClubRequest.id == request_id).first()
    if req:
        req.status = models.RequestStatus.REJECTED
        db.commit()
        
        # Notify User of Rejection
        try:
            create_notification(
                db,
                user_ids=[req.created_by],
                notification_type=NotificationType.CLUB_REJECTED,
                title="Club Request Rejected",
                message=f"We regret to inform you that your request for '{req.name}' has been rejected.",
                entity_type=EntityType.ACADEMY,
                entity_id=req.id
            )
        except Exception as ne:
            print(f"Failed to notify user of club rejection: {ne}")
    return req

def create_invitation(db: Session, invite_in: schemas.InvitationCreate, inviter_id: UUID) -> models.Invitation:
    try:
        if invite_in.invited_user_id == inviter_id:
            raise HTTPException(status_code=400, detail="Cannot invite yourself")
        
        # Check for duplicate pending invitation
        existing = db.query(models.Invitation).filter(
            models.Invitation.invited_user_id == invite_in.invited_user_id,
            models.Invitation.club_id == invite_in.club_id,
            models.Invitation.role == invite_in.role,
            models.Invitation.status == models.InvitationStatus.PENDING
        ).first()

        club = get_club_by_id(db, invite_in.club_id)
        if not club:
            raise HTTPException(status_code=404, detail="Club not found")
            
        is_owner = club.owner_id == inviter_id
        
        if existing:
            log_debug(f"Found existing pending invitation for user {invite_in.invited_user_id}. Re-triggering notification.")
            db_obj = existing
            is_approved = existing.is_approved
            # Optionally update team_id if it changed
            if invite_in.team_id:
                db_obj.team_id = invite_in.team_id
            db.commit()
            db.refresh(db_obj)
        else:
            log_debug(f"Creating new invitation for user {invite_in.invited_user_id}")
            is_approved = True
            if not is_owner and invite_in.role in [ClubRole.MANAGER, ClubRole.COACH]:
                is_approved = False # Manager can invite, but Owner must approve staff
            
            db_obj = models.Invitation(
                **invite_in.model_dump(),
                invited_by=inviter_id,
                is_approved=is_approved,
                status=models.InvitationStatus.PENDING
            )
            db.add(db_obj)
            db.commit()
            db.refresh(db_obj)
        
        # Create Notification
        try:
            log_debug(f"Starting notification creation for invite {db_obj.id}, is_approved={is_approved}")
            # Get inviter name
            inviter = db.query(User).filter(User.id == inviter_id).first()
            inviter_name = inviter.name if inviter else "Someone"
            log_debug(f"Inviter name: {inviter_name}")
            
            if is_approved:
                log_debug(f"Notifying invited user: {invite_in.invited_user_id}")
                create_notification(
                    db,
                    user_ids=[invite_in.invited_user_id],
                    notification_type=NotificationType.TEAM_INVITE,
                    title="New Club Invitation",
                    message=f"{inviter_name} invited you to join {club.name} as {invite_in.role.value}",
                    entity_type=EntityType.ACADEMY,
                    entity_id=db_obj.id
                )
            else:
                log_debug(f"Notifying owner for approval: {club.owner_id}")
                create_notification(
                    db,
                    user_ids=[club.owner_id],
                    notification_type=NotificationType.TEAM_INVITE,
                    title="Invitation Approval Required",
                    message=f"{inviter_name} wants to invite a new member. Please approve.",
                    entity_type=EntityType.ACADEMY,
                    entity_id=db_obj.id
                )
            log_debug("Notification creation call finished successfully")
        except Exception as ne:
            log_debug(f"Failed to create notification for invite: {ne}")
            import traceback
            log_debug(traceback.format_exc())

        return db_obj
    except HTTPException as e:
        raise e
    except Exception as e:
        db.rollback()
        print(f"CRITICAL ERROR in create_invitation: {str(e)}")
        import traceback; traceback.print_exc()
        raise HTTPException(status_code=500, detail=f"Internal Server Error during invitation creation: {str(e)}")

def accept_invitation(db: Session, invitation_id: UUID, user_id: UUID) -> dict:
    try:
        invite = db.query(models.Invitation).filter(models.Invitation.id == invitation_id).first()
        if not invite or invite.status != models.InvitationStatus.PENDING:
            raise HTTPException(status_code=400, detail="Invalid invitation")
        
        # Check if user is the invited user OR a parent of the invited user
        if invite.invited_user_id != user_id:
            from app.users.models import ParentChildRelation, ParentChildStatus
            relation = db.query(ParentChildRelation).filter(
                ParentChildRelation.parent_id == user_id,
                ParentChildRelation.child_id == invite.invited_user_id,
                ParentChildRelation.status.in_([ParentChildStatus.ACCEPTED, ParentChildStatus.PENDING])
            ).first()
            if not relation:
                raise HTTPException(status_code=403, detail="Not authorized to accept this invitation")
        
        if not invite.is_approved:
            raise HTTPException(status_code=403, detail="Invitation is pending owner approval")
        
        # Act as the invited user (the child) for the following logic
        target_user_id = invite.invited_user_id
        
        invite.status = models.InvitationStatus.ACCEPTED
        
        # Membership (for the child)
        db.add(models.ClubStaff(club_id=invite.club_id, user_id=target_user_id, role=invite.role, status=models.ClubMembershipStatus.ACTIVE))
        
        detail = "Invitation accepted"
        if invite.role == ClubRole.PLAYER:
            # Linking logic
            if invite.child_profile_id:
                cp = db.query(models.ChildProfile).filter(models.ChildProfile.id == invite.child_profile_id).first()
                if cp:
                    cp.linked_user_id = target_user_id
                    detail += f". Linked to child profile {cp.first_name}"
            
            # PlayerProfile (for the child)
            from app.users.models import PlayerProfile
            profile = db.query(PlayerProfile).filter(PlayerProfile.user_id == target_user_id).first()
            if not profile:
                profile = PlayerProfile(user_id=target_user_id)
                db.add(profile); db.flush()
                
            if invite.team_id:
                from app.teams.models import TeamMembership, MembershipStatus
                db.add(TeamMembership(team_id=invite.team_id, player_profile_id=profile.id, status=MembershipStatus.ACTIVE))
                detail += " and joined team"

        db.commit()
        
        # Create Notification for inviter
        try:
            # Get invitee name
            invitee = db.query(User).filter(User.id == user_id).first()
            invitee_name = invitee.name if invitee else "Someone"
            
            create_notification(
                db,
                user_ids=[invite.invited_by],
                notification_type=NotificationType.PLAYER_SELECTED, # Or similar for acceptance
                title="Invitation Accepted",
                message=f"{invitee_name} has accepted your invitation to join the club.",
                entity_type=EntityType.ACADEMY,
                entity_id=invite.club_id
            )
        except Exception as ne:
            print(f"Failed to create notification for acceptance: {ne}")

        # Clear existing notifications for this invitation
        try:
            mark_notifications_by_entity(db, invitation_id)
        except Exception as me:
            print(f"Failed to clear notifications for invitation {invitation_id}: {me}")

        return {"status": "success", "detail": detail}
    except HTTPException as e:
        raise e
    except Exception as e:
        db.rollback()
        print(f"CRITICAL ERROR in accept_invitation: {str(e)}")
        import traceback; traceback.print_exc()
        raise HTTPException(status_code=500, detail=f"Internal Server Error during invitation acceptance: {str(e)}")

def create_child_profile(db: Session, profile_in: schemas.ChildProfileCreate, creator_id: UUID) -> models.ChildProfile:
    try:
        db_obj = models.ChildProfile(**profile_in.model_dump(), created_by=creator_id)
        db.add(db_obj); db.commit(); db.refresh(db_obj)
        return db_obj
    except Exception as e:
        db.rollback()
        print(f"CRITICAL ERROR in create_child_profile: {str(e)}")
        import traceback; traceback.print_exc()
        raise HTTPException(status_code=500, detail=f"Internal Server Error during child profile creation: {str(e)}")

def get_user_invitations(db: Session, user_id: UUID) -> List[models.Invitation]:
    return db.query(models.Invitation).filter(models.Invitation.invited_user_id == user_id, models.Invitation.status == models.InvitationStatus.PENDING).all()

def approve_invitation(db: Session, invitation_id: UUID, current_user_id: UUID) -> dict:
    try:
        invite = db.query(models.Invitation).filter(models.Invitation.id == invitation_id).first()
        if not invite: raise HTTPException(status_code=404, detail="Invitation not found")
        
        # Check if user is owner of the club the invite belongs to
        club = get_club_by_id(db, invite.club_id)
        if not club or club.owner_id != current_user_id:
            raise HTTPException(status_code=403, detail="Only the club owner can approve staff invitations")
            
        invite.is_approved = True
        db.commit()
        
        # Create notification for invited user that their invite is now approved
        try:
            create_notification(
                db,
                user_ids=[invite.invited_user_id],
                notification_type=NotificationType.TEAM_INVITE,
                title="Invitation Approved",
                message=f"Your invitation to join {club.name} has been approved by the owner and is ready for acceptance.",
                entity_type=EntityType.ACADEMY,
                entity_id=invite.id
            )
        except Exception as ne:
            print(f"Failed to create notification for approval: {ne}")
            
        return {"status": "success", "detail": "Invitation approved by owner"}
    except HTTPException as e:
        raise e
    except Exception as e:
        db.rollback()
        print(f"CRITICAL ERROR in approve_invitation: {str(e)}")
        raise HTTPException(status_code=500, detail="Internal Server Error during invitation approval")

def decline_invitation(db: Session, invitation_id: UUID, user_id: UUID) -> dict:
    try:
        invite = db.query(models.Invitation).filter(models.Invitation.id == invitation_id).first()
        if not invite or invite.status != models.InvitationStatus.PENDING:
            raise HTTPException(status_code=400, detail="Invalid invitation")
        
        # Check if user is the invited user OR a parent of the invited user
        if invite.invited_user_id != user_id:
            from app.users.models import ParentChildRelation, ParentChildStatus
            relation = db.query(ParentChildRelation).filter(
                ParentChildRelation.parent_id == user_id,
                ParentChildRelation.child_id == invite.invited_user_id,
                ParentChildRelation.status.in_([ParentChildStatus.ACCEPTED, ParentChildStatus.PENDING])
            ).first()
            if not relation:
                raise HTTPException(status_code=403, detail="Not authorized to decline this invitation")

        invite.status = models.InvitationStatus.REJECTED
        db.commit()
        
        # Create Notification for inviter
        try:
            # Get invitee name
            invitee = db.query(User).filter(User.id == user_id).first()
            invitee_name = invitee.name if invitee else "Someone"
            
            create_notification(
                db,
                user_ids=[invite.invited_by],
                notification_type=NotificationType.PLAYER_SELECTED, # Or similar for rejection
                title="Invitation Declined",
                message=f"{invitee_name} has declined your invitation.",
                entity_type=EntityType.ACADEMY,
                entity_id=invite.club_id
            )
        except Exception as ne:
            print(f"Failed to create notification for decline: {ne}")
            
        # Clear existing notifications for this invitation
        try:
            mark_notifications_by_entity(db, invitation_id)
        except Exception as me:
            print(f"Failed to clear notifications for invitation {invitation_id}: {me}")

        return {"status": "success", "detail": "Invitation declined"}
    except HTTPException as e:
        raise e
    except Exception as e:
        db.rollback()
        print(f"CRITICAL ERROR in decline_invitation: {str(e)}")
        raise HTTPException(status_code=500, detail="Internal Server Error during invitation decline")

def get_coach_dashboard(db: Session, coach_id: UUID) -> schemas.CoachDashboardResponse:
    from app.matches.models import Match, MatchResult, MatchStatus
    
    # Get teams coached by this user
    teams = db.query(models.Team).filter(models.Team.coach_id == coach_id).all()
    team_ids = [t.id for t in teams]
    
    team_responses = []
    for t in teams:
        # Get players in this team
        mems = db.query(TeamMembership).filter(TeamMembership.team_id == t.id, TeamMembership.status == MembershipStatus.ACTIVE).all()
        players = []
        for m in mems:
            if not m.player_profile:
                continue
            user = m.player_profile.user
            if not user:
                continue
                
            players.append(schemas.CoachPlayerResponse(
                user_id=user.id,
                name=user.name,
                profile_id=m.player_profile_id,
                position=m.player_profile.preferred_position if hasattr(m.player_profile, 'preferred_position') else None,
                jersey_number=m.jersey_number
            ))
        
        team_responses.append(schemas.CoachTeamResponse(
            id=t.id,
            name=t.name,
            birth_year=t.birth_year,
            players=players
        ))
    
    # Calculate Performance Stats
    perf = schemas.CoachPerformanceStats()
    if team_ids:
        # Finished matches
        finished_matches = db.query(Match).filter(
            (Match.home_team_id.in_(team_ids)) | (Match.away_team_id.in_(team_ids)),
            Match.status == MatchStatus.FINISHED
        ).all()
        
        perf.matches_played = len(finished_matches)
        for m in finished_matches:
            if not m.result: continue
            
            is_home = m.home_team_id in team_ids
            my_score = m.result.home_score if is_home else m.result.away_score
            opp_score = m.result.away_score if is_home else m.result.home_score
            
            perf.goals_scored += my_score
            perf.goals_conceded += opp_score
            if opp_score == 0: perf.clean_sheets += 1
            
            if my_score > opp_score: perf.wins += 1
            elif my_score < opp_score: perf.losses += 1
            else: perf.draws += 1
            
    # Upcoming matches
    upcoming_matches = []
    if team_ids:
        future_matches = db.query(Match).filter(
            (Match.home_team_id.in_(team_ids)) | (Match.away_team_id.in_(team_ids)),
            Match.status == MatchStatus.SCHEDULED
        ).order_by(Match.match_date.asc()).limit(5).all()
        
        for m in future_matches:
            upcoming_matches.append(schemas.CoachMatchResponse(
                id=m.id,
                tournament_name=m.tournament.name if m.tournament else "Friendly",
                home_team_name=m.home_team.name,
                away_team_name=m.away_team.name,
                scheduled_at=m.match_date
            ))

    return schemas.CoachDashboardResponse(
        teams=team_responses,
        upcoming_matches=upcoming_matches,
        performance_stats=perf
    )

def update_team_coach(db: Session, team_id: UUID, new_coach_id: UUID) -> models.Team:
    team = db.query(models.Team).filter(models.Team.id == team_id).first()
    if not team:
        raise HTTPException(status_code=404, detail="Team not found")
    
    # Check if new coach is actually a coach in the club
    is_coach = db.query(ClubStaff).filter(
        ClubStaff.club_id == team.academy.club_id,
        ClubStaff.user_id == new_coach_id,
        ClubStaff.role == ClubRole.COACH,
        ClubStaff.status == ClubMembershipStatus.ACTIVE
    ).first()
    
    if not is_coach:
        raise HTTPException(status_code=400, detail="User is not an active coach in this club")
        
    team.coach_id = new_coach_id
    db.commit()
    db.refresh(team)
    return team

# --- Endpoints for tournaments/lineups (Originals) ---
def submit_match_lineup(db: Session, match_id: UUID, team_id: UUID, lineup_in: schemas.MatchSheetCreate, user_id: UUID):
    from app.tournaments.models import MatchSheet, MatchSheetPlayer
    sheet = MatchSheet(match_id=match_id, team_id=team_id, submitted_by=user_id)
    db.add(sheet); db.flush()
    for p in lineup_in.players:
        db.add(MatchSheetPlayer(match_sheet_id=sheet.id, player_profile_id=p.player_profile_id, jersey_number=p.jersey_number, is_starting=p.is_starting))
    db.commit(); return sheet

def get_player_career_history(db: Session, player_profile_id: UUID) -> schemas.PlayerCareerResponse:
    profile = db.query(PlayerProfile).filter(PlayerProfile.id == player_profile_id).first()
    if not profile: raise HTTPException(status_code=404, detail="Profile not found")
    mems = db.query(TeamMembership).filter(TeamMembership.player_profile_id == player_profile_id).order_by(TeamMembership.joined_at.desc()).all()
    career = [schemas.CareerRecord(club_name=m.team.academy.club.name, team_name=m.team.name, joined_at=m.joined_at, left_at=m.left_at, status=m.status.value) for m in mems]
    return schemas.PlayerCareerResponse(player_name=profile.user.name, career_history=career, total_goals=0, total_assists=0, awards=[])
