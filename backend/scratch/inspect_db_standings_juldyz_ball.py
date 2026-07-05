from app.database import SessionLocal
from app.tournaments.models import TournamentStandings, TournamentGroup, Tournament
from app.teams.models import Team
from uuid import UUID

db = SessionLocal()
TOURNAMENT_ID = UUID('2a53a03f-dd1b-4c63-b73e-4fb685a03202')

standings = db.query(TournamentStandings).filter(TournamentStandings.tournament_id == TOURNAMENT_ID).all()
print("Standings in DB for Juldyz Ball:")
for s in standings:
    t = db.query(Team).filter(Team.id == s.team_id).first()
    g = db.query(TournamentGroup).filter(TournamentGroup.id == s.group_id).first() if s.group_id else None
    print(f"  team={t.name if t else 'Unknown'} group_id={s.group_id} group_name={g.name if g else 'None'} played={s.played} points={s.points}")
    
db.close()
