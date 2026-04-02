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
        # Cleanup
        print("Cleaning up old test memberships/staff...")
        db.query(TeamMembership).delete()
        db.query(AcademyPlayer).delete()
        db.query(ClubStaff).filter(ClubStaff.role != ClubRole.OWNER).delete()
        db.commit()

        password_hashed = hash_password("password")
        
        for club_info in CLUBS_DATA:
            # 1. Create Club Owner
            email = f"{club_info['login']}@test.com"
            existing_user = db.query(User).filter(User.email == email).first()
            if existing_user:
                club = db.query(Club).filter(Club.owner_id == existing_user.id).first()
                if not club:
                    owner = existing_user
                else:
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
                db.add(UserRole(user_id=owner.id, role=Role.CLUB_OWNER))
            
            # 2. Create Club
            club = db.query(Club).filter(Club.name == club_info['name']).first()
            if not club:
                club = Club(
                    id=uuid.uuid4(),
                    name=club_info['name'],
                    city="Astana",
                    owner_id=owner.id,
                    address=f"Astana, {club_info['name']} Street 1"
                )
                db.add(club)
                db.flush()
            
            # 3. Create Academy
            academy = db.query(Academy).filter(Academy.club_id == club.id).first()
            if not academy:
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
            
            # 4. Create Coach
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
                db.add(UserRole(user_id=coach.id, role=Role.COACH))
                
                db.add(ClubStaff(
                    id=uuid.uuid4(),
                    club_id=club.id,
                    user_id=coach.id,
                    role=ClubRole.COACH,
                    status=ClubMembershipStatus.ACTIVE
                ))
            
            # 5. Create Team
            team = db.query(Team).filter(Team.academy_id == academy.id).first()
            if not team:
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
            
            # 6. Create 12 Players
            for i in range(12):
                player_name = get_random_name()
                player_email = f"player_{i}_{club_info['login']}@test.com"
                
                existing_p = db.query(User).filter(User.email == player_email).first()
                if existing_p: continue
                    
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
                
                db.add(UserRole(user_id=player_user.id, role=Role.PLAYER_CHILD))
                
                profile = PlayerProfile(
                    id=uuid.uuid4(),
                    user_id=player_user.id,
                    preferred_position=random.choice(["ST", "CM", "CB", "GK", "LW", "RW"]),
                    dominant_foot="RIGHT"
                )
                db.add(profile)
                db.flush()
                
                # Active vs Pending Logic
                if i < 8:
                    # 8 Active Players
                    db.add(AcademyPlayer(id=uuid.uuid4(), player_id=player_user.id, player_profile_id=profile.id, academy_id=academy.id))
                    db.add(TeamMembership(id=uuid.uuid4(), team_id=team.id, player_id=player_user.id, player_profile_id=profile.id, role=MembershipRole.PLAYER, jersey_number=random.randint(1, 99)))
                    
                    db.add(ClubStaff(
                        id=uuid.uuid4(),
                        club_id=club.id,
                        user_id=player_user.id,
                        role=ClubRole.PLAYER,
                        status=ClubMembershipStatus.ACTIVE
                    ))
                else:
                    # 4 Pending Players (Self-Applied to the club / team)
                    from app.clubs.models import Invitation, InvitationStatus
                    db.add(Invitation(
                        id=uuid.uuid4(),
                        club_id=club.id,
                        team_id=team.id,
                        invited_user_id=player_user.id,
                        invited_by=player_user.id, # self application
                        role=ClubRole.PLAYER,
                        status=InvitationStatus.PENDING,
                        is_approved=False
                    ))
                
            print(f"Created Club: {club_info['name']} with 8 active and 4 pending players.")

        # -----------------------------------------------
        # 7. Create Parents and Orphan Children
        # -----------------------------------------------
        for i in range(2):
            parent_email = f"parent_{i}@test.com"
            existing_parent = db.query(User).filter(User.email == parent_email).first()
            if not existing_parent:
                parent_user = User(
                    id=uuid.uuid4(),
                    name=f"Test Parent {i+1}",
                    email=parent_email,
                    password_hash=password_hashed,
                    phone=f"+7777{random.randint(100000, 999999)}",
                    onboarding_completed=True
                )
                db.add(parent_user)
                db.flush()
                db.add(UserRole(user_id=parent_user.id, role=Role.PARENT))
                
            for j in range(2):
                child_email = f"orphan_child_{i}_{j}@test.com"
                existing_child = db.query(User).filter(User.email == child_email).first()
                if not existing_child:
                    child_user = User(
                        id=uuid.uuid4(),
                        name=f"Orphan Child {j+1} of Parent {i+1}",
                        email=child_email,
                        password_hash=password_hashed,
                        date_of_birth=date(random.choice([2013, 2014, 2015]), 5, 10),
                        onboarding_completed=True
                    )
                    db.add(child_user)
                    db.flush()
                    db.add(UserRole(user_id=child_user.id, role=Role.PLAYER_CHILD))
                    
                    db.add(PlayerProfile(
                        id=uuid.uuid4(),
                        user_id=child_user.id,
                        preferred_position="CM",
                        dominant_foot="LEFT"
                    ))

        print("Created 2 parents and 4 orphan children.")
        db.commit()
        print("Successfully seeded remote database data!")
    except Exception as e:
        db.rollback()
        import traceback
        traceback.print_exc()
        print(f"Error seeding data: {e}")
    finally:
        db.close()

if __name__ == "__main__":
    seed_test_data()
