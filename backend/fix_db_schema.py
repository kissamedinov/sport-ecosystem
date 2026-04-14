import os
from sqlalchemy import create_engine, text
from dotenv import load_dotenv

# Load environment variables
load_dotenv()

DATABASE_URL = os.getenv("DATABASE_URL")
if DATABASE_URL and DATABASE_URL.startswith("postgres://"):
    DATABASE_URL = DATABASE_URL.replace("postgres://", "postgresql://", 1)

from app.database import Base
# Import ALL models to ensure they are registered with Base.metadata
from app.academies.models import Academy, TrainingSession, TrainingAttendance, TrainingSchedule, training_session_teams, training_schedule_teams
from app.teams.models import Team, TeamMembership
from app.users.models import User, PlayerProfile

engine = create_engine(DATABASE_URL)

def fix_schema():
    # 1. Create all missing tables (like training_session_teams)
    print("Creating missing tables...")
    Base.metadata.create_all(engine)
    print("- Done.")

    with engine.connect() as conn:
        print("\nChecking for missing columns in 'teams' table...")
        
        # Add 'division' column if it doesn't exist
        try:
            conn.execute(text("ALTER TABLE teams ADD COLUMN IF NOT EXISTS division VARCHAR DEFAULT 'Group A';"))
            print("- Column 'division' added or already exists.")
        except Exception as e:
            print(f"- Error adding 'division': {e}")

        # Add 'is_active' column if it doesn't exist
        try:
            conn.execute(text("ALTER TABLE teams ADD COLUMN IF NOT EXISTS is_active BOOLEAN DEFAULT TRUE;"))
            print("- Column 'is_active' added or already exists.")
        except Exception as e:
            print(f"- Error adding 'is_active': {e}")

        # Add 'birth_year' column if it doesn't exist
        try:
            conn.execute(text("ALTER TABLE teams ADD COLUMN IF NOT EXISTS birth_year INTEGER;"))
            print("- Column 'birth_year' added or already exists.")
        except Exception as e:
            print(f"- Error adding 'birth_year': {e}")

        # Commit changes
        conn.execute(text("COMMIT;"))
        print("\nDatabase schema updated successfully!")

if __name__ == "__main__":
    fix_schema()
