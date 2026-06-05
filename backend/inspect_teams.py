import psycopg2

conn = psycopg2.connect('postgresql://postgres:postgres@localhost:5432/sportseco')
cur = conn.cursor()
cur.execute("SELECT column_name, data_type FROM information_schema.columns WHERE table_name = 'teams'")
for r in cur.fetchall():
    print(r)
cur.close()
conn.close()
