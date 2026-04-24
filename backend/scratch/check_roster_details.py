
import os
from dotenv import load_dotenv
from sqlalchemy import create_engine
from sqlalchemy.orm import sessionmaker

# Import EVERYTHING
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
    team_id = '9b68faa0-247b-4df6-9a6e-388ec6b9340c'
    memberships = db.query(TeamMembership).filter(TeamMembership.team_id == team_id).all()
    print(f"TEAM MEMBERSHIPS FOR {team_id}: {len(memberships)}")
    
    empty_child_count = 0
    for m in memberships:
        if not m.child_profile_id:
            empty_child_count += 1
            
    print(f"MEMBERSHIPS WITHOUT child_profile_id: {empty_child_count}")
    
    # Check one example
    if memberships:
        m = memberships[0]
        user = db.query(User).filter(User.id == m.player_id).first()
        child_profile = db.query(ChildProfile).filter(ChildProfile.linked_user_id == m.player_id).first()
        print(f"EXAMPLE: Player {user.name if user else 'None'} | child_profile_id: {m.child_profile_id} | Actual ChildProfile exists: {child_profile.id if child_profile else 'No'}")

finally:
    db.close()
