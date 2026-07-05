from app.database import SessionLocal
from app.matches.models import Match
from uuid import UUID

db = SessionLocal()
TEST_T_ID = UUID('f573f21f-3482-4672-880a-14c4788dddea')

playoff_matches = db.query(Match).filter(Match.tournament_id == TEST_T_ID, Match.group_id == None).all()
print(f"Playoff matches count for Test test test (f573f21f...): {len(playoff_matches)}")
for m in playoff_matches:
    print(f"  match_id={m.id} round_number={m.round_number} bracket_position={m.bracket_position} home={m.home_team_id} away={m.away_team_id} status={m.status}")
db.close()
