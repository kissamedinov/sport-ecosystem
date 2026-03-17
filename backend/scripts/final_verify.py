import sys
import os
from sqlalchemy import create_engine
from dotenv import load_dotenv

# Add current directory to path
sys.path.append(os.getcwd())

def verify_init():
    try:
        from app.database import engine
        from app.tournaments.models import Tournament
        from app.matches.models import Match
        
        print("Models imported and connected successfully.")
        
        # Test a simple query to ensure columns exist
        with engine.connect() as conn:
            from sqlalchemy import text
            conn.execute(text("SELECT id FROM tournaments LIMIT 1"))
            conn.execute(text("SELECT num_fields FROM tournaments LIMIT 1"))
            print("Database query successful.")
            
    except Exception as e:
        print(f"Verification failed: {e}")
        import traceback
        traceback.print_exc()
        sys.exit(1)

if __name__ == "__main__":
    load_dotenv()
    verify_init()
