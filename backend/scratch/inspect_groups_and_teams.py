from app.database import SessionLocal
from app.tournaments.models import TournamentGroup, TournamentGroupTeam, TournamentTeam
from app.teams.models import Team
from uuid import UUID

db = SessionLocal()
TOURNAMENT_ID = UUID('46bdeb91-c2cd-43b9-9a4e-35892b3d1652')

groups = db.query(TournamentGroup).filter(TournamentGroup.tournament_id == TOURNAMENT_ID).all()
print("Groups:")
for g in groups:
    print(f"Group: id={g.id} name={g.name}")
    gg_teams = db.query(TournamentGroupTeam).filter(TournamentGroupTeam.group_id == g.id).all()
    for gt in gg_teams:
        tt = db.query(TournamentTeam).filter(TournamentTeam.id == gt.tournament_team_id).first()
        t = db.query(Team).filter(Team.id == tt.team_id).first() if tt else None
        print(f"  Team: name={t.name if t else 'Unknown'} tt_id={gt.tournament_team_id}")

all_tt = db.query(TournamentTeam).filter(TournamentTeam.tournament_id == TOURNAMENT_ID).all()
print("\nAll TournamentTeams:")
for tt in all_tt:
    t = db.query(Team).filter(Team.id == tt.team_id).first()
    print(f"  tt_id={tt.id} team_name={t.name if t else 'Unknown'} team_id={tt.team_id}")

db.close()
