from app.database import SessionLocal
from sqlalchemy import text

db = SessionLocal()

row = db.execute(text("SELECT * FROM notifications LIMIT 1")).first()
if row:
    print("Notification row columns:")
    keys = db.execute(text("SELECT * FROM notifications LIMIT 1")).keys()
    for k in keys:
        print(f"  {k}")
else:
    print("No notifications found")
db.close()
