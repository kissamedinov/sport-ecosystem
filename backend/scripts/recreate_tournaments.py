from app.database import engine, Base
# Explicitly import all models to ensure they are registered with Base
from app.tournaments.models import Tournament, TournamentRegistration, TournamentTeam, TournamentSquad, TournamentGroup, TournamentGroupTeam, TournamentStandings, ScheduleTask
import sqlalchemy as sa
import traceback

def recreate_tournaments():
    print("Manually recreating tournament tables...")
    try:
        # We use the specific classes to ensure they are the only ones being created if possible
        # or just call create_all on the metadata which now contains these tables.
        Base.metadata.create_all(bind=engine)
        print("Successfully called Base.metadata.create_all")
        
        # Verify
        inspector = sa.inspect(engine)
        tables = inspector.get_table_names()
        if "tournaments" in tables:
            print("SUCCESS: 'tournaments' table now exists.")
        else:
            print("FAILURE: 'tournaments' table still missing after create_all!")
            
    except Exception as e:
        print("ERROR during creation:")
        print(traceback.format_exc())

if __name__ == "__main__":
    recreate_tournaments()
