from sqlalchemy.orm import Session
from uuid import UUID
from typing import List, Set
from app.users.models import User, UserRole, RolePermission, Permission

def get_user_permissions(db: Session, user_id: UUID) -> Set[str]:
    # Get all roles for the user
    user_roles = db.query(UserRole).filter(UserRole.user_id == user_id).all()
    roles = [ur.role for ur in user_roles]
    
    if not roles:
        return set()
    
    # Get all permissions linked to those roles
    permissions = db.query(Permission.name).join(RolePermission).filter(
        RolePermission.role.in_(roles)
    ).all()
    
    return {p.name for p in permissions}

def check_permission(db: Session, user_id: UUID, permission_name: str) -> bool:
    user_perms = get_user_permissions(db, user_id)
    return permission_name in user_perms
