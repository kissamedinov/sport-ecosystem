
import os
from dotenv import load_dotenv
from sqlalchemy import create_engine, or_, exists
from sqlalchemy.orm import sessionmaker

# Import models
from app.tournaments.models import Tournament, TournamentTeam
from app.database import Base

load_dotenv()

SQLALCHEMY_DATABASE_URL = os.getenv("DATABASE_URL")
engine = create_engine(SQLALCHEMY_DATABASE_URL)
SessionLocal = sessionmaker(bind=engine)
db = SessionLocal()

try:
    print("Attempting to fetch tournaments...")
    # This matches the logic in services.py
    query = db.query(Tournament)
    
    # Let's try to run the full query including filters
    # If we don't have a user_id, let's just try query.all() first
    results = query.all()
    print(f"Simple query.all() SUCCESS! Found {len(results)} tournaments.")
    
    # Now let's try with a dummy user_id to test the filters
    from uuid import uuid4
    user_id = uuid4()
    is_creator = Tournament.created_by == user_id
    has_reg = exists().where(
        (TournamentTeam.tournament_id == Tournament.id) & 
        (TournamentTeam.registered_by == user_id)
    )
    
    print("Attempting to fetch tournaments with filters...")
    query_filtered = db.query(Tournament).filter(or_(is_creator, has_reg))
    results_filtered = query_filtered.all()
    print(f"Filtered query SUCCESS! Found {len(results_filtered)} tournaments.")

except Exception as e:
    print("\nFAILED with error:")
    print(e)
    import traceback
    traceback.print_exc()

finally:
    db.close()
