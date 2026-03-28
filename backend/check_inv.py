import psycopg2

def check_after_action():
    conn = psycopg2.connect('postgresql://postgres:postgres@localhost:5432/sportseco')
    cur = conn.cursor()
    
    child_id = '3d4ad526-10e0-4e7d-8223-5997f99141fc'
    
    print(f"--- Invitations for child {child_id} ---")
    cur.execute(f"SELECT id, status::text, is_approved FROM invitations WHERE invited_user_id = '{child_id}'")
    invites = cur.fetchall()
    for row in invites:
        print(row)
        inv_id = row[0]
        cur.execute(f"SELECT id, type, entity_id FROM notifications WHERE entity_id = '{inv_id}'")
        notifs = cur.fetchall()
        print(f"  Notifications: {notifs}")
        for n in notifs:
            n_id = n[0]
            cur.execute(f"SELECT is_read, user_id FROM notification_targets WHERE notification_id = '{n_id}'")
            print(f"    Targets: {cur.fetchall()}")

    print(f"\n--- Memberships for child {child_id} ---")
    cur.execute(f"SELECT club_id, role::text, status::text FROM club_staff WHERE user_id = '{child_id}'")
    print(f"  ClubStaff: {cur.fetchall()}")
    
    cur.close()
    conn.close()

if __name__ == "__main__":
    check_after_action()
