from pydantic import BaseModel
from uuid import UUID
from datetime import date, datetime
from typing import List, Optional

class QuizQuestionSchema(BaseModel):
    id: UUID
    question_text: str
    options: List[str]
    correct_option_index: int
    explanation: Optional[str] = None

    class Config:
        from_attributes = True

class QuizAttemptSchema(BaseModel):
    id: UUID
    user_id: UUID
    quiz_id: UUID
    score: int
    total_questions: int
    completed_at: datetime

    class Config:
        from_attributes = True

class DailyQuizSchema(BaseModel):
    id: UUID
    date: date
    questions: List[QuizQuestionSchema]
    user_attempt: Optional[QuizAttemptSchema] = None
    user_streak: int = 0

    class Config:
        from_attributes = True

class QuizAttemptCreate(BaseModel):
    score: int
    total_questions: int = 10
