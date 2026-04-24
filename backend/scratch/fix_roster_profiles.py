
import os
import uuid
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
    print(f"FIXING {len(memberships)} MEMBERSHIPS...")
    
    fixed_count = 0
    for m in memberships:
        user = db.query(User).filter(User.id == m.player_id).first()
        if not user:
            continue
            
        # 1. Create or find ChildProfile
        child = db.query(ChildProfile).filter(ChildProfile.linked_user_id == user.id).first()
        if not child:
            name_parts = user.name.split(' ', 1)
            first_name = name_parts[0]
            last_name = name_parts[1] if len(name_parts) > 1 else ""
            
            from datetime import date
            team_obj = db.query(Team).filter(Team.id == team_id).first()
            child = ChildProfile(
                id=uuid.uuid4(),
                linked_user_id=user.id,
                first_name=first_name,
                last_name=last_name,
                date_of_birth=date(2013, 1, 1),
                club_id=team_obj.academy_id,
                created_by=team_obj.coach_id
            )
            db.add(child)
            db.flush()
            print(f"Created ChildProfile for {user.name}")
            
        # 2. Link to membership
        if m.child_profile_id != child.id:
            m.child_profile_id = child.id
            fixed_count += 1
            
    db.commit()
    print(f"SUCCESS! Linked {fixed_count} players with ChildProfiles.")

finally:
    db.close()
