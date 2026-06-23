import psycopg2
import os

DATABASE_URL = os.getenv("DATABASE_URL", "postgresql://postgres:postgres@localhost:5432/sportseco")
if os.path.exists(".env"):
    with open(".env", "r") as f:
        for line in f:
            if line.startswith("DATABASE_URL="):
                DATABASE_URL = line.split("=", 1)[1].strip()

def migrate():
    conn = psycopg2.connect(DATABASE_URL)
    conn.autocommit = True
    cur = conn.cursor()
    
    try:
        print("Adding DRAFT to matchstatus enum...")
        try:
            cur.execute("ALTER TYPE matchstatus ADD VALUE 'DRAFT';")
            print("Successfully added DRAFT to matchstatus.")
        except psycopg2.errors.DuplicateObject:
            print("DRAFT already exists in matchstatus enum.")
        except Exception as e:
            print(f"Non-critical info: Could not add DRAFT value to enum matchstatus: {e}")
            
        print("Altering tournament_series table columns...")
        cur.execute("ALTER TABLE tournament_series ADD COLUMN IF NOT EXISTS logo_url VARCHAR;")
        
        print("Altering matches table columns...")
        cur.execute("ALTER TABLE matches ALTER COLUMN home_team_id DROP NOT NULL;")
        cur.execute("ALTER TABLE matches ALTER COLUMN away_team_id DROP NOT NULL;")
        cur.execute("ALTER TABLE matches ADD COLUMN IF NOT EXISTS next_match_id UUID REFERENCES matches(id);")
        cur.execute("ALTER TABLE matches ADD COLUMN IF NOT EXISTS bracket_position INTEGER;")
        cur.execute("ALTER TABLE matches ADD COLUMN IF NOT EXISTS division_id UUID REFERENCES tournament_divisions(id);")
        
        print("Migration completed successfully!")
    except Exception as e:
        print(f"Error migrating: {e}")
    finally:
        cur.close()
        conn.close()

if __name__ == "__main__":
    migrate()
