import os
import subprocess
import time
from sqlalchemy import create_engine, text
from dotenv import load_dotenv

# Load environment variables
load_dotenv()

DATABASE_URL = os.getenv("DATABASE_URL")
if DATABASE_URL and DATABASE_URL.startswith("postgres://"):
    DATABASE_URL = DATABASE_URL.replace("postgres://", "postgresql://", 1)

def reset_server():
    print("--- [1/3] Terminating hung PostgreSQL sessions ---")
    try:
        engine = create_engine(DATABASE_URL)
        with engine.connect() as conn:
            # Kill all sessions except our own
            conn.execute(text("""
                SELECT pg_terminate_backend(pid) 
                FROM pg_stat_activity 
                WHERE datname = current_database() 
                AND pid <> pg_backend_pid();
            """))
            conn.execute(text("COMMIT;"))
        print("Done.")
    except Exception as e:
        print(f"Error resetting DB sessions: {e}")

    print("\n--- [2/3] Cleaning up Python/Gunicorn processes ---")
    try:
        # Kill gunicorn workers
        subprocess.run(["pkill", "-f", "gunicorn"], check=False)
        # Kill uvicorn workers
        subprocess.run(["pkill", "-f", "uvicorn"], check=False)
        print("Done.")
    except Exception as e:
        print(f"Error killing processes: {e}")

    print("\n--- [3/3] Restarting systemd service ---")
    try:
        subprocess.run(["sudo", "systemctl", "restart", "orleon-backend"], check=True)
        print("Service restarted successfully.")
    except Exception as e:
        print(f"Error restarting service: {e}")

    print("\n--- Verification ---")
    time.sleep(2)
    status = subprocess.run(["systemctl", "status", "orleon-backend"], capture_output=True, text=True)
    print(status.stdout)

if __name__ == "__main__":
    reset_server()
