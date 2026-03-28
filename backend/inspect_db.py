import psycopg2

def inspect_db():
    conn = psycopg2.connect('postgresql://postgres:postgres@localhost:5432/sportseco')
    cur = conn.cursor()
    
    with open('inspect_results.txt', 'w') as f:
        f.write("--- All Tables in Public Schema ---\n")
        cur.execute("SELECT table_name FROM information_schema.tables WHERE table_schema = 'public'")
        for r in cur.fetchall():
            f.write(f"{r[0]}\n")

    cur.close()
    conn.close()

if __name__ == "__main__":
    inspect_db()
