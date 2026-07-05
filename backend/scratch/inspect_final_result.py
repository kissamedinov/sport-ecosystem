from app.database import SessionLocal
from app.matches.models import Match, MatchResult
from uuid import UUID

db = SessionLocal()
final_id = UUID('34f770c7-8cf4-42d2-8ab2-d6e50892e529')

m = db.query(Match).filter(Match.id == final_id).first()
res = db.query(MatchResult).filter(MatchResult.match_id == final_id).all()

print(f"Final match: status={m.status} home={m.home_team_id} away={m.away_team_id}")
print(f"Results count: {len(res)}")
for r in res:
    print(f"  id={r.id} home_score={r.home_score} away_score={r.away_score} status={r.status}")
db.close()
