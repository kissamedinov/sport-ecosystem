from app.database import SessionLocal
from app.matches.models import Match
from uuid import UUID

db = SessionLocal()
KULTEGIN_TEAM_ID = UUID('548ee50c-449d-461e-a37c-1db07cd3fbe0')

matches = db.query(Match).filter(
    (Match.home_team_id == KULTEGIN_TEAM_ID) | (Match.away_team_id == KULTEGIN_TEAM_ID)
).all()

print(f"Matches for Kultegin: {len(matches)}")
for m in matches:
    print(f"  match_id={m.id} home={m.home_team_id} away={m.away_team_id} status={m.status}")
    
db.close()
