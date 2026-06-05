
import psycopg2
import sys

DATABASE_URL = "postgresql://postgres:postgres@localhost:5432/sportseco"
t_id = sys.argv[1] if len(sys.argv) > 1 else 'f67c730d-c838-433a-a820-988f8257a8b0'

import uuid
try:
    conn = psycopg2.connect(DATABASE_URL)
    cur = conn.cursor()
    cur.execute("INSERT INTO tournament_divisions (id, tournament_edition_id, name, birth_year, max_teams) VALUES (%s, %s, %s, %s, %s)", (str(uuid.uuid4()), t_id, 'Test Div', 2015, 10))
    conn.commit()
    print("Direct SQL Success!")
except Exception as e:
    print(f"Direct SQL Error: {e}")
finally:
    if 'conn' in locals(): conn.close()
