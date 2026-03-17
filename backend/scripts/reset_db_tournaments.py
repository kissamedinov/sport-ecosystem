from app.database import engine, Base
from app.tournaments.models import Tournament, TournamentRegistration, TournamentTeam, TournamentSquad, TournamentGroup, TournamentGroupTeam, TournamentStandings, ScheduleTask
import sqlalchemy as sa

def reset_tournament_schema():
    print("Resetting tournament schema...")
    inspector = sa.inspect(engine)
    
    # Tables to drop in order (respecting foreign keys)
    tables_to_drop = [
        "tournament_standings",
        "tournament_group_teams",
        "tournament_groups",
        "tournament_squads",
        "tournament_teams",
        "tournament_registrations",
        "schedule_tasks",
        "tournaments"
    ]
    
    with engine.connect() as conn:
        trans = conn.begin()
        try:
            for table in tables_to_drop:
                if table in inspector.get_table_names():
                    print(f"Dropping table: {table}")
                    conn.execute(sa.text(f'DROP TABLE IF EXISTS "{table}" CASCADE'))
            trans.commit()
            print("Tables dropped successfully.")
        except Exception as e:
            trans.rollback()
            print(f"Error dropping tables: {e}")
            return

    print("Recreating tables...")
    Base.metadata.create_all(bind=engine)
    print("Tournament schema successfully synchronized!")

if __name__ == "__main__":
    reset_tournament_schema()
