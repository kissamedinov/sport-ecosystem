import sys
import os
from sqlalchemy import create_engine, inspect
from dotenv import load_dotenv

# Add the current directory to sys.path to import app modules
sys.path.append(os.getcwd())

from app.database import SQLALCHEMY_DATABASE_URL

def verify_fix():
    engine = create_engine(SQLALCHEMY_DATABASE_URL)
    inspector = inspect(engine)
    
    print("--- SCHEMA VERIFICATION ---")
    
    # Check teams
    teams_columns = [c['name'] for c in inspector.get_columns('teams')]
    print(f"\nColumns in 'teams': {teams_columns}")
    expected_teams = ["rating", "matches_played", "wins", "draws", "losses"]
    for col in expected_teams:
        print(f"HAS {col}: {col in teams_columns}")
        
    # Check tournaments data
    with engine.connect() as conn:
        result = conn.execute(text("SELECT count(*) FROM tournaments WHERE surface_type = 'GRASS'"))
        grass_count = result.scalar()
        print(f"\nTournaments with surface_type 'GRASS': {grass_count}")
        
        result = conn.execute(text("SELECT count(*) FROM tournaments WHERE surface_type = 'NATURAL_GRASS'"))
        natural_grass_count = result.scalar()
        print(f"Tournaments with surface_type 'NATURAL_GRASS': {natural_grass_count}")

    print("\n--- END OF VERIFICATION ---")

if __name__ == "__main__":
    from sqlalchemy import text # Import text locally if needed, but it's usually at top
    load_dotenv()
    verify_fix()
