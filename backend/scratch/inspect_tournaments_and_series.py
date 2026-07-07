from app.database import SessionLocal
from app.tournaments.models import Tournament
from app.users.models import User

db = SessionLocal()

print("--- TOURNAMENTS & CREATORS ---")
tournaments = db.query(Tournament).all()
for t in tournaments:
    creator_info = "No creator"
    if t.created_by:
        user = db.query(User).filter(User.id == t.created_by).first()
        if user:
            creator_info = f"ID: {user.id} | Email: {user.email} | Roles: {user.roles}"
    print(f"Tournament: {t.name} (ID: {t.id}) | Creator: {creator_info}")

print("\n--- ALL ORGANIZERS/ADMINS ---")
users = db.query(User).all()
for u in users:
    if u.roles and any(role in u.roles for role in ['TOURNAMENT_ORGANIZER', 'ADMIN']):
        print(f"User ID: {u.id} | Email: {u.email} | Roles: {u.roles}")

db.close()
