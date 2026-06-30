from app.database import engine
from sqlalchemy import text

def migrate():
    with engine.connect() as conn:
        print("Adding columns to PostgreSQL matches table...")
        conn.execute(text("""
            ALTER TABLE matches ADD COLUMN IF NOT EXISTS home_score INTEGER DEFAULT 0;
            ALTER TABLE matches ADD COLUMN IF NOT EXISTS away_score INTEGER DEFAULT 0;
            ALTER TABLE matches ADD COLUMN IF NOT EXISTS elapsed_seconds INTEGER DEFAULT 0;
            ALTER TABLE matches ADD COLUMN IF NOT EXISTS is_timer_running BOOLEAN DEFAULT FALSE;
            ALTER TABLE matches ADD COLUMN IF NOT EXISTS timer_updated_at TIMESTAMP WITH TIME ZONE;
            ALTER TABLE tournaments ADD COLUMN IF NOT EXISTS has_placement_matches BOOLEAN DEFAULT FALSE;
        """))
        conn.commit()
        
        print("Backfilling scores from match_results...")
        conn.execute(text("""
            UPDATE matches 
            SET home_score = match_results.home_score, 
                away_score = match_results.away_score 
            FROM match_results 
            WHERE matches.id = match_results.match_id;
        """))
        conn.commit()
        print("Migration complete!")

if __name__ == "__main__":
    migrate()
