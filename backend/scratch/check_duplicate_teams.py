
import os
from dotenv import load_dotenv
from sqlalchemy import create_engine
from sqlalchemy.orm import sessionmaker
from app.teams.models import Team, TeamMembership
from app.clubs.models import Club
from app.academies.models import Academy # Add this to resolve relationships

load_dotenv()

SQLALCHEMY_DATABASE_URL = os.getenv("DATABASE_URL")
engine = create_engine(SQLALCHEMY_DATABASE_URL)
SessionLocal = sessionmaker(bind=engine)
db = SessionLocal()

try:
    teams = db.query(Team).filter(Team.name.ilike('%Astana City%')).all()
    print(f"FOUND {len(teams)} TEAMS:")
    for t in teams:
        count = db.query(TeamMembership).filter(TeamMembership.team_id == t.id).count()
        club = db.query(Club).filter(Club.id == t.club_id).first()
        print(f"- ID: {t.id} | NAME: '{t.name}' | PLAYERS: {count} | CLUB: {club.name if club else 'None'}")
finally:
    db.close()
