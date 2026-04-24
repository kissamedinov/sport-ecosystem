
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
    
    # 1. Find users to remove
    names_to_remove = ["Biba", "Orphan Child 1 of Parent 1", "Orphan Child 2 of Parent 1", "Orphan Child 1 of Parent 2", "Orphan Child 2 of Parent 2"]
    users_to_remove = db.query(User).filter(User.name.in_(names_to_remove)).all()
    user_ids = [u.id for u in users_to_remove]
    
    print(f"FOUND {len(users_to_remove)} TEST PLAYERS TO REMOVE FROM ROSTER.")
    
    # 2. Remove from TeamMembership
    deleted_count = db.query(TeamMembership).filter(
        TeamMembership.team_id == team_id,
        TeamMembership.player_id.in_(user_ids)
    ).delete(synchronize_session=False)
    
    db.commit()
    print(f"SUCCESS! Removed {deleted_count} test players from team roster.")

finally:
    db.close()
