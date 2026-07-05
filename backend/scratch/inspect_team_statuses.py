from app.database import SessionLocal
from app.tournaments.models import TournamentTeam
from app.teams.models import Team
from uuid import UUID

db = SessionLocal()
TOURNAMENT_ID = UUID('46bdeb91-c2cd-43b9-9a4e-35892b3d1652')

tt_teams = db.query(TournamentTeam).filter(TournamentTeam.tournament_id == TOURNAMENT_ID).all()
print("Tournament teams and statuses:")
for tt in tt_teams:
    t = db.query(Team).filter(Team.id == tt.team_id).first()
    print(f"  name={t.name if t else 'Unknown'} status={tt.status}")
    
db.close()
