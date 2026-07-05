from app.database import SessionLocal
from app.matches.models import Match
from uuid import UUID

db = SessionLocal()
T_ID = UUID('46bdeb91-c2cd-43b9-9a4e-35892b3d1652')

group_matches = db.query(Match).filter(Match.tournament_id == T_ID, Match.group_id.isnot(None)).all()
print("Group stage matches status:")
for m in group_matches:
    print(f"  Match {m.id}: status={m.status} home={m.home_team_id} away={m.away_team_id}")
db.close()
