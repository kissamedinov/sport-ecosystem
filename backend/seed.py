from datetime import date
from sqlalchemy.orm import Session
from app.database import SessionLocal, engine, Base
from app.users.models import User, Role
from app.auth.security import hash_password

def seed_db():
    Base.metadata.create_all(bind=engine)
    db = SessionLocal()
    
    try:
        users = [
            User(
                name="Admin User",
                email="admin@example.com",
                password_hash=hash_password("adminpass"),
                role=Role.ADMIN,
                date_of_birth=date(1990, 1, 1),
                phone="1234567890"
            ),
            User(
                name="Coach Smith",
                email="coach@example.com",
                password_hash=hash_password("coachpass"),
                role=Role.COACH,
                date_of_birth=date(1985, 5, 12),
                phone="1234567890"
            ),
            User(
                name="Adult Player",
                email="adult@example.com",
                password_hash=hash_password("adultpass"),
                role=Role.PLAYER_ADULT,
                date_of_birth=date(2000, 3, 15),
                phone="1234567890"
            ),
            User(
                name="Child Player",
                email="child@example.com",
                password_hash=hash_password("childpass"),
                role=Role.PLAYER_CHILD,
                date_of_birth=date(2010, 8, 20),
                phone="1234567890"
            ),
            User(
                name="Field Owner",
                email="owner@example.com",
                password_hash=hash_password("ownerpass"),
                role=Role.FIELD_OWNER,
                date_of_birth=date(1980, 11, 2),
                phone="1234567890"
            ),
        ]
        
        for u in users:
            existing = db.query(User).filter(User.email == u.email).first()
            if not existing:
                db.add(u)
        
        db.commit()
        print("Seed data inserted successfully.")
    except Exception as e:
        print(f"Error seeding database: {e}")
        db.rollback()
    finally:
        db.close()

if __name__ == "__main__":
    seed_db()
