from sqlalchemy import create_engine, text
import os

def get_db_url():
    if os.path.exists('.env'):
        with open('.env', 'r') as f:
            for line in f:
                if line.startswith('DATABASE_URL='):
                    return line.split('=', 1)[1].strip()
    return "postgresql://sportuser:sportpassword123@localhost:5432/sportseco"

SQLALCHEMY_DATABASE_URL = get_db_url()
engine = create_engine(SQLALCHEMY_DATABASE_URL)

def fix_nullable():
    with engine.connect() as conn:
        print("Applying SQL: ALTER TABLE teams ALTER COLUMN coach_id DROP NOT NULL;")
        try:
            conn.execute(text("ALTER TABLE teams ALTER COLUMN coach_id DROP NOT NULL;"))
            conn.commit()
            print("Successfully updated 'teams' table.")
        except Exception as e:
            print(f"Error (maybe already updated?): {e}")
            conn.rollback()

if __name__ == "__main__":
    fix_nullable()
