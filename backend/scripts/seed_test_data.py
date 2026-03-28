import uuid
import random
from datetime import date
from sqlalchemy.orm import Session
from app.database import SessionLocal, engine, Base

# Import ALL models to ensure they are registered with Base
import app.users.models
import app.clubs.models
import app.academies.models
import app.teams.models
import app.tournaments.models
import app.matches.models
import app.bookings.models
import app.fields.models
import app.club_teams.models
import app.pickup.models
import app.scouting.models
import app.stats.models

from app.users.models import User, UserRole, Role, PlayerProfile
from app.auth.security import hash_password
from app.clubs.models import Club, ClubRole, ClubStaff, ClubMembershipStatus
from app.academies.models import Academy, AcademyPlayer
from app.teams.models import Team, TeamMembership, MembershipRole

# Seed Data Configurations
CLUBS_DATA = [
    {"name": "Astana City", "login": "astanacity1"},
    {"name": "Astana United", "login": "astanaunited1"},
    {"name": "Astana Villa", "login": "astanavilla1"},
    {"name": "Real Astana", "login": "realastana1"},
]

KAZAKH_FIRST_NAMES = ["Alibek", "Sultan", "Bauyrzhan", "Daniyar", "Temirlan", "Madiyar", "Kuanysh", "Bekzat", "Olzhas", "Askhat"]
RUSSIAN_FIRST_NAMES = ["Artyom", "Maksim", "Aleksandr", "Mikhail", "Andrey", "Ivan", "Danil", "Kirill", "Nikita", "Stanislav"]
TATAR_FIRST_NAMES = ["Rustam", "Damir", "Ildar", "Marat", "Renat", "Timur"]

LAST_NAMES = ["Amanov", "Suleimenov", "Ivanov", "Kuznetsov", "Sapariev", "Bolatov", "Nurlanov", "Ismailov", "Kim", "Abramov"]

def get_random_name():
    first_names = KAZAKH_FIRST_NAMES + RUSSIAN_FIRST_NAMES + TATAR_FIRST_NAMES
    return f"{random.choice(first_names)} {random.choice(LAST_NAMES)}"

def seed_test_data():
    db = SessionLocal()
    try:
        # 0. Optional Cleanup for clean re-runs
        print("Cleaning up old test memberships/staff...")
        db.query(TeamMembership).delete()
        db.query(AcademyPlayer).delete()
        # Delete staff who aren't owners (owners are created with clubs)
        db.query(ClubStaff).filter(ClubStaff.role != ClubRole.OWNER).delete()
        db.commit()
        print("Cleanup complete.")

        password_hashed = hash_password("password")
        
        for club_info in CLUBS_DATA:
            # 1. Create Club Owner
            email = f"{club_info['login']}@test.com"
            existing_user = db.query(User).filter(User.email == email).first()
            if existing_user:
                print(f"Skipping {email}, already exists.")
                # We still want to make sure the club/academy exist or get them
                club = db.query(Club).filter(Club.owner_id == existing_user.id).first()
                if club:
                    continue
                owner = existing_user
            else:
                owner = User(
                    id=uuid.uuid4(),
                    name=f"{club_info['name']} Owner",
                    email=email,
                    password_hash=password_hashed,
                    onboarding_completed=True
                )
                db.add(owner)
                db.flush()
                
                owner_role = UserRole(user_id=owner.id, role=Role.CLUB_OWNER)
                db.add(owner_role)
            
            # 2. Create Club
            club = Club(
                id=uuid.uuid4(),
                name=club_info['name'],
                city="Astana",
                owner_id=owner.id,
                address=f"Astana, {club_info['name']} Street 1"
            )
            db.add(club)
            db.flush()
            
            # 3. Create Academy (Branch)
            academy = Academy(
                id=uuid.uuid4(),
                club_id=club.id,
                name=f"{club_info['name']} Academy",
                city="Astana",
                address=f"Astana, Sport Ave {random.randint(1, 100)}",
                owner_id=owner.id
            )
            db.add(academy)
            db.flush()
            
            # 4. Create Coach Placeholder
            coach_email = f"coach_{club_info['login']}@test.com"
            coach = db.query(User).filter(User.email == coach_email).first()
            if not coach:
                coach = User(
                    id=uuid.uuid4(),
                    name=f"Coach {club_info['name']}",
                    email=coach_email,
                    password_hash=password_hashed,
                    onboarding_completed=True
                )
                db.add(coach)
                db.flush()
                
                coach_role = UserRole(user_id=coach.id, role=Role.COACH)
                db.add(coach_role)
                
                # Add to Club Staff for Dashboard visibility
                club_staff_coach = ClubStaff(
                    id=uuid.uuid4(),
                    club_id=club.id,
                    user_id=coach.id,
                    role=ClubRole.COACH,
                    status=ClubMembershipStatus.ACTIVE
                )
                db.add(club_staff_coach)
            
            # 5. Create Team
            team = Team(
                id=uuid.uuid4(),
                academy_id=academy.id,
                name=f"{club_info['name']} 2013-14",
                age_category="U11/U13",
                birth_year=2013,
                coach_id=coach.id
            )
            db.add(team)
            db.flush()
            
            # 6. Create Players
            for i in range(12):
                player_name = get_random_name()
                player_email = f"player_{i}_{club_info['login']}@test.com"
                
                # Check if player exists
                existing_p = db.query(User).filter(User.email == player_email).first()
                if existing_p:
                    continue
                    
                player_user = User(
                    id=uuid.uuid4(),
                    name=player_name,
                    email=player_email,
                    password_hash=password_hashed,
                    date_of_birth=date(random.choice([2013, 2014]), random.randint(1, 12), random.randint(1, 28)),
                    onboarding_completed=True
                )
                db.add(player_user)
                db.flush()
                
                player_role = UserRole(user_id=player_user.id, role=Role.PLAYER_CHILD)
                db.add(player_role)
                
                profile = PlayerProfile(
                    id=uuid.uuid4(),
                    user_id=player_user.id,
                    preferred_position=random.choice(["ST", "CM", "CB", "GK", "LW", "RW"]),
                    dominant_foot="RIGHT"
                )
                db.add(profile)
                db.flush()
                
                # Link to Academy as player
                acad_player = AcademyPlayer(
                    id=uuid.uuid4(),
                    player_id=player_user.id,
                    player_profile_id=profile.id,
                    academy_id=academy.id
                )
                db.add(acad_player)
                
                # Membership in Team
                membership = TeamMembership(
                    id=uuid.uuid4(),
                    team_id=team.id,
                    player_id=player_user.id,
                    player_profile_id=profile.id,
                    role=MembershipRole.PLAYER,
                    jersey_number=random.randint(1, 99)
                )
                db.add(membership)

                # Add to Club Staff for Dashboard visibility
                club_staff_player = ClubStaff(
                    id=uuid.uuid4(),
                    club_id=club.id,
                    user_id=player_user.id,
                    role=ClubRole.PLAYER,
                    status=ClubMembershipStatus.ACTIVE
                )
                db.add(club_staff_player)
                
            print(f"Created Club: {club_info['name']} with 12 players.")
            
        db.commit()
        print("Successfully seeded all test data!")
    except Exception as e:
        db.rollback()
        import traceback
        traceback.print_exc()
        print(f"Error seeding data: {e}")
    finally:
        db.close()

if __name__ == "__main__":
    seed_test_data()
