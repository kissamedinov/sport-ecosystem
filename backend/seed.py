from datetime import date, datetime, timedelta, time
from sqlalchemy.orm import Session
from app.database import SessionLocal, engine, Base
from app.users.models import User, Role
from app.auth.security import hash_password
from app.fields.models import Field, FieldSlot

def seed_db():
    # Import all models to prevent relationship mapper errors
    from app.users import models as user_models
    from app.teams import models as team_models
    from app.tournaments import models as tournament_models
    from app.matches import models as match_models
    from app.bookings import models as booking_models
    from app.fields import models as field_models
    from app.clubs import models as club_models_system
    from app.academies import models as academy_models
    from app.club_teams import models as club_teams_models
    from app.pickup import models as pickup_models
    from app.scouting import models as scouting_models
    from app.stats import models as stats_models
    from app.media import models as media_models
    from app.notifications import models as notification_models
    from app.quizzes import models as quiz_models
    from app.planner import models as planner_models

    Base.metadata.create_all(bind=engine)
    db = SessionLocal()
    
    try:
        users_data = [
            {
                "name": "Admin User",
                "email": "admin@example.com",
                "password_hash": hash_password("adminpass"),
                "date_of_birth": date(1990, 1, 1),
                "phone": "1234567890",
                "role": Role.ADMIN
            },
            {
                "name": "Coach Smith",
                "email": "coach@example.com",
                "password_hash": hash_password("coachpass"),
                "date_of_birth": date(1985, 5, 12),
                "phone": "1234567890",
                "role": Role.COACH
            },
            {
                "name": "Adult Player",
                "email": "adult@example.com",
                "password_hash": hash_password("adultpass"),
                "date_of_birth": date(2000, 3, 15),
                "phone": "1234567890",
                "role": Role.PLAYER_ADULT
            },
            {
                "name": "Child Player",
                "email": "child@example.com",
                "password_hash": hash_password("childpass"),
                "date_of_birth": date(2010, 8, 20),
                "phone": "1234567890",
                "role": Role.PLAYER_CHILD
            },
            {
                "name": "Field Owner",
                "email": "owner@example.com",
                "password_hash": hash_password("ownerpass"),
                "date_of_birth": date(1980, 11, 2),
                "phone": "1234567890",
                "role": Role.FIELD_OWNER
            },
        ]
        
        from app.users.models import UserRole

        for u_data in users_data:
            existing = db.query(User).filter(User.email == u_data["email"]).first()
            if not existing:
                u = User(
                    name=u_data["name"],
                    email=u_data["email"],
                    password_hash=u_data["password_hash"],
                    date_of_birth=u_data["date_of_birth"],
                    phone=u_data["phone"]
                )
                db.add(u)
                db.commit()
                db.refresh(u)
                
                # Add role
                user_role = UserRole(user_id=u.id, role=u_data["role"])
                db.add(user_role)
                db.commit()
        
        print("Users seeded successfully.")

        # Seed Fields and Slots
        owner = db.query(User).filter(User.email == "owner@example.com").first()
        if owner:
            arenas_data = [
                {'name': 'SAIRAN ARENA', 'location': 'Turan Ave 48, Astana', 'price': 15000},
                {'name': 'SPORT CITY PITCHES', 'location': 'Kabanbay Batyr Ave 47, Astana', 'price': 12000},
                {'name': 'ASTANA ARENA', 'location': 'Kabanbay Batyr Ave 33, Astana', 'price': 25000},
                {'name': 'DUMAN SPORT COMPLEX', 'location': 'Kurgalzhyn Highway 2, Astana', 'price': 10000},
                {'name': 'QAZAQSTAN ATHLETIC COMPLEX', 'location': 'Turan Ave 59, Astana', 'price': 20000},
            ]
            
            for arena in arenas_data:
                field = db.query(Field).filter(
                    Field.name == arena['name']
                ).first()
                if not field:
                    field = Field(
                        name=arena['name'],
                        location=arena['location'],
                        owner_id=owner.id
                    )
                    db.add(field)
                    db.commit()
                    db.refresh(field)
                    print(f"Created field: {field.name}")
                
                # Generate slots for next 14 days
                today = date.today()
                for day_offset in range(14):
                    slot_date = today + timedelta(days=day_offset)
                    
                    # Target slots config (08:00, 10:00, 12:00, 14:00, 16:00, 18:00, 20:00, 22:00, 00:00)
                    slot_times = [8, 10, 12, 14, 16, 18, 20, 22, 0]
                    for start_hour in slot_times:
                        # Construct start and end time
                        slot_start = datetime.combine(slot_date, time(hour=start_hour, minute=0))
                        # If start_hour is 0, it means 00:00 (midnight of next day relative to start of that day offset)
                        if start_hour == 0:
                            # 00:00 is next calendar day
                            slot_start = datetime.combine(slot_date + timedelta(days=1), time(hour=0, minute=0))
                        
                        slot_end = slot_start + timedelta(minutes=90)
                        
                        # Check if slot already exists
                        exists = db.query(FieldSlot).filter(
                            FieldSlot.field_id == field.id,
                            FieldSlot.start_time == slot_start
                        ).first()
                        
                        if not exists:
                            new_slot = FieldSlot(
                                field_id=field.id,
                                start_time=slot_start,
                                end_time=slot_end,
                                price=arena['price'],
                                is_available=True
                            )
                            db.add(new_slot)
            db.commit()
            print("Successfully seeded fields and slots for the next 14 days.")
    except Exception as e:
        print(f"Error seeding database: {e}")
        db.rollback()
    finally:
        db.close()

if __name__ == "__main__":
    seed_db()
