from app.database import SessionLocal
from app.tournaments.standings_service import update_standings
from app.tournaments.models import TournamentTeam, TournamentGroup, TournamentStandings
from app.matches.models import Match
from app.matches.services import seed_playoffs_automatically
from uuid import UUID
from sqlalchemy import text

db = SessionLocal()
T_ID = UUID('46bdeb91-c2cd-43b9-9a4e-35892b3d1652')

try:
    print("Recalculating standings with fixed group resolution...")
    t_teams = db.query(TournamentTeam).filter(TournamentTeam.tournament_id == T_ID).all()
    for tt in t_teams:
        update_standings(db, T_ID, tt.team_id)
        
    db.commit()
    print("Standings recalculated successfully!")
    
    # Print standings to verify
    print("\n--- UPDATED STANDINGS ---")
    groups = db.query(TournamentGroup).filter(TournamentGroup.tournament_id == T_ID).all()
    for g in sorted(groups, key=lambda x: x.name):
        print(f"\nGroup {g.name}:")
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
            
    # Trigger playoff seeding
    print("\nTriggering automatic playoff seeding...")
    seed_playoffs_automatically(db, T_ID)
    
    # Print playoff matches
    print("\n--- VERIFYING PLAYOFF MATCHES ---")
    playoffs = db.query(Match).filter(Match.tournament_id == T_ID, Match.group_id == None, Match.round_number == 1).order_by(Match.bracket_position).all()
    for m in playoffs:
        h_name = db.execute(text("SELECT name FROM teams WHERE id = :tid"), {"tid": m.home_team_id}).scalar()
        a_name = db.execute(text("SELECT name FROM teams WHERE id = :tid"), {"tid": m.away_team_id}).scalar()
        stage = "Semifinal 1" if m.bracket_position == 0 else "Semifinal 2" if m.bracket_position == 1 else "5-6th Place" if m.bracket_position == 2 else "7-8th Place"
        print(f"  {stage} (ID: {m.id}): {h_name} vs {a_name} -> status={m.status}")

except Exception as e:
    db.rollback()
    print(f"Error: {e}")
finally:
    db.close()
