from app.database import SessionLocal
import app.users.models
import app.academies.models
import app.teams.models
import app.clubs.models
import app.tournaments.models
import app.matches.models
import app.quizzes.models

db = SessionLocal()
try:
    user_id = 'c964ce18-afe9-4872-8fb9-bd9c745ab756'
    user = db.query(app.users.models.User).filter(app.users.models.User.id == user_id).first()
    if user:
        print(f"User: {user.name}")
        print(f"Email: {user.email}")
        print(f"Streak: {user.quiz_streak}")
        
        attempts = db.query(app.quizzes.models.QuizAttempt).filter(app.quizzes.models.QuizAttempt.user_id == user_id).all()
        print(f"Attempts Count: {len(attempts)}")
        total_pts = sum(a.score for a in attempts)
        print(f"Total points calculated from attempts: {total_pts}")
        
        # Let's list all users to see who has what streak/attempts
        all_users = db.query(app.users.models.User).all()
        user_scores = []
        for u in all_users:
            u_attempts = db.query(app.quizzes.models.QuizAttempt).filter(app.quizzes.models.QuizAttempt.user_id == u.id).all()
            pts = sum(a.score for a in u_attempts)
            user_scores.append((u.name, u.email, u.quiz_streak, pts))
        
        print("\nLeaderboard ranking:")
        user_scores.sort(key=lambda x: x[3], reverse=True)
        for i, (name, email, streak, pts) in enumerate(user_scores, 1):
            print(f"#{i}: {name} ({email}) - Streak: {streak}, Points: {pts}")
    else:
        print("User not found.")
except Exception as e:
    import traceback
    traceback.print_exc()
finally:
    db.close()
