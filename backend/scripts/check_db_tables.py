from app.database import engine
import sqlalchemy as sa

def check_tables():
    print("Listing all tables in the database...")
    inspector = sa.inspect(engine)
    tables = inspector.get_table_names()
    print(f"Existing tables: {tables}")
    
    if "tournaments" not in tables:
        print("CRITICAL: 'tournaments' table is missing!")
    else:
        print("'tournaments' table found.")
        columns = [c['name'] for c in inspector.get_columns('tournaments')]
        print(f"Columns in 'tournaments': {columns}")

if __name__ == "__main__":
    check_tables()
