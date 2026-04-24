
from sqlalchemy import create_engine
from sqlalchemy.orm import sessionmaker
from app.users.models import User, PlayerProfile
from app.clubs.models import Club, ClubStaff, ClubRole
from app.teams.models import Team, TeamMembership
from app.academies.models import Academy

import os`nfrom dotenv import load_dotenv`nload_dotenv()`n`nSQLALCHEMY_DATABASE_URL = os.getenv("DATABASE_URL", "postgresql://postgres:postgres@localhost:5432/sportseco")
engine = create_engine(SQLALCHEMY_DATABASE_URL)
SessionLocal = sessionmaker(bind=engine)
db = SessionLocal()

try:
    club = db.query(Club).filter(Club.name.ilike('%Astana City%')).first()
    user = db.query(User).filter(User.name.ilike('%Coach Astana City%')).first()
    
    if club and user:
        staff = db.query(ClubStaff).filter(ClubStaff.club_id == club.id, ClubStaff.user_id == user.id).first()
        if staff:
            print(f"USER {user.name} is STAFF in {club.name} with ROLE: {staff.role}")
        else:
            print(f"USER {user.name} is NOT staff in {club.name}")
finally:
    db.close()
