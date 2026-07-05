from app.database import SessionLocal
from app.tournaments.models import TournamentGroup, TournamentGroupTeam, TournamentTeam, TournamentStandings
from app.teams.models import Team
from app.matches.models import Match
from uuid import UUID

db = SessionLocal()
TOURNAMENT_ID = UUID('46bdeb91-c2cd-43b9-9a4e-35892b3d1652')
group_a_id = UUID('633957a0-2376-49a9-a3cf-4360bf7fee32')
group_b_id = UUID('1d2eb51b-112a-4681-94ce-55a4e1546b75')

def print_group_info(group_id, label):
    print(f"\n=== {label} (ID: {group_id}) ===")
    
    # 1. TournamentGroupTeam
    gg_teams = db.query(TournamentGroupTeam).filter(TournamentGroupTeam.group_id == group_id).all()
    print("TournamentGroupTeam teams:")
    for gt in gg_teams:
        tt = db.query(TournamentTeam).filter(TournamentTeam.id == gt.tournament_team_id).first()
        t = db.query(Team).filter(Team.id == tt.team_id).first() if tt else None
        print(f"  gt_id={gt.id} tt_id={gt.tournament_team_id} team_name={t.name if t else 'Unknown'}")
        
    # 2. TournamentStandings
    standings = db.query(TournamentStandings).filter(TournamentStandings.group_id == group_id).all()
    print("TournamentStandings teams:")
    for s in standings:
        t = db.query(Team).filter(Team.id == s.team_id).first()
        print(f"  std_id={s.id} team_name={t.name if t else 'Unknown'}")
        
    # 3. Matches
    matches = db.query(Match).filter(Match.group_id == group_id).all()
    print("Matches:")
    for m in matches:
        t_home = db.query(Team).filter(Team.id == m.home_team_id).first() if m.home_team_id else None
        t_away = db.query(Team).filter(Team.id == m.away_team_id).first() if m.away_team_id else None
        print(f"  match_id={m.id} {t_home.name if t_home else 'None'} vs {t_away.name if t_away else 'None'}")

print_group_info(group_a_id, "GROUP A (db name)")
print_group_info(group_b_id, "GROUP B (db name)")
db.close()
