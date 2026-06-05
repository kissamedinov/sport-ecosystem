from app.database import SessionLocal
import app.users.models
import app.academies.models
import app.teams.models
import app.clubs.models
import app.tournaments.models
import app.matches.models
from app.quizzes.models import DailyQuiz, QuizQuestion, QuizAttempt
from app.quizzes.services import QuizService
from datetime import date

db = SessionLocal()
try:
    user_id = "85a0e190-73b0-4aa4-b376-3181f8d528f6" # Child Player
    user = db.query(app.users.models.User).filter(app.users.models.User.id == user_id).first()
    if not user:
        print("Child player user not found!")
        exit(1)

    print(f"Testing for user: {user.name} ({user.email})")
    
    # 1. Create a dummy Daily Quiz if none exists
    today = date.today()
    quiz = db.query(DailyQuiz).filter(DailyQuiz.date == today, DailyQuiz.audience == "KIDS").first()
    if not quiz:
        print("Creating dummy daily quiz...")
        quiz = DailyQuiz(date=today, audience="KIDS")
        db.add(quiz)
        db.flush()
        db.commit()
    
    # 2. Add an attempt
    print("Adding dummy attempt for user...")
    attempt = QuizAttempt(user_id=user_id, quiz_id=quiz.id, score=8)
    db.add(attempt)
    db.commit()
    print("Attempt added successfully!")
    
    # 3. Test stats function
    points, rank = QuizService.get_user_quiz_stats(db, user)
    print(f"Stats calculated -> Points: {points}, Rank: {rank}")
    
    # 4. Test leaderboard function
    leaderboard = QuizService.get_global_leaderboard(db, user)
    print("\nGlobal Leaderboard entries:")
    for i, entry in enumerate(leaderboard, 1):
        print(f"#{i}: {entry.name} - Streak: {entry.quiz_streak}, Points: {entry.points}")
        
    # Clean up dummy attempt so we don't pollute local DB
    db.delete(attempt)
    db.commit()
    print("\nCleanup complete.")
    
except Exception as e:
    import traceback
    traceback.print_exc()
finally:
    db.close()
