from app.database import SessionLocal
from sqlalchemy import text

db = SessionLocal()

# Check all tables containing field or fields
rows = db.execute(text("SELECT id, name FROM fields")).all()
print("Fields in database:")
for r in rows:
    print(f"  id={r[0]}, name={r[1]}")
db.close()
