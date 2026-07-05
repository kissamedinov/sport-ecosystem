from app.database import SessionLocal
from app.matches.models import Match
from app.teams.models import Team
from uuid import UUID

db = SessionLocal()

# Team IDs in Juldyz Ball Cup
LEGACY_ID = UUID('5d12225e-1aa7-4b36-9035-6801d9fd3627')

matches = db.query(Match).filter(
    (Match.home_team_id == LEGACY_ID) | (Match.away_team_id == LEGACY_ID)
).all()

print(f"Matches for Legacy in DB: {len(matches)}")
for m in matches:
    h = db.query(Team).filter(Team.id == m.home_team_id).first()
    a = db.query(Team).filter(Team.id == m.away_team_id).first()
    print(f"  match_id={m.id} tournament_id={m.tournament_id} home={h.name if h else 'None'} away={a.name if a else 'None'} status={m.status}")
    
db.close()
