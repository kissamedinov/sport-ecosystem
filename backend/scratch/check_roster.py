
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
    team = db.query(Team).filter(Team.name.ilike('%Astana City 2013-14%')).first()
    if team:
        print(f"TEAM: {team.name} (ID: {team.id})")
        mems = db.query(TeamMembership).filter(TeamMembership.team_id == team.id).all()
        print(f"Total memberships found: {len(mems)}")
        for m in mems:
            user = db.query(User).filter(User.id == m.player_id).first()
            user_name = user.name if user else "Unknown User"
            print(f"- Member ID: {m.id} | User: {user_name} | Status: {m.status} | JoinStatus: {m.join_status}")
    else:
        print("Team not found")
finally:
    db.close()
