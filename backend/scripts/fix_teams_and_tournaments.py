import sys
import os
from sqlalchemy import create_engine, text, inspect
from dotenv import load_dotenv

# Add the current directory to sys.path to import app modules
sys.path.append(os.getcwd())

from app.database import SQLALCHEMY_DATABASE_URL

def fix_teams_and_tournaments():
    engine = create_engine(SQLALCHEMY_DATABASE_URL)
    inspector = inspect(engine)
    
    with engine.connect() as conn:
        print("--- FIXING TEAMS TABLE ---")
        teams_columns = [c['name'] for c in inspector.get_columns('teams')]
        
        team_updates = [
            ("rating", "INTEGER DEFAULT 1000"),
            ("matches_played", "INTEGER DEFAULT 0"),
            ("wins", "INTEGER DEFAULT 0"),
            ("draws", "INTEGER DEFAULT 0"),
            ("losses", "INTEGER DEFAULT 0")
        ]
        
        for col_name, col_type in team_updates:
            if col_name not in teams_columns:
                print(f"Adding column {col_name} to teams table...")
                try:
                    conn.execute(text(f"ALTER TABLE teams ADD COLUMN {col_name} {col_type}"))
                    conn.commit()
                    print(f"Successfully added {col_name}.")
                except Exception as e:
                    print(f"Error adding {col_name}: {e}")
            else:
                print(f"Column {col_name} already exists in teams table.")

        print("\n--- FIXING TOURNAMENTS TABLE ---")
        # Fix the invalid enum value 'GRASS'
        try:
            print("Migrating 'GRASS' to 'NATURAL_GRASS' in tournaments table...")
            # We use a raw SQL update because SQLAlchemy would fail validation trying to load 'GRASS'
            result = conn.execute(text("UPDATE tournaments SET surface_type = 'NATURAL_GRASS' WHERE surface_type = 'GRASS'"))
            conn.commit()
            print(f"Updated {result.rowcount} rows in tournaments table.")
        except Exception as e:
            print(f"Error updating surface_type: {e}")

    print("\nSchema and data fix completed.")

if __name__ == "__main__":
    load_dotenv()
    fix_teams_and_tournaments()
