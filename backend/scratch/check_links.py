
from sqlalchemy import create_engine
from sqlalchemy.orm import sessionmaker
from app.users.models import User, ParentChildRelation, PlayerProfile
from app.clubs.models import ChildProfile, Club, ClubStaff
from app.teams.models import Team, TeamMembership
from app.academies.models import Academy

SQLALCHEMY_DATABASE_URL = "postgresql://postgres:postgres@localhost:5432/sportseco"
engine = create_engine(SQLALCHEMY_DATABASE_URL)
SessionLocal = sessionmaker(bind=engine)
db = SessionLocal()

try:
    print("PARENT-CHILD RELATIONS:")
    relations = db.query(ParentChildRelation).all()
    for r in relations:
        parent = db.query(User).filter(User.id == r.parent_id).first()
        child = db.query(User).filter(User.id == r.child_id).first()
        p_name = parent.name if parent else "Unknown"
        c_name = child.name if child else "Unknown"
        print(f"- Parent: {p_name} -> Child: {c_name} | Status: {r.status}")
        
    print("\nCHILD PROFILES:")
    children = db.query(ChildProfile).all()
    for cp in children:
        print(f"- {cp.first_name} {cp.last_name} | Linked User: {cp.linked_user_id}")
finally:
    db.close()
