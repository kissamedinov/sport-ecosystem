from app.database import SessionLocal
from app.matches.models import Match
from uuid import UUID

db = SessionLocal()
TOURNAMENT_ID = UUID('46bdeb91-c2cd-43b9-9a4e-35892b3d1652')

try:
    # 1. Update next_match_id = None on round 1 matches that point to round 2 pos 2/3
    updated = db.query(Match).filter(
        Match.tournament_id == TOURNAMENT_ID,
        Match.group_id.is_(None),
        Match.round_number == 1,
        Match.bracket_position.in_([2, 3])
    ).update({Match.next_match_id: None})
    print(f"Updated next_match_id to None for {updated} round 1 placement matches.")
    
    # 2. Delete round=2, pos=2 and pos=3 matches
    deleted = db.query(Match).filter(
        Match.tournament_id == TOURNAMENT_ID,
        Match.group_id.is_(None),
        Match.round_number == 2,
        Match.bracket_position.in_([2, 3])
    ).delete(synchronize_session=False)
    db.commit()
    print(f"Successfully deleted {deleted} extra playoff matches from DB!")
except Exception as e:
    db.rollback()
    print(f"Error: {e}")
finally:
    db.close()
