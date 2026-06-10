import os
from dotenv import load_dotenv

load_dotenv()

import google.generativeai as genai

api_key = os.getenv("GOOGLE_API_KEY")
genai.configure(api_key=api_key)

try:
    print("Listing models...")
    for m in genai.list_models():
        if 'generateContent' in m.supported_generation_methods:
            print(f"Model: {m.name}")
            print(f"  Supported methods: {m.supported_generation_methods}")
            print(f"  Description: {m.description}")
except Exception as e:
    print(f"Error listing models: {e}")
