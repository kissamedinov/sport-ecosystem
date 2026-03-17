from app.database import SessionLocal
from app.users.models import User, UserRole, Role

db = SessionLocal()
try:
    user = db.query(User).filter(User.email == 'jupsik@gmail.com').first()
    if user:
        role_exists = db.query(UserRole).filter(
            UserRole.user_id == user.id, 
            UserRole.role == Role.TOURNAMENT_MANAGER
        ).first()
        
        if not role_exists:
            db.add(UserRole(user_id=user.id, role=Role.TOURNAMENT_MANAGER))
            db.commit()
            print(f"Role TOURNAMENT_MANAGER added to {user.email}")
        else:
            print(f"User {user.email} already has TOURNAMENT_MANAGER role")
            
        # Also give COACH if missing
        coach_exists = db.query(UserRole).filter(
            UserRole.user_id == user.id, 
            UserRole.role == Role.COACH
        ).first()
        if not coach_exists:
            db.add(UserRole(user_id=user.id, role=Role.COACH))
            db.commit()
            print(f"Role COACH added to {user.email}")
    else:
        print("User jupsik@gmail.com not found")
except Exception as e:
    print(f"Error: {e}")
    db.rollback()
finally:
    db.close()
