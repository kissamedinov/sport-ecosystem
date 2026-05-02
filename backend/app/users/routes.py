from fastapi import APIRouter, Depends, HTTPException, status
from sqlalchemy import select
from sqlalchemy.orm import Session
from typing import List
from uuid import UUID
from app.database import get_db
from app.users import models, schemas
from app.common.dependencies import get_current_user, require_parent
from app.auth.security import hash_password
from app.notifications.models import NotificationType, EntityType
from app.notifications.service import create_notification

router = APIRouter(prefix="/users", tags=["users"])

@router.get("/my-children", response_model=List[schemas.UserResponse])
def get_my_children(
    current_user: models.User = Depends(require_parent),
    db: Session = Depends(get_db)
):
    try:
        """
        Returns a list of youth players linked to this parent.
        """
        children_relations = db.query(models.ParentChildRelation).filter(
            models.ParentChildRelation.parent_id == current_user.id,
            models.ParentChildRelation.status == models.ParentChildStatus.ACCEPTED
        ).all()
        
        children_ids = [rel.child_id for rel in children_relations]
        children = db.query(models.User).filter(models.User.id.in_(children_ids)).all()
        
        response = []
        for child in children:
            # Safer way to get roles that bypasses model attributes to avoid 500 error
            stmt = select(models.UserRole.role).where(models.UserRole.user_id == child.id)
            roles_list_query = db.execute(stmt).scalars().all()
            roles_list = [r.value for r in roles_list_query]
            
            child_data = {
                "id": child.id,
                "name": child.name,
                "email": child.email,
                "roles": roles_list,
                "role": roles_list[0] if roles_list else "PLAYER_YOUTH",
                "created_at": child.created_at,
                "date_of_birth": child.date_of_birth,
                "phone": child.phone,
                "onboarding_completed": child.onboarding_completed,
                "unique_code": child.unique_code
            }

            response.append(child_data)
            
        return response
    except Exception as e:
        print(f"CRITICAL ERROR in get_my_children: {str(e)}")
        import traceback; traceback.print_exc()
        raise HTTPException(status_code=500, detail=f"Internal Server Error during children retrieval: {str(e)}")

@router.post("/link-child/{child_id}")
def link_child(
    child_id: UUID,
    current_user: models.User = Depends(require_parent),
    db: Session = Depends(get_db)
):
    """
    Links a parent to a child player.
    """
    child = db.query(models.User).filter(models.User.id == child_id).first()
    if not child:
        raise HTTPException(status_code=404, detail="Child not found")
    
    # Check if relation already exists
    existing = db.query(models.ParentChildRelation).filter(
        models.ParentChildRelation.parent_id == current_user.id,
        models.ParentChildRelation.child_id == child_id
    ).first()
    if existing:
        return {"message": "Already linked"}
        
    new_relation = models.ParentChildRelation(
        parent_id=current_user.id,
        child_id=child_id,
        relation_type=models.RelationType.GUARDIAN,
        status=models.ParentChildStatus.PENDING
    )
    db.add(new_relation)
    db.commit()
    
    try:
        create_notification(
            db,
            user_ids=[child_id],
            notification_type=NotificationType.PARENT_LINK_REQUEST,
            title="Parent Link Request",
            message=f"{current_user.name} wants to link to your account as a parent/guardian.",
            entity_type=EntityType.PLAYER,
            entity_id=new_relation.id
        )
    except Exception as e:
        print(f"Failed to create notification: {e}")
        
    return {"message": "Request sent to child. Waiting for approval."}

