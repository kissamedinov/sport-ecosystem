import sys
import os
import random
import string
from sqlalchemy import create_engine, text

# Add the backend directory to sys.path
sys.path.append(os.path.join(os.getcwd(), 'backend'))

def get_db_url():
    if os.path.exists('.env'):
        with open('.env', 'r') as f:
            for line in f:
                if line.startswith('DATABASE_URL='):
                    return line.split('=', 1)[1].strip()
    return "postgresql://sportuser:sportpassword123@localhost:5432/sportseco"

SQLALCHEMY_DATABASE_URL = get_db_url()
engine = create_engine(SQLALCHEMY_DATABASE_URL)

def generate_code(length=5):
    chars = string.ascii_uppercase + string.digits
    return ''.join(random.choice(chars) for _ in range(length))

def migrate_and_populate():
    with engine.connect() as conn:
        print(f"Connecting to DB...")
        
        # 1. Check current status
        total = conn.execute(text("SELECT count(*) FROM users")).scalar()
        with_code = conn.execute(text("SELECT count(*) FROM users WHERE unique_code IS NOT NULL AND unique_code != ''")).scalar()
        print(f"Total users: {total}, Users with IDs: {with_code}")

        # 2. Add column if missing (safety check)
        check_col = conn.execute(text("SELECT column_name FROM information_schema.columns WHERE table_name='users' AND column_name='unique_code';")).fetchone()
        if not check_col:
            print("Adding unique_code column...")
            conn.execute(text("ALTER TABLE users ADD COLUMN unique_code VARCHAR;"))
            conn.execute(text("CREATE UNIQUE INDEX ix_users_unique_code ON users (unique_code);"))
            conn.commit()

        # 3. Force update users who have NULL or empty unique_code
        users_to_update = conn.execute(text("SELECT id, email FROM users WHERE unique_code IS NULL OR unique_code = '';")).fetchall()
        print(f"Found {len(users_to_update)} users to update.")

        for user_id, email in users_to_update:
            code = f"ID-{generate_code()}"
            while conn.execute(text("SELECT 1 FROM users WHERE unique_code = :c"), {"c": code}).fetchone():
                code = f"ID-{generate_code()}"
            
            conn.execute(
                text("UPDATE users SET unique_code = :c WHERE id = :id"),
                {"c": code, "id": user_id}
            )
            print(f"Assigned {code} to {email}")
        
        conn.commit()
        print("Done!")

if __name__ == "__main__":
    migrate_and_populate()
