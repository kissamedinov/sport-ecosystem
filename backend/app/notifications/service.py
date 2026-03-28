import uuid
import os
from typing import List, Optional
from sqlalchemy.orm import Session
from app.notifications.models import Notification, NotificationType, EntityType, NotificationTarget

def log_debug(msg):
    # Ensure logs directory exists
    log_dir = os.path.join(os.getcwd(), "logs")
    if not os.path.exists(log_dir):
        os.makedirs(log_dir)
        
    with open(os.path.join(log_dir, "debug_log.txt"), "a") as f:
        import datetime
        f.write(f"[{datetime.datetime.now()}] {msg}\n")

def create_notification(
    db: Session,
    user_ids: List[uuid.UUID] | uuid.UUID,
    notification_type: NotificationType,
    title: str,
    message: str,
    entity_type: Optional[EntityType] = None,
    entity_id: Optional[uuid.UUID] = None
) -> Notification:
    # Handle single UUID
    if isinstance(user_ids, uuid.UUID):
        user_ids = [user_ids]
    
    # Robust Enum handling (Python 3.11+ stringification fix)
    type_val = notification_type.value if hasattr(notification_type, 'value') else notification_type
    e_type_val = entity_type.value if entity_type and hasattr(entity_type, 'value') else entity_type

    log_debug(f"Inside create_notification: type={type_val}, user_ids={user_ids}")
    notification = Notification(
        type=type_val,
        title=title,
        message=message,
        entity_type=e_type_val,
        entity_id=entity_id
    )
    try:
        db.add(notification)
        db.flush()
        log_debug(f"Notification object flushed, ID: {notification.id}")

        for uid in user_ids:
            log_debug(f"Adding target for user: {uid}")
            target = NotificationTarget(
                notification_id=notification.id,
                user_id=uid
            )
            db.add(target)
        
        db.commit()
        log_debug(f"Notification {notification.id} committed successfully")
        db.refresh(notification)
        return notification
    except Exception as e:
        db.rollback()
        log_debug(f"ERROR in create_notification: {e}")
        import traceback
        log_debug(traceback.format_exc())
        raise e

def get_user_notifications(db: Session, user_id: uuid.UUID):
    results = db.query(Notification, NotificationTarget.is_read).join(
        NotificationTarget, Notification.id == NotificationTarget.notification_id
    ).filter(
        NotificationTarget.user_id == user_id
    ).order_by(Notification.created_at.desc()).all()
    
    notifications = []
    for notification, is_read in results:
        n_dict = {
            "id": notification.id,
            "type": notification.type,
            "title": notification.title,
            "message": notification.message,
            "entity_type": notification.entity_type,
            "entity_id": notification.entity_id,
            "is_read": is_read,
            "created_at": notification.created_at
        }
        notifications.append(n_dict)
    return notifications

def mark_as_read(db: Session, notification_id: uuid.UUID, user_id: uuid.UUID):
    target = db.query(NotificationTarget).filter(
        NotificationTarget.notification_id == notification_id,
        NotificationTarget.user_id == user_id
    ).first()
    if target:
        target.is_read = True
        import datetime
        target.read_at = datetime.datetime.now()
        db.commit()
    return target

def get_unread_count(db: Session, user_id: uuid.UUID):
    return db.query(NotificationTarget).filter(
        NotificationTarget.user_id == user_id,
        NotificationTarget.is_read == False
    ).count()

def mark_notifications_by_entity(db: Session, entity_id: uuid.UUID):
    """Marks all notifications for a specific entity as read for all targets."""
    targets = db.query(NotificationTarget).join(Notification).filter(
        Notification.entity_id == entity_id
    ).all()
    
    import datetime
    now = datetime.datetime.now()
    for t in targets:
        t.is_read = True
        t.read_at = now
    db.commit()
    return len(targets)
