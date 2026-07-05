from app.database import SessionLocal
from app.matches.models import MatchResult
from uuid import UUID

db = SessionLocal()
m_id = UUID('3ebf5326-d36b-480e-b78f-5101c95286d2')
res = db.query(MatchResult).filter(MatchResult.match_id == m_id).all()
print(f"Results count for 3ebf5326...: {len(res)}")
for r in res:
    print(f"  id={r.id} match_id={r.match_id} home_score={r.home_score} away_score={r.away_score}")
db.close()
