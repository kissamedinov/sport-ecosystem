from app.database import engine
from sqlalchemy import text

def debug_state():
    with engine.connect() as conn:
        # 1. Relations
        print("--- Parent-Child Relations ---")
        res = conn.execute(text("SELECT parent_id, child_id, status FROM parent_child_relations"))
        for row in res:
            print(f"Parent: {row[0]} -> Child: {row[1]} [Status: {row[2]}]")

        # 2. Invitations
        print("\n--- Invitations ---")
        res = conn.execute(text("SELECT invited_user_id, status, club_id FROM invitations"))
        for row in res:
            print(f"To: {row[0]} | Status: {row[1]} | Club: {row[2]}")

        # 3. Notifications and Targets
        print("\n--- Recent Notifications ---")
        res = conn.execute(text("SELECT id, type, title, created_at FROM notifications ORDER BY created_at DESC LIMIT 10"))
        for row in res:
            notif_id = row[0]
            targets = conn.execute(text(f"SELECT user_id FROM notification_targets WHERE notification_id = '{notif_id}'"))
            target_ids = [str(t[0]) for t in targets]
            print(f"ID: {notif_id} | Type: {row[1]} | Title: {row[2]} | Targets: {target_ids}")

if __name__ == "__main__":
    debug_state()
