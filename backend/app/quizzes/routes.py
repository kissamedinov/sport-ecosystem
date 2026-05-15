from fastapi import APIRouter, Depends, HTTPException, status
from sqlalchemy.orm import Session
from datetime import date
from typing import List
from app.database import get_db
from app.auth.routes import get_current_user
from app.quizzes.schemas import DailyQuizSchema, QuizAttemptSchema, QuizAttemptCreate
from app.quizzes.services import QuizService, get_astana_date

router = APIRouter(prefix="/quizzes", tags=["Quizzes"])

@router.get("/daily", response_model=DailyQuizSchema)
def get_daily_quiz(
    db: Session = Depends(get_db),
    current_user = Depends(get_current_user)
):
    """Get the football quiz for today. Generates it if it doesn't exist."""
    today = get_astana_date()
    quiz = QuizService.get_daily_quiz(db, today, current_user)
    return quiz

@router.post("/daily/submit", response_model=QuizAttemptSchema)
def submit_quiz_attempt(
    attempt_data: QuizAttemptCreate,
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
