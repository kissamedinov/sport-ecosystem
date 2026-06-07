import uuid
import os
from sqlalchemy import create_engine, text
from sqlalchemy.orm import sessionmaker
from dotenv import load_dotenv

# Load environment variables
load_dotenv()

SQLALCHEMY_DATABASE_URL = os.getenv("DATABASE_URL", "postgresql://postgres:postgres@localhost:5432/sportseco")
print(f"Connecting to database: {SQLALCHEMY_DATABASE_URL}")

engine = create_engine(SQLALCHEMY_DATABASE_URL)
SessionLocal = sessionmaker(autocommit=False, autoflush=False, bind=engine)
db = SessionLocal()

try:
    # 1. Backfill player_id in team_memberships using player_profiles.user_id
    query_player_id = text("""
        UPDATE team_memberships tm
        SET player_id = pp.user_id
        FROM player_profiles pp
        WHERE tm.player_profile_id = pp.id
          AND tm.player_id IS NULL
          AND pp.user_id IS NOT NULL;
    """)
    result_player_id = db.execute(query_player_id)
    print(f"Backfilled player_id for {result_player_id.rowcount} team memberships.")

    # 2. Backfill child_profile_id in team_memberships using child_profiles where linked_user_id matches player_id
    query_child_id = text("""
        UPDATE team_memberships tm
        SET child_profile_id = cp.id
        FROM child_profiles cp
        WHERE tm.player_id = cp.linked_user_id
          AND tm.child_profile_id IS NULL
          AND cp.linked_user_id IS NOT NULL;
    """)
    result_child_id = db.execute(query_child_id)
    print(f"Backfilled child_profile_id for {result_child_id.rowcount} team memberships.")

    # 3. Commit the changes
    db.commit()
    print("Database updates committed successfully.")

except Exception as e:
    db.rollback()
    print(f"An error occurred: {e}")
finally:
    db.close()
