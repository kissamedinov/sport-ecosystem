from app.database import SessionLocal
from app.matches.models import Match
from app.teams.models import Team
from uuid import UUID

db = SessionLocal()
TOURNAMENT_ID = UUID('46bdeb91-c2cd-43b9-9a4e-35892b3d1652')

matches = db.query(Match).filter(Match.tournament_id == TOURNAMENT_ID).all()
print("All matches for tournament:")
for m in matches:
    t_home = db.query(Team).filter(Team.id == m.home_team_id).first() if m.home_team_id else None
    t_away = db.query(Team).filter(Team.id == m.away_team_id).first() if m.away_team_id else None
    print(f"  match_id={m.id} group_id={m.group_id} stage_round={m.round_number} pos={m.bracket_position} {t_home.name if t_home else 'None'} {m.home_score} : {m.away_score} {t_away.name if t_away else 'None'}  status={m.status}")

db.close()
