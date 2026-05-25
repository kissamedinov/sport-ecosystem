from fastapi import APIRouter, Depends, HTTPException, status
from sqlalchemy.orm import Session
from google.oauth2 import id_token
from google.auth.transport import requests
import os

from app.database import get_db
from app.users.models import User, UserRole, Role, PlayerProfile
from app.users.schemas import UserCreate, UserResponse, UserLogin, Token, GoogleLogin
from app.auth.security import hash_password, verify_password
from app.auth.jwt import create_access_token
from app.common.dependencies import get_current_user

router = APIRouter(prefix="/auth", tags=["Authentication"])

@router.post("/google", response_model=Token)
def google_auth(data: GoogleLogin, db: Session = Depends(get_db)):
    """
    Verify Google ID Token and login/register the user.
    """
    token = data.id_token
    client_id = os.getenv("GOOGLE_CLIENT_ID")
    
    if not client_id:
        raise HTTPException(
            status_code=500, 
            detail="GOOGLE_CLIENT_ID is not configured on the server"
        )

    try:
        # Verify the ID token
        idinfo = id_token.verify_oauth2_token(token, requests.Request(), client_id)

        # ID token is valid. Get the user's Google ID and email.
        email = idinfo['email']
        name = idinfo.get('name', email.split('@')[0])
        
        # 1. Check if user exists
        user = db.query(User).filter(User.email == email).first()
        
        if not user:
            # 2. Register new user if they don't exist
            # Generate a random password since they use Google
            import secrets
            random_password = secrets.token_urlsafe(16)
            
            user = User(
                name=name,
                email=email,
                password_hash=hash_password(random_password),
                onboarding_completed=False
            )
            db.add(user)
            db.flush()
            
            # Default role: PLAYER_ADULT
            user_role = UserRole(user_id=user.id, role=Role.PLAYER_ADULT)
            db.add(user_role)
            
            # Create player profile
            player_profile = PlayerProfile(user_id=user.id)
            db.add(player_profile)
            
            db.commit()
            db.refresh(user)
            
            role_value = Role.PLAYER_ADULT.value
        else:
            # Get existing user's role
            user_role_entry = db.query(UserRole).filter(UserRole.user_id == user.id).first()
            role_value = user_role_entry.role.value if user_role_entry else Role.PLAYER_ADULT.value
            
            # Ensure PlayerProfile exists (for users who were created before this feature)
            if role_value in [Role.PLAYER_YOUTH.value, Role.PLAYER_ADULT.value, Role.PLAYER_CHILD.value]:
                existing_profile = db.query(PlayerProfile).filter(PlayerProfile.user_id == user.id).first()
                if not existing_profile:
                    new_profile = PlayerProfile(user_id=user.id)
                    db.add(new_profile)
                    db.commit()

        # 3. Create our own JWT token
        access_token = create_access_token(data={"user_id": str(user.id), "role": role_value})
        
        return {"access_token": access_token, "token_type": "bearer"}

    except ValueError:
        # Invalid token
        raise HTTPException(status_code=401, detail="Invalid Google token")
    except Exception as e:
        print(f"Error in google_auth: {str(e)}")
        raise HTTPException(status_code=500, detail="Internal server error during Google auth")

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

        # add role to UserRole table
        role_value = user_in.role if isinstance(user_in.role, Role) else Role(user_in.role)
        user_role = UserRole(user_id=new_user.id, role=role_value)
        db.add(user_role)

        # Each PLAYER_YOUTH or PLAYER_ADULT user must have one PlayerProfile.
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
            "onboarding_completed": False,
            "unique_code": new_user.unique_code,
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
        "onboarding_completed": current_user.onboarding_completed,
        "unique_code": current_user.unique_code,
        "player_profile_id": current_user.player_profile_id,
        "bio": current_user.bio,
        "phone": current_user.phone,
        "avatar_url": current_user.avatar_url,
        "date_of_birth": current_user.date_of_birth,
    }

