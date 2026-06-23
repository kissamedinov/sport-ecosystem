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
    cur = conn.cursor()
    
    try:
        print("Altering match_lineup_players table columns...")
        cur.execute("ALTER TABLE match_lineup_players ADD COLUMN IF NOT EXISTS pos_x FLOAT;")
        cur.execute("ALTER TABLE match_lineup_players ADD COLUMN IF NOT EXISTS pos_y FLOAT;")
        
        conn.commit()
        print("Migration completed successfully!")
    except Exception as e:
        print(f"Error migrating: {e}")
        conn.rollback()
    finally:
        cur.close()
        conn.close()

if __name__ == "__main__":
    migrate()
