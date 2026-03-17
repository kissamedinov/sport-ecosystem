import sys
import os
sys.path.append(os.path.dirname(os.path.dirname(os.path.abspath(__file__))))

from sqlalchemy import text
from app.database import engine

def debug_enum():
    with engine.connect() as conn:
        result = conn.execute(text("SELECT enumlabel FROM pg_enum JOIN pg_type ON pg_enum.enumtypid = pg_type.oid WHERE pg_type.typname = 'role'"))
        labels = [row[0] for row in result]
        print(f"Current role enum labels: {labels}")

def update_enums_safe():
    new_roles = [
        "ADMIN", "TOURNAMENT_MANAGER", "REFEREE", "COACH", 
        "PLAYER_ADULT", "PLAYER_CHILD", "PARENT", "FIELD_OWNER", "SCOUT"
    ]
    
    # Use execution_options(isolation_level="AUTOCOMMIT") to avoid transaction blocks
    with engine.connect().execution_options(isolation_level="AUTOCOMMIT") as conn:
        for role in new_roles:
            try:
                conn.execute(text(f"ALTER TYPE role ADD VALUE '{role}'"))
                print(f"Added {role} to enum role")
            except Exception as e:
                print(f"Skip {role}: values already exists or error {e}")

if __name__ == "__main__":
    debug_enum()
    update_enums_safe()
    debug_enum()
