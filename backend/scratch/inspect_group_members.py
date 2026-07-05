from app.database import SessionLocal
from app.tournaments.models import TournamentGroup, TournamentStandings
from app.teams.models import Team
from uuid import UUID
from sqlalchemy import text

db = SessionLocal()
T_ID = UUID('46bdeb91-c2cd-43b9-9a4e-35892b3d1652')

print("Groups:")
groups = db.query(TournamentGroup).filter(TournamentGroup.tournament_id == T_ID).all()
for g in groups:
    print(f"  Group ID={g.id} Name={g.name}")

print("\nTournamentStandings entries:")
ts_entries = db.query(TournamentStandings).filter(TournamentStandings.tournament_id == T_ID).all()
for s in ts_entries:
    team_name = db.execute(text("SELECT name FROM teams WHERE id = :tid"), {"tid": s.team_id}).scalar()
    print(f"  Team={team_name} team_id={s.team_id} group_id={s.group_id} points={s.points}")
db.close()
