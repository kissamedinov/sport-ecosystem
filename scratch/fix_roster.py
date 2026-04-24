
import uuid
import os
from sqlalchemy import create_engine
from sqlalchemy.orm import sessionmaker
from app.database import Base

# Import all models to resolve relationships
from app.users.models import User, Role, UserRole, PlayerProfile
from app.clubs.models import Club, ChildProfile, ClubStaff, ClubRole, ClubMembershipStatus
from app.teams.models import Team, TeamMembership, MembershipStatus, MembershipRole
from app.academies.models import Academy

# Database connection
SQLALCHEMY_DATABASE_URL = "postgresql://postgres:postgres@localhost:5432/sportseco"
engine = create_engine(SQLALCHEMY_DATABASE_URL)
SessionLocal = sessionmaker(autocommit=False, autoflush=False, bind=engine)
db = SessionLocal()

try:
    # 1. Find the club
    club = db.query(Club).filter(Club.name.ilike('%Astana City%')).first()
    if not club:
        print("Club 'Astana City' not found")
    else:
        print(f"Found Club: {club.name} (ID: {club.id})")
        
        # 2. Find the team
        team = db.query(Team).filter(Team.name.ilike('%Astana City 2013-14%')).first()
        if not team:
            print("Team 'Astana City 2013-14' not found")
        else:
            print(f"Found Team: {team.name} (ID: {team.id})")
            
            # 3. Find children in the club
            children = db.query(ChildProfile).filter(ChildProfile.club_id == club.id).all()
            print(f"Found {len(children)} children in club")
            
            added_count = 0
            for child in children:
                # Check if already in roster
                exists = db.query(TeamMembership).filter(
                    TeamMembership.team_id == team.id,
                    TeamMembership.child_profile_id == child.id
                ).first()
                
                if not exists:
                    target_user_id = child.linked_user_id
                    if not target_user_id:
                        print(f"Skipping {child.first_name} - no linked user")
                        continue
                        
                    profile = db.query(PlayerProfile).filter(PlayerProfile.user_id == target_user_id).first()
                    if not profile:
                        profile = PlayerProfile(user_id=target_user_id)
                        db.add(profile)
                        db.flush()
                    
                    # Add to roster
                    new_mem = TeamMembership(
                        team_id=team.id,
                        player_profile_id=profile.id,
                        child_profile_id=child.id,
                        status=MembershipStatus.ACTIVE,
                        role=MembershipRole.PLAYER
                    )
                    db.add(new_mem)
                    print(f"Added {child.first_name} {child.last_name} to roster")
                    added_count += 1
            
            db.commit()
            print(f"Roster updated successfully. Added {added_count} players.")

finally:
    db.close()
