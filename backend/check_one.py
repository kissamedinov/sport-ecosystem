import psycopg2

def check_one_inv(inv_id):
    conn = psycopg2.connect('postgresql://postgres:postgres@localhost:5432/sportseco')
    cur = conn.cursor()
    cur.execute(f"SELECT id, status::text, invited_user_id, club_id FROM invitations WHERE id = '{inv_id}'")
    row = cur.fetchone()
    if row:
        print(f"Invitation {inv_id}: Status={row[1]}, User={row[2]}, Club={row[3]}")
    else:
        print(f"Invitation {inv_id}: NOT FOUND")
    
    # Also list ALL pending invitations for this child
    child_id = '3d4ad526-10e0-4e7d-8223-5997f99141fc'
    cur.execute(f"SELECT id, status::text FROM invitations WHERE invited_user_id = '{child_id}'")
    print(f"\nAll invitations for child {child_id}:")
    for r in cur.fetchall():
        print(r)
        
    cur.close()
    conn.close()

if __name__ == "__main__":
    check_one_inv('e584ef76-f1af-4369-9824-3ff22ef8836e')
