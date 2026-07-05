from app.database import SessionLocal
from app.matches.models import Match
from app.teams.models import Team

db = SessionLocal()

# Print first 5 matches to see what their fields look like
matches = db.query(Match).limit(5).all()
for m in matches:
    print(f"Match: id={m.id} tournament_id={m.tournament_id} home={m.home_team_id} away={m.away_team_id}")
    
db.close()
