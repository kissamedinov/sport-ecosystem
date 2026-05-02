from sqlalchemy import create_engine, text

# Database connection
SQLALCHEMY_DATABASE_URL = "postgresql://postgres:postgres@localhost:5432/sportseco"
engine = create_engine(SQLALCHEMY_DATABASE_URL)

def check_user_role(email):
    with engine.connect() as connection:
        query = text("""
            SELECT u.email, string_agg(CAST(ur.role AS TEXT), ', ') as roles
            FROM users u
            LEFT JOIN user_roles ur ON u.id = ur.user_id
            WHERE u.email = :email
            GROUP BY u.email;
        """)
        row = connection.execute(query, {"email": email}).fetchone()
        if row:
            print(f"EMAIL: {row[0]}")
            print(f"ROLES: {row[1] if row[1] else 'NO ROLES'}")
        else:
            print(f"User with email '{email}' NOT FOUND.")

if __name__ == "__main__":
    check_user_role("serikserik@gmail.com")
