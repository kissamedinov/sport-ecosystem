from sqlalchemy import text, inspect
from app.database import engine

def migrate():
    print("Starting migration for Academy Branches and Schedules...")
    with engine.begin() as conn:
        # 1. Create academy_branches table
        conn.execute(text("""
            CREATE TABLE IF NOT EXISTS academy_branches (
                id UUID PRIMARY KEY,
                academy_id UUID NOT NULL REFERENCES football_academies(id) ON DELETE CASCADE,
                name VARCHAR NOT NULL,
                address VARCHAR NOT NULL,
                description VARCHAR,
                created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP
            );
        """))
        print("Table academy_branches created or verified.")

        # 2. Add branch_id to academy_training_schedules
        try:
            conn.execute(text("ALTER TABLE academy_training_schedules ADD COLUMN branch_id UUID REFERENCES academy_branches(id) ON DELETE SET NULL;"))
            print("Added branch_id to academy_training_schedules.")
        except Exception as e:
            print(f"Skipping adding branch_id (probably exists): {e}")

        # 3. Fix Association Tables (Switch from teams to academy_teams)
        # This is CRITICAL to fix the 500 error.
        
        tables_to_fix = ["training_schedule_teams", "training_session_teams"]
        for table in tables_to_fix:
            print(f"Fixing foreign keys for {table}...")
            try:
                # Find the current foreign key name for team_id
                inspector = inspect(engine)
                fks = inspector.get_foreign_keys(table)
                for fk in fks:
                    if "team_id" in fk["constrained_columns"]:
                        fk_name = fk["name"]
                        conn.execute(text(f"ALTER TABLE {table} DROP CONSTRAINT {fk_name};"))
                        print(f"Dropped old constraint {fk_name} from {table}.")
                
                # Add new constraint pointing to academy_teams
                conn.execute(text(f"ALTER TABLE {table} ADD CONSTRAINT {table}_team_id_fkey FOREIGN KEY (team_id) REFERENCES academy_teams(id) ON DELETE CASCADE;"))
                print(f"Added new constraint to {table} pointing to academy_teams.")
            except Exception as e:
                print(f"Error fixing {table}: {e}")

    print("Migration finished successfully!")

if __name__ == "__main__":
    migrate()
