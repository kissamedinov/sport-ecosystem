import os
from sqlalchemy import create_engine
from sqlalchemy.orm import sessionmaker
from dotenv import load_dotenv
from app.database import Base
# Import models to register them with Base
from app.academies.models import Academy, AcademyTeam, AcademyPlayer, TrainingSession, TrainingAttendance, TrainingSchedule, AcademyBillingConfig

load_dotenv()

DATABASE_URL = os.getenv("DATABASE_URL", "postgresql://postgres:postgres@localhost/sportseco")
engine = create_engine(DATABASE_URL)

def migrate():
    print("Connecting to database...")
    print(f"Using DATABASE_URL: {DATABASE_URL}")
    print("Ensuring new Academy CRM tables are created...")
    
    # This will create tables for any models registered with Base that don't exist yet
    Base.metadata.create_all(bind=engine)
    
    print("Migration completed successfully.")

if __name__ == "__main__":
    migrate()
