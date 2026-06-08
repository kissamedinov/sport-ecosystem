from app.database import SessionLocal
import app.users.models
import app.academies.models
import app.teams.models
import app.clubs.models
import app.matches.models
from app.teams.models import Team, TeamMembership
from app.users.models import User
from app.clubs.models import ChildProfile

db = SessionLocal()
try:
    teams = db.query(Team).all()
    print("Found Teams:")
    for t in teams:
        print(f"ID: {t.id}, Name: {t.name}")
        memberships = db.query(TeamMembership).filter(TeamMembership.team_id == t.id).all()
        print(f"  Memberships count: {len(memberships)}")
        for m in memberships:
            player_name = "Unknown"
            if m.player_id:
                u = db.query(User).filter(User.id == m.player_id).first()
                if u:
                    player_name = u.name
            elif m.child_profile_id:
                cp = db.query(ChildProfile).filter(ChildProfile.id == m.child_profile_id).first()
                if cp:
                    player_name = cp.full_name + " (Child)"
            print(f"    Membership ID: {m.id}, PlayerID: {m.player_id}, ChildProfileID: {m.child_profile_id}, Name: {player_name}, Jersey: {m.jersey_number}")
finally:
    db.close()
