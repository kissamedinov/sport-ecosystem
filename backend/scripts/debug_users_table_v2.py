import sys
import os
from sqlalchemy import create_engine, inspect
from dotenv import load_dotenv

# Add the current directory to sys.path to import app modules
sys.path.append(os.getcwd())

from app.database import SQLALCHEMY_DATABASE_URL

def check_users_table():
    engine = create_engine(SQLALCHEMY_DATABASE_URL)
    inspector = inspect(engine)
    
    print("--- DATABASE SCHEMA CHECK ---")
    tables = inspector.get_table_names()
    print(f"Total tables: {len(tables)}")
    print(f"Tables found: {tables}")
    
    if 'users' in tables:
        print("\n[users] Table Details:")
        columns = inspector.get_columns('users')
        column_names = [c['name'] for c in columns]
        print(f"Column names: {column_names}")
        
        has_academy_id = 'academy_id' in column_names
        print(f"HAS academy_id: {has_academy_id}")
        
        for column in columns:
            print(f"  - {column['name']}: {column['type']}")
    else:
        print("\nERROR: 'users' table NOT FOUND!")

    if 'football_academies' in tables:
        print("\n[football_academies] table EXISTS.")
    else:
        print("\n[football_academies] table MISSING.")

    print("\n--- END OF CHECK ---")

if __name__ == "__main__":
    load_dotenv()
    check_users_table()
