from app.database import SessionLocal
from app.matches.models import Match
from app.teams.models import Team
from uuid import UUID

db = SessionLocal()
TOURNAMENT_ID = UUID('46bdeb91-c2cd-43b9-9a4e-35892b3d1652')
AYAGOZ_TEAM_ID = UUID('32192b38-a67c-458b-88ca-0af792ead1bb')

matches = db.query(Match).filter(
    Match.tournament_id == TOURNAMENT_ID,
    (Match.home_team_id == AYAGOZ_TEAM_ID) | (Match.away_team_id == AYAGOZ_TEAM_ID)
).all()

print(f"Matches involving Ayagoz found in DB query: {len(matches)}")
for m in matches:
    print(f"Match: id={m.id} home={m.home_team_id} (type={type(m.home_team_id)}) away={m.away_team_id} (type={type(m.away_team_id)})")
    
db.close()
