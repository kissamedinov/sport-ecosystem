
from app.database import engine, Base
# Import all models to make sure they are registered
from app.users.models import User, Role, UserRole, PlayerProfile
from app.teams.models import Team, TeamMembership
from app.academies.models import Academy
from app.tournaments.models import (
    Tournament, TournamentDivision, TournamentTeam, 
    TournamentStandings, TournamentGroup, TournamentGroupTeam,
    TournamentAward, TournamentPlayerStats, TournamentSeries,
    ScheduleTask
)
from app.matches.models import Match, MatchResult, MatchEvent

def create_tables():
    print("Creating all tables in the database...")
    try:
        Base.metadata.create_all(bind=engine)
        print("Successfully created/updated all tables!")
    except Exception as e:
        print(f"Error creating tables: {e}")

if __name__ == "__main__":
    create_tables()
