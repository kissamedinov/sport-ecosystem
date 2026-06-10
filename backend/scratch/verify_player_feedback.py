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

from app.database import SessionLocal
from app.users.models import User, UserRole, Role
from app.academies.models import CoachFeedback
from app.academies.schemas import CoachFeedbackResponse

db = SessionLocal()

try:
    # Find a child player who has feedback
    # Let's find child players and check if they have feedback
    child_players = db.query(User).join(UserRole).filter(UserRole.role == Role.PLAYER_CHILD).all()
    
    print(f"Found {len(child_players)} child players in DB.")
    
    target_child = None
    for child in child_players:
        cnt = db.query(CoachFeedback).filter(CoachFeedback.player_id == child.id).count()
        if cnt > 0:
            target_child = child
            print(f"Child {child.name} has {cnt} feedbacks.")
            break
            
    if not target_child:
        print("No child players with feedback found! Let's insert a test feedback.")
        # Let's take the first child player and insert a feedback
        if child_players:
            target_child = child_players[0]
            # Find an academy they might be enrolled in, or just any academy ID
            from app.academies.models import AcademyPlayer
            enr = db.query(AcademyPlayer).filter(AcademyPlayer.player_id == target_child.id).first()
            academy_id = enr.academy_id if enr else None
            
            # Let's create dummy feedback
            fb = CoachFeedback(
                player_id=target_child.id,
                coach_id=db.query(User).join(UserRole).filter(UserRole.role == Role.COACH).first().id,
                technical=8,
                tactical=7,
                physical=9,
                discipline=10,
                comment="Отличная тренировка, высокий темп и дисциплина!",
                academy_id=academy_id
            )
            db.add(fb)
            db.commit()
            print(f"Inserted dummy feedback for child: {target_child.name}")
        else:
            print("No child players found in DB at all!")
            sys.exit(1)
            
    # Now simulate the get_player_feedback logic
    print(f"\nTesting get_player_feedback logic for player {target_child.name}...")
    feedbacks = db.query(CoachFeedback).filter(
        CoachFeedback.player_id == target_child.id
    ).order_by(CoachFeedback.created_at.desc()).limit(10).all()
    
    print(f"Retrieved {len(feedbacks)} feedbacks.")
    for idx, fb in enumerate(feedbacks):
        resp = CoachFeedbackResponse.model_validate(fb)
        print(f"Feedback {idx+1}:")
        print(f"  Technical: {resp.technical}")
        print(f"  Tactical: {resp.tactical}")
        print(f"  Physical: {resp.physical}")
        print(f"  Discipline: {resp.discipline}")
        print(f"  Comment: {resp.comment}")
        print(f"  Date: {resp.created_at}")

except Exception as e:
    print(f"Error during verification: {e}")
finally:
    db.close()
