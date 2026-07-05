from app.database import SessionLocal
from app.matches.models import Match
from app.teams.models import Team
from uuid import UUID

db = SessionLocal()
T_ID = UUID('f573f21f-3482-4672-880a-14c4788dddea')

matches = db.query(Match).filter(Match.tournament_id == T_ID).all()
print(f"Matches in Test test test: {len(matches)}")
for m in matches:
    h = db.query(Team).filter(Team.id == m.home_team_id).first()
    a = db.query(Team).filter(Team.id == m.away_team_id).first()
    print(f"  match_id={m.id} home={h.name if h else 'None'} ({m.home_score}) vs away={a.name if a else 'None'} ({m.away_score}) status={m.status} group_id={m.group_id} round={m.round_number} pos={m.bracket_position}")

db.close()
