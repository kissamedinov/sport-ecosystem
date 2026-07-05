import json

filepath = r"C:\Users\Asus\.gemini\antigravity\brain\6ef4a3c2-e47c-456a-8fe7-115f8d23d91e\.system_generated\logs\transcript.jsonl"

print("Searching for matches and scores in transcript...")
with open(filepath, 'r', encoding='utf-8') as f:
    for line in f:
        if not line.strip():
            continue
        try:
            obj = json.loads(line)
            content_str = str(obj.get('content', ''))
            # Look for matches, results, or scores in the text
            if 'score' in content_str.lower() or 'матч' in content_str.lower():
                # Print a small snippet of the match/score info
                for term in ['Legacy', 'Arda', 'Elsana', 'ASU 1', 'Commandos', 'Sairan', 'IM']:
                    if term in content_str:
                        print(f"Step {obj.get('step_index')}: Found {term}")
                        # Print some surrounding characters
                        idx = content_str.find(term)
                        print(content_str[max(0, idx-100):min(len(content_str), idx+200)])
                        print("-" * 50)
                        break
        except Exception as e:
            pass
