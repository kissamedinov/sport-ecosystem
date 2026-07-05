filepath = "/root/sport-ecosystem/backend/logs/debug_log.txt"

with open(filepath, 'r', encoding='utf-8') as f:
    lines = f.readlines()

print("Searching for MATCH_RESULT notifications in VPS logs...")
for idx, line in enumerate(lines):
    if "MATCH_RESULT" in line or "create_notification" in line:
        # Print the line and next 5 lines if they exist
        print(f"Line {idx}: {line.strip()}")
        for i in range(1, 4):
            if idx + i < len(lines):
                print(f"  + {lines[idx+i].strip()}")
        print("-" * 50)
