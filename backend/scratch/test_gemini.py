import os
import json
import logging
from dotenv import load_dotenv

load_dotenv()

logging.basicConfig(level=logging.INFO)
logger = logging.getLogger(__name__)

api_key = os.getenv("GOOGLE_API_KEY")
print(f"GOOGLE_API_KEY: {api_key}")

try:
    import google.generativeai as genai
    print("google.generativeai package is installed!")
except ImportError as e:
    print(f"google.generativeai package import failed: {e}")
    exit(1)

if not api_key:
    print("API Key is missing")
    exit(1)

genai.configure(api_key=api_key)
model = genai.GenerativeModel('gemini-flash-latest')

prompt = """
Generate 10 football (soccer) quiz questions for kids (age 8-12), but make them challenging!
Mix the difficulty: 3 Easy, 4 Medium, and 3 Hard (expert level) questions.
Format: JSON list of objects.
Each object must have:
- "question": string
- "options": list of 4 strings
- "correct_index": integer (0-3)
- "explanation": string (fun fact or educational tip)

Language: Russian.
Return ONLY the JSON array.
"""

try:
    print("Calling Gemini...")
    response = model.generate_content(
        prompt,
        generation_config={"response_mime_type": "application/json"}
    )
    print("Response received:")
    text = response.text
    print(text)
    # Check parsing
    parsed = json.loads(text)
    print(f"Successfully parsed! Number of questions: {len(parsed)}")
except Exception as e:
    print(f"Error calling Gemini: {e}")
