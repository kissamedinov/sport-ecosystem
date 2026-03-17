from app.database import engine, Base
import app.tournaments.models
import sqlalchemy as sa

def debug_create_and_check():
    print("Running create_all...")
    Base.metadata.create_all(bind=engine)
    
    print("Checking tables immediately...")
    inspector = sa.inspect(engine)
    tables = inspector.get_table_names()
    print(f"Tables FOUND: {tables}")
    
    needed = ["tournaments", "tournament_registrations"]
    for n in needed:
        if n in tables:
            print(f"VERIFIED: {n} exists.")
        else:
            print(f"MISSING: {n} is NOT in the list.")

if __name__ == "__main__":
    debug_create_and_check()
