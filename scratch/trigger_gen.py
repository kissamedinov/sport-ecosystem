import uuid
from app.database import SessionLocal
from app.tournaments.services import generate_tournament_schedule

db = SessionLocal()
try:
    res = generate_tournament_schedule(db, uuid.UUID('cb521583-b9e2-442f-8938-47ab625aee12'))
    print("Generation result:", res)
finally:
    db.close()
