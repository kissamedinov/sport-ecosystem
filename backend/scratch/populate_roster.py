
import uuid
from sqlalchemy import create_engine
from sqlalchemy.orm import sessionmaker
from app.users.models import User, PlayerProfile, UserRole, Role
from app.clubs.models import Club, ClubStaff, ClubRole, ClubMembershipStatus
from app.teams.models import Team, TeamMembership, MembershipStatus, MembershipRole
from app.academies.models import Academy

import os
from dotenv import load_dotenv
load_dotenv()

SQLALCHEMY_DATABASE_URL = os.getenv("DATABASE_URL", "postgresql://postgres:postgres@localhost:5432/sportseco")
engine = create_engine(SQLALCHEMY_DATABASE_URL)
SessionLocal = sessionmaker(bind=engine)
db = SessionLocal()

try:
    # 1. Find the club and team
    club = db.query(Club).filter(Club.name.ilike('%Astana City%')).first()
    team = db.query(Team).filter(Team.name.ilike('%Astana City 2013-14%')).first()
    
    if not club or not team:
        print(f"Club or Team not found. Club: {club}, Team: {team}")
    else:
        print(f"Updating roster for Team: {team.name} in Club: {club.name}")
        
        # 2. Find players to add
        player_names = [
            "Alikhan Kasym", "Sultan Kasym", "Aibar White", "Serikzhan White",
            "Youth Player"
        ]
        
        players_to_add = db.query(User).filter(User.name.in_(player_names)).all()
        print(f"Found {len(players_to_add)} candidate players")
        
        added_count = 0
        for p in players_to_add:
            # Ensure PlayerProfile exists
            profile = db.query(PlayerProfile).filter(PlayerProfile.user_id == p.id).first()
            if not profile:
                profile = PlayerProfile(user_id=p.id)
                db.add(profile); db.flush()
            
            # Ensure in ClubStaff as PLAYER
            staff = db.query(ClubStaff).filter(ClubStaff.club_id == club.id, ClubStaff.user_id == p.id).first()
            if not staff:
                staff = ClubStaff(club_id=club.id, user_id=p.id, role=ClubRole.PLAYER, status=ClubMembershipStatus.ACTIVE)
                db.add(staff)
            
            # Ensure in TeamMembership
            mem = db.query(TeamMembership).filter(TeamMembership.team_id == team.id, TeamMembership.player_id == p.id).first()
            if not mem:
                mem = TeamMembership(
                    team_id=team.id,
                    player_id=p.id,
                    player_profile_id=profile.id,
                    status=MembershipStatus.ACTIVE,
                    role=MembershipRole.PLAYER
                )
                db.add(mem)
                print(f"Added {p.name} to roster")
                added_count += 1
        
        db.commit()
        print(f"Roster updated. Added {added_count} players.")

finally:
    db.close()
