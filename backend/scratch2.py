import traceback
from app.database import SessionLocal, engine
from app.database import Base
from app.users.models import User
import app.teams.models
import app.clubs.models
import app.academies.models
from app.academies.schemas import AcademyTeamCreate
from app.academies.routes import add_academy_team
from app.academies.models import Academy
import uuid

# Re-create all tables locally so we don't have missing columns
Base.metadata.drop_all(bind=engine)
Base.metadata.create_all(bind=engine)

try:
    db = SessionLocal()
    # Create a user
    user = User(
        id=uuid.uuid4(),
        name="Test",
        email="test@test.com",
        password_hash="fake"
    )
    db.add(user)
    db.commit()
    db.refresh(user)

    # Create an academy
    academy = Academy(
        id=uuid.uuid4(),
        name="Academy",
        city="city",
        address="address",
        club_id=uuid.uuid4(),
        owner_id=user.id
    )
    db.add(academy)
    db.commit()
    db.refresh(academy)

    team_in = AcademyTeamCreate(name="test team", age_group="2013")
    res = add_academy_team(id=academy.id, team_in=team_in, db=db, current_user=user)
    print("Success:", res)
except Exception as e:
    print("CRASH!")
    traceback.print_exc()
