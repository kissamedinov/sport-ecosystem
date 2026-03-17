import sys
import os
from sqlalchemy import create_engine, text, inspect
from dotenv import load_dotenv

# Add the current directory to sys.path to import app modules
sys.path.append(os.getcwd())

from app.database import SQLALCHEMY_DATABASE_URL

def fix_schema():
    engine = create_engine(SQLALCHEMY_DATABASE_URL)
    inspector = inspect(engine)
    
    with engine.connect() as conn:
        # 1. Check 'users' table columns
        users_columns = [c['name'] for c in inspector.get_columns('users')]
        print(f"Current columns in 'users': {users_columns}")
        
        if 'academy_id' not in users_columns:
            print("Adding 'academy_id' to 'users' table...")
            try:
                conn.execute(text("ALTER TABLE users ADD COLUMN academy_id UUID REFERENCES football_academies(id)"))
                conn.commit()
                print("Successfully added academy_id.")
            except Exception as e:
                print(f"Error adding academy_id: {e}")
        else:
            print("academy_id already exists in users table.")

        # 2. Check for other potential missing columns
        if 'phone' not in users_columns:
            print("Adding 'phone' to 'users' table...")
            try:
                conn.execute(text("ALTER TABLE users ADD COLUMN phone VARCHAR"))
                conn.commit()
                print("Successfully added phone.")
            except Exception as e:
                print(f"Error adding phone: {e}")

        # 3. Verify 'football_academies' table
        tables = inspector.get_table_names()
        if 'football_academies' not in tables:
            print("WARNING: 'football_academies' table is missing! This might cause foreign key errors.")
        else:
            print("'football_academies' table exists.")

    print("Schema fix process completed.")

if __name__ == "__main__":
    load_dotenv()
    fix_schema()
