import psycopg2
import os

DATABASE_URL = "postgresql://postgres:postgres@localhost:5432/sportseco"

def update_schema():
    conn = psycopg2.connect(DATABASE_URL)
    cur = conn.cursor()
    
    try:
        # Update teams table
        print("Updating teams table...")
        cur.execute("ALTER TABLE teams ADD COLUMN IF NOT EXISTS academy_name VARCHAR;")
        cur.execute("ALTER TABLE teams ADD COLUMN IF NOT EXISTS age_category VARCHAR;")
        
        # Update tournament_teams table
        print("Updating tournament_teams table...")
        # Note: status uses RegistrationStatus enum in models, but for SQL we can use VARCHAR if not using native enums
        cur.execute("ALTER TABLE tournament_teams ADD COLUMN IF NOT EXISTS status VARCHAR DEFAULT 'PENDING';")
        
        # Update tournament_matches table
        print("Updating tournament_matches table...")
        cur.execute("ALTER TABLE tournament_matches ADD COLUMN IF NOT EXISTS status VARCHAR DEFAULT 'SCHEDULED';")
        cur.execute("ALTER TABLE tournament_matches ADD COLUMN IF NOT EXISTS home_score INTEGER DEFAULT 0;")
        cur.execute("ALTER TABLE tournament_matches ADD COLUMN IF NOT EXISTS away_score INTEGER DEFAULT 0;")
        
        conn.commit()
        print("Database schema updated successfully!")
    except Exception as e:
        print(f"Error updating schema: {e}")
        conn.rollback()
    finally:
        cur.close()
        conn.close()

if __name__ == "__main__":
    update_schema()
