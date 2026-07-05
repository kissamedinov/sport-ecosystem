from app.database import SessionLocal
from app.matches.models import Match
from uuid import UUID

db = SessionLocal()
T_ID = UUID('46bdeb91-c2cd-43b9-9a4e-35892b3d1652')

matches = db.query(Match).filter(Match.tournament_id == T_ID, Match.group_id == None).all()
print("Playoff matches next_match_id:")
for m in matches:
    print(f"  match_id={m.id} round_number={m.round_number} bracket_position={m.bracket_position} next_match_id={m.next_match_id}")
db.close()
