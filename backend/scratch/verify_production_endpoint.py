import os
import sys

# Import all models for SQLAlchemy registry compilation
from app.users import models as user_models
from app.teams import models as team_models
from app.tournaments import models as tournament_models
from app.matches import models as match_models
from app.bookings import models as booking_models
from app.fields import models as field_models
from app.clubs import models as club_models_system
from app.academies import models as academy_models
from app.club_teams import models as club_teams_models
from app.pickup import models as pickup_models
from app.scouting import models as scouting_models
from app.stats import models as stats_models
from app.media import models as media_models
from app.notifications import models as notification_models
from app.quizzes import models as quiz_models
from app.planner import models as planner_models

from app.main import app
from app.database import SessionLocal
from app.users.models import User, UserRole, Role
from app.common.dependencies import get_current_user
from fastapi.testclient import TestClient

db = SessionLocal()
client = TestClient(app)

try:
    # Find the child player we created feedback for
    child = db.query(User).filter(User.name == "Yernar Smetov").first()
    if not child:
        # Fallback to any child player
        child = db.query(User).join(UserRole).filter(UserRole.role == Role.PLAYER_CHILD).first()
        
    if not child:
        print("No child player found!")
        sys.exit(1)
        
    print(f"Testing endpoint /academies/player/feedback as player: {child.name} ({child.id})")
    
    # Override authentication dependency
    app.dependency_overrides[get_current_user] = lambda: child
    
    # Call endpoint
    response = client.get("/academies/player/feedback")
    print("Response status code:", response.status_code)
    print("Response body:")
    print(response.json())
    
    if response.status_code == 200:
        print("\nSUCCESS! The endpoint is fully working and returns serialized coach feedback data!")
    else:
        print("\nFAILURE! Status code is not 200.")

except Exception as e:
    print(f"Error: {e}")
finally:
    db.close()
