import sys
import os
from sqlalchemy import text
from sqlalchemy.orm import Session

# Add the current directory to sys.path to import app modules
sys.path.append(os.path.abspath(os.path.join(os.path.dirname(__file__), '.')))

from app.database import SessionLocal

def fix_schema():
    db = SessionLocal()
    try:
        print("Starting schema fix...")
        
        # Drop legacy team_id columns from both tables to support many-to-many transition
        commands = [
            "ALTER TABLE training_sessions DROP COLUMN IF EXISTS team_id;",
            "ALTER TABLE academy_training_schedules DROP COLUMN IF EXISTS team_id;",
        ]
        
        for cmd in commands:
            print(f"Executing: {cmd}")
            db.execute(text(cmd))
        
        db.commit()
        print("Schema fix applied successfully!")
        
    except Exception as e:
        print(f"Error applying schema fix: {str(e)}")
        db.rollback()
    finally:
        db.close()

if __name__ == "__main__":
    fix_schema()
