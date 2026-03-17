import sys
import os
sys.path.append(os.path.dirname(os.path.dirname(os.path.abspath(__file__))))

from sqlalchemy import text
from app.database import engine
from app.users.models import Role

def update_role_enum():
    print("Checking and updating 'role' enum in database...")
    
    # Get all roles from the model
    all_roles = [r.value for r in Role]
    print(f"Roles in model: {all_roles}")
    
    with engine.connect().execution_options(isolation_level="AUTOCOMMIT") as conn:
        # Check current values in DB
        result = conn.execute(text("SELECT enumlabel FROM pg_enum JOIN pg_type ON pg_enum.enumtypid = pg_type.oid WHERE pg_type.typname = 'role'"))
        db_roles = [row[0] for row in result]
        print(f"Current roles in DB: {db_roles}")
        
        # Add missing roles
        for role in all_roles:
            if role not in db_roles:
                try:
                    conn.execute(text(f"ALTER TYPE role ADD VALUE '{role}'"))
                    print(f"Successfully added {role} to enum role")
                except Exception as e:
                    print(f"Failed to add {role}: {e}")
            else:
                print(f"Role {role} already exists in DB")

if __name__ == "__main__":
    try:
        update_role_enum()
        print("\nInfrastructure update completed successfully.")
    except Exception as e:
        print(f"\nAn error occurred during update: {e}")
        sys.exit(1)