@router.post("/link-child-by-email")
def link_child_by_email(
    request: schemas.LinkChildByEmailRequest,
    current_user: models.User = Depends(require_parent),
    db: Session = Depends(get_db)
):
    """
    Links a parent to a child player securely by searching for their email.
    """
    child = db.query(models.User).filter(models.User.email == request.email).first()
    if not child:
        raise HTTPException(status_code=404, detail="No child account found with that email")
        
    child_roles = {ur.role for ur in child.roles}
    if models.Role.PLAYER_CHILD not in child_roles and models.Role.PLAYER_YOUTH not in child_roles:
        raise HTTPException(status_code=400, detail="The specified email does not belong to a child account")

    # Check if relation already exists
    existing = db.query(models.ParentChildRelation).filter(
        models.ParentChildRelation.parent_id == current_user.id,
        models.ParentChildRelation.child_id == child.id
    ).first()
    
    if existing:
        if existing.status == models.ParentChildStatus.ACCEPTED:
            return {"message": "Already linked"}
        elif existing.status == models.ParentChildStatus.PENDING:
            # Resend the notification if it was missed
            try:
                create_notification(
                    db,
                    user_ids=[child.id],
                    notification_type=NotificationType.PARENT_LINK_REQUEST,
                    title="Parent Link Request (Resent)",
                    message=f"{current_user.name} wants to link to your account as a parent.",
                    entity_type=EntityType.PLAYER,
                    entity_id=existing.id
                )
            except Exception as e:
                pass
            return {"message": "Request already pending. We sent a new notification to the child!"}
            
    new_relation = models.ParentChildRelation(
        parent_id=current_user.id,
        child_id=child.id,
        relation_type=models.RelationType.GUARDIAN,
        status=models.ParentChildStatus.PENDING
    )
    db.add(new_relation)
    db.commit()

    try:
        create_notification(
            db,
            user_ids=[child.id],
            notification_type=NotificationType.PARENT_LINK_REQUEST,
            title="Parent Link Request",
            message=f"{current_user.name} wants to link to your account as a parent/guardian.",
            entity_type=EntityType.PLAYER,
            entity_id=new_relation.id
        )
    except Exception as e:
        print(f"Failed to create notification: {e}")

    return {"message": "Link request sent successfully via email!"}

@router.get("/parents", response_model=List[schemas.UserResponse])
def get_parents(
    current_user: models.User = Depends(get_current_user),
    db: Session = Depends(get_db)
):
    """
    Returns list of accepted parents for the current user (child).
    """
    relations = db.query(models.ParentChildRelation).filter(
        models.ParentChildRelation.child_id == current_user.id,
        models.ParentChildRelation.status == models.ParentChildStatus.ACCEPTED
    ).all()
    
    parents_response = []
    for rel in relations:
        parent = db.query(models.User).filter(models.User.id == rel.parent_id).first()
        if parent:
            # Safer way to get roles that bypasses model attributes
            stmt = select(models.UserRole.role).where(models.UserRole.user_id == parent.id)
            roles_list_query = db.execute(stmt).scalars().all()
            roles_list = [r.value for r in roles_list_query]
            
            parent_data = {
                "id": parent.id,
                "name": parent.name,
                "email": parent.email,
                "roles": roles_list,
                "role": roles_list[0] if roles_list else "PARENT",
                "created_at": parent.created_at,
                "date_of_birth": parent.date_of_birth,
                "phone": parent.phone,
                "onboarding_completed": parent.onboarding_completed,
                "unique_code": parent.unique_code
            }

            parents_response.append(parent_data)
    return parents_response

@router.patch("/me", response_model=schemas.UserResponse)
def update_my_profile(
    user_update: schemas.UserUpdate,
    current_user: models.User = Depends(get_current_user),
    db: Session = Depends(get_db)
):
    if user_update.name is not None:
        current_user.name = user_update.name
    if user_update.date_of_birth is not None:
        current_user.date_of_birth = user_update.date_of_birth
        # Sync with ChildProfile if exists
        from app.clubs.models import ChildProfile
        child_profile = db.query(ChildProfile).filter(ChildProfile.linked_user_id == current_user.id).first()
        if child_profile:
            import datetime
            # Convert date to datetime for ChildProfile
            child_profile.date_of_birth = datetime.datetime.combine(user_update.date_of_birth, datetime.time.min)
    if user_update.phone is not None:
        current_user.phone = user_update.phone
    if user_update.bio is not None:
        current_user.bio = user_update.bio
    if user_update.avatar_url is not None:
        current_user.avatar_url = user_update.avatar_url
    
    db.commit()
    db.refresh(current_user)
    
    stmt = select(models.UserRole.role).where(models.UserRole.user_id == current_user.id)
    roles_list = [r.value for r in db.execute(stmt).scalars().all()]
    
    return {
        "id": current_user.id,
        "name": current_user.name,
        "email": current_user.email,
        "roles": roles_list,
        "role": roles_list[0] if roles_list else "PLAYER_ADULT",
        "created_at": current_user.created_at,
        "date_of_birth": current_user.date_of_birth,
        "phone": current_user.phone,
        "bio": current_user.bio,
        "avatar_url": current_user.avatar_url,
        "onboarding_completed": current_user.onboarding_completed,
        "unique_code": current_user.unique_code
    }


