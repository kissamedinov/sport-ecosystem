import psycopg2

def check_notif_entity():
    conn = psycopg2.connect('postgresql://postgres:postgres@localhost:5432/sportseco')
    cur = conn.cursor()
    
    # Aibar's notification ID from Flutter log: 4cffd85b
    # Invitation ID from Flutter log: e584ef76
    
    print("--- Notifications for Aibar ---")
    # Actually, let's find the notification TARGET for Aibar
    aibar_id = 'a91006f6-d240-42ad-8bf6-afcf234a7523'
    cur.execute(f"SELECT notification_id FROM notification_targets WHERE user_id = '{aibar_id}'")
    nt = cur.fetchall()
    for row in nt:
        n_id = row[0]
        cur.execute(f"SELECT id, type, entity_id FROM notifications WHERE id = '{n_id}'")
        n = cur.fetchone()
        print(f"Notification {n_id}: Type={n[1]}, EntityID={n[2]}")
        
    print("\n--- Invitations for Aibar ---")
    cur.execute(f"SELECT id, status::text FROM invitations WHERE invited_user_id = '{aibar_id}'")
    for r in cur.fetchall():
        print(f"Invitation {r[0]}: Status={r[1]}")

    cur.close()
    conn.close()

if __name__ == "__main__":
    check_notif_entity()
