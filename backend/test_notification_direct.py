
import sys
import os
import uuid
sys.path.append(os.getcwd())
from app.database import SessionLocal
from app.notifications.service import create_notification
from app.notifications.models import NotificationType, EntityType

db = SessionLocal()
try:
    # Find a user ID
    from sqlalchemy import text
    u_id = db.execute(text("SELECT id FROM users LIMIT 1")).scalar()
    if not u_id:
        print("No users in DB")
        sys.exit(1)
        
    print(f"Testing direct notification for user: {u_id}")
    n = create_notification(
        db,
        user_ids=[u_id],
        type=NotificationType.TEAM_INVITE,
        title="Direct Test",
        message="Direct test message",
        entity_type=EntityType.ACADEMY,
        entity_id=uuid.uuid4()
    )
    print(f"Success! Notification created with ID: {n.id}")
    
except Exception as e:
    print(f"Failed direct test: {e}")
    import traceback; traceback.print_exc()
finally:
    db.close()
