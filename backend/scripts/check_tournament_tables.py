from app.database import engine
import sqlalchemy as sa

def check_tournament_tables():
    print("Listing all tournament-related tables...")
    inspector = sa.inspect(engine)
    all_tables = inspector.get_table_names()
    
    tournament_tables = [
        "tournaments",
        "tournament_registrations",
        "tournament_teams",
        "tournament_squads",
        "tournament_groups",
        "tournament_group_teams",
        "tournament_standings",
        "schedule_tasks"
    ]
    
    missing = []
    found = []
    for table in tournament_tables:
        if table in all_tables:
            found.append(table)
        else:
            missing.append(table)
            
    print(f"Tables FOUND: {found}")
    print(f"Tables MISSING: {missing}")
    
    if "tournaments" in found:
        columns = [c['name'] for c in inspector.get_columns('tournaments')]
        print(f"Columns in 'tournaments': {columns}")

if __name__ == "__main__":
    check_tournament_tables()
