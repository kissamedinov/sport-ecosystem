
import uuid
import sys
import os

# Add current directory to path
sys.path.append(os.getcwd())

from sqlalchemy import create_engine, text
from app.database import SQLALCHEMY_DATABASE_URL

engine = create_engine(SQLALCHEMY_DATABASE_URL)

def run_query(query):
    print(f"\n--- {query} ---")
    with engine.connect() as conn:
        result = conn.execute(text(query))
        rows = result.fetchall()
        for row in rows:
            print(row)

run_query("SELECT id, invited_user_id, status FROM invitations ORDER BY created_at DESC LIMIT 5")
run_query("SELECT id, type, title FROM notifications ORDER BY created_at DESC LIMIT 5")
run_query("SELECT * FROM notification_targets ORDER BY id DESC LIMIT 5")
run_query("SELECT id, email, name FROM users ORDER BY id DESC LIMIT 5")
