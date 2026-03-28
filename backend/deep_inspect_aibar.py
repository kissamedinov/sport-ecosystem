import psycopg2

def deep_inspect_aibar():
    conn = psycopg2.connect('postgresql://postgres:postgres@localhost:5432/sportseco')
    cur = conn.cursor()
    
    aibar_id = 'a91006f6-d240-42ad-8bf6-afcf234a7523'
    
    print(f"\n--- Invitations for child Aibar {aibar_id} ---")
    cur.execute(f"SELECT id, status::text FROM invitations WHERE invited_user_id = '{aibar_id}'")
    for r in cur.fetchall():
        print(r)
        
    print(f"\n--- ClubStaff for child Aibar {aibar_id} ---")
    cur.execute(f"SELECT club_id, user_id, role::text, status::text FROM club_staff WHERE user_id = '{aibar_id}'")
    for r in cur.fetchall():
        print(r)

    print(f"\n--- Notifications for child Aibar {aibar_id} ---")
    cur.execute(f"SELECT n.id, n.type, t.is_read FROM notifications n JOIN notification_targets t ON n.id = t.notification_id WHERE t.user_id = '{aibar_id}'")
    for r in cur.fetchall():
        print(r)

    cur.close()
    conn.close()

if __name__ == "__main__":
    deep_inspect_aibar()
