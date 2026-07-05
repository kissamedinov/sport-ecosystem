from app.database import SessionLocal
from app.matches.models import Match
from app.tournaments.models import Tournament
from app.teams.models import Team

db = SessionLocal()

matches = db.query(Match).filter(Match.group_id == None).all()
print(f"Total playoff matches (group_id is None) in DB: {len(matches)}")
for m in matches:
    t = db.query(Tournament).filter(Tournament.id == m.tournament_id).first()
    h = db.query(Team).filter(Team.id == m.home_team_id).first()
    a = db.query(Team).filter(Team.id == m.away_team_id).first()
    print(f"  match_id={m.id} tournament={t.name if t else 'None'} ({m.tournament_id}) home={h.name if h else 'None'} vs away={a.name if a else 'None'} status={m.status} round={m.round_number}")

db.close()
