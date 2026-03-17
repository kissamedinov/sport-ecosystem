# Sync missing database columns for Club Expansion

import os
import uuid
from sqlalchemy import create_engine, text
from sqlalchemy.orm import sessionmaker
from dotenv import load_dotenv

load_dotenv()

DATABASE_URL = os.getenv("DATABASE_URL", "postgresql://postgres:postgres@localhost/sportseco")
engine = create_engine(DATABASE_URL)
SessionLocal = sessionmaker(bind=engine)

def migrate():
    with engine.connect() as conn:
        print("Checking for club_id in football_academies...")
        try:
            # Check if club_id exists
            conn.execute(text("SELECT club_id FROM football_academies LIMIT 1"))
            print("club_id already exists in football_academies.")
        except Exception:
            conn.rollback()
            print("Adding club_id to football_academies...")
            # We need a valid club to link to if there are existing academies, 
            # but since this is dev, we can just add it as nullable first or with a default if we have a "system" club.
            # I'll add it as nullable first, then the user might need to link them, or I'll link to the first club found.
            
            # Get a default club ID if any exists
            result = conn.execute(text("SELECT id FROM clubs LIMIT 1"))
            default_club = result.fetchone()
            
            conn.execute(text("ALTER TABLE football_academies ADD COLUMN club_id UUID REFERENCES clubs(id)"))
            
            if default_club:
                print(f"Linking existing academies to club: {default_club[0]}")
                conn.execute(text(f"UPDATE football_academies SET club_id = '{default_club[0]}' WHERE club_id IS NULL"))
            
            # Now set to NOT NULL if desired, but let's keep it careful for now.
            print("Successfully added club_id column.")
        
        # Ensure other new tables exist (using Base.metadata.create_all is safer)
        from app.database import Base
        from app.clubs.models import Club, ClubStaff, ClubRequest, Invitation, ChildProfile
        # We need to import all models to make sure they are registered with Base
        print("Ensuring all new tables are created...")
        Base.metadata.create_all(bind=engine)
        print("Done.")
        conn.commit()

if __name__ == "__main__":
    migrate()
