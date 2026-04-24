
from sqlalchemy import create_engine
from sqlalchemy.orm import sessionmaker
from app.users.models import User, PlayerProfile
from app.clubs.models import Club, ClubStaff
from app.teams.models import Team, TeamMembership
from app.academies.models import Academy

import os`nfrom dotenv import load_dotenv`nload_dotenv()`n`nSQLALCHEMY_DATABASE_URL = os.getenv("DATABASE_URL", "postgresql://postgres:postgres@localhost:5432/sportseco")
engine = create_engine(SQLALCHEMY_DATABASE_URL)
SessionLocal = sessionmaker(bind=engine)
db = SessionLocal()

try:
    team = db.query(Team).filter(Team.name.ilike('%Astana City 2013-14%')).first()
    if team:
        coach = db.query(User).filter(User.id == team.coach_id).first()
        print(f"TEAM: {team.name} | COACH: {coach.name if coach else 'Unknown'} (ID: {team.coach_id})")
        
    user = db.query(User).filter(User.name.ilike('%Coach Astana City%')).first()
    if user:
        print(f"USER: {user.name} (ID: {user.id})")
finally:
    db.close()
