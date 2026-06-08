import os
from dotenv import load_dotenv
from sqlalchemy import create_engine
from sqlalchemy.orm import sessionmaker
from uuid import UUID

from app.users.models import User, PlayerProfile, UserRole, Role
from app.clubs.models import Club, ClubStaff, ClubRole, ClubMembershipStatus, ChildProfile
from app.teams.models import Team, TeamMembership, MembershipStatus, MembershipRole
from app.academies.models import Academy

load_dotenv()

SQLALCHEMY_DATABASE_URL = os.getenv("DATABASE_URL")
engine = create_engine(SQLALCHEMY_DATABASE_URL)
SessionLocal = sessionmaker(bind=engine)
db = SessionLocal()

try:
    academy_id = UUID("3e6e81de-1b98-4894-a569-cda6e03b4558")
    
    # 1. Plain query by academy_id
    plain_teams = db.query(Team).filter(Team.academy_id == academy_id).all()
    print(f"PLAIN QUERY TEAMS: {len(plain_teams)}")
    for t in plain_teams:
        print(f"  - Team: {t.name} | Academy ID: {t.academy_id}")
        
    # 2. Find club owner user ID
    academy = db.query(Academy).filter(Academy.id == academy_id).first()
    club = db.query(Club).filter(Club.id == academy.club_id).first()
    if club:
        print(f"CLUB: {club.name} | Owner ID: {club.owner_id}")
        # Run query with owner_id
        owner_teams = db.query(Team).join(Academy).filter(Academy.club_id == club.id).all()
        print(f"OWNER QUERY TEAMS (Join): {len(owner_teams)}")
        for t in owner_teams:
            print(f"  - Team: {t.name} | Academy ID: {t.academy_id}")
finally:
    db.close()