@router.patch("/{user_id}", response_model=schemas.UserResponse)
def update_user_profile(
    user_id: UUID,
    user_update: schemas.UserUpdate,
    current_user: models.User = Depends(get_current_user),
    db: Session = Depends(get_db)
):
    if current_user.id == user_id:
        target_user = current_user
    else:
        # Check if parent-child link exists
        is_link = db.query(models.ParentChildRelation).filter(
            models.ParentChildRelation.parent_id == current_user.id,
            models.ParentChildRelation.child_id == user_id
        ).first()
        if not is_link:
            raise HTTPException(status_code=403, detail="Not authorized to update this user profile")
        target_user = db.query(models.User).filter(models.User.id == user_id).first()

    if not target_user:
        raise HTTPException(status_code=404, detail="User not found")

    if user_update.name is not None:
        target_user.name = user_update.name
    if user_update.date_of_birth is not None:
        target_user.date_of_birth = user_update.date_of_birth
        # Sync with ChildProfile if exists
        from app.clubs.models import ChildProfile
        child_profile = db.query(ChildProfile).filter(ChildProfile.linked_user_id == target_user.id).first()
        if child_profile:
            import datetime
            child_profile.date_of_birth = datetime.datetime.combine(user_update.date_of_birth, datetime.time.min)
    if user_update.phone is not None:
        target_user.phone = user_update.phone
    if user_update.bio is not None:
        target_user.bio = user_update.bio
    if user_update.avatar_url is not None:
        target_user.avatar_url = user_update.avatar_url
    
    db.commit()
    db.refresh(target_user)
    
    stmt = select(models.UserRole.role).where(models.UserRole.user_id == target_user.id)
    roles_list = [r.value for r in db.execute(stmt).scalars().all()]
    
    return {
        "id": target_user.id,
        "name": target_user.name,
        "email": target_user.email,
        "roles": roles_list,
        "role": roles_list[0] if roles_list else "PLAYER_ADULT",
        "created_at": target_user.created_at,
        "date_of_birth": target_user.date_of_birth,
        "phone": target_user.phone,
        "bio": target_user.bio,
        "avatar_url": target_user.avatar_url,
        "onboarding_completed": target_user.onboarding_completed,
        "unique_code": target_user.unique_code
    }



@router.get("/parent-requests", response_model=List[schemas.ParentChildRequestResponse])
def get_parent_requests(
    current_user: models.User = Depends(get_current_user),
    db: Session = Depends(get_db)
):
    """
    Returns list of PENDING parent link requests for the current user (child).
    """
    requests = db.query(models.ParentChildRelation).filter(
        models.ParentChildRelation.child_id == current_user.id,
        models.ParentChildRelation.status == models.ParentChildStatus.PENDING
    ).all()
    
    # Enrich with parent names
    response = []
    for r in requests:
        parent = db.query(models.User).filter(models.User.id == r.parent_id).first()
        response.append({
            "id": r.id,
            "parent_id": r.parent_id,
            "parent_name": parent.name if parent else "Unknown",
            "status": r.status,
            "created_at": r.created_at
        })
    return response

