
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
    children = db.query(ChildProfile).all()
    print(f"TOTAL CHILDREN IN DB: {len(children)}")
    for child in children:
        club = db.query(Club).filter(Club.id == child.club_id).first()
        club_name = club.name if club else "No Club"
        print(f"- {child.first_name} {child.last_name} (ID: {child.id}) | Club: {club_name} (ID: {child.club_id})")
finally:
    db.close()
