import psycopg2
import os

DATABASE_URL = "postgresql://postgres:postgres@localhost:5432/sportseco"

def update_schema():
    conn = None
    try:
        conn = psycopg2.connect(DATABASE_URL)
        cur = conn.cursor()
        
        print("Updating tournaments table...")
        
        # Add surface_type column if it doesn't exist
        cur.execute("""
            ALTER TABLE tournaments 
            ADD COLUMN IF NOT EXISTS surface_type VARCHAR DEFAULT 'GRASS';
        """)
        
        # Add series_name column if it doesn't exist
        cur.execute("""
            ALTER TABLE tournaments 
            ADD COLUMN IF NOT EXISTS series_name VARCHAR;
        """)
        
        conn.commit()
        print("Schema updated successfully!")
        cur.close()
    except Exception as e:
        print(f"Error updating schema: {e}")
        if conn:
            conn.rollback()
    finally:
        if conn:
            conn.close()

if __name__ == "__main__":
    update_schema()
