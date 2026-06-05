import os
from dotenv import load_dotenv
from sqlalchemy import create_engine, select
from sqlalchemy.orm import sessionmaker
from app.users.models import User, PlayerProfile, UserRole
from app.clubs.models import Club, ChildProfile, ClubStaff, Invitation
from app.teams.models import Team, TeamMembership
from app.academies.models import Academy

load_dotenv()

SQLALCHEMY_DATABASE_URL = os.getenv("DATABASE_URL", "postgresql://postgres:postgres@localhost:5432/sportseco")
engine = create_engine(SQLALCHEMY_DATABASE_URL)
SessionLocal = sessionmaker(bind=engine)
db = SessionLocal()

try:
    # Query users matching Sultan
    users = db.query(User).filter(User.name.ilike("%sultan%")).all()
    print(f"USERS WITH SULTAN: {len(users)}")
    for u in users:
        print(f"USER: {u.name} (ID: {u.id}) | Email: {u.email}")
        roles = db.execute(select(UserRole.role).where(UserRole.user_id == u.id)).scalars().all()
        print(f"  Roles: {roles}")
        
        # Check parent-child relations
        from app.users.models import ParentChildRelation
        relations_as_parent = db.query(ParentChildRelation).filter(ParentChildRelation.parent_id == u.id).all()
        for r in relations_as_parent:
            print(f"  Parent relation to child ID {r.child_id}, status={r.status}")
        relations_as_child = db.query(ParentChildRelation).filter(ParentChildRelation.child_id == u.id).all()
        for r in relations_as_child:
            print(f"  Child relation from parent ID {r.parent_id}, status={r.status}")
            
        # Check active ClubStaff
        staffs = db.query(ClubStaff).filter(ClubStaff.user_id == u.id).all()
        for s in staffs:
            club = db.query(Club).filter(Club.id == s.club_id).first()
            print(f"  ClubStaff: role={s.role}, status={s.status}, club_name={club.name if club else 'None'}")
            
        # Check child profile linked to this user
        cp = db.query(ChildProfile).filter(ChildProfile.linked_user_id == u.id).first()
        if cp:
            club = db.query(Club).filter(Club.id == cp.club_id).first()
            print(f"  ChildProfile: name={cp.first_name} {cp.last_name}, club_name={club.name if club else 'None'}")
            
        # Check invitations
        invites = db.query(Invitation).filter(Invitation.invited_user_id == u.id).all()
        for inv in invites:
            club = db.query(Club).filter(Club.id == inv.club_id).first()
            print(f"  Invitation: role={inv.role}, status={inv.status}, club_name={club.name if club else 'None'}")

except Exception as e:
    print(f"Error: {e}")
finally:
    db.close()
