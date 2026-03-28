import psycopg2

def final_rel_check():
    conn = psycopg2.connect('postgresql://postgres:postgres@localhost:5432/sportseco')
    cur = conn.cursor()
    
    parent_id = '7dc9592c-37b0-4dc6-89b3-4f27b25978d1'
    
    print(f"--- Relations for Parent ({parent_id}) ---")
    cur.execute(f"SELECT parent_id, child_id, status::text FROM parent_child_relations WHERE parent_id = '{parent_id}'")
    rels = cur.fetchall()
    for r in rels:
        # Get child name
        cur.execute(f"SELECT name FROM users WHERE id = '{r[1]}'")
        name = cur.fetchone()
        name = name[0] if name else "Unknown"
        print(f"Parent -> {name} ({r[1]}): Status={r[2]}")
        
    cur.close()
    conn.close()

if __name__ == "__main__":
    final_rel_check()
