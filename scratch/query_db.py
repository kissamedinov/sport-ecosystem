from app.database import SessionLocal
from app.users.models import User, UserRole

db = SessionLocal()
try:
    user = db.query(User).filter(User.email == "maneo@test.com").first()
    if user:
        print("Found local user maneo@test.com:")
        print(f"ID: {user.id}")
        print(f"Name: {user.name}")
        print(f"Password Hash: {user.password_hash}")
        
        # Get roles
        roles = db.query(UserRole).filter(UserRole.user_id == user.id).all()
        print("Roles:")
        for r in roles:
            print(f"  Role: {r.role}")
            print(f"  Role type: {type(r.role)}")
            try:
                print(f"  Role value: {r.role.value}")
            except Exception as ex:
                print(f"  Failed to get value: {ex}")
    else:
        print("maneo@test.com not found in local db.")
except Exception as e:
    print(f"Error querying local DB: {e}")
finally:
    db.close()
