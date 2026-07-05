from app.database import SessionLocal
from sqlalchemy import text

db = SessionLocal()
row = db.execute(text("SELECT * FROM fields LIMIT 1")).first()
keys = db.execute(text("SELECT * FROM fields LIMIT 1")).keys()
print("Fields table columns:")
for k in keys:
    print(f"  {k}")
db.close()
