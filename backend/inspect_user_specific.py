
import sys
import os
import uuid
sys.path.append(os.getcwd())
from sqlalchemy import create_engine, text
from app.database import SQLALCHEMY_DATABASE_URL
engine = create_engine(SQLALCHEMY_DATABASE_URL)

target_user_id = 'a12d4818-c655-4f46-80a7-557ad409ba71'

with engine.connect() as conn:
    print(f"--- DB CHECK FOR USER {target_user_id} ---")
    
    # Invitations
    res = conn.execute(text("SELECT count(*) FROM invitations WHERE invited_user_id = :uid"), {"uid": target_user_id})
    print(f"Invitations Count: {res.scalar()}")
    
    # Notifications for this user
    res = conn.execute(text("""
        SELECT n.id, n.type, n.title, nt.is_read, n.created_at 
        FROM notifications n
        JOIN notification_targets nt ON n.id = nt.notification_id
        WHERE nt.user_id = :uid
        ORDER BY n.created_at DESC
    """), {"uid": target_user_id})
    rows = res.fetchall()
    print(f"Notifications Count: {len(rows)}")
    for r in rows:
        print(r)
        
    # All Notifications count
    res = conn.execute(text("SELECT count(*) FROM notifications"))
    print(f"Total Notifications in DB: {res.scalar()}")
    
    # All Targets count
    res = conn.execute(text("SELECT count(*) FROM notification_targets"))
    print(f"Total Notification Targets in DB: {res.scalar()}")
