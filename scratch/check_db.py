import sys
import os

# Add backend directory to sys.path
backend_dir = "/root/sport-ecosystem/backend"
sys.path.append(backend_dir)

from sqlalchemy import text
from app.database import SessionLocal, SQLALCHEMY_DATABASE_URL

print(f"DATABASE URL: {SQLALCHEMY_DATABASE_URL}")

db = SessionLocal()
try:
    # Query postgres enum labels for 'matchstatus'
    sql = """
    SELECT enumlabel 
    FROM pg_enum 
    JOIN pg_type ON pg_enum.enumtypid = pg_type.oid 
    WHERE pg_type.typname = 'matchstatus';
    """
    result = db.execute(text(sql)).fetchall()
    print("Enum values found:")
    for r in result:
        print(f"  - {r[0]}")
        
    # Check if there are other enum types containing status
    sql_types = """
    SELECT typname FROM pg_type WHERE typtype = 'e';
    """
    types_res = db.execute(text(sql_types)).fetchall()
    print("All Enum types in DB:")
    for t in types_res:
        print(f"  * {t[0]}")
        
except Exception as e:
    print(f"Error querying database: {e}")
finally:
    db.close()
