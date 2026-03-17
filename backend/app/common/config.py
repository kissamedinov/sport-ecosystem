import os
from dotenv import load_dotenv

load_dotenv()

AI_SCHEDULER_TOKEN = os.getenv("AI_SCHEDULER_TOKEN", "your_ai_token_here")
