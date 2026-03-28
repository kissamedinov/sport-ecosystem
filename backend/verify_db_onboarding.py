from sqlalchemy import text
from app.database import engine

def check():
    with engine.connect() as conn:
        print("Checking users table...")
        res = conn.execute(text("SELECT * FROM users LIMIT 1"))
        print(f"Users columns: {res.keys()}")
        
        print("Checking clubs table...")
        res = conn.execute(text("SELECT * FROM clubs LIMIT 1"))
        print(f"Clubs columns: {res.keys()}")

if __name__ == "__main__":
    check()
