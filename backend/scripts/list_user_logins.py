import sys
import os
from sqlalchemy import create_engine, text

# Database connection
SQLALCHEMY_DATABASE_URL = "postgresql://postgres:postgres@localhost:5432/sportseco"
engine = create_engine(SQLALCHEMY_DATABASE_URL)

def list_users_raw():
    with engine.connect() as connection:
        query = text("""
            SELECT u.email, string_agg(CAST(ur.role AS TEXT), ', ') as roles
            FROM users u
            LEFT JOIN user_roles ur ON u.id = ur.user_id
            GROUP BY u.email
            ORDER BY u.email;
        """)
        result = connection.execute(query).fetchall()
        
        print(f"\n{'EMAIL (LOGIN)':<40} | {'ROLES'}")
        print("-" * 75)
        for row in result:
            email = str(row[0]) if row[0] else "no-email"
            roles = str(row[1]) if row[1] else "no-roles"
            print(f"{email:<40} | {roles}")
        print("-" * 75)

if __name__ == "__main__":
    try:
        list_users_raw()
    except Exception as e:
        print(f"SQL Error: {e}")
