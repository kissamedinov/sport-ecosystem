
import sys
import os
sys.path.append(os.getcwd())
from sqlalchemy import create_engine, text
from app.database import SQLALCHEMY_DATABASE_URL
engine = create_engine(SQLALCHEMY_DATABASE_URL)

with engine.connect() as conn:
    print("\n--- CLUBS ---")
    res = conn.execute(text("SELECT id, name, owner_id FROM clubs"))
    for row in res:
        print(row)
        
    print("\n--- USERS ---")
    res = conn.execute(text("SELECT id, email, name FROM users"))
    for row in res:
        print(row)

    print("\n--- ALL INVITATIONS ---")
    res = conn.execute(text("SELECT id, club_id, invited_user_id, invited_by, role, status, is_approved FROM invitations"))
    for row in res:
        print(row)
        
    print("\n--- ALL NOTIFICATIONS ---")
    res = conn.execute(text("SELECT id, type, title, message FROM notifications"))
    for row in res:
        print(row)

    print("\n--- NOTIFICATION TARGETS ---")
    res = conn.execute(text("SELECT * FROM notification_targets"))
    for row in res:
        print(row)
