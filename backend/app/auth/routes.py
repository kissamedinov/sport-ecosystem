from fastapi import APIRouter, Depends, HTTPException, status
from sqlalchemy.orm import Session
from app.database import get_db
from app.users.models import User, UserRole, Role, PlayerProfile
from app.users.schemas import UserCreate, UserResponse, UserLogin, Token
from app.auth.security import hash_password, verify_password
from app.auth.jwt import create_access_token
from app.common.dependencies import get_current_user

router = APIRouter(prefix="/auth", tags=["Authentication"])

@router.post("/register", status_code=status.HTTP_201_CREATED)
def register(user_in: UserCreate, db: Session = Depends(get_db)):
    try:
        existing_user = db.query(User).filter(User.email == user_in.email).first()
        if existing_user:
            raise HTTPException(status_code=400, detail="Email already registered")
        
        new_user = User(
            name=user_in.name,
            email=user_in.email,
            password_hash=hash_password(user_in.password),
            date_of_birth=user_in.date_of_birth,
            phone=user_in.phone
        )
        db.add(new_user)
        db.flush()  # Get the new_user.id without committing

        # Add role to UserRole table
        role_value = user_in.role if isinstance(user_in.role, Role) else Role(user_in.role)
        user_role = UserRole(user_id=new_user.id, role=role_value)
        db.add(user_role)

        # Requirement: Each PLAYER_YOUTH or PLAYER_ADULT user must have one PlayerProfile.
        if role_value in [Role.PLAYER_YOUTH, Role.PLAYER_ADULT, Role.PLAYER_CHILD]:
            player_profile = PlayerProfile(user_id=new_user.id)
            db.add(player_profile)

        db.commit()
        db.refresh(new_user)
        
        token = create_access_token(data={"user_id": str(new_user.id), "role": role_value.value})
        
        return {
            "id": str(new_user.id),
            "name": new_user.name,
            "email": new_user.email,
            "role": role_value.value,
            "roles": [role_value.value],
            "access_token": token,
            "token_type": "bearer"
        }
    except HTTPException as e:
        raise e
    except Exception as e:
        db.rollback()
        print(f"CRITICAL ERROR in registration: {str(e)}")
        import traceback; traceback.print_exc()
        raise HTTPException(status_code=500, detail=f"Internal Server Error during registration: {str(e)}")

@router.post("/login", response_model=Token)
def login(login_data: UserLogin, db: Session = Depends(get_db)):
    user = db.query(User).filter(User.email == login_data.email).first()
    if not user or not verify_password(login_data.password, user.password_hash):
        raise HTTPException(
            status_code=status.HTTP_401_UNAUTHORIZED,
            detail="Incorrect email or password",
            headers={"WWW-Authenticate": "Bearer"},
        )
    
    # Get user's primary role from UserRole table
    user_role_entry = db.query(UserRole).filter(UserRole.user_id == user.id).first()
    role_value = user_role_entry.role.value if user_role_entry else "PLAYER_ADULT"
        
    token = create_access_token(data={"user_id": str(user.id), "role": role_value})
    return {"access_token": token, "token_type": "bearer"}

@router.get("/me")
def read_users_me(current_user: User = Depends(get_current_user), db: Session = Depends(get_db)):
    # Get all roles from UserRole table
    user_roles = db.query(UserRole).filter(UserRole.user_id == current_user.id).all()
    role_values = [ur.role.value for ur in user_roles]
    primary_role = role_values[0] if role_values else "PLAYER_ADULT"
    return {
        "id": str(current_user.id),
        "name": current_user.name,
        "email": current_user.email,
        "role": primary_role,
        "roles": role_values,
    }
