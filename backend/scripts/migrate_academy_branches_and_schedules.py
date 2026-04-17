from sqlalchemy import text, inspect
from app.database import engine

def run_sql(sql_str):
    print(f"Executing: {sql_str[:100]}...")
    try:
        with engine.begin() as conn:
            conn.execute(text(sql_str))
        print("Done.")
    except Exception as e:
        print(f"Skipping/Error: {e}")

def migrate():
    print("Starting Improved Migration for Academy Branches and Schedules...")
    
    # 1. Create academy_branches table
    run_sql("""
        CREATE TABLE IF NOT EXISTS academy_branches (
            id UUID PRIMARY KEY,
            academy_id UUID NOT NULL REFERENCES football_academies(id) ON DELETE CASCADE,
            name VARCHAR NOT NULL,
            address VARCHAR NOT NULL,
            description VARCHAR,
            created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP
        );
    """)

    # 2. Add branch_id to academy_training_schedules
    run_sql("ALTER TABLE academy_training_schedules ADD COLUMN branch_id UUID REFERENCES academy_branches(id) ON DELETE SET NULL;")

    # 3. Drop legacy team_id column (CRITICAL FIX)
    # The error 'NotNullViolation' on team_id happens because it exists in the DB but not in our code anymore
    run_sql("ALTER TABLE academy_training_schedules DROP COLUMN IF EXISTS team_id;")

    # 4. Fix Association Tables (Switch from teams to academy_teams)
    tables_to_fix = ["training_schedule_teams", "training_session_teams"]
    for table in tables_to_fix:
        print(f"Fixing foreign keys for {table}...")
        try:
            inspector = inspect(engine)
            fks = inspector.get_foreign_keys(table)
            for fk in fks:
                if "team_id" in fk["constrained_columns"]:
                    fk_name = fk["name"]
                    run_sql(f"ALTER TABLE {table} DROP CONSTRAINT {fk_name};")
            
            # Add new constraint pointing to academy_teams
            run_sql(f"ALTER TABLE {table} ADD CONSTRAINT {table}_team_id_fkey FOREIGN KEY (team_id) REFERENCES academy_teams(id) ON DELETE CASCADE;")
        except Exception as e:
            print(f"Error checking {table}: {e}")

    print("\nMigration finished successfully!")

if __name__ == "__main__":
    migrate()
