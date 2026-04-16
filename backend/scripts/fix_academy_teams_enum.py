from sqlalchemy import text
from app.database import engine

def migrate_age_group():
    print("Migrating academy_teams.age_group from ENUM to VARCHAR...")
    with engine.begin() as conn:
        try:
            # PostgreSQL command to change an ENUM column to a string column
            conn.execute(text("ALTER TABLE academy_teams ALTER COLUMN age_group TYPE VARCHAR;"))
            print("Successfully altered column type!")
        except Exception as e:
            print(f"Error, maybe it's already VARCHAR or table missing? Details: {e}")

if __name__ == "__main__":
    migrate_age_group()
