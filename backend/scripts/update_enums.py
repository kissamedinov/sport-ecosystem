import sys
import os
sys.path.append(os.path.dirname(os.path.dirname(os.path.abspath(__file__))))

from sqlalchemy import text
from app.database import engine

def update_enums():
    new_roles = [
        "ADMIN", "TOURNAMENT_MANAGER", "REFEREE", "COACH", 
        "PLAYER_ADULT", "PLAYER_CHILD", "PARENT", "FIELD_OWNER", "SCOUT"
    ]
    
    with engine.connect() as conn:
        # Check current values if possible, but ALTER TYPE ... ADD VALUE IF NOT EXISTS is safer in newer PG
        # For older PG, we might need to handle errors.
        for role in new_roles:
            try:
                # PostgreSQL doesn't support IF NOT EXISTS for ADD VALUE easily in transactions, 
                # so we do it one by one and catch the "already exists" error.
                conn.execute(text(f"ALTER TYPE role ADD VALUE '{role}'"))
                print(f"Added {role} to enum role")
            except Exception as e:
                # psycopg2.errors.DuplicateObject: enum value "..." already exists
                print(f"Skip {role}: {e}")
        conn.commit()

if __name__ == "__main__":
    update_enums()
