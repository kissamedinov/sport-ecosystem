from app.database import SessionLocal
from sqlalchemy import text

db = SessionLocal()

# Notification IDs from the logs
notif_ids = [
    '795b99f7-72e1-4d83-bc04-f933b173ad84',
    'f44fbe59-e1e1-4d1e-87e3-ca703a2bc56a',
    'eaa6fda1-746e-4bc5-a0b0-ab5857d68d22',
    'e87e4364-06fb-4b41-a2c5-1c0ff89269f0',
    'c2c4e394-0f14-4fe7-b78a-e137625b1b96',
    '3822a1da-4a1f-458d-8e49-627e3cefc9ca',
    '445dcb78-19bc-41cf-981c-3d52a012d871'
]

print("Fetching notification details from DB:")
for n_id in notif_ids:
    row = db.execute(
        text("SELECT id, title, message, created_at FROM notifications WHERE id = :nid"),
        {"nid": n_id}
    ).first()
    if row:
        print(f"ID: {row[0]}\n  Title: {row[1]}\n  Message: {row[2]}\n  Time: {row[3]}\n")
    else:
        print(f"Notification {n_id} not found in DB")
        
db.close()
