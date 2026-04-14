from app.database import SessionLocal
from app.academies.models import Academy, AcademyTeam, AcademyTeamPlayer, TrainingSession, TrainingSchedule, TrainingAttendance, AcademyBillingConfig
from app.teams.models import Team, TeamMembership, TeamRatingHistory
from app.clubs.models import Club, ClubStaff, ClubRequest
from app.users.models import User, PlayerProfile
from app.tournaments.models import Tournament, TournamentAward, TournamentMatch, TournamentStandings, TournamentRegistration
import uuid

def migrate():
    db = SessionLocal()
    try:
        academy_teams = db.query(AcademyTeam).all()
        print(f"Found {len(academy_teams)} academy teams to migrate.")
        
        for at in academy_teams:
            # 1. Check if tournament team exists
            existing = db.query(Team).filter(Team.name == at.name, Team.academy_id == at.academy_id).first()
            
            if not existing:
                print(f"Creating new team record for {at.name}...")
                new_team = Team(
                    id=at.id, 
                    name=at.name, 
                    academy_id=at.academy_id, 
                    coach_id=at.coach_id, 
                    birth_year=2013,  # Default, can be adjusted manually
                    division="Group A"
                )
                db.add(new_team)
                db.flush()
                target_team_id = new_team.id
            else:
                print(f"Syncing existing team record for {at.name}...")
                target_team_id = existing.id
            
            # 2. Migrate memberships
            for atp in at.players:
                # Check if already a member
                exists = db.query(TeamMembership).filter(
                    TeamMembership.team_id == target_team_id,
                    TeamMembership.player_profile_id == atp.player_profile_id
                ).first()
                
                if not exists:
                    m = TeamMembership(
                        team_id=target_team_id,
                        player_profile_id=atp.player_profile_id
                    )
                    db.add(m)
        
        db.commit()
        print("Migration complete perfectly.")
    except Exception as e:
        db.rollback()
        print(f"Migration failed: {e}")
    finally:
        db.close()

if __name__ == "__main__":
    migrate()
