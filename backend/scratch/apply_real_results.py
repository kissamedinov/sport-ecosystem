from app.database import SessionLocal
from app.matches.models import Match, MatchResult, ResultStatus
from app.matches.services import finalize_match_result
from uuid import UUID, uuid4
from datetime import datetime
from sqlalchemy import text

db = SessionLocal()
T_ID = UUID('46bdeb91-c2cd-43b9-9a4e-35892b3d1652')
ORGANIZER_ID = UUID('56cfe898-95f0-4736-bbe3-131a6e9d2c4f')

# Real match results submitted by the user this morning
real_results = [
    (UUID('3ebf5326-d36b-480e-b78f-5101c95286d2'), 0, 1),  # IM vs Kultegin -> 0 : 1
    (UUID('5ffd4fcc-ea11-464a-989d-b3ff45ad9a62'), 2, 2),  # Sairan vs Kultegin -> 2 : 2
    (UUID('a7ee4deb-9d28-4ac2-878a-627155824e2b'), 1, 1),  # Fc Arda vs Legacy -> 1 : 1
    (UUID('53d92058-bc7e-4389-9cf5-2d0890283d25'), 3, 2),  # Commandos vs Kultegin -> 3 : 2
]

try:
    print("Applying user's actual group stage results...")
    for idx, (m_id, home_s, away_s) in enumerate(real_results, 1):
        m = db.query(Match).filter(Match.id == m_id).first()
        h_name = db.execute(text("SELECT name FROM teams WHERE id = :tid"), {"tid": m.home_team_id}).scalar()
        a_name = db.execute(text("SELECT name FROM teams WHERE id = :tid"), {"tid": m.away_team_id}).scalar()
        print(f"\nFinalizing match {idx}/4: '{h_name} vs {a_name}' with score {home_s} : {away_s}...")
        
        m.home_score = home_s
        m.away_score = away_s
        
        # Check if MatchResult already exists
        res = db.query(MatchResult).filter(MatchResult.match_id == m_id).first()
        if res:
            res.home_score = home_s
            res.away_score = away_s
            res.status = ResultStatus.FINAL
            print("  Updated existing MatchResult.")
        else:
            db.add(MatchResult(
                id=uuid4(),
                match_id=m_id,
                home_score=home_s,
                away_score=away_s,
                status=ResultStatus.FINAL,
                submitted_by=ORGANIZER_ID,
                created_at=datetime.utcnow()
            ))
            print("  Created new MatchResult.")
            
        db.flush()
        finalize_match_result(db, m_id)
        
    db.commit()
    print("\nAll actual group stage results successfully applied!")
    
    # Verify the automatically seeded playoff matches
    print("\n--- VERIFYING AUTOMATICALLY SEEDED PLAYOFF MATCHES ---")
    playoffs = db.query(Match).filter(Match.tournament_id == T_ID, Match.group_id == None, Match.round_number == 1).order_by(Match.bracket_position).all()
    for m in playoffs:
        h_name = db.execute(text("SELECT name FROM teams WHERE id = :tid"), {"tid": m.home_team_id}).scalar()
        a_name = db.execute(text("SELECT name FROM teams WHERE id = :tid"), {"tid": m.away_team_id}).scalar()
        stage = "Semifinal 1" if m.bracket_position == 0 else "Semifinal 2" if m.bracket_position == 1 else "5-6th Place" if m.bracket_position == 2 else "7-8th Place"
        print(f"  {stage}: {h_name} vs {a_name} -> status={m.status}")

except Exception as e:
    db.rollback()
    print(f"Error: {e}")
finally:
    db.close()
