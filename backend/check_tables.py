import sqlite3
import os

db_path = os.path.join(os.path.dirname(__file__), "sport_ecosystem.db")
conn = sqlite3.connect(db_path)
cursor = conn.cursor()

cursor.execute("SELECT name FROM sqlite_master WHERE type='table';")
tables = [t[0] for t in cursor.fetchall()]
print("Existing tables:", tables)

if "matches" in tables:
    cursor.execute("PRAGMA table_info(matches)")
    columns = [row[1] for row in cursor.fetchall()]
    print("Matches columns:", columns)
    
    new_cols = [
        ("home_score", "INTEGER DEFAULT 0"),
        ("away_score", "INTEGER DEFAULT 0"),
        ("elapsed_seconds", "INTEGER DEFAULT 0"),
        ("is_timer_running", "BOOLEAN DEFAULT 0"),
        ("timer_updated_at", "DATETIME")
    ]

    for col_name, col_type in new_cols:
        if col_name not in columns:
            print(f"Adding column {col_name} to matches table...")
            cursor.execute(f"ALTER TABLE matches ADD COLUMN {col_name} {col_type}")

    conn.commit()
    print("Migration done!")
else:
    print("Table 'matches' does not exist yet. Running create_all...")
    from app.database import engine, Base
    import app.matches.models
    Base.metadata.create_all(bind=engine)
    print("Created all tables!")

conn.close()