@router.post("/parent-requests/{request_id}/accept")
def accept_parent_request(
    request_id: UUID,
    current_user: models.User = Depends(get_current_user),
    db: Session = Depends(get_db)
):
    req = db.query(models.ParentChildRelation).filter(
        models.ParentChildRelation.id == request_id,
        models.ParentChildRelation.child_id == current_user.id
    ).first()
    
    if not req:
        raise HTTPException(status_code=404, detail="Request not found")
        
    req.status = models.ParentChildStatus.ACCEPTED
    db.commit()
    return {"message": "Link accepted"}

@router.post("/parent-requests/{request_id}/reject")
def reject_parent_request(
    request_id: UUID,
    current_user: models.User = Depends(get_current_user),
    db: Session = Depends(get_db)
):
    req = db.query(models.ParentChildRelation).filter(
        models.ParentChildRelation.id == request_id,
        models.ParentChildRelation.child_id == current_user.id
    ).first()
    
    if not req:
        raise HTTPException(status_code=404, detail="Request not found")
        
    req.status = models.ParentChildStatus.DECLINED
    # Optional: Delete the rejected request or keep it as DECLINED
    db.commit()
    return {"message": "Link rejected"}

@router.post("/create-child", response_model=schemas.UserResponse)
def create_child_by_parent(
    child_in: schemas.ChildCreateByParent,
    current_user: models.User = Depends(require_parent),
    db: Session = Depends(get_db)
):
    """
    Creates a new child user, player profile, and links them to the current parent.
    """
    # 1. Check if email exists
    existing_user = db.query(models.User).filter(models.User.email == child_in.email).first()
    if existing_user:
        raise HTTPException(status_code=400, detail="Email already registered")
        
    # 2. Create child user
    child_name = f"{child_in.first_name} {child_in.last_name}"
    new_child = models.User(
        name=child_name,
        email=child_in.email,
        password_hash=hash_password(child_in.password),
        date_of_birth=child_in.date_of_birth,
        onboarding_completed=True
    )
    db.add(new_child)
    db.flush() # Get the new_child.id
    
    # 3. Add PLAYER_CHILD role
    child_role = models.UserRole(user_id=new_child.id, role=models.Role.PLAYER_CHILD)
    db.add(child_role)
    
    # 4. Create Player Profile
    new_profile = models.PlayerProfile(user_id=new_child.id)
    db.add(new_profile)
    db.flush()
    
    # 5. Create Parent-Child Relation (ACCEPTED)
    new_relation = models.ParentChildRelation(
        parent_id=current_user.id,
        child_id=new_child.id,
        relation_type=models.RelationType.GUARDIAN,
        status=models.ParentChildStatus.ACCEPTED
    )
    db.add(new_relation)
    
    # 6. Handle Academy Invite Code (Implementation Placeholder)
    if child_in.academy_invite_code:
        # Search for academy or team by invite code and add the player
        pass

    db.commit()
    db.refresh(new_child)
    
    return {
        "id": new_child.id,
        "name": new_child.name,
        "email": new_child.email,
        "role": models.Role.PLAYER_CHILD,
        "roles": [models.Role.PLAYER_CHILD.value],
        "date_of_birth": new_child.date_of_birth,
        "phone": new_child.phone,
        "onboarding_completed": new_child.onboarding_completed,
        "created_at": new_child.created_at
    }



