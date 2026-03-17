from app.database import engine
import sqlalchemy as sa
import traceback

def force_create_tournaments():
    print("Forcing creation of 'tournaments' table using raw SQL...")
    
    # We use the exactly defined columns from models.py
    create_sql = """
    CREATE TABLE IF NOT EXISTS "tournaments" (
        id UUID PRIMARY KEY,
        name VARCHAR NOT NULL,
        location VARCHAR NOT NULL,
        start_date DATE NOT NULL,
        end_date DATE NOT NULL,
        registration_open DATE NOT NULL,
        registration_close DATE NOT NULL,
        format VARCHAR NOT NULL,
        age_category VARCHAR NOT NULL,
        num_fields INTEGER DEFAULT 1,
        match_half_duration INTEGER DEFAULT 20,
        halftime_break_duration INTEGER DEFAULT 5,
        break_between_matches INTEGER DEFAULT 10,
        start_time TIMESTAMP WITHOUT TIME ZONE,
        end_time TIMESTAMP WITHOUT TIME ZONE,
        minimum_rest_slots INTEGER DEFAULT 1,
        points_for_win INTEGER DEFAULT 3,
        points_for_draw INTEGER DEFAULT 1,
        points_for_loss INTEGER DEFAULT 0,
        status VARCHAR DEFAULT 'upcoming',
        created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
    );
    """
    
    with engine.connect() as conn:
        try:
            conn.execute(sa.text(create_sql))
            conn.commit()
            print("Successfully created 'tournaments' table.")
            
            # Now try to call create_all to handle other tables that might be missing
            from app.tournaments.models import Tournament, TournamentRegistration, TournamentTeam, TournamentSquad, TournamentGroup, TournamentGroupTeam, TournamentStandings, ScheduleTask
            from app.database import Base
            Base.metadata.create_all(bind=engine)
            print("Called create_all for remaining tables.")
            
        except Exception as e:
            print(f"FAILED: {e}")
            print(traceback.format_exc())

if __name__ == "__main__":
    force_create_tournaments()
