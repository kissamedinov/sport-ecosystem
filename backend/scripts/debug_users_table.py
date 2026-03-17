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
    
    print("Listing all tables...")
    tables = inspector.get_table_names()
    print(f"Tables: {tables}")
    
    if 'users' in tables:
        print("\nColumns in 'users' table:")
        columns = inspector.get_columns('users')
        for column in columns:
            print(f"- {column['name']}: {column['type']}")
    else:
        print("\n'users' table NOT FOUND!")

    if 'football_academies' in tables:
        print("\n'football_academies' table found.")
    else:
        print("\n'football_academies' table NOT FOUND!")

if __name__ == "__main__":
    load_dotenv()
    check_users_table()
