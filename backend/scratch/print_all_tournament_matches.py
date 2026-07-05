from app.database import SessionLocal
from app.matches.models import Match
from app.teams.models import Team
from uuid import UUID

db = SessionLocal()
TOURNAMENT_ID = UUID('46bdeb91-c2cd-43b9-9a4e-35892b3d1652')

matches = db.query(Match).filter(Match.tournament_id == TOURNAMENT_ID).all()
print(f"Total matches in tournament: {len(matches)}")
for m in matches:
    home_name = db.query(Team).filter(Team.id == m.home_team_id).first().name if m.home_team_id else 'None'
    away_name = db.query(Team).filter(Team.id == m.away_team_id).first().name if m.away_team_id else 'None'
    print(f"  Match: id={m.id} status={m.status} {home_name} ({m.home_team_id}) vs {away_name} ({m.away_team_id})")
    
db.close()
