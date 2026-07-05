import json
import re

filepath = r"C:\Users\Asus\.gemini\antigravity\brain\6ef4a3c2-e47c-456a-8fe7-115f8d23d91e\.system_generated\logs\transcript_full.jsonl"

print("Searching transcript_full.jsonl...")
teams = ['Legacy', 'Arda', 'Elsana', 'ASU 1', 'Commandos', 'Sairan', 'IM', 'Ayagoz']

with open(filepath, 'r', encoding='utf-8') as f:
    for line in f:
        if not line.strip():
            continue
        try:
            obj = json.loads(line)
            content = str(obj.get('content', ''))
            
            # Search for pattern like: TeamName ... score ... TeamName or vice versa
            # Let's search if any lines contain at least two team names
            lines = content.split('\n')
            for l in lines:
                matched_teams = [t for t in teams if t.lower() in l.lower()]
                if len(matched_teams) >= 2 and any(char.isdigit() for char in l):
                    print(f"Step {obj.get('step_index')}: {l.strip()}")
        except Exception as e:
            pass
