import os
import json
import logging
from datetime import date, datetime, timedelta, timezone
from typing import List, Optional
from sqlalchemy.orm import Session
from app.quizzes.models import DailyQuiz, QuizQuestion, QuizAttempt
from app.quizzes.schemas import QuizAttemptCreate
from app.users.models import User

def get_astana_date():
    # Astana is UTC+5
    return (datetime.now(timezone(timedelta(hours=5)))).date()

logger = logging.getLogger(__name__)

# Try to import Google Generative AI, but handle if not installed
try:
    import google.generativeai as genai
    HAS_GEMINI = True
except ImportError:
    HAS_GEMINI = False

class QuizService:
    @staticmethod
    def get_daily_quiz(db: Session, target_date: date, user: User):
        # 1. Check if quiz already exists for this date
        quiz = db.query(DailyQuiz).filter(DailyQuiz.date == target_date).first()
        if not quiz:
            # 2. If not, generate new one
            quiz = QuizService.generate_daily_quiz(db, target_date)

        # 3. Attach user-specific data
        attempt = db.query(QuizAttempt).filter(
            QuizAttempt.quiz_id == quiz.id,
            QuizAttempt.user_id == user.id
        ).first()
        
        quiz.user_attempt = attempt
        quiz.user_streak = user.quiz_streak
        return quiz

    @staticmethod
    def generate_daily_quiz(db: Session, target_date: date):
        logger.info(f"--- QUIZ GENERATION START for {target_date} ---")
        
        questions_data = []
        api_key = os.getenv("GOOGLE_API_KEY")

        if not api_key:
            logger.error("!!! GOOGLE_API_KEY NOT FOUND IN ENVIRONMENT !!!")
            questions_data = QuizService._get_fallback_questions()
        elif not HAS_GEMINI:
            logger.error("!!! google-generativeai PACKAGE NOT INSTALLED !!!")
            questions_data = QuizService._get_fallback_questions()
        else:
            try:
                logger.info("Calling Gemini API...")
                questions_data = QuizService._generate_with_gemini(api_key)
                logger.info("Gemini API call successful!")
            except Exception as e:
                logger.error(f"!!! Gemini generation failed: {e} !!!")
                questions_data = QuizService._get_fallback_questions()

        # Create Quiz Record
        new_quiz = DailyQuiz(date=target_date)
        db.add(new_quiz)
        db.flush() # Get ID

        for q in questions_data:
            question = QuizQuestion(
                quiz_id=new_quiz.id,
                question_text=q['question'],
                options=q['options'],
                correct_option_index=q['correct_index'],
                explanation=q.get('explanation')
            )
            db.add(question)
        
        db.commit()
        db.refresh(new_quiz)
        return new_quiz

    @staticmethod
    def _generate_with_gemini(api_key: str) -> List[dict]:
        genai.configure(api_key=api_key)
        # Используем модель, которая точно есть в списке (аналог 1.5 Flash)
        model = genai.GenerativeModel('gemini-flash-latest')
        
        prompt = """
        Generate 10 football (soccer) quiz questions for kids (age 8-12), but make them challenging!
        Mix the difficulty: 3 Easy, 4 Medium, and 3 Hard (expert level) questions.
        Topics should include: 
        - Famous players and their records
        - Football rules and referee signals
        - Basic tactics (e.g., "What is a 4-3-3 formation?")
        - Major tournament history (Champions League, World Cup)
        
        Format: JSON list of objects.
        Each object must have:
        - "question": string
        - "options": list of 4 strings
        - "correct_index": integer (0-3)
        - "explanation": string (fun fact or educational tip)
        
        Language: Russian.
        Return ONLY the JSON array.
        """
        
        response = model.generate_content(prompt)
        # Clean response text from markdown code blocks if present
        text = response.text.strip()
        if text.startswith("```json"):
            text = text[7:-3].strip()
        elif text.startswith("```"):
            text = text[3:-3].strip()
            
        return json.loads(text)

    @staticmethod
    def _get_fallback_questions() -> List[dict]:
        return [
            {
                "question": "Сколько игроков в одной футбольной команде на поле?",
                "options": ["7", "11", "5", "9"],
                "correct_index": 1,
                "explanation": "В классическом футболе на поле выходит по 11 игроков от каждой команды."
            },
            {
                "question": "Как называется игрок, которому можно трогать мяч руками?",
                "options": ["Нападающий", "Защитник", "Вратарь", "Судья"],
                "correct_index": 2,
                "explanation": "Только вратарь может брать мяч в руки, но только внутри своей штрафной площади."
            },
            {
                "question": "Кто получил больше всего Золотых мячей в истории?",
                "options": ["Роналду", "Мбаппе", "Месси", "Пеле"],
                "correct_index": 2,
                "explanation": "Лионель Месси является рекордсменом по количеству Золотых мячей."
            },
            {
                "question": "Как называется удар с 11-метровой отметки?",
                "options": ["Угловой", "Пенальти", "Штрафной", "Аут"],
                "correct_index": 1,
                "explanation": "Пенальти — это особый штрафной удар, который исполняется с 11 метров."
            },
            {
                "question": "Какая страна выиграла чемпионат мира в 2022 году?",
                "options": ["Франция", "Бразилия", "Аргентина", "Германия"],
                "correct_index": 2,
                "explanation": "Аргентина во главе с Месси стала чемпионом мира в Катаре."
            },
            {
                "question": "Сколько длится один тайм в футболе?",
                "options": ["30 минут", "45 минут", "60 минут", "20 минут"],
                "correct_index": 1,
                "explanation": "Один тайм длится 45 минут, а весь матч — 90 минут плюс добавленное время."
            },
            {
                "question": "Какого цвета карточку показывает судья при удалении игрока?",
                "options": ["Желтую", "Синюю", "Красную", "Зеленую"],
                "correct_index": 2,
                "explanation": "Красная карточка означает, что игрок должен покинуть поле до конца матча."
            }
        ]

    @staticmethod
    def submit_attempt(db: Session, user: User, quiz_id: str, score: int):
        # 1. Save attempt
        attempt = QuizAttempt(
            user_id=user.id,
            quiz_id=quiz_id,
            score=score,
            total_questions=10
        )
        db.add(attempt)
        
        # 2. Update Streak
        today = get_astana_date()
        yesterday = today - timedelta(days=1)
        
        if score >= 5:
            if user.last_quiz_date == yesterday:
                user.quiz_streak += 1
            else:
                user.quiz_streak = 1
        else:
            user.quiz_streak = 0
            
        user.last_quiz_date = today
        
        db.commit()
        db.refresh(attempt)
        return attempt
