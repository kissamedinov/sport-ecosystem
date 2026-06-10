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
    
    models_to_try = [
        'gemini-3.5-flash',
        'gemini-3.1-flash-lite',
        'gemini-2.5-flash',
        'gemini-2.0-flash',
        'gemini-flash-latest',
        'gemini-flash-lite-latest'
    ]
    
    text = None
    success = False
    for model_name in models_to_try:
        try:
            print(f"Trying model: {model_name}...")
            model = genai.GenerativeModel(model_name)
            response = model.generate_content(
                prompt,
                generation_config={"response_mime_type": "application/json", "temperature": 1.0}
            )
            text = response.text
            print(f"Success with model: {model_name}!")
            success = True
            break
        except Exception as model_err:
            print(f"Model {model_name} failed: {model_err}")
            
    if not success:
        raise Exception("All models failed!")
        
    print("Response received:")
    print(text)
    # Check parsing
    parsed = json.loads(text)
    print(f"Successfully parsed! Number of questions: {len(parsed)}")
except Exception as e:
    print(f"Error calling Gemini: {e}")
