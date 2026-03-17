import sys
import os
sys.path.append(os.path.dirname(os.path.dirname(os.path.abspath(__file__))))

from sqlalchemy.orm import Session
from app.database import SessionLocal
from app.clubs import services
from uuid import UUID

def debug_dashboard():
    user_id = UUID("cda81552-0e07-445b-9904-39c401bf07c0")
    db = SessionLocal()
    try:
        print(f"Finding club for user {user_id}...")
        club = services.get_my_club(db, user_id)
        if not club:
            print("Club not found for this user.")
            return
            
        print(f"Found club: {club.name} ({club.id})")
        print("Calling get_club_dashboard...")
        dashboard = services.get_club_dashboard(db, club.id)
        print("Dashboard fetched successfully!")
        print(f"Academies count: {dashboard.academies_count}")
        print(f"Teams count: {dashboard.teams_count}")
    except Exception as e:
        import traceback
        print(f"Error fetching dashboard: {e}")
        traceback.print_exc()
    finally:
        db.close()

if __name__ == "__main__":
    debug_dashboard()
