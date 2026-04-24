
import os
from dotenv import load_dotenv
from sqlalchemy import create_engine
from sqlalchemy.orm import sessionmaker

# Import EVERYTHING to avoid mapping errors
from app.users.models import User, PlayerProfile, UserRole, Role
from app.clubs.models import Club, ClubStaff, ClubRole, ClubMembershipStatus
from app.teams.models import Team, TeamMembership, MembershipStatus, MembershipRole
from app.academies.models import Academy

load_dotenv()

SQLALCHEMY_DATABASE_URL = os.getenv("DATABASE_URL")
engine = create_engine(SQLALCHEMY_DATABASE_URL)
SessionLocal = sessionmaker(bind=engine)
db = SessionLocal()

try:
    print("SEARCHING FOR ALL TEAMS WITH '2013' OR '2014':")
    teams = db.query(Team).filter(
        (Team.name.ilike('%2013%')) | (Team.name.ilike('%2014%'))
    ).all()
    
    print(f"FOUND {len(teams)} TEAMS:")
    for t in teams:
        count = db.query(TeamMembership).filter(TeamMembership.team_id == t.id).count()
        academy = db.query(Academy).filter(Academy.id == t.academy_id).first()
        print(f"- ID: {t.id} | NAME: '{t.name}' | PLAYERS: {count} | ACADEMY: {academy.name if academy else 'None'}")
finally:
    db.close()
