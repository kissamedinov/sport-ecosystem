from app.database import engine
import sqlalchemy as sa

def add_missing_columns_raw():
    print("Attempting to add missing columns using raw SQL...")
    columns_to_add = [
        ("num_fields", "INTEGER DEFAULT 1"),
        ("match_half_duration", "INTEGER DEFAULT 20"),
        ("halftime_break_duration", "INTEGER DEFAULT 5"),
        ("break_between_matches", "INTEGER DEFAULT 10"),
        ("start_time", "TIMESTAMP WITHOUT TIME ZONE"),
        ("end_time", "TIMESTAMP WITHOUT TIME ZONE"),
        ("minimum_rest_slots", "INTEGER DEFAULT 1"),
        ("points_for_win", "INTEGER DEFAULT 3"),
        ("points_for_draw", "INTEGER DEFAULT 1"),
        ("points_for_loss", "INTEGER DEFAULT 0"),
        ("status", "VARCHAR DEFAULT 'upcoming'")
    ]
    
    with engine.connect() as conn:
        # PostgreSQL supports ADD COLUMN IF NOT EXISTS in newer versions (9.6+)
        # If the version is too old, we wrap in try-except
        for col_name, col_type in columns_to_add:
            try:
                print(f"Trying to add column: {col_name}")
                conn.execute(sa.text(f'ALTER TABLE "tournaments" ADD COLUMN IF NOT EXISTS "{col_name}" {col_type}'))
                print(f"Successfully ensured column: {col_name}")
                conn.commit()
            except Exception as e:
                # If IF NOT EXISTS is not supported, this might fail differently if it already exists
                print(f"Note for column {col_name}: {e}")
                # We don't want to stop here, just keep going
                continue
    print("Migration attempt finished.")

if __name__ == "__main__":
    add_missing_columns_raw()
