
from sqlalchemy import create_engine
from sqlalchemy.orm import sessionmaker
from app.users.models import User, PlayerProfile
from app.clubs.models import Club, ChildProfile, ClubStaff
from app.teams.models import Team, TeamMembership
from app.academies.models import Academy

import os`nfrom dotenv import load_dotenv`nload_dotenv()`n`nSQLALCHEMY_DATABASE_URL = os.getenv("DATABASE_URL", "postgresql://postgres:postgres@localhost:5432/sportseco")
engine = create_engine(SQLALCHEMY_DATABASE_URL)
SessionLocal = sessionmaker(bind=engine)
db = SessionLocal()

try:
    club = db.query(Club).filter(Club.name.ilike('%Astana City%')).first()
    if club:
        owner = db.query(User).filter(User.id == club.owner_id).first()
        print(f"CLUB: {club.name} | OWNER: {owner.name if owner else 'Unknown'} (ID: {club.owner_id})")
        
    current_user = db.query(User).filter(User.name.ilike('%Coach Astana City%')).first()
    if current_user:
        print(f"CURRENT USER: {current_user.name} (ID: {current_user.id})")
finally:
    db.close()
