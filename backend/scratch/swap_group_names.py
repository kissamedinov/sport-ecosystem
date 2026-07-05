from app.database import SessionLocal
from app.tournaments.models import TournamentGroup
from uuid import UUID

db = SessionLocal()

group_a_id = UUID('633957a0-2376-49a9-a3cf-4360bf7fee32')
group_b_id = UUID('1d2eb51b-112a-4681-94ce-55a4e1546b75')

try:
    g_a = db.query(TournamentGroup).filter(TournamentGroup.id == group_a_id).first()
    g_b = db.query(TournamentGroup).filter(TournamentGroup.id == group_b_id).first()
    
    if g_a and g_b:
        print(f"Current names: A={g_a.name}, B={g_b.name}")
        g_a.name = "Group B"
        g_b.name = "Group A"
        db.commit()
        print(f"Updated names: A={g_a.name}, B={g_b.name}")
    else:
        print("Groups not found!")
except Exception as e:
    db.rollback()
    print(f"Error swapping group names: {e}")
finally:
    db.close()
