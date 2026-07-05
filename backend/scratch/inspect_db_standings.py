from app.database import SessionLocal
from app.tournaments.models import TournamentStandings, TournamentGroup
from uuid import UUID

db = SessionLocal()
TOURNAMENT_ID = UUID('46bdeb91-c2cd-43b9-9a4e-35892b3d1652')

standings = db.query(TournamentStandings).filter(TournamentStandings.tournament_id == TOURNAMENT_ID).all()
print("Database Standings:")
for s in standings:
    print(f"team_id={s.team_id} group_id={s.group_id} group_rel={s.group} group_name={s.group.name if s.group else 'NoGroupRel'}")
    
db.close()
