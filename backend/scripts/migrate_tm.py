from sqlalchemy import create_engine, text
import os
from dotenv import load_dotenv

load_dotenv()
SQLALCHEMY_DATABASE_URL = os.getenv("DATABASE_URL", "postgresql://postgres:postgres@localhost/sportseco")
engine = create_engine(SQLALCHEMY_DATABASE_URL)

def migrate():
    with engine.connect() as conn:
        print("Adding player_id to team_memberships...")
        try:
            conn.execute(text("ALTER TABLE team_memberships ADD COLUMN player_id UUID REFERENCES users(id)"))
            conn.commit()
            print("Successfully added player_id column.")
        except Exception as e:
            if "already exists" in str(e):
                print("Column player_id already exists.")
            else:
                print(f"Error: {e}")

if __name__ == "__main__":
    migrate()
