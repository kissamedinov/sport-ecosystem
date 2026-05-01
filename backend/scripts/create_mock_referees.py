import asyncio
import uuid
import random
from datetime import datetime, timedelta
from app.database import SessionLocal
from app.users.models import User, UserRole, Role, PlayerProfile
# Import other models to satisfy relationships
import app.academies.models
import app.teams.models
import app.tournaments.models
from app.auth.security import hash_password

async def create_mock_referees():
    db = SessionLocal()
    try:
        referees = [
            {"name": "Ivan Ivanov", "email": "ivan@ref.com", "phone": "+77012223344"},
            {"name": "Sergey Petrov", "email": "sergey@ref.com", "phone": "+77013334455"},
            {"name": "Dmitry Sidorov", "email": "dmitry@ref.com", "phone": "+77014445566"},
            {"name": "Arman Yesenov", "email": "arman@ref.com", "phone": "+77015556677"},
            {"name": "Bauyrzhan Omarov", "email": "bauyr@ref.com", "phone": "+77016667788"},
        ]

        for ref_data in referees:
            # Check if user exists
            existing_user = db.query(User).filter(User.email == ref_data["email"]).first()
            if not existing_user:
                new_user_id = uuid.uuid4()
                new_user = User(
                    id=new_user_id,
                    email=ref_data["email"],
                    password_hash=hash_password("password123"),
                    name=ref_data["name"],
                    phone=ref_data["phone"]
                )
                db.add(new_user)
                
                # Add REFEREE role
                db.add(UserRole(user_id=new_user_id, role=Role.REFEREE))
                print(f"Created referee: {ref_data['name']}")
            else:
                print(f"Referee already exists: {ref_data['name']}")
        
        db.commit()
        print("Successfully created mock referees.")
    except Exception as e:
        print(f"Error during referee creation: {e}")
        db.rollback()
    finally:
        db.close()

if __name__ == "__main__":
    asyncio.run(create_mock_referees())
