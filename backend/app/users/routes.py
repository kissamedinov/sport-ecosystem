from fastapi import APIRouter, Depends, HTTPException, status
from sqlalchemy.orm import Session
from typing import List
from uuid import UUID
from app.database import get_db
from app.users import models, schemas
from app.common.dependencies import get_current_user, require_parent

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
            models.ParentChildRelation.parent_id == current_user.id
        ).all()
        
        children_ids = [rel.child_id for rel in children_relations]
        children = db.query(models.User).filter(models.User.id.in_(children_ids)).all()
        
        # Manually populate roles for schemas until we improve model relations
        for child in children:
            user_roles = db.query(models.UserRole).filter(models.UserRole.user_id == child.id).all()
            child.roles = [ur.role.value for ur in user_roles]
            child.role = child.roles[0] if child.roles else "PLAYER_YOUTH"
            
        return children
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
        relation_type=models.RelationType.GUARDIAN
    )
    db.add(new_relation)
    db.commit()
    return {"message": "Linked successfully"}


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
