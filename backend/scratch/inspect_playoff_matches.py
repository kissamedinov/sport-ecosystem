from app.database import SessionLocal
from app.matches.models import Match
from uuid import UUID

db = SessionLocal()
matches = db.query(Match).filter(
    Match.tournament_id == UUID('46bdeb91-c2cd-43b9-9a4e-35892b3d1652'),
    Match.group_id == None
).all()
print(f"Playoff matches count: {len(matches)}")
for m in matches:
    print(f"  round={m.round_number} pos={m.bracket_position} home={m.home_team_id} away={m.away_team_id}")
db.close()
