import psycopg2

def find_aibar():
    conn = psycopg2.connect('postgresql://postgres:postgres@localhost:5432/sportseco')
    cur = conn.cursor()
    
    cur.execute("SELECT id, email, name FROM users WHERE name LIKE 'Aibar%'")
    users = cur.fetchall()
    print("--- Users named Aibar ---")
    for u in users:
        print(u)
        # Check relations for each
        cur.execute(f"SELECT parent_id, status::text FROM parent_child_relations WHERE child_id = '{u[0]}'")
        print(f"  Relations: {cur.fetchall()}")

    cur.close()
    conn.close()

if __name__ == "__main__":
    find_aibar()
