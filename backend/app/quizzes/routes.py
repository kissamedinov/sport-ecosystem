from fastapi import APIRouter, Depends, HTTPException, status
from sqlalchemy.orm import Session
from datetime import date
from typing import List
from app.database import get_db
from app.auth.routes import get_current_user
from app.quizzes import schemas
from app.quizzes.services import QuizService, get_astana_date

router = APIRouter(prefix="/quizzes", tags=["Quizzes"])

@router.get("/daily", response_model=schemas.DailyQuizSchema)
def get_daily_quiz(
    db: Session = Depends(get_db),
    current_user = Depends(get_current_user)
):
    """Get the football quiz for today. Generates it if it doesn't exist."""
    today = get_astana_date()
    quiz = QuizService.get_daily_quiz(db, today, current_user)
    points, rank = QuizService.get_user_quiz_stats(db, current_user)
    quiz.user_points = points
    quiz.user_rank = rank
    return quiz

@router.post("/daily/submit", response_model=schemas.QuizAttemptSchema)
def submit_quiz_attempt(
    attempt_data: schemas.QuizAttemptCreate,
    db: Session = Depends(get_db),
    current_user = Depends(get_current_user)
):
    """Submit the result of today's quiz."""
    today = get_astana_date()
    quiz = QuizService.get_daily_quiz(db, today, current_user)
    
    # Anti-cheat: Check if already attempted today 
    if quiz.user_attempt:
        raise HTTPException(
            status_code=status.HTTP_403_FORBIDDEN,
            detail="You have already participated in today's quiz."
        )
    
    attempt = QuizService.submit_attempt(
        db, 
        user=current_user, 
        quiz_id=quiz.id, 
        score=attempt_data.score
    )
    return attempt

@router.get("/leaderboard", response_model=List[schemas.QuizLeaderboardEntry])
def get_quiz_leaderboard(
    db: Session = Depends(get_db),
    current_user = Depends(get_current_user)
):
    """Get the global quiz leaderboard of users/players."""
    leaderboard = QuizService.get_global_leaderboard(db, current_user)
    result = []
    for index, entry in enumerate(leaderboard):
        result.append({
            "rank": index + 1,
            "name": entry.name,
            "points": entry.points,
            "streak": entry.quiz_streak,
            "user_id": entry.id
        })
    return result
