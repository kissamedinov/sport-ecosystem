import os
import json
import time
from dotenv import load_dotenv

load_dotenv()

from app.quizzes.services import QuizService
from datetime import date

api_key = os.getenv("GOOGLE_API_KEY")

print("Waiting 35 seconds to clear Gemini rate limit...")
time.sleep(35)

try:
    print("Generating for ADULTS...")
    adult_questions = QuizService._generate_with_gemini(api_key, "ADULTS", date.today())
    print(f"ADULTS Questions generated successfully! Count: {len(adult_questions)}")
    print(json.dumps(adult_questions[0], indent=2, ensure_ascii=False))
except Exception as e:
    print(f"Error: {e}")
