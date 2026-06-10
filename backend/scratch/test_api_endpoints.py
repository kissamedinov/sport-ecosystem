import os
import sys
from dotenv import load_dotenv

load_dotenv()

# Set PYTHONPATH
sys.path.insert(0, os.path.abspath(os.path.join(os.path.dirname(__file__), "..")))

from sqlalchemy.orm import Session

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
from app.quizzes.models import DailyQuiz, QuizQuestion
from app.quizzes.services import QuizService, get_astana_date

# Find test users in DB
db = SessionLocal()

# Find a child player
child_user = db.query(User).join(UserRole).filter(UserRole.role == Role.PLAYER_CHILD).first()
# Find an adult player or coach
adult_user = db.query(User).join(UserRole).filter(UserRole.role == Role.PLAYER_ADULT).first()
if not adult_user:
    adult_user = db.query(User).join(UserRole).filter(UserRole.role == Role.COACH).first()
if not adult_user:
    adult_user = db.query(User).first()

print(f"Child User: {child_user.name if child_user else 'None'}")
print(f"Adult User: {adult_user.name if adult_user else 'None'}")

if not child_user or not adult_user:
    print("Test users not found! Cannot proceed with testing.")
    db.close()
    sys.exit(1)

def run_tests():
    today = get_astana_date()
    print(f"\nToday's Date (Astana): {today}")
    
    # 1. Reset today's daily quiz
    print("\n--- Resetting Daily Quiz (deleting from DB) ---")
    deleted_count = db.query(DailyQuiz).filter(DailyQuiz.date == today).delete()
    db.commit()
    print(f"Deleted {deleted_count} quiz records for today.")
    
    # 2. Retrieve Kids Daily Quiz (triggers generation)
    print("\n--- Retrieving Daily Quiz for KIDS (Child User) ---")
    quiz_kids = QuizService.get_daily_quiz(db, today, child_user)
    print(f"Kids Quiz Audience: {quiz_kids.audience}")
    print(f"Kids Quiz Date: {quiz_kids.date}")
    print(f"Number of questions generated: {len(quiz_kids.questions)}")
    for idx, q in enumerate(quiz_kids.questions):
        print(f"  Q{idx+1}: {q.question_text}")
        
    # 3. Retrieve Adults Daily Quiz (triggers generation)
    # Since we can hit rate limit, let's catch it if it fails, or wait if needed
    print("\n--- Retrieving Daily Quiz for ADULTS (Adult User) ---")
    quiz_adults = QuizService.get_daily_quiz(db, today, adult_user)
    print(f"Adults Quiz Audience: {quiz_adults.audience}")
    print(f"Adults Quiz Date: {quiz_adults.date}")
    print(f"Number of questions generated: {len(quiz_adults.questions)}")
    for idx, q in enumerate(quiz_adults.questions):
        print(f"  Q{idx+1}: {q.question_text}")

try:
    run_tests()
finally:
    db.close()
