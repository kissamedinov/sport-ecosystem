import psycopg2

def verify_system():
    conn = psycopg2.connect('postgresql://postgres:postgres@localhost:5432/sportseco')
    conn.autocommit = True
    cur = conn.cursor()
    
    child_id = '3d4ad526-10e0-4e7d-8223-5997f99141fc'
    
    print(f"Checking for child {child_id}...")
    
    # 1. Clean old test data if exists
    cur.execute("DELETE FROM notification_targets WHERE notification_id = '00000000-0000-0000-0000-000000000001'")
    cur.execute("DELETE FROM notifications WHERE id = '00000000-0000-0000-0000-000000000001'")

    # 2. Insert test
    print("Inserting test notification...")
    cur.execute("""
        INSERT INTO notifications (id, type, title, message, created_at) 
        VALUES ('00000000-0000-0000-0000-000000000001', 'TEAM_INVITE', 'Test Invitation', 'Success test', NOW())
    """)
    cur.execute(f"""
        INSERT INTO notification_targets (id, notification_id, user_id, is_read) 
        VALUES ('00000000-0000-0000-0000-000000000002', '00000000-0000-0000-0000-000000000001', '{child_id}', false)
    """)
    
    # 3. Verify retrieval
    print("Verifying retrieval...")
    cur.execute(f"SELECT n.title FROM notifications n JOIN notification_targets nt ON n.id = nt.notification_id WHERE nt.user_id = '{child_id}'")
    rows = cur.fetchall()
    print(f"Retrieved: {rows}")
    
    cur.close()
    conn.close()

if __name__ == "__main__":
    verify_system()
