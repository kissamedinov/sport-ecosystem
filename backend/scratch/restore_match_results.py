from app.database import SessionLocal
from app.matches.models import Match, MatchResult, ResultStatus
from uuid import UUID, uuid4
from datetime import datetime

db = SessionLocal()

# Tournaments creator ID to satisfy the non-null constraint
ORGANIZER_ID = UUID('56cfe898-95f0-4736-bbe3-131a6e9d2c4f')

# Map of match_id -> (home_score, away_score, status)
match_updates = {
    # Group A
    UUID('77e93d1f-fb63-466d-bffd-19dcbb2ff80c'): (5, 3, 'FINISHED'),  # Legacy vs Elsana
    UUID('8414a233-d932-4c74-9aec-6809296fb3ff'): (6, 0, 'FINISHED'),  # Legacy vs FC ASU 1
    UUID('d0668674-8a5b-4777-b2aa-efdf61a618d8'): (0, 3, 'FINISHED'),  # Elsana vs Fc Arda
    UUID('5e8e355b-4618-44ca-8f44-af9cd7f31626'): (4, 1, 'FINISHED'),  # Fc Arda vs FC ASU 1
    UUID('07cbb9ab-6315-45c5-974c-13b3d4e63e0d'): (0, 0, 'SCHEDULED'), # Elsana vs FC ASU 1
    UUID('a7ee4deb-9d28-4ac2-878a-627155824e2b'): (0, 0, 'SCHEDULED'), # Fc Arda vs Legacy

    # Group B
    UUID('f0e7e16e-97b4-4570-8250-b6333a7ecbaf'): (1, 5, 'FINISHED'),  # IM vs Commandos
    UUID('a147aeca-36a3-4d98-b0f7-bb994951f0a4'): (3, 0, 'FINISHED'),  # Sairan vs IM
    UUID('25ecfd79-e535-4087-8ba0-51d79eaf7747'): (5, 4, 'FINISHED'),  # Commandos vs Sairan
    UUID('3ebf5326-d36b-480e-b78f-5101c95286d2'): (0, 1, 'FINISHED'),  # IM vs Kultegin
    UUID('53d92058-bc7e-4389-9cf5-2d0890283d25'): (0, 1, 'FINISHED'),  # Commandos vs Kultegin
    UUID('5ffd4fcc-ea11-464a-989d-b3ff45ad9a62'): (0, 1, 'FINISHED'),  # Sairan vs Kultegin
}

try:
    for m_id, (h_score, a_score, m_status) in match_updates.items():
        m = db.query(Match).filter(Match.id == m_id).first()
        if m:
            print(f"Updating match {m_id} ({m_status})")
            m.home_score = h_score
            m.away_score = a_score
            m.status = m_status
            
            # Delete any existing MatchResult for this match first
            db.query(MatchResult).filter(MatchResult.match_id == m_id).delete()
            
            # If finished, create a MatchResult record
            if m_status == 'FINISHED':
                db.add(MatchResult(
                    id=uuid4(),
                    match_id=m_id,
                    home_score=h_score,
                    away_score=a_score,
                    status=ResultStatus.FINAL,
                    submitted_by=ORGANIZER_ID,
                    created_at=datetime.utcnow()
                ))
        else:
            print(f"Match {m_id} not found in database!")
            
    db.commit()
    print("Successfully restored all match records and results in database!")
except Exception as e:
    db.rollback()
    print(f"Error during restore: {e}")
finally:
    db.close()
