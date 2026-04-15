import os
import time
from sqlalchemy import create_engine, text
from sqlalchemy.orm import Session
from dotenv import load_dotenv
from uuid import UUID

# Load environment variables
load_dotenv()

DATABASE_URL = os.getenv("DATABASE_URL")
if DATABASE_URL and DATABASE_URL.startswith("postgres://"):
    DATABASE_URL = DATABASE_URL.replace("postgres://", "postgresql://", 1)

engine = create_engine(DATABASE_URL)

def test_performance(user_id_str):
    uid = UUID(user_id_str)
    with Session(engine) as session:
        print(f"--- Performance Test for User ID: {user_id_str} ---")
        
        # Test 1: Academy by owner_id
        start = time.time()
        res1 = session.execute(text("SELECT id FROM football_academies WHERE owner_id = :uid LIMIT 1"), {"uid": uid}).first()
        print(f"Query 1 (Academy by owner): {(time.time() - start)*1000:.2f}ms - Result: {res1}")

        # Test 2: Club by owner_id
        start = time.time()
        res2 = session.execute(text("SELECT id FROM clubs WHERE owner_id = :uid LIMIT 1"), {"uid": uid}).first()
        print(f"Query 2 (Club by owner): {(time.time() - start)*1000:.2f}ms - Result: {res2}")

        if res2:
            # Test 3: Academy by club_id
            start = time.time()
            res3 = session.execute(text("SELECT id FROM football_academies WHERE club_id = :cid LIMIT 1"), {"cid": res2.id}).first()
            print(f"Query 3 (Academy by club): {(time.time() - start)*1000:.2f}ms - Result: {res3}")

        # Test 4: Team by coach_id
        start = time.time()
        res4 = session.execute(text("SELECT id FROM teams WHERE coach_id = :uid LIMIT 1"), {"uid": uid}).first()
        print(f"Query 4 (Team by coach): {(time.time() - start)*1000:.2f}ms - Result: {res4}")

if __name__ == "__main__":
    # Using the ID from your diagnostic: fff54668-de77-41f7-8b62-2cfd73128c79
    test_performance("fff54668-de77-41f7-8b62-2cfd73128c79")
