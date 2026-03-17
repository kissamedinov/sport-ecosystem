
import uuid
from sqlalchemy import create_engine
from sqlalchemy.orm import sessionmaker
from app.database import SQLALCHEMY_DATABASE_URL
from app.clubs.models import Invitation
from app.notifications.models import Notification, NotificationTarget
from app.users.models import User

engine = create_engine(SQLALCHEMY_DATABASE_URL)
SessionLocal = sessionmaker(autocommit=False, autoflush=False, bind=engine)
db = SessionLocal()

print("--- RECENT INVITATIONS ---")
invites = db.query(Invitation).order_by(Invitation.created_at.desc()).limit(5).all()
for i in invites:
    print(f"ID: {i.id}, Invited: {i.invited_user_id}, By: {i.invited_by}, Status: {i.status}, Approved: {i.is_approved}")

print("\n--- RECENT NOTIFICATIONS ---")
notifications = db.query(Notification).order_by(Notification.created_at.desc()).limit(5).all()
for n in notifications:
    print(f"ID: {n.id}, Type: {n.type}, Title: {n.title}")
    targets = db.query(NotificationTarget).filter(NotificationTarget.notification_id == n.id).all()
    for t in targets:
        print(f"  Target User: {t.user_id}, Read: {t.is_read}")

db.close()
