import sys
import os
from sqlalchemy import create_engine, text, inspect
from dotenv import load_dotenv

# Add the current directory to sys.path to import app modules
sys.path.append(os.getcwd())

from app.database import SQLALCHEMY_DATABASE_URL
from app.tournaments.models import Base

def update_schema():
    engine = create_engine(SQLALCHEMY_DATABASE_URL)
    
    # 1. Add missing columns to 'tournaments' table
    columns_to_add = [
        ("series_id", "UUID"),
        ("year", "INTEGER"),
        ("season", "VARCHAR"),
        ("surface_type", "VARCHAR"),
        ("age_category", "VARCHAR"),
        ("allowed_age_categories", "VARCHAR"),
        ("created_by", "UUID"),
        ("num_fields", "INTEGER DEFAULT 1"),
        ("match_half_duration", "INTEGER DEFAULT 20"),
        ("halftime_break_duration", "INTEGER DEFAULT 5"),
        ("break_between_matches", "INTEGER DEFAULT 10"),
        ("start_time", "TIMESTAMP"),
        ("end_time", "TIMESTAMP"),
        ("minimum_rest_slots", "INTEGER DEFAULT 1"),
        ("points_for_win", "INTEGER DEFAULT 3"),
        ("points_for_draw", "INTEGER DEFAULT 1"),
        ("points_for_loss", "INTEGER DEFAULT 0"),
        ("status", "VARCHAR DEFAULT 'upcoming'"),
        ("history_data", "VARCHAR"),
        ("created_at", "TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP"),
        ("updated_at", "TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP")
    ]
    
    inspector = inspect(engine)
    existing_columns = [c['name'] for c in inspector.get_columns('tournaments')]
    
    with engine.connect() as conn:
        for col_name, col_type in columns_to_add:
            if col_name not in existing_columns:
                print(f"Adding column {col_name} to tournaments table...")
                try:
                    conn.execute(text(f"ALTER TABLE tournaments ADD COLUMN {col_name} {col_type}"))
                    conn.commit()
                except Exception as e:
                    print(f"Error adding column {col_name}: {e}")
            else:
                print(f"Column {col_name} already exists in tournaments table.")
        
        # 2. Add 'birth_year' to 'teams' table
        existing_team_columns = [c['name'] for c in inspector.get_columns('teams')]
        if 'birth_year' not in existing_team_columns:
            print("Adding column birth_year to teams table...")
            try:
                conn.execute(text("ALTER TABLE teams ADD COLUMN birth_year INTEGER"))
                conn.commit()
            except Exception as e:
                print(f"Error adding birth_year to teams: {e}")

        # 3. Create all new tables
        print("Creating new tables if they don't exist...")
        Base.metadata.create_all(bind=engine)
        print("Schema update completed successfully.")

if __name__ == "__main__":
    load_dotenv()
    update_schema()
