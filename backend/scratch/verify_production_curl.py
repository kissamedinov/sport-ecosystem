import os
import sys
import json
import urllib.request

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

from app.database import SessionLocal
from app.users.models import User, UserRole, Role
from app.auth.jwt import create_access_token

db = SessionLocal()

try:
    # Find the child player Yernar Smetov
    child = db.query(User).filter(User.name == "Yernar Smetov").first()
    if not child:
        child = db.query(User).join(UserRole).filter(UserRole.role == Role.PLAYER_CHILD).first()
        
    if not child:
        print("No child player found!")
        sys.exit(1)
        
    print(f"Generating JWT token for player: {child.name} ({child.id})")
    
    # Create token
    token = create_access_token(data={"user_id": str(child.id), "role": "PLAYER_CHILD"})
    
    # Request endpoint using urllib
    url = "http://localhost:8000/academies/player/feedback"
    req = urllib.request.Request(
        url,
        headers={
            "Authorization": f"Bearer {token}",
            "Accept": "application/json"
        }
    )
    
    print(f"Sending GET request to {url}...")
    with urllib.request.urlopen(req) as response:
        status_code = response.getcode()
        body = response.read().decode('utf-8')
        print("Response status code:", status_code)
        print("Response body:")
        parsed = json.loads(body)
        print(json.dumps(parsed, indent=2, ensure_ascii=False))
        
        if status_code == 200:
            print("\nSUCCESS! The endpoint is fully working and returns serialized coach feedback data via HTTP!")
        else:
            print("\nFAILURE!")

except Exception as e:
    print(f"Error: {e}")
finally:
    db.close()
