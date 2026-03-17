import sys
import os
from sqlalchemy import create_engine
from sqlalchemy.orm import sessionmaker
import uuid

# Add backend to path
sys.path.append(os.path.abspath(os.path.join(os.getcwd(), "backend")))

from app.database import Base
from app.users.models import User, UserRole, Role, PlayerProfile
from app.clubs.models import Club, ClubMembership, ClubRole, ClubMembershipStatus
from app.teams.models import Team, TeamMembership, MembershipStatus
from app.academies.models import Academy
from app.tournaments.models import Tournament, TournamentDivision, TournamentMatch, MatchStatus
from app.matches.models import Match
from app.club_teams.models import ClubTeam
from app.clubs import services, schemas

# Mock DB
SQLALCHEMY_DATABASE_URL = "sqlite:///./test_club.db"
engine = create_engine(SQLALCHEMY_DATABASE_URL, connect_args={"check_same_thread": False})
TestingSessionLocal = sessionmaker(autocommit=False, autoflush=False, bind=engine)

def verify():
    Base.metadata.create_all(bind=engine)
    
    # Force rebuild due to Pydantic v2 quirks
    schemas.AcademyResponse.model_rebuild()
    schemas.ClubDashboardResponse.model_rebuild()
    
    db = TestingSessionLocal()
    
    try:
        # 1. Create Owner
        unique_id = str(uuid.uuid4())[:8]
        owner = User(name="Owner", email=f"owner_{unique_id}@test.com", password_hash="hash")
        db.add(owner)
        db.flush()
        db.add(UserRole(user_id=owner.id, role=Role.CLUB_OWNER))
        
        # 2. Create Club
        club_in = schemas.ClubCreate(name=f"FC Test {unique_id}", city="Test City")
        club = services.create_club(db, club_in, owner.id)
        print(f"Club created: {club.name}")
        
        # 3. Create Academy
        academy_in = schemas.AcademyCreate(name=f"Astana Academy {unique_id}", city="Astana", address="Main St")
        academy = services.create_academy_in_club(db, club.id, academy_in)
        print(f"Academy created: {academy.name}")
        
        # 4. Create Team in Academy
        coach = User(name="Coach", email=f"coach_{unique_id}@test.com", password_hash="hash")
        db.add(coach)
        db.flush()
        db.add(UserRole(user_id=coach.id, role=Role.COACH))
        
        team_in = schemas.TeamCreateInAcademy(name="U15", birth_year=2010, coach_id=coach.id)
        team = services.create_team_in_academy(db, academy.id, team_in)
        print(f"Team created: {team.name}")
        
        # 5. Add Player
        player_user = User(name="Player", email=f"player_{unique_id}@test.com", password_hash="hash")
        db.add(player_user)
        db.flush()
        db.add(UserRole(user_id=player_user.id, role=Role.PLAYER_YOUTH))
        db.commit()
        db.refresh(player_user)
        
        player_add = schemas.ClubPlayerAdd(
            player_user_id=player_user.id,
            team_id=team.id,
            jersey_number=10
        )
        services.add_player_to_team(db, team.id, player_add)
        print(f"Player added to team via Academy")
        
        # 6. Verify Dashboard
        dashboard = services.get_club_dashboard(db, club.id)
        print(f"Dashboard Stats: Academies={dashboard.academies_count}, Teams={dashboard.teams_count}, Players={dashboard.players_count}")
        
        # 7. Transfer Player
        academy2_in = schemas.AcademyCreate(name=f"Almaty Academy {unique_id}", city="Almaty", address="South St")
        academy2 = services.create_academy_in_club(db, club.id, academy2_in)
        
        team2_in = schemas.TeamCreateInAcademy(name="U15-2", birth_year=2010, coach_id=coach.id)
        team2 = services.create_team_in_academy(db, academy2.id, team2_in)
        
        services.transfer_player(db, player_user.id, team.id, team2.id)
        print(f"Player transferred between academies")
        
        # 8. Check Career
        profile = db.query(PlayerProfile).filter(PlayerProfile.user_id == player_user.id).first()
        career = services.get_player_career_history(db, profile.id)
        print(f"Career Records: {len(career.career_history)}")
        for rec in career.career_history:
             print(f" - {rec.club_name} | {rec.team_name} | {rec.status}")
        
        db.commit()
    finally:
        db.close()
        engine.dispose()
        # Clean up
        try:
            if os.path.exists("test_club.db"):
                os.remove("test_club.db")
        except:
            pass

if __name__ == "__main__":
    verify()
