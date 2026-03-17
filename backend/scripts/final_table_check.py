from app.database import engine
import sqlalchemy as sa

def final_check():
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
    all_found = True
    for table in tournament_tables:
        if table in all_tables:
            print(f"OK: {table}")
        else:
            print(f"MISSING: {table}")
            all_found = False
    
    if all_found:
        print("RESULT: ALL TOURNAMENT TABLES OK")
    else:
        print("RESULT: MISSING TABLES DETECTED")

if __name__ == "__main__":
    final_check()
