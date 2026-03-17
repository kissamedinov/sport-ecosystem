import uuid
from sqlalchemy import text
from app.database import engine

def fix_schema():
    print("Checking academy_players table...")
    try:
        with engine.connect() as conn:
            # Check if column exists
            # Using a more robust query for PostgreSQL
            result = conn.execute(text("SELECT column_name FROM information_schema.columns WHERE table_name='academy_players' AND column_name='player_profile_id'"))
            column_exists = result.fetchone() is not None
            
            if not column_exists:
                print("Adding player_profile_id to academy_players...")
                # Add the column and the foreign key constraint
                conn.execute(text("ALTER TABLE academy_players ADD COLUMN player_profile_id UUID REFERENCES player_profiles(id)"))
                conn.commit()
                print("Column and constraint added successfully.")
            else:
                print("Column player_profile_id already exists.")
    except Exception as e:
        print(f"Error fixing schema: {e}")

if __name__ == "__main__":
    fix_schema()
