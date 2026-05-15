import uuid
from sqlalchemy import Column, String, Date, DateTime, ForeignKey, Integer, func, JSON
from sqlalchemy.dialects.postgresql import UUID
from sqlalchemy.orm import relationship
from app.database import Base

class DailyQuiz(Base):
    __tablename__ = "daily_quizzes"

    id = Column(UUID(as_uuid=True), primary_key=True, default=uuid.uuid4)
    date = Column(Date, unique=True, nullable=False, index=True)
    created_at = Column(DateTime(timezone=True), server_default=func.now())

    questions = relationship("QuizQuestion", back_populates="quiz", cascade="all, delete-orphan")

class QuizQuestion(Base):
    __tablename__ = "quiz_questions"

    id = Column(UUID(as_uuid=True), primary_key=True, default=uuid.uuid4)
    quiz_id = Column(UUID(as_uuid=True), ForeignKey("daily_quizzes.id"), nullable=False)
    question_text = Column(String, nullable=False)
    options = Column(JSON, nullable=False) # List of strings
    correct_option_index = Column(Integer, nullable=False)
    explanation = Column(String, nullable=True)

    quiz = relationship("DailyQuiz", back_populates="questions")

class QuizAttempt(Base):
    __tablename__ = "quiz_attempts"

    id = Column(UUID(as_uuid=True), primary_key=True, default=uuid.uuid4)
    user_id = Column(UUID(as_uuid=True), ForeignKey("users.id"), nullable=False)
    quiz_id = Column(UUID(as_uuid=True), ForeignKey("daily_quizzes.id"), nullable=False)
    score = Column(Integer, nullable=False)
    total_questions = Column(Integer, default=7)
    completed_at = Column(DateTime(timezone=True), server_default=func.now())

    user = relationship("app.users.models.User")
    quiz = relationship("DailyQuiz")
