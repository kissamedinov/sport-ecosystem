
import uuid
import sys
import os
sys.path.append(os.getcwd())
from sqlalchemy.orm import Session
from app.database import SessionLocal
from app.notifications.service import create_notification
from app.notifications.models import NotificationType, EntityType
from app.users.models import User

db = SessionLocal()
try:
    user = db.query(User).first()
    if not user:
        print("No users found!")
    else:
        print(f"Testing notification for user: {user.id} ({user.email})")
        n = create_notification(
            db,
            user_ids=[user.id],
            type=NotificationType.MATCH_SCHEDULED,
            title="Test Notification",
            message="This is a test notification from script",
            entity_type=EntityType.MATCH,
            entity_id=uuid.uuid4()
        )
        print(f"Success! Notification ID: {n.id}")
        
        # Verify
        from app.notifications.models import Notification, NotificationTarget
        res = db.query(Notification).filter(Notification.id == n.id).first()
        print(f"Verified Notification exists: {res is not None}")
        target = db.query(NotificationTarget).filter(NotificationTarget.notification_id == n.id).first()
        print(f"Verified Target exists: {target is not None}")
        
except Exception as e:
    print(f"Error occurred: {e}")
    import traceback; traceback.print_exc()
finally:
    db.close()
