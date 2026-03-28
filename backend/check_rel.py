import psycopg2

def check_relation():
    conn = psycopg2.connect('postgresql://postgres:postgres@localhost:5432/sportseco')
    cur = conn.cursor()
    
    parent_id = '7dc9592c-37b0-4dc6-89b3-4f27b25978d1'
    aibar_id = 'a91006f6-d240-42ad-8bf6-afcf234a7523'
    
    print(f"--- Relation between Parent {parent_id} and Child {aibar_id} ---")
    cur.execute(f"SELECT status::text FROM parent_child_relations WHERE parent_id = '{parent_id}' AND child_id = '{aibar_id}'")
    print(cur.fetchall())
    
    # Also check if the status enum values are correct
    cur.execute(f"SELECT status::text, child_id FROM parent_child_relations WHERE parent_id = '{parent_id}'")
    print("\nAll relations for this parent:")
    for r in cur.fetchall():
        print(r)

    cur.close()
    conn.close()

if __name__ == "__main__":
    check_relation()
