from app.database import SessionLocal
import app.users.models
import app.academies.models
import app.teams.models
import app.clubs.models
from app.users.models import User
from app.clubs.models import ChildProfile
from app.teams.models import TeamMembership, Team

db = SessionLocal()
try:
    print("Searching for Nurlybek:")
    cp = db.query(ChildProfile).filter(ChildProfile.first_name.contains("Nurlybek") | ChildProfile.last_name.contains("Nurlybek")).all()
    for c in cp:
        print(f"ChildProfile: ID={c.id}, Name={c.full_name}")
        mems = db.query(TeamMembership).filter(TeamMembership.child_profile_id == c.id).all()
        for m in mems:
            t = db.query(Team).filter(Team.id == m.team_id).first()
            print(f"  Membership ID: {m.id}, Team: {t.name if t else 'None'} ({m.team_id}), Status: {m.status}, JoinStatus: {m.join_status}, PlayerID: {m.player_id}, ChildProfileID: {m.child_profile_id}, Jersey: {m.jersey_number}")

    u = db.query(User).filter(User.name.contains("Nurlybek")).all()
    for usr in u:
        print(f"User: ID={usr.id}, Name={usr.name}")
        mems = db.query(TeamMembership).filter(TeamMembership.player_id == usr.id).all()
        for m in mems:
            t = db.query(Team).filter(Team.id == m.team_id).first()
            print(f"  Membership ID: {m.id}, Team: {t.name if t else 'None'} ({m.team_id}), Status: {m.status}, JoinStatus: {m.join_status}, PlayerID: {m.player_id}, ChildProfileID: {m.child_profile_id}, Jersey: {m.jersey_number}")
finally:
    db.close()
