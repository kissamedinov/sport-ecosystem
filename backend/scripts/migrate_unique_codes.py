import sys
import os
import random
import string
from sqlalchemy import create_engine, text

# Add the backend directory to sys.path
sys.path.append(os.path.join(os.getcwd(), 'backend'))

# Database connection
SQLALCHEMY_DATABASE_URL = "postgresql://postgres:postgres@localhost:5432/sportseco"
engine = create_engine(SQLALCHEMY_DATABASE_URL)

def generate_code(length=5):
    chars = string.ascii_uppercase + string.digits
    return ''.join(random.choice(chars) for _ in range(length))

def migrate_and_populate():
    with engine.connect() as conn:
        print("Migrating database: adding 'unique_code' column...")
        try:
            conn.execute(text("ALTER TABLE users ADD COLUMN unique_code VARCHAR;"))
            conn.execute(text("CREATE UNIQUE INDEX ix_users_unique_code ON users (unique_code);"))
            conn.commit()
            print("Column added successfully.")
        except Exception as e:
            print(f"Column might already exist or error occurred: {e}")
            conn.rollback()

        print("Populating unique codes for existing users...")
        users = conn.execute(text("SELECT id, email FROM users WHERE unique_code IS NULL;")).fetchall()
        
        for user_id, email in users:
            code = f"ID-{generate_code()}"
            # Ensure uniqueness in a simple way
            while conn.execute(text("SELECT 1 FROM users WHERE unique_code = :c"), {"c": code}).fetchone():
                code = f"ID-{generate_code()}"
            
            conn.execute(
                text("UPDATE users SET unique_code = :c WHERE id = :id"),
                {"c": code, "id": user_id}
            )
            print(f"Assigned {code} to {email}")
        
        conn.commit()
        print("Migration and population complete.")

if __name__ == "__main__":
    migrate_and_populate()
