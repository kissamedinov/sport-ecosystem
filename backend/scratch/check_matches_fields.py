from app.database import SessionLocal
from app.matches.models import Match
from uuid import UUID

db = SessionLocal()
T_ID = UUID('46bdeb91-c2cd-43b9-9a4e-35892b3d1652')

matches = db.query(Match).filter(Match.tournament_id == T_ID).all()
print("Matches fields info:")
for m in matches:
    print(f"  Match {m.id}: field_id={m.field_id}, field_name={getattr(m, 'field_name', 'No field_name attr')}")
db.close()
