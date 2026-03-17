
import os
log_path = "c:/Users/Asus/Desktop/test/mobile/backend/debug_log.txt"
if os.path.exists(log_path):
    with open(log_path, "r", encoding="utf-8", errors="ignore") as f:
        lines = f.readlines()
        print("".join(lines[-100:]))
else:
    print("Log file NOT FOUND")
