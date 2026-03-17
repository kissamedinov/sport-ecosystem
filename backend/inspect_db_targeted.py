
import sys
import os
sys.path.append(os.getcwd())
from sqlalchemy import create_engine, text
from app.database import SQLALCHEMY_DATABASE_URL
engine = create_engine(SQLALCHEMY_DATABASE_URL)

with engine.connect() as conn:
    print("\nCounts:")
    print("Invitations:", conn.execute(text("SELECT count(*) FROM invitations")).scalar())
    print("Notifications:", conn.execute(text("SELECT count(*) FROM notifications")).scalar())
    print("Targets:", conn.execute(text("SELECT count(*) FROM notification_targets")).scalar())
    
    print("\nLast 3 Invitations:")
    res = conn.execute(text("SELECT id, invited_user_id, status, created_at FROM invitations ORDER BY created_at DESC LIMIT 3"))
    for row in res:
        print(row)
        
    print("\nLast 3 Notifications with Targets:")
    res = conn.execute(text("""
        SELECT n.id, n.type, n.title, t.user_id, t.is_read 
        FROM notifications n 
        JOIN notification_targets t ON n.id = t.notification_id 
        ORDER BY n.created_at DESC LIMIT 5
    """))
    for row in res:
        print(row)
