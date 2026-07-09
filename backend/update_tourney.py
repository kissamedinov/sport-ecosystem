from app.database import SessionLocal
from app.tournaments.models import Tournament
from sqlalchemy import text

db = SessionLocal()
try:
    # Alter column size in DB
    db.execute(text("ALTER TABLE tournaments ALTER COLUMN age_category TYPE character varying(50)"))
    db.commit()
    print("Database column altered successfully!")
    
    t = db.query(Tournament).filter(Tournament.name == "Juldyz Ball CUP 2016-2017").first()
    if t:
        t.age_category = "2016-2017"
        db.commit()
        print("Updated age category for Juldyz Ball CUP 2016-2017 to 2016-2017 successfully!")
    else:
        print("Tournament not found!")
finally:
    db.close()
