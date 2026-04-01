import os
from sqlalchemy import create_engine, text
from dotenv import load_dotenv

# Load environment variables
load_dotenv()

# Get database URL
DATABASE_URL = os.getenv("DATABASE_URL", "postgresql://postgres:postgres@localhost/sportseco")

def fix_database():
    print(f"Connecting to database: {DATABASE_URL}")
    engine = create_engine(DATABASE_URL)
    
    with engine.connect() as connection:
        # Add 'bio' column
        try:
            print("Adding 'bio' column to 'users' table...")
            connection.execute(text("ALTER TABLE users ADD COLUMN IF NOT EXISTS bio VARCHAR;"))
            print("Successfully added 'bio' column.")
        except Exception as e:
            print(f"Error adding 'bio' column: {e}")
            
        # Add 'avatar_url' column
        try:
            print("Adding 'avatar_url' column to 'users' table...")
            connection.execute(text("ALTER TABLE users ADD COLUMN IF NOT EXISTS avatar_url VARCHAR;"))
            print("Successfully added 'avatar_url' column.")
        except Exception as e:
            print(f"Error adding 'avatar_url' column: {e}")
            
        connection.commit()
    
    print("Database migration completed.")

if __name__ == "__main__":
    fix_database()
