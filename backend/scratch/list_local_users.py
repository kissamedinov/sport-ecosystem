from app.database import SessionLocal
import app.users.models
import app.academies.models
import app.teams.models
import app.clubs.models

db = SessionLocal()
try:
    users = db.query(app.users.models.User).limit(5).all()
    print("Local users:")
    for u in users:
        print(f"ID: {u.id}, Name: {u.name}, Email: {u.email}")
finally:
    db.close()
