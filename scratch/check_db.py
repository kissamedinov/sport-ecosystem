
from sqlalchemy import create_engine
from sqlalchemy.orm import sessionmaker
from app.users.models import User, PlayerProfile
from app.clubs.models import Club, ChildProfile, ClubStaff
from app.teams.models import Team, TeamMembership
from app.academies.models import Academy

SQLALCHEMY_DATABASE_URL = "postgresql://postgres:postgres@localhost:5432/sportseco"
engine = create_engine(SQLALCHEMY_DATABASE_URL)
SessionLocal = sessionmaker(bind=engine)
db = SessionLocal()

try:
    clubs = db.query(Club).all()
    print("CLUBS:")
    for c in clubs:
        children_count = db.query(ChildProfile).filter(ChildProfile.club_id == c.id).count()
        print(f"- {c.name} (ID: {c.id}) | Children: {children_count}")
        
    teams = db.query(Team).all()
    print("\nTEAMS:")
    for t in teams:
        members_count = db.query(TeamMembership).filter(TeamMembership.team_id == t.id).count()
        print(f"- {t.name} (ID: {t.id}) | Members: {members_count}")
finally:
    db.close()
