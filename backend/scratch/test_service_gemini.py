import os
import json
import logging
from dotenv import load_dotenv

load_dotenv()

logging.basicConfig(level=logging.INFO)

from app.quizzes.services import QuizService
from datetime import date

api_key = os.getenv("GOOGLE_API_KEY")
print(f"GOOGLE_API_KEY: {api_key}")

try:
    print("Generating for KIDS...")
    kids_questions = QuizService._generate_with_gemini(api_key, "KIDS", date.today())
    print(f"KIDS Questions generated successfully! Count: {len(kids_questions)}")
    print(json.dumps(kids_questions[0], indent=2, ensure_ascii=False))
    
    print("\nGenerating for ADULTS...")
    adult_questions = QuizService._generate_with_gemini(api_key, "ADULTS", date.today())
    print(f"ADULTS Questions generated successfully! Count: {len(adult_questions)}")
    print(json.dumps(adult_questions[0], indent=2, ensure_ascii=False))
except Exception as e:
    print(f"Error during test: {e}")
