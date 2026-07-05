from app.database import SessionLocal
from app.matches.models import Match, MatchResult
from uuid import UUID

db = SessionLocal()
T_ID = UUID('46bdeb91-c2cd-43b9-9a4e-35892b3d1652')

playoffs = db.query(Match).filter(Match.tournament_id == T_ID, Match.group_id == None).all()
print("Playoff matches state in DB:")
for m in playoffs:
    res = db.query(MatchResult).filter(MatchResult.match_id == m.id).first()
    print(f"  Match {m.id}: round={m.round_number} pos={m.bracket_position} status={m.status} home={m.home_team_id} away={m.away_team_id} score={m.home_score}:{m.away_score} next={m.next_match_id} has_result_record={res is not None} res_status={res.status if res else 'None'} res_score={res.home_score if res else 0}:{res.away_score if res else 0}")
db.close()
