import psycopg2
import traceback

try:
    print("Trying default postgres:postgres connection...")
    conn = psycopg2.connect('postgresql://postgres:postgres@localhost:5432/postgres')
    print("Success!")
    conn.close()
except:
    print("Failed")
    traceback.print_exc()
