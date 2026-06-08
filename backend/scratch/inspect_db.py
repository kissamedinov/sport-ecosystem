import sys
sys.path.append('.')
from app.database import SessionLocal, SQLALCHEMY_DATABASE_URL
from sqlalchemy import create_engine, inspect

engine = create_engine(SQLALCHEMY_DATABASE_URL)
inspector = inspect(engine)
try:
    print("--- TEAMS TABLE COLUMNS ---")
    columns = inspector.get_columns('teams')
    for c in columns:
        print(f"Name: {c['name']} | Type: {c['type']}")
finally:
    pass
