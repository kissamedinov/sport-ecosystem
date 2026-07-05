from app.database import SessionLocal
from app.matches.models import Match
from app.teams.models import Team
from uuid import UUID

db = SessionLocal()
T_ID = UUID('2a53a03f-dd1b-4c63-b73e-4fb685a03202')

matches = db.query(Match).filter(Match.tournament_id == T_ID).all()
print(f"Matches in Juldyz Ball: {len(matches)}")
for m in matches:
    h = db.query(Team).filter(Team.id == m.home_team_id).first()
    a = db.query(Team).filter(Team.id == m.away_team_id).first()
    print(f"  match_id={m.id} home={h.name if h else 'None'} ({m.home_score}) vs away={a.name if a else 'None'} ({m.away_score}) status={m.status}")

db.close()
