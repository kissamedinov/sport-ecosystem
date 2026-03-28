import psycopg2
import sys
import os

# Add current directory to path
sys.path.append(os.getcwd())

from app.database import engine, Base
from app.notifications import models as notif_models

# Import other models so FKs can resolve if needed
from app.users import models as user_models

def force_reset():
    db_url = 'postgresql://postgres:postgres@localhost:5432/sportseco'
    conn = psycopg2.connect(db_url)
    conn.autocommit = True
    cur = conn.cursor()
    
    # 1. Drop tables with CASCADE
    print("Dropping notification_targets...")
    cur.execute("DROP TABLE IF EXISTS notification_targets CASCADE")
    print("Dropping notifications...")
    cur.execute("DROP TABLE IF EXISTS notifications CASCADE")
    
    # 2. Recreate specifically these tables
    print("Recreating tables via SQLAlchemy...")
    try:
        notif_models.Notification.__table__.create(engine)
        print("Created notifications")
        notif_models.NotificationTarget.__table__.create(engine)
        print("Created notification_targets")
    except Exception as e:
        print(f"Error during creation: {e}")
    
    # 3. Verify
    print("Verifying...")
    cur.execute("SELECT table_name FROM information_schema.tables WHERE table_name IN ('notifications', 'notification_targets')")
    tables = [t[0] for t in cur.fetchall()]
    print(f"Existing tables: {tables}")
    
    cur.close()
    conn.close()

if __name__ == "__main__":
    force_reset()
