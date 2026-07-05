from app.database import SessionLocal
from app.tournaments.models import Tournament, TournamentTeam, TournamentGroup, TournamentGroupTeam
from app.teams.models import Team
from uuid import UUID

db = SessionLocal()

for t_id in [UUID('00be78a4-a93c-4745-8c0f-3263abf639c6'), UUID('2a53a03f-dd1b-4c63-b73e-4fb685a03202'), UUID('46bdeb91-c2cd-43b9-9a4e-35892b3d1652')]:
    t = db.query(Tournament).filter(Tournament.id == t_id).first()
    print(f"\nTournament: {t.name} (id={t.id})")
    
    # Print groups
    groups = db.query(TournamentGroup).filter(TournamentGroup.tournament_id == t_id).all()
    for g in groups:
        gt_teams = db.query(TournamentGroupTeam).filter(TournamentGroupTeam.group_id == g.id).all()
        team_names = []
        for gt in gt_teams:
            tt = db.query(TournamentTeam).filter(TournamentTeam.id == gt.tournament_team_id).first()
            if tt:
                team = db.query(Team).filter(Team.id == tt.team_id).first()
                team_names.append(team.name if team else 'Unknown')
        print(f"  Group '{g.name}': {', '.join(team_names)}")

db.close()
