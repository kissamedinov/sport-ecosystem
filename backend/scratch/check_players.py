
from sqlalchemy import create_engine
from sqlalchemy.orm import sessionmaker
from app.users.models import User, UserRole, Role, PlayerProfile
from app.teams.models import Team, TeamMembership
from app.academies.models import Academy
from app.clubs.models import Club

SQLALCHEMY_DATABASE_URL = "postgresql://postgres:postgres@localhost:5432/sportseco"
engine = create_engine(SQLALCHEMY_DATABASE_URL)
SessionLocal = sessionmaker(bind=engine)
db = SessionLocal()

try:
    # Find users with player roles
    player_roles = [Role.PLAYER_CHILD, Role.PLAYER_YOUTH, Role.PLAYER_ADULT]
    players = db.query(User).join(UserRole).filter(UserRole.role.in_(player_roles)).all()
    print(f"TOTAL PLAYERS (USERS) IN DB: {len(players)}")
    for p in players:
        # Check their memberships
        mems = db.query(TeamMembership).filter(TeamMembership.player_id == p.id).all()
        print(f"- {p.name} (ID: {p.id}) | Memberships: {len(mems)}")
        for m in mems:
            team = db.query(Team).filter(Team.id == m.team_id).first()
            team_name = team.name if team else "Unknown Team"
            print(f"  * Team: {team_name} (ID: {m.team_id}) | Status: {m.status}")

    # Check the specific team again
    team = db.query(Team).filter(Team.name.ilike('%Astana City 2013-14%')).first()
    if team:
        print(f"\nChecking team: {team.name}")
        # Find ANY memberships
        mems = db.query(TeamMembership).filter(TeamMembership.team_id == team.id).all()
        print(f"Direct memberships in {team.name}: {len(mems)}")
        
finally:
    db.close()
