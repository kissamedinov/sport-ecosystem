
import psycopg2
conn = psycopg2.connect('postgresql://postgres:postgres@localhost:5432/sportseco')
cur = conn.cursor()
cur.execute("SELECT column_name, is_nullable, column_default FROM information_schema.columns WHERE table_name = 'teams'")
rows = cur.fetchall()
for r in rows: print(r)
conn.close()
