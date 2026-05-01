import os
import sys
from uuid import UUID

# Add backend directory to path
sys.path.append(os.getcwd())

from app.database import SessionLocal
from app.teams.models import Team, TeamMembership, MembershipStatus
from app.academies.models import AcademyPlayer, Academy
from app.academies.services import add_player_to_academy
from app.academies.schemas import AcademyPlayerCreate

def sync_players():
    db = SessionLocal()
    try:
        print("Starting Academy Player Synchronization...")
        
        # 1. Get all teams that belong to an academy
        teams = db.query(Team).filter(Team.academy_id != None).all()
        print(f"Found {len(teams)} teams linked to academies.")
        
        total_synced = 0
        for team in teams:
            print(f"Processing team: {team.name} (Academy: {team.academy.name})")
            
            # 2. Get all active players in this team
            memberships = db.query(TeamMembership).filter(
                TeamMembership.team_id == team.id,
                TeamMembership.status == MembershipStatus.ACTIVE
            ).all()
            
            print(f"  Team has {len(memberships)} active players.")
            
            for m in memberships:
                if not m.player_profile_id:
                    continue
                
                # 3. Ensure they are in the academy registry
                # add_player_to_academy handles checking for existing records and club staff sync
                try:
                    add_player_to_academy(
                        db, 
                        team.academy_id, 
                        AcademyPlayerCreate(player_profile_id=m.player_profile_id)
                    )
                    total_synced += 1
                except Exception as e:
                    print(f"    Error syncing player {m.player_profile_id}: {e}")
        
        db.commit()
        print(f"Sync complete! Total player-academy associations processed/synced: {total_synced}")
        
    finally:
        db.close()

if __name__ == "__main__":
    sync_players()
