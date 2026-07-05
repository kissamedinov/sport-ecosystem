from app.database import SessionLocal
from app.matches.models import Match
from app.teams.models import Team
from uuid import UUID

db = SessionLocal()

# Team names in Juldyz Ball Cup
team_names = ["Elsana 2016-2017", "Fc Arda 2016-2017", "Legacy 2016-2017", "FC ASU 1", "Commandos 2016-2017", "Sairan 2016-2017", "IM 2016-2017"]
teams = db.query(Team).filter(Team.name.in_(team_names)).all()
team_ids = [t.id for t in teams]

matches = db.query(Match).filter(
    (Match.home_team_id.in_(team_ids)) & (Match.away_team_id.in_(team_ids))
).all()

print(f"Total matches in DB between these teams: {len(matches)}")
for m in matches:
    h = db.query(Team).filter(Team.id == m.home_team_id).first()
    a = db.query(Team).filter(Team.id == m.away_team_id).first()
    print(f"  match_id={m.id} tournament_id={m.tournament_id} home={h.name if h else 'None'} ({m.home_score}) vs away={a.name if a else 'None'} ({m.away_score}) status={m.status}")

db.close()
