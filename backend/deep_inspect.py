import psycopg2

def deep_inspect():
    conn = psycopg2.connect('postgresql://postgres:postgres@localhost:5432/sportseco')
    cur = conn.cursor()
    
    child_id = '3d4ad526-10e0-4e7d-8223-5997f99141fc'
    
    print(f"\n--- Invitations for child {child_id} ---")
    cur.execute(f"SELECT id, status::text, club_id, team_id FROM invitations WHERE invited_user_id = '{child_id}'")
    for r in cur.fetchall():
        print(r)
        
    print(f"\n--- ClubStaff for child {child_id} ---")
    cur.execute(f"SELECT club_id, user_id, role::text, status::text FROM club_staff WHERE user_id = '{child_id}'")
    for r in cur.fetchall():
        print(r)

    print(f"\n--- TeamMembership for child {child_id} ---")
    # Need to find player_profile_id first
    cur.execute(f"SELECT id FROM player_profiles WHERE user_id = '{child_id}'")
    pid = cur.fetchone()
    if pid:
        pid = pid[0]
        cur.execute(f"SELECT team_id, player_profile_id, status::text FROM team_memberships WHERE player_profile_id = '{pid}'")
        for r in cur.fetchall():
            print(r)
    else:
        print("No Player Profile found for child")

    cur.close()
    conn.close()

if __name__ == "__main__":
    deep_inspect()
