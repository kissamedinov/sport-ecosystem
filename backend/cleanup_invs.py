import psycopg2

def cleanup():
    conn = psycopg2.connect('postgresql://postgres:postgres@localhost:5432/sportseco')
    cur = conn.cursor()
    
    print("Deleting all invitations and associated notifications...")
    
    # Delete notification targets for TEAM_INVITE notifications
    cur.execute("""
        DELETE FROM notification_targets 
        WHERE notification_id IN (SELECT id FROM notifications WHERE type = 'TEAM_INVITE')
    """)
    
    # Delete TEAM_INVITE notifications
    cur.execute("DELETE FROM notifications WHERE type = 'TEAM_INVITE'")
    
    # Delete all invitations
    cur.execute("DELETE FROM invitations")
    
    conn.commit()
    print("Cleanup successful.")
    
    cur.close()
    conn.close()

if __name__ == "__main__":
    cleanup()
