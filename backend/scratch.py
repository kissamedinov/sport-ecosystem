import traceback
from app.database import SessionLocal
from app.users.models import User
from app.academies.schemas import AcademyTeamCreate
from app.academies.routes import add_academy_team
from app.academies.models import Academy
import app.teams.models # Import to resolve TeamMembership
import app.clubs.models
import uuid

try:
    db = SessionLocal()
    user = db.query(User).filter(User.email.contains("test.com")).first()
    academy_id = uuid.UUID("478e9b40-4d35-41be-aa5e-5f412e920965")
    a = db.query(Academy).first()
    if a:
        academy_id = a.id
    team_in = AcademyTeamCreate(name="test", age_group="2013")
    res = add_academy_team(id=academy_id, team_in=team_in, db=db, current_user=user)
    print("Success:", res)
except Exception as e:
    traceback.print_exc()
