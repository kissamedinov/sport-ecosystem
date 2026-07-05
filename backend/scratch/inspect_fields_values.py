from app.database import SessionLocal
from sqlalchemy import text

db = SessionLocal()
rows = db.execute(text("SELECT id, name, location, owner_id FROM fields")).all()
for r in rows:
    print(f"id={r[0]} name={r[1]} location={r[2]} owner_id={r[3]}")
db.close()