@router.patch("/{user_id}", response_model=schemas.UserResponse)
def update_user(
    user_id: UUID,
    user_in: schemas.UserUpdate,
    current_user: models.User = Depends(get_current_user),
    db: Session = Depends(get_db)
):
    """
    Updates a user's profile. Parents can update their children's profiles.
    """
    target_user = db.query(models.User).filter(models.User.id == user_id).first()
    if not target_user:
        raise HTTPException(status_code=404, detail="User not found")
        
    # Permission check: Self or Parent
    if current_user.id != user_id:
        # Check if current_user is parent of target_user
        relation = db.query(models.ParentChildRelation).filter(
            models.ParentChildRelation.parent_id == current_user.id,
            models.ParentChildRelation.child_id == user_id,
            models.ParentChildRelation.status == models.ParentChildStatus.ACCEPTED
        ).first()
        
        if not relation:
            raise HTTPException(status_code=403, detail="Not authorized to update this user")

    if user_in.name is not None:
        target_user.name = user_in.name
    if user_in.date_of_birth is not None:
        target_user.date_of_birth = user_in.date_of_birth
    if user_in.phone is not None:
        target_user.phone = user_in.phone
        
    db.commit()
    db.refresh(target_user)
    
    # Get roles for response
    stmt = select(models.UserRole.role).where(models.UserRole.user_id == target_user.id)
    roles_list = db.execute(stmt).scalars().all()
    roles = [r.value for r in roles_list]
    
    return {
        **target_user.__dict__,
        "roles": roles,
        "role": roles[0] if roles else "PLAYER_ADULT"
    }


@router.get("/{user_id}/profile")
def get_player_profile(
    user_id: UUID,
    db: Session = Depends(get_db),
):
    """
    Returns the player profile for a given user, including their tournament stats and awards.
    """
    from app.tournaments.models import TournamentPlayerStats, TournamentAward
    from app.tournaments.services import get_player_awards

    user = db.query(models.User).filter(models.User.id == user_id).first()
    if not user:
        raise HTTPException(status_code=404, detail="User not found")

    profile = db.query(models.PlayerProfile).filter(
        models.PlayerProfile.user_id == user_id
    ).first()

    # Build response
    tournament_stats = []
    awards = []
    if profile:
        raw_stats = db.query(TournamentPlayerStats).filter(
            TournamentPlayerStats.player_profile_id == profile.id
        ).all()
        for s in raw_stats:
            tournament_stats.append({
                "division_id": str(s.division_id),
                "goals": s.goals,
                "assists": s.assists,
                "matches_played": s.matches_played,
                "clean_sheets": s.clean_sheets,
                "yellow_cards": s.yellow_cards,
                "red_cards": s.red_cards,
            })

        raw_awards = db.query(TournamentAward).filter(
            TournamentAward.player_profile_id == profile.id
        ).all()
        for a in raw_awards:
            awards.append({
                "id": str(a.id),
                "title": a.title,
                "description": a.description,
                "division_id": str(a.division_id),
                "created_at": a.created_at.isoformat() if a.created_at else None,
            })

    return {
        "id": str(user.id),
        "name": user.name,
        "email": user.email,
        "date_of_birth": user.date_of_birth.isoformat() if user.date_of_birth else None,
        "profile_id": str(profile.id) if profile else None,
        "preferred_position": profile.preferred_position if profile else None,
        "dominant_foot": profile.dominant_foot.value if profile and profile.dominant_foot else None,
        "height": profile.height if profile else None,
        "weight": profile.weight if profile else None,
        "tournament_stats": tournament_stats,
        "awards": awards,
    }
@router.get("/referees", response_model=List[schemas.UserResponse])
def get_referees(
    db: Session = Depends(get_db)
):
    """
    Returns a list of all users with the REFEREE role.
    """
    referee_roles = db.query(models.UserRole).filter(models.UserRole.role == models.Role.REFEREE).all()
    referee_ids = [r.user_id for r in referee_roles]
    referees = db.query(models.User).filter(models.User.id.in_(referee_ids)).all()
    
    response = []
    for ref in referees:
        stmt = select(models.UserRole.role).where(models.UserRole.user_id == ref.id)
        roles_list = [r.value for r in db.execute(stmt).scalars().all()]
        
        response.append({
            "id": ref.id,
            "name": ref.name,
            "email": ref.email,
            "roles": roles_list,
            "role": "REFEREE",
            "created_at": ref.created_at,
            "date_of_birth": ref.date_of_birth,
            "phone": ref.phone,
            "onboarding_completed": ref.onboarding_completed,
            "avatar_url": ref.avatar_url,
            "bio": ref.bio,
            "unique_code": ref.unique_code
        })

        
    return response
