
import sys
import os
import uuid
sys.path.append(os.getcwd())
from sqlalchemy import text
from app.database import engine

with engine.connect() as conn:
    # Find a user
    u_res = conn.execute(text("SELECT id FROM users LIMIT 1")).fetchone()
    if not u_res:
        print("No users found!")
        sys.exit(1)
    u_id = u_res[0]
    print(f"Target User: {u_id}")
    
    n_id = uuid.uuid4()
    t_id = uuid.uuid4()
    
    # Use explicit transaction
    trans = conn.begin()
    try:
        conn.execute(text("""
            INSERT INTO notifications (id, type, title, message, created_at) 
            VALUES (:id, 'TEAM_INVITE', 'Manual Test', 'Manual test message', now())
        """), {"id": n_id})
        
        conn.execute(text("""
            INSERT INTO notification_targets (id, notification_id, user_id, is_read) 
            VALUES (:tid, :nid, :uid, false)
        """), {"tid": t_id, "nid": n_id, "uid": u_id})
        
        trans.commit()
        print(f"Success! Inserted notification for user {u_id}")
    except Exception as e:
        trans.rollback()
        print(f"Error: {e}")
