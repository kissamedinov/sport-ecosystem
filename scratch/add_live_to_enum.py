import sys
import os

# Add backend directory to sys.path
backend_dir = "/root/sport-ecosystem/backend"
sys.path.append(backend_dir)

from sqlalchemy import text
from app.database import SessionLocal

db = SessionLocal()
try:
    # ALTER TYPE ... ADD VALUE cannot run in a transaction block in some postgres versions
    # so we commit/autocommit or handle it carefully.
    connection = db.connection()
    # In psycopg2/SQLAlchemy, we can execute it directly on the raw connection or autocommit connection
    raw_conn = connection.connection
    raw_conn.autocommit = True
    cursor = raw_conn.cursor()
    cursor.execute("ALTER TYPE matchstatus ADD VALUE 'LIVE';")
    print("Enum type matchstatus altered successfully to include 'LIVE'.")
except Exception as e:
    print(f"Error altering enum: {e}")
finally:
    db.close()
