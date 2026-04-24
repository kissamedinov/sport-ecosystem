
import os
import uuid
from dotenv import load_dotenv
from sqlalchemy import create_engine
from sqlalchemy.orm import sessionmaker
# Import all models to avoid SQLAlchemy mapping errors
from app.users.models import User, PlayerProfile, UserRole, Role
from app.clubs.models import Club, ClubStaff, ClubRole, ClubMembershipStatus
from app.teams.models import Team, TeamMembership, MembershipStatus, MembershipRole
from app.academies.models import Academy

load_dotenv()

SQLALCHEMY_DATABASE_URL = os.getenv("DATABASE_URL", "postgresql://postgres:postgres@localhost:5432/sportseco")
engine = create_engine(SQLALCHEMY_DATABASE_URL)
SessionLocal = sessionmaker(bind=engine)
db = SessionLocal()

try:
    club = db.query(Club).filter(Club.name.ilike('%Astana City%')).first()
    team = db.query(Team).filter(Team.name.ilike('%Astana City 2013-14%')).first()
    
    if not club or not team:
        print(f"Club or Team not found. Club: {club}, Team: {team}")
    else:
        print(f"Updating roster for Team: {team.name} in Club: {club.name}")
        
        # Scan for all users with player roles
        player_roles = [Role.PLAYER_CHILD, Role.PLAYER_YOUTH]
        all_players = db.query(User).join(UserRole).filter(UserRole.role.in_(player_roles)).all()
        print(f"Scanning {len(all_players)} players in database...")
        
        added_count = 0
        for p in all_players:
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
