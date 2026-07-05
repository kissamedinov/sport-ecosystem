from app.database import SessionLocal
from app.matches.models import Match
from app.teams.models import Team
from uuid import UUID

db = SessionLocal()
T_ID = UUID('46bdeb91-c2cd-43b9-9a4e-35892b3d1652')

matches = db.query(Match).filter(Match.tournament_id == T_ID).all()
print("Matches dates:")
for m in matches:
    h = db.query(Team).filter(Team.id == m.home_team_id).first()
    a = db.query(Team).filter(Team.id == m.away_team_id).first()
    h_name = h.name if h else 'None'
    a_name = a.name if a else 'None'
    print(f"  Match {m.id}: {h_name} vs {a_name} -> date={m.match_date}")
db.close()
