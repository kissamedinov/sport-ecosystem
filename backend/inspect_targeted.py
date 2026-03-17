
import sys
import os
import uuid
sys.path.append(os.getcwd())
from sqlalchemy import create_engine, text
from app.database import SQLALCHEMY_DATABASE_URL
engine = create_engine(SQLALCHEMY_DATABASE_URL)

with engine.connect() as conn:
    print("\n--- RECENT INVITATIONS ---")
    res = conn.execute(text("SELECT id, invited_user_id, role, status, is_approved, created_at FROM invitations ORDER BY created_at DESC LIMIT 5"))
    invites = res.fetchall()
    for row in invites:
        print(row)
        
    print("\n--- RECENT NOTIFICATIONS ---")
    res = conn.execute(text("SELECT id, type, title, created_at FROM notifications ORDER BY created_at DESC LIMIT 5"))
    for row in res:
        print(row)

    print("\n--- NOTIFICATION TARGETS ---")
    res = conn.execute(text("SELECT * FROM notification_targets ORDER BY id LIMIT 10"))
    for row in res:
        print(row)

    print("\n--- USERS ---")
    res = conn.execute(text("SELECT id, email, name FROM users"))
    for row in res:
        print(row)
