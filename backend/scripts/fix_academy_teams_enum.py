import sys
from sqlalchemy import text
from app.database import engine

def migrate_age_group():
    print("Migrating academy_teams.age_group from ENUM to VARCHAR...")
    with engine.begin() as conn:
        try:
            # PostgreSQL requires USING clause when casting ENUM to VARCHAR
            conn.execute(text("ALTER TABLE academy_teams ALTER COLUMN age_group TYPE VARCHAR USING age_group::text;"))
            print("Successfully altered column type to VARCHAR!")
        except Exception as e:
            print(f"FAILED TO ALTER COLUMN. Error: {e}")
            sys.exit(1)

if __name__ == "__main__":
    migrate_age_group()
