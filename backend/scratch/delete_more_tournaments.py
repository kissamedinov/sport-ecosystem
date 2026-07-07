from app.database import SessionLocal
from app.tournaments.models import Tournament
from sqlalchemy import text, or_

db = SessionLocal()

# We target tournaments containing: "321", "333", "322", "kuzbayev", "aman cup"
tournaments = db.query(Tournament).filter(
    or_(
        Tournament.name.ilike("%321%"),
        Tournament.name.ilike("%333%"),
        Tournament.name.ilike("%322%"),
        Tournament.name.ilike("%kuzbayev%"),
        Tournament.name.ilike("%aman cup%")
    )
).all()

print(f"Found {len(tournaments)} tournaments to delete.")

for t in tournaments:
    t_id = t.id
    print(f"Deleting tournament '{t.name}' (id: {t_id})...")
    
    # 1. Get match IDs
    match_ids = [m[0] for m in db.execute(text("SELECT id FROM matches WHERE tournament_id = :t_id"), {"t_id": t_id}).fetchall()]
    
    if match_ids:
        print(f"  - Deleting {len(match_ids)} matches and stats...")
        # Delete from player_match_stats
        db.execute(text("DELETE FROM player_match_stats WHERE match_id = ANY(:match_ids)"), {"match_ids": match_ids})
        # Delete from team_rating_history
        db.execute(text("DELETE FROM team_rating_history WHERE match_id = ANY(:match_ids)"), {"match_ids": match_ids})
        # Delete from match_awards
        db.execute(text("DELETE FROM match_awards WHERE match_id = ANY(:match_ids)"), {"match_ids": match_ids})
        # Delete from match_events
        db.execute(text("DELETE FROM match_events WHERE match_id = ANY(:match_ids)"), {"match_ids": match_ids})
        # Delete from match_player_stats
        db.execute(text("DELETE FROM match_player_stats WHERE match_id = ANY(:match_ids)"), {"match_ids": match_ids})
        # Delete from match_lineup_players
        db.execute(text("DELETE FROM match_lineup_players WHERE lineup_id IN (SELECT id FROM match_lineups WHERE match_id = ANY(:match_ids))"), {"match_ids": match_ids})
        # Delete from match_lineups
        db.execute(text("DELETE FROM match_lineups WHERE match_id = ANY(:match_ids)"), {"match_ids": match_ids})
        # Delete from match_results
        db.execute(text("DELETE FROM match_results WHERE match_id = ANY(:match_ids)"), {"match_ids": match_ids})
        # Delete from matches
        db.execute(text("DELETE FROM matches WHERE tournament_id = :t_id"), {"t_id": t_id})
        
    # 2. Get division IDs
    division_ids = [d[0] for d in db.execute(text("SELECT id FROM tournament_divisions WHERE tournament_edition_id = :t_id"), {"t_id": t_id}).fetchall()]
    
    # 3. Get tournament team IDs
    tteam_ids = [tt[0] for tt in db.execute(text("SELECT id FROM tournament_teams WHERE tournament_id = :t_id OR (division_id = ANY(:div_ids) AND division_id IS NOT NULL)"), {"t_id": t_id, "div_ids": division_ids or [None]}).fetchall()]
    
    if tteam_ids:
        print(f"  - Deleting {len(tteam_ids)} tournament teams...")
        # Delete from tournament_squads
        db.execute(text("DELETE FROM tournament_squads WHERE tournament_team_id = ANY(:tteam_ids)"), {"tteam_ids": tteam_ids})
        # Delete from tournament_group_teams
        db.execute(text("DELETE FROM tournament_group_teams WHERE tournament_team_id = ANY(:tteam_ids)"), {"tteam_ids": tteam_ids})
        # Delete from tournament_teams
        db.execute(text("DELETE FROM tournament_teams WHERE id = ANY(:tteam_ids)"), {"tteam_ids": tteam_ids})
        
    # 4. Get group IDs
    group_ids = [g[0] for g in db.execute(text("SELECT id FROM tournament_groups WHERE tournament_id = :t_id"), {"t_id": t_id}).fetchall()]
    if group_ids:
        print(f"  - Deleting {len(group_ids)} groups...")
        db.execute(text("DELETE FROM tournament_group_teams WHERE group_id = ANY(:group_ids)"), {"group_ids": group_ids})
        # Delete from tournament_groups
        db.execute(text("DELETE FROM tournament_groups WHERE tournament_id = :t_id"), {"t_id": t_id})
        
    # 5. Delete other associations
    db.execute(text("DELETE FROM tournament_standings WHERE tournament_id = :t_id"), {"t_id": t_id})
    db.execute(text("DELETE FROM tournament_registrations WHERE tournament_id = :t_id"), {"t_id": t_id})
    db.execute(text("DELETE FROM schedule_tasks WHERE tournament_id = :t_id"), {"t_id": t_id})
    db.execute(text("DELETE FROM payments WHERE tournament_id = :t_id"), {"t_id": t_id})
    db.execute(text("DELETE FROM media_items WHERE tournament_id = :t_id"), {"t_id": t_id})
    
    # 6. Delete divisions
    if division_ids:
        print(f"  - Deleting {len(division_ids)} divisions...")
        db.execute(text("DELETE FROM tournament_player_stats WHERE division_id = ANY(:div_ids)"), {"div_ids": division_ids})
        db.execute(text("DELETE FROM tournament_awards WHERE division_id = ANY(:div_ids)"), {"div_ids": division_ids})
        db.execute(text("DELETE FROM tournament_divisions WHERE tournament_edition_id = :t_id"), {"t_id": t_id})
        
    # 7. Delete tournament
    db.execute(text("DELETE FROM tournaments WHERE id = :t_id"), {"t_id": t_id})
    print(f"Successfully deleted '{t.name}'.")

db.commit()
print("Selected tournaments deleted successfully.")
db.close()
