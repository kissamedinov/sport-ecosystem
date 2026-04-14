import os
from sqlalchemy import create_engine, text
from sqlalchemy.orm import Session
from dotenv import load_dotenv
import uuid

# Load environment variables
load_dotenv()

DATABASE_URL = os.getenv("DATABASE_URL")
if DATABASE_URL and DATABASE_URL.startswith("postgres://"):
    DATABASE_URL = DATABASE_URL.replace("postgres://", "postgresql://", 1)

engine = create_engine(DATABASE_URL)

def inspect_user_data(email="mu@test.com"):
    with Session(engine) as session:
        print(f"--- Inspecting data for User: {email} ---")
        
        # 1. Find User
        user = session.execute(text("SELECT id, name FROM users WHERE email = :email"), {"email": email}).first()
        if not user:
            print("User not found!")
            return
        
        user_id = user.id
        print(f"User ID: {user_id}")

        # 2. Find Clubs owned by this user
        clubs = session.execute(text("SELECT id, name FROM clubs WHERE owner_id = :uid"), {"uid": user_id}).all()
        print(f"\nOwned Clubs: {len(clubs)}")
        club_ids = []
        for c in clubs:
            print(f"- Club: {c.name} (ID: {c.id})")
            club_ids.append(c.id)

        # 3. Find Academies owned by this user
        academies_owned = session.execute(text("SELECT id, name, club_id FROM football_academies WHERE owner_id = :uid"), {"uid": user_id}).all()
        print(f"\nOwned Academies (direct): {len(academies_owned)}")
        for a in academies_owned:
            print(f"- Academy: {a.name} (ID: {a.id}, linked club_id: {a.club_id})")

        # 4. Find Academies linked to the user's clubs
        if club_ids:
            academies_via_club = session.execute(text("SELECT id, name, club_id, owner_id FROM football_academies WHERE club_id IN :cids"), {"cids": tuple(club_ids)}).all()
            print(f"\nAcademies linked to your Clubs: {len(academies_via_club)}")
            for a in academies_via_club:
                print(f"- Academy: {a.name} (ID: {a.id}, owner_id: {a.owner_id})")

        # 5. Find Teams for these academies
        all_acc_ids = list(set([str(a.id) for a in academies_owned] + [str(a.id) for a in (academies_via_club if club_ids else [])]))
        if all_acc_ids:
            teams = session.execute(text("SELECT id, name, academy_id FROM teams WHERE academy_id IN :aids"), {"aids": tuple(all_acc_ids)}).all()
            print(f"\nTeams found in these Academies: {len(teams)}")
            for t in teams:
                print(f"- Team: {t.name} (ID: {t.id}, AcademyID: {t.academy_id})")
        else:
            print("\nNo Academies found to check teams for.")

if __name__ == "__main__":
    inspect_user_data()
