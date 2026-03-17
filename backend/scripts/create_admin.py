from datetime import date
from sqlalchemy.orm import Session
from app.database import SessionLocal, engine, Base
import app.users.models as user_models
from app.users.models import User, Role, UserRole
import app.teams.models as team_models
import app.tournaments.models as tournament_models
import app.matches.models as match_models
import app.bookings.models as booking_models
import app.fields.models as field_models
import app.clubs.models as club_models_system
import app.academies.models as academy_models
import app.club_teams.models as club_teams_models
import app.pickup.models as pickup_models
import app.scouting.models as scouting_models
import app.stats.models as stats_models
from app.auth.security import hash_password
import uuid

def create_admin():
    db = SessionLocal()
    try:
        email = "superadmin@sportseco.com"
        password = "password123"
        name = "Super Admin"
        
        # Check if exists
        user = db.query(User).filter(User.email == email).first()
        if not user:
            user = User(
                id=uuid.uuid4(),
                name=name,
                email=email,
                password_hash=hash_password(password),
                date_of_birth=date(1990, 1, 1),
            )
            db.add(user)
            db.flush()
            print(f"User {email} created.")
        else:
            print(f"User {email} already exists.")
            
        # Check for ADMIN role
        admin_role = db.query(UserRole).filter(UserRole.user_id == user.id, UserRole.role == Role.ADMIN).first()
        if not admin_role:
            db.add(UserRole(user_id=user.id, role=Role.ADMIN))
            print(f"ADMIN role added to {email}.")
        else:
            print(f"ADMIN role already present for {email}.")
            
        db.commit()
    except Exception as e:
        db.rollback()
        print(f"Error: {e}")
    finally:
        db.close()

if __name__ == "__main__":
    create_admin()
