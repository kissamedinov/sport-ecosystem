import sys
import os
from sqlalchemy.orm import Session

# Add the current directory to sys.path to allow imports from app
sys.path.append(os.getcwd())

from app.database import SessionLocal
from app.users.models import User, UserRole, Role
from app.auth.security import hash_password

# Import all other model modules to resolve relationships (Academy, PlayerProfile, etc.)
from app.teams import models as team_models
from app.tournaments import models as tournament_models
from app.matches import models as match_models
from app.bookings import models as booking_models
from app.fields import models as field_models
from app.clubs import models as club_models
from app.academies import models as academy_models
from app.club_teams import models as club_teams_models
from app.pickup import models as pickup_models
from app.scouting import models as scouting_models
from app.stats import models as stats_models
from app.media import models as media_models
from app.notifications import models as notification_models

def create_superadmin():
    db: Session = SessionLocal()
    email = "superadmin@sportseco.com"
    password = "admin123"
    name = "Super Admin"

    try:
        # Check if user already exists
        existing_user = db.query(User).filter(User.email == email).first()
        if existing_user:
            print(f"User with email {email} already exists.")
            return

        # Create new user
        new_user = User(
            name=name,
            email=email,
            password_hash=hash_password(password),
            onboarding_completed=True
        )
        db.add(new_user)
        db.flush()  # To get the ID

        # Assign ADMIN role
        admin_role = UserRole(user_id=new_user.id, role=Role.ADMIN)
        db.add(admin_role)
        
        db.commit()
        print(f"Superadmin user created successfully!")
        print(f"Email: {email}")
        print(f"Password: {password}")
        print(f"Role: ADMIN")

    except Exception as e:
        db.rollback()
        print(f"Error creating superadmin: {e}")
    finally:
        db.close()

if __name__ == "__main__":
    create_superadmin()
