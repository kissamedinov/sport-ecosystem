from app.database import engine
import sqlalchemy as sa

def add_missing_columns():
    print("Checking for missing columns in 'tournaments' table...")
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
    
    inspector = sa.inspect(engine)
    existing_columns = [c['name'] for c in inspector.get_columns('tournaments')]
    
    with engine.connect() as conn:
        trans = conn.begin()
        try:
            for col_name, col_type in columns_to_add:
                if col_name not in existing_columns:
                    print(f"Adding column: {col_name}")
                    conn.execute(sa.text(f'ALTER TABLE "tournaments" ADD COLUMN "{col_name}" {col_type}'))
                else:
                    print(f"Column {col_name} already exists.")
            trans.commit()
            print("Database schema successfully updated!")
        except Exception as e:
            trans.rollback()
            print(f"Error updating schema: {e}")

if __name__ == "__main__":
    add_missing_columns()
