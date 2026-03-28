from sqlalchemy import create_engine, text
import os
from dotenv import load_dotenv

load_dotenv()
SQLALCHEMY_DATABASE_URL = os.getenv("DATABASE_URL", "postgresql://postgres:postgres@localhost/sportseco")
engine = create_engine(SQLALCHEMY_DATABASE_URL)

def inspect_table():
    with engine.connect() as conn:
        print("\n--- team_memberships columns ---")
        result = conn.execute(text("SELECT column_name, data_type, is_nullable FROM information_schema.columns WHERE table_name = 'team_memberships'"))
        for row in result:
            print(row)

if __name__ == "__main__":
    inspect_table()
