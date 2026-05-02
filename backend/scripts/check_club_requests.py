from sqlalchemy import create_engine, text

# Database connection
SQLALCHEMY_DATABASE_URL = "postgresql://postgres:postgres@localhost:5432/sportseco"
engine = create_engine(SQLALCHEMY_DATABASE_URL)

def check_requests():
    with engine.connect() as connection:
        query = text("""
            SELECT id, name, status, created_at 
            FROM club_requests 
            ORDER BY created_at DESC 
            LIMIT 10;
        """)
        results = connection.execute(query).fetchall()
        print(f"\n{'ID':<40} | {'NAME':<20} | {'STATUS':<10} | {'CREATED AT'}")
        print("-" * 100)
        for row in results:
            print(f"{str(row[0]):<40} | {str(row[1]):<20} | {str(row[2]):<10} | {str(row[3])}")
        print("-" * 100)

if __name__ == "__main__":
    try:
        check_requests()
    except Exception as e:
        print(f"Error: {e}")
