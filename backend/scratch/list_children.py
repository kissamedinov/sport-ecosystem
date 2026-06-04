import os
from dotenv import load_dotenv
from sqlalchemy import create_engine
from sqlalchemy.orm import sessionmaker
from app.users.models import User, PlayerProfile
from app.clubs.models import Club, ChildProfile, ClubStaff
from app.teams.models import Team, TeamMembership
from app.academies.models import Academy

load_dotenv()

SQLALCHEMY_DATABASE_URL = os.getenv("DATABASE_URL", "postgresql://postgres:postgres@localhost:5432/sportseco")
engine = create_engine(SQLALCHEMY_DATABASE_URL)
SessionLocal = sessionmaker(bind=engine)
db = SessionLocal()

try:
    children = db.query(ChildProfile).all()
    print(f"TOTAL CHILDREN IN DB: {len(children)}")
    for child in children:
        club = db.query(Club).filter(Club.id == child.club_id).first()
        club_name = club.name if club else "No Club"
        print(f"- {child.first_name} {child.last_name} (ID: {child.id}) | Linked User: {child.linked_user_id} | Club: {club_name} (ID: {child.club_id})")
        
        # Check user name of linked user if present
        if child.linked_user_id:
            user = db.query(User).filter(User.id == child.linked_user_id).first()
            if user:
                print(f"   Linked User details: name={user.name}, email={user.email}")
                # check if there's any active ClubStaff or accepted invitations
                staffs = db.query(ClubStaff).filter(ClubStaff.user_id == user.id).all()
                for staff in staffs:
                    print(f"   ClubStaff: club_id={staff.club_id}, role={staff.role}, status={staff.status}")
except Exception as e:
    print(f"Error: {e}")
finally:
    db.close()
