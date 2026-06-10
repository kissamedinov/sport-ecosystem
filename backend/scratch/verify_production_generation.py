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
from app.quizzes.services import QuizService, get_astana_date

db = SessionLocal()
today = get_astana_date()

# Find child user
child_user = db.query(User).join(UserRole).filter(UserRole.role == Role.PLAYER_CHILD).first()
# Find adult user
adult_user = db.query(User).join(UserRole).filter(UserRole.role == Role.PLAYER_ADULT).first()
if not adult_user:
    adult_user = db.query(User).join(UserRole).filter(UserRole.role == Role.COACH).first()

print(f"Child User: {child_user.name if child_user else 'None'}")
print(f"Adult User: {adult_user.name if adult_user else 'None'}")

try:
    if child_user:
        print("\n--- Generating daily quiz for KIDS on production ---")
        quiz_kids = QuizService.get_daily_quiz(db, today, child_user)
        print(f"KIDS Quiz Audience: {quiz_kids.audience}")
        print(f"KIDS Quiz Date: {quiz_kids.date}")
        print(f"Number of questions: {len(quiz_kids.questions)}")
        for idx, q in enumerate(quiz_kids.questions):
            print(f"  Q{idx+1}: {q.question_text}")
            
    if adult_user:
        print("\n--- Generating daily quiz for ADULTS on production ---")
        quiz_adults = QuizService.get_daily_quiz(db, today, adult_user)
        print(f"ADULTS Quiz Audience: {quiz_adults.audience}")
        print(f"ADULTS Quiz Date: {quiz_adults.date}")
        print(f"Number of questions: {len(quiz_adults.questions)}")
        for idx, q in enumerate(quiz_adults.questions):
            print(f"  Q{idx+1}: {q.question_text}")

except Exception as e:
    print(f"Error during verification: {e}")
finally:
    db.close()
