import psycopg2
conn = psycopg2.connect("postgresql://postgres:postgres@localhost:5432/sportseco")
cur = conn.cursor()
cur.execute("SELECT column_name, data_type FROM information_schema.columns WHERE table_name = 'matches';")
print("matches columns:")
for row in cur.fetchall():
    print(row)
cur.close()
conn.close()
