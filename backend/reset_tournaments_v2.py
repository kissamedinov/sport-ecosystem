import sys
import os
# Add the current directory to sys.path so 'app' can be found
sys.path.append(os.getcwd())

from sqlalchemy import text
from app.database import engine

def reset_tournaments():
    print("--- Tournament 2.0 Robust Reset ---")
    
    # Tables to permanently remove (legacy)
    legacy_tables = [
        "tournament_matches",
        "tournament_match_player_stats",
        "match_sheets",
        "match_sheet_players",
        "tournament_top_scorers"
    ]
    
    # Tables to clear (new system)
    # Order matters due to foreign keys, but CASCADE handles it if we use it.
    tournament_tables = [
        "tournament_squad_members",
        "tournament_standings",
        "tournament_teams",
        "tournament_group_teams",
        "tournament_groups",
        "tournament_divisions",
        "tournament_announcements",
        "tournament_awards",
        "tournament_player_stats",
        "tournaments",
        "tournament_series",
        "tournament_registrations",
        "tournament_squads"
    ]

    with engine.connect() as conn:
        print("1. Dropping legacy tables...")
        for table in legacy_tables:
            try:
                conn.execute(text(f"DROP TABLE IF EXISTS {table} CASCADE"))
                conn.commit()
                print(f"   - Dropped {table}")
            except Exception as e:
                print(f"   - Skip {table}: {str(e).splitlines()[0]}")
                conn.rollback()

        print("2. Truncating tournament data...")
        for table in tournament_tables:
            try:
                conn.execute(text(f"TRUNCATE TABLE {table} CASCADE"))
                conn.commit()
                print(f"   - Truncated {table}")
            except Exception as e:
                print(f"   - Skip {table}: {str(e).splitlines()[0]}")
                conn.rollback()

        print("3. Cleaning up core Match tables (tournament-linked only)...")
        try:
            # Delete events linked to tournament matches
            conn.execute(text("""
                DELETE FROM match_events 
                WHERE match_id IN (SELECT id FROM matches WHERE tournament_id IS NOT NULL);
            """))
            # Delete lineups linked to tournament matches
            conn.execute(text("""
                DELETE FROM match_lineups 
                WHERE match_id IN (SELECT id FROM matches WHERE tournament_id IS NOT NULL);
            """))
            # Delete the matches themselves
            conn.execute(text("DELETE FROM matches WHERE tournament_id IS NOT NULL;"))
            conn.commit()
            print("   - Core Match tables cleaned.")
        except Exception as e:
            print(f"   - Error cleaning Match tables: {str(e).splitlines()[0]}")
            conn.rollback()

    print("4. Recreating schema from updated models...")
    try:
        # Import main to trigger all model registrations
        from app.main import app 
        from app.database import Base
        Base.metadata.create_all(bind=engine)
        print("   - Schema recreation complete.")
    except Exception as e:
        print(f"   - Error during recreation: {e}")

    print("\n--- Reset Process Finished ---")

if __name__ == "__main__":
    reset_tournaments()
