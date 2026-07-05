from app.database import SessionLocal
from app.matches.models import Match, MatchResult, ResultStatus
from app.tournaments.models import TournamentStandings
from app.matches.services import finalize_match_result
from uuid import UUID, uuid4
from datetime import datetime
from sqlalchemy import text

db = SessionLocal()
T_ID = UUID('46bdeb91-c2cd-43b9-9a4e-35892b3d1652')
ORGANIZER_ID = UUID('56cfe898-95f0-4736-bbe3-131a6e9d2c4f')

# The 4 actual unplayed group stage matches
unplayed_matches = [
    (UUID('53d92058-bc7e-4389-9cf5-2d0890283d25'), 1, 2),  # Commandos vs Kultegin -> 1 : 2
    (UUID('3ebf5326-d36b-480e-b78f-5101c95286d2'), 0, 3),  # IM vs Kultegin -> 0 : 3
    (UUID('5ffd4fcc-ea11-464a-989d-b3ff45ad9a62'), 2, 2),  # Sairan vs Kultegin -> 2 : 2
    (UUID('a7ee4deb-9d28-4ac2-878a-627155824e2b'), 1, 1),  # Fc Arda vs Legacy -> 1 : 1
]

print("=== STARTING DRY-RUN SIMULATION OF AUTOMATIC PLAYOFF TRANSITION ===")

try:
    # Delete any existing results for these unplayed matches just in case
    for m_id, _, _ in unplayed_matches:
        db.query(MatchResult).filter(MatchResult.match_id == m_id).delete()
    db.flush()

    # 1. Play the 4 unplayed matches
    for idx, (m_id, home_s, away_s) in enumerate(unplayed_matches, 1):
        m = db.query(Match).filter(Match.id == m_id).first()
        h_name = db.execute(text("SELECT name FROM teams WHERE id = :tid"), {"tid": m.home_team_id}).scalar()
        a_name = db.execute(text("SELECT name FROM teams WHERE id = :tid"), {"tid": m.away_team_id}).scalar()
        print(f"\n{idx}. Simulating match '{h_name} vs {a_name}' ending with score {home_s} : {away_s}...")
        m.home_score = home_s
        m.away_score = away_s
        db.add(MatchResult(
            id=uuid4(),
            match_id=m_id,
            home_score=home_s,
            away_score=away_s,
            status=ResultStatus.FINAL,
            submitted_by=ORGANIZER_ID,
            created_at=datetime.utcnow()
        ))
        db.flush()
        finalize_match_result(db, m_id)
    
    # 2. Check if playoff matches are automatically seeded and scheduled
    print("\n[VERIFICATION] Group stage finished. Checking automatically seeded playoff matches (1/2, 5-6, 7-8 places):")
    playoffs = db.query(Match).filter(Match.tournament_id == T_ID, Match.group_id == None, Match.round_number == 1).order_by(Match.bracket_position).all()
    for m in playoffs:
        h_name = db.execute(text("SELECT name FROM teams WHERE id = :tid"), {"tid": m.home_team_id}).scalar()
        a_name = db.execute(text("SELECT name FROM teams WHERE id = :tid"), {"tid": m.away_team_id}).scalar()
        stage = "Semifinal 1" if m.bracket_position == 0 else "Semifinal 2" if m.bracket_position == 1 else "5-6th Place" if m.bracket_position == 2 else "7-8th Place"
        print(f"  {stage} (ID: {m.id}): {h_name} vs {a_name} -> status={m.status}")

    # 3. Play Semifinals
    sf1_id = playoffs[0].id
    sf2_id = playoffs[1].id
    
    # Clear any old results for these just in case
    db.query(MatchResult).filter(MatchResult.match_id == sf1_id).delete()
    db.query(MatchResult).filter(MatchResult.match_id == sf2_id).delete()
    db.flush()

    print(f"\n5. Simulating Semifinal 1 (SF1) finishing with score 3 : 2...")
    db.add(MatchResult(
        id=uuid4(),
        match_id=sf1_id,
        home_score=3,
        away_score=2,
        status=ResultStatus.FINAL,
        submitted_by=ORGANIZER_ID,
        created_at=datetime.utcnow()
    ))
    db.flush()
    finalize_match_result(db, sf1_id)

    print(f"\n6. Simulating Semifinal 2 (SF2) finishing with score 0 : 2...")
    db.add(MatchResult(
        id=uuid4(),
        match_id=sf2_id,
        home_score=0,
        away_score=2,
        status=ResultStatus.FINAL,
        submitted_by=ORGANIZER_ID,
        created_at=datetime.utcnow()
    ))
    db.flush()
    finalize_match_result(db, sf2_id)
    
    # 4. Check if Final and 3rd Place are updated and scheduled
    print("\n[VERIFICATION] Semifinals finished. Checking automatically seeded Final and 3rd Place matches:")
    finals = db.query(Match).filter(Match.tournament_id == T_ID, Match.group_id == None, Match.round_number == 2).order_by(Match.bracket_position).all()
    for m in finals:
        h_name = db.execute(text("SELECT name FROM teams WHERE id = :tid"), {"tid": m.home_team_id}).scalar()
        a_name = db.execute(text("SELECT name FROM teams WHERE id = :tid"), {"tid": m.away_team_id}).scalar()
        stage = "Final Match 🏆" if m.bracket_position == 0 else "3rd Place Match 🥉"
        print(f"  {stage} (ID: {m.id}): {h_name} vs {a_name} -> status={m.status}")

    print("\n=== SIMULATION COMPLETED SUCCESSFULY. ROLLING BACK TRANSACTION... ===")
except Exception as e:
    print(f"\nError during simulation: {e}")
finally:
    db.rollback()
    db.close()
