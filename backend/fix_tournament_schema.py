
import psycopg2

DATABASE_URL = "postgresql://postgres:postgres@localhost:5432/sportseco"

def fix_schema():
    conn = psycopg2.connect(DATABASE_URL)
    cur = conn.cursor()
    
    tables_to_drop = [
        "tournament_standings", "tournament_group_teams", "tournament_groups", 
        "tournament_awards", "tournament_player_stats", "tournament_teams",
        "tournament_divisions", "schedule_tasks"
    ]
    
    print("Dropping broken tables...")
    for table in tables_to_drop:
        try:
            cur.execute(f"DROP TABLE IF EXISTS {table} CASCADE")
        except Exception as e:
            print(f"Error dropping {table}: {e}")
    
    print("Fixing teams table constraints...")
    try:
        cur.execute("ALTER TABLE teams ALTER COLUMN coach_id DROP NOT NULL")
        cur.execute("ALTER TABLE teams ALTER COLUMN name SET NOT NULL")
    except Exception as e:
        print(f"Error fixing teams table: {e}")
    
    conn.commit()
    print("Tables dropped. Now recreating from models...")
    
    from app.database import Base, engine
    from app.tournaments.models import (
        Tournament, TournamentDivision, TournamentTeam, 
        TournamentStandings, TournamentGroup, TournamentGroupTeam,
        TournamentAward, TournamentPlayerStats, TournamentSeries,
        ScheduleTask
    )
    
    Base.metadata.create_all(bind=engine)
    print("Schema fixed successfully!")
    
    conn.close()

if __name__ == "__main__":
    fix_schema()
