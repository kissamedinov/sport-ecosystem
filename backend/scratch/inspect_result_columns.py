from app.database import SessionLocal
from sqlalchemy import text

db = SessionLocal()
keys = db.execute(text("SELECT * FROM match_results LIMIT 1")).keys()
print("Match results columns:")
for k in keys:
    print(f"  {k}")
db.close()
