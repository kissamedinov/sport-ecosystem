from fastapi import Depends, HTTPException, status
from fastapi.security import OAuth2PasswordBearer
from sqlalchemy.orm import Session
from uuid import UUID
from app.database import get_db
from app.auth.jwt import decode_access_token
from app.users.models import User, Role

oauth2_scheme = OAuth2PasswordBearer(tokenUrl="auth/login")

def get_current_user(token: str = Depends(oauth2_scheme), db: Session = Depends(get_db)) -> User:
    credentials_exception = HTTPException(
        status_code=status.HTTP_401_UNAUTHORIZED,
        detail="Could not validate credentials",
        headers={"WWW-Authenticate": "Bearer"},
    )
    payload = decode_access_token(token)
    if payload is None:
        raise credentials_exception
    user_id: str = payload.get("user_id")
    if user_id is None:
        raise credentials_exception
    user = db.query(User).filter(User.id == user_id).first()
    if user is None:
        raise credentials_exception
    return user

def require_role(role: Role):
    def role_dependency(current_user: User = Depends(get_current_user)):
        user_roles = {ur.role for ur in current_user.roles}
        if role not in user_roles:
            raise HTTPException(
                status_code=status.HTTP_403_FORBIDDEN,
                detail=f"Operation not permitted. Requires role {role.value}"
            )
        return current_user
    return role_dependency

def require_coach(current_user: User = Depends(get_current_user)):
    user_roles = {ur.role for ur in current_user.roles}
    required_roles = {Role.COACH, Role.TEAM_OWNER, Role.CLUB_OWNER, Role.CLUB_MANAGER, Role.ADMIN}
    if not user_roles.intersection(required_roles):
        raise HTTPException(
            status_code=status.HTTP_403_FORBIDDEN,
            detail="Operation not permitted. Requires COACH, TEAM_OWNER, or Club Management role"
        )
    return current_user

def require_player(current_user: User = Depends(get_current_user)):
    user_roles = {ur.role for ur in current_user.roles}
    player_roles = {Role.PLAYER_ADULT, Role.PLAYER_CHILD, Role.PLAYER_YOUTH}
    if not user_roles.intersection(player_roles):
        raise HTTPException(
            status_code=status.HTTP_403_FORBIDDEN,
            detail="Operation not permitted. Requires PLAYER role"
        )
    return current_user

def require_tournament_organizer(current_user: User = Depends(get_current_user)):
    user_roles = {ur.role for ur in current_user.roles}
    organizer_roles = {
        Role.TOURNAMENT_ORGANIZER, Role.ADMIN, Role.TEAM_OWNER, 
        Role.ACADEMY_ADMIN, Role.FIELD_OWNER, Role.CLUB_OWNER, Role.CLUB_MANAGER
    }
    if not user_roles.intersection(organizer_roles):
        raise HTTPException(
            status_code=status.HTTP_403_FORBIDDEN,
            detail="Operation not permitted. Requires Tournament Organizer, Club Owner, or Academy Admin role"
        )
    return current_user

def require_permission(permission_name: str):
    def permission_dependency(
        current_user: User = Depends(get_current_user),
        db: Session = Depends(get_db)
    ):
        from app.users.permissions_service import check_permission
        if not check_permission(db, current_user.id, permission_name):
            raise HTTPException(
                status_code=status.HTTP_403_FORBIDDEN,
                detail=f"Operation not permitted. Missing permission: {permission_name}"
            )
        return current_user
    return permission_dependency
def require_match_reporter(current_user: User = Depends(get_current_user)):
    user_roles = {ur.role for ur in current_user.roles}
    required_roles = {Role.REFEREE, Role.TOURNAMENT_MANAGER, Role.COACH, Role.CLUB_OWNER, Role.CLUB_MANAGER, Role.ADMIN}
    if not user_roles.intersection(required_roles):
        raise HTTPException(
            status_code=status.HTTP_403_FORBIDDEN,
            detail="Operation not permitted. Requires Match Reporter, Club Staff, or Admin role"
        )
    return current_user

def require_club_owner(current_user: User = Depends(get_current_user)):
    user_roles = {ur.role for ur in current_user.roles}
    if Role.CLUB_OWNER not in user_roles and Role.CLUB_MANAGER not in user_roles and Role.ADMIN not in user_roles:
        raise HTTPException(
            status_code=status.HTTP_403_FORBIDDEN,
            detail="Operation not permitted. Requires CLUB_OWNER or CLUB_MANAGER role"
        )
    return current_user

def require_club_staff(current_user: User = Depends(get_current_user)):
    user_roles = {ur.role for ur in current_user.roles}
    required_roles = {Role.CLUB_OWNER, Role.CLUB_MANAGER, Role.COACH, Role.ADMIN}
    if not user_roles.intersection(required_roles):
        raise HTTPException(
            status_code=status.HTTP_403_FORBIDDEN,
            detail="Operation not permitted. Requires Club Staff role (Owner, Manager, or Coach)"
        )
    return current_user

def require_parent(current_user: User = Depends(get_current_user)):
    user_roles = {ur.role for ur in current_user.roles}
    if Role.PARENT not in user_roles and Role.ADMIN not in user_roles:
        raise HTTPException(
            status_code=status.HTTP_403_FORBIDDEN,
            detail="Operation not permitted. Requires PARENT role"
        )
    return current_user

def get_parent_children_ids(current_user: User = Depends(get_current_user), db: Session = Depends(get_db)) -> list[UUID]:
    from app.users.models import ParentChildRelation
    relations = db.query(ParentChildRelation).filter(ParentChildRelation.parent_id == current_user.id).all()
    return [r.child_id for r in relations]
