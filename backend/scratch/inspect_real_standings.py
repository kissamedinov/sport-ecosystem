from app.database import SessionLocal
from app.tournaments.models import TournamentGroup, TournamentStandings
from uuid import UUID
from sqlalchemy import text

db = SessionLocal()
T_ID = UUID('46bdeb91-c2cd-43b9-9a4e-35892b3d1652')

groups = db.query(TournamentGroup).filter(TournamentGroup.tournament_id == T_ID).all()
for g in sorted(groups, key=lambda x: x.name):
    print(f"\nGroup {g.name} Standings:")
    standings = db.query(TournamentStandings).filter(
        TournamentStandings.tournament_id == T_ID,
        TournamentStandings.group_id == g.id
    ).order_by(
        TournamentStandings.points.desc(),
        TournamentStandings.goal_difference.desc(),
        TournamentStandings.goals_for.desc()
    ).all()
    for idx, s in enumerate(standings, 1):
        team_name = db.execute(text("SELECT name FROM teams WHERE id = :tid"), {"tid": s.team_id}).scalar()
        print(f"  {idx}. {team_name}: pts={s.points} gd={s.goal_difference} gf={s.goals_for}")
db.close()
