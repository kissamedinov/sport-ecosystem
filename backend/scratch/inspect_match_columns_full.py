from app.database import SessionLocal
from app.matches.models import Match

db = SessionLocal()
m = db.query(Match).first()
if m:
    for c in m.__table__.columns:
        print(f"Match column: {c.name}")
db.close()
