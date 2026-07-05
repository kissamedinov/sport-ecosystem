from app.database import SessionLocal
from app.tournaments.models import TournamentTeam, TournamentStandings
from app.teams.models import Team
from uuid import UUID

db = SessionLocal()
T_ID = UUID('46bdeb91-c2cd-43b9-9a4e-35892b3d1652')

arda = db.query(Team).filter(Team.name.like('%Arda%')).first()
if arda:
    print(f"Arda Team ID: {arda.id}")
    tt = db.query(TournamentTeam).filter(TournamentTeam.tournament_id == T_ID, TournamentTeam.team_id == arda.id).first()
    if tt:
        print(f"TournamentTeam: registered_by={tt.registered_by} division_id={tt.division_id}")
    ts = db.query(TournamentStandings).filter(TournamentStandings.tournament_id == T_ID, TournamentStandings.team_id == arda.id).first()
    if ts:
        print(f"TournamentStandings: group_id={ts.group_id} points={ts.points}")
    else:
        print("TournamentStandings NOT found for Arda!")
else:
    print("Arda team not found at all!")
db.close()
