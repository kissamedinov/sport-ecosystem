from app.database import SessionLocal
from app.matches.models import Match, MatchResult
from uuid import UUID

db = SessionLocal()
T_ID = UUID('46bdeb91-c2cd-43b9-9a4e-35892b3d1652')

print("--- CURRENT STATE OF UNPLAYED GROUP MATCHES ---")
unplayed_ids = [
    UUID('53d92058-bc7e-4389-9cf5-2d0890283d25'),
    UUID('3ebf5326-d36b-480e-b78f-5101c95286d2'),
    UUID('5ffd4fcc-ea11-464a-989d-b3ff45ad9a62'),
    UUID('a7ee4deb-9d28-4ac2-878a-627155824e2b')
]
for m_id in unplayed_ids:
    m = db.query(Match).filter(Match.id == m_id).first()
    res = db.query(MatchResult).filter(MatchResult.match_id == m_id).first()
    print(f"Match {m.id}: status={m.status} home_score={m.home_score} away_score={m.away_score} has_result_record={res is not None}")

print("\n--- CURRENT STATE OF PLAYOFF MATCHES ---")
playoffs = db.query(Match).filter(Match.tournament_id == T_ID, Match.group_id == None).all()
for m in playoffs:
    print(f"Match {m.id}: round={m.round_number} pos={m.bracket_position} home={m.home_team_id} away={m.away_team_id} status={m.status}")

db.close()
