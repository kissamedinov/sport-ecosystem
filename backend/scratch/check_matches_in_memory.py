from app.database import SessionLocal
from app.matches.models import Match

db = SessionLocal()
matches = db.query(Match).all()
count = 0
for m in matches:
    if str(m.tournament_id) == '46bdeb91-c2cd-43b9-9a4e-35892b3d1652':
        count += 1
print(f"Matches matching Juldyz Ball Cup string UUID in memory: {count}")
db.close()
