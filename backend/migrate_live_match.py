import sqlite3
import os

db_path = os.path.join(os.path.dirname(__file__), "sport_ecosystem.db")
if not os.path.exists(db_path):
    print("DB not found at", db_path)
    exit(0)

conn = sqlite3.connect(db_path)
cursor = conn.cursor()

cursor.execute("PRAGMA table_info(matches)")
columns = [row[1] for row in cursor.fetchall()]

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
conn.close()
print("Migration completed successfully!")
