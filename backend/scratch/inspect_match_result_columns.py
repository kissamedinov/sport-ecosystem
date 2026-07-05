from app.database import SessionLocal
from app.matches.models import MatchResult

db = SessionLocal()
mr = db.query(MatchResult).first()
if mr:
    for c in mr.__table__.columns:
        print(f"MatchResult column: {c.name}")
db.close()
