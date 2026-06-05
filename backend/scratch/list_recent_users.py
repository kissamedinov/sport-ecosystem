import os
from dotenv import load_dotenv
from sqlalchemy import create_engine, select, desc
from sqlalchemy.orm import sessionmaker
from app.users.models import User, PlayerProfile, UserRole
from app.clubs.models import Club, ChildProfile, ClubStaff, Invitation
from app.teams.models import Team, TeamMembership
from app.academies.models import Academy

load_dotenv()

SQLALCHEMY_DATABASE_URL = os.getenv("DATABASE_URL", "postgresql://postgres:postgres@localhost:5432/sportseco")
engine = create_engine(SQLALCHEMY_DATABASE_URL)
SessionLocal = sessionmaker(bind=engine)
db = SessionLocal()

try:
    print("LAST 20 CREATED USERS:")
    users = db.query(User).order_by(desc(User.created_at)).limit(20).all()
    for u in users:
        print(f"- {u.name} (ID: {u.id}) | Email: {u.email} | Created At: {u.created_at}")
except Exception as e:
    print(f"Error: {e}")
finally:
    db.close()
