import psycopg2
import uuid

def link_and_clear():
    conn = psycopg2.connect('postgresql://postgres:postgres@localhost:5432/sportseco')
    cur = conn.cursor()
    
    parent_id = '7dc9592c-37b0-4dc6-89b3-4f27b25978d1' # The one in token
    aibar_id = 'a91006f6-d240-42ad-8bf6-afcf234a7523'
    
    print(f"Linking parent {parent_id} to child {aibar_id}...")
    
    # Try update first
    cur.execute(f"UPDATE parent_child_relations SET status='ACCEPTED' WHERE parent_id='{parent_id}' AND child_id='{aibar_id}'")
    if cur.rowcount == 0:
        # If not, try insert
        new_id = str(uuid.uuid4())
        cur.execute(f"INSERT INTO parent_child_relations (id, parent_id, child_id, relation_type, status) VALUES ('{new_id}', '{parent_id}', '{aibar_id}', 'GUARDIAN', 'ACCEPTED')")
    
    conn.commit()
    print("Done.")
    
    cur.close()
    conn.close()

if __name__ == "__main__":
    link_and_clear()
