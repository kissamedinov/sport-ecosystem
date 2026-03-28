from sqlalchemy import text
from app.database import engine

def migrate():
    with engine.connect() as conn:
        print("Checking/Adding columns to users table...")
        try:
            # PostgreSQL syntax to add column if not exists is tricky without procedural code, 
            # so we use a simple try/except block.
            conn.execute(text("ALTER TABLE users ADD COLUMN onboarding_completed BOOLEAN DEFAULT FALSE"))
            conn.commit()
            print("Added onboarding_completed to users")
        except Exception as e:
            print(f"Users table update failed (onboarding_completed): {e}")
            conn.rollback()

        print("Checking/Adding columns to clubs table...")
        try:
            conn.execute(text("ALTER TABLE clubs ADD COLUMN address VARCHAR"))
            conn.commit()
            print("Added address to clubs")
        except Exception as e:
            print(f"Clubs address update failed: {e}")
            conn.rollback()

        try:
            conn.execute(text("ALTER TABLE clubs ADD COLUMN training_schedule VARCHAR"))
            conn.commit()
            print("Added training_schedule to clubs")
        except Exception as e:
            print(f"Clubs schedule update failed: {e}")
            conn.rollback()

if __name__ == "__main__":
    migrate()
