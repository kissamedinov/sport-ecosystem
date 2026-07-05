from app.database import SessionLocal
from sqlalchemy import text

db = SessionLocal()

try:
    print("Adding penalty columns to matches and match_results tables...")
    db.execute(text("ALTER TABLE matches ADD COLUMN IF NOT EXISTS home_penalty_score INTEGER;"))
    db.execute(text("ALTER TABLE matches ADD COLUMN IF NOT EXISTS away_penalty_score INTEGER;"))
    db.execute(text("ALTER TABLE match_results ADD COLUMN IF NOT EXISTS home_penalty_score INTEGER;"))
    db.execute(text("ALTER TABLE match_results ADD COLUMN IF NOT EXISTS away_penalty_score INTEGER;"))
    db.commit()
    print("Successfully added penalty columns!")
except Exception as e:
    db.rollback()
    print(f"Error: {e}")
finally:
    db.close()
