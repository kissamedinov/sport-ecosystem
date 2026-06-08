import os
from dotenv import load_dotenv
from sqlalchemy import create_engine
from sqlalchemy.orm import sessionmaker

# Import all models to register them in SQLAlchemy clsregistry
from app.users.models import User, PlayerProfile, UserRole, Role
from app.clubs.models import Club, ClubStaff, ClubRole, ClubMembershipStatus, ChildProfile
from app.teams.models import Team, TeamMembership, MembershipStatus, MembershipRole
from app.academies.models import Academy, TrainingSchedule

load_dotenv()

SQLALCHEMY_DATABASE_URL = os.getenv("DATABASE_URL")
engine = create_engine(SQLALCHEMY_DATABASE_URL)
SessionLocal = sessionmaker(bind=engine)
db = SessionLocal()

try:
    academies = db.query(Academy).all()
    print(f"Total academies: {len(academies)}")
    for a in academies:
        teams = db.query(Team).filter(Team.academy_id == a.id).all()
        schedules = db.query(TrainingSchedule).filter(TrainingSchedule.academy_id == a.id).all()
        print(f"Academy: {a.name} | ID: {a.id} | Club ID: {a.club_id} | Teams: {len(teams)} | Schedules: {len(schedules)}")
        for t in teams:
            print(f"  - Team: {t.name} (ID: {t.id})")
        for s in schedules:
            print(f"  - Schedule: ID: {s.id} | Day: {s.day_of_week} | Time: {s.start_time}-{s.end_time}")
finally:
    db.close()
