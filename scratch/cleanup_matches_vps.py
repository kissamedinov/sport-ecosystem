import uuid
from app.database import SessionLocal
from app.matches.models import Match, MatchResult, MatchLineup, MatchLineupPlayer, MatchEvent, MatchPlayerStats, MatchAward

db = SessionLocal()
try:
    t_id = uuid.UUID("cb521583-b9e2-442f-8938-47ab625aee12")
    match_ids = [m.id for m in db.query(Match).filter(Match.tournament_id == t_id).all()]
    print(f"Found {len(match_ids)} matches to clean up")
    if match_ids:
        # Delete related child records first to satisfy FK constraints
        db.query(MatchAward).filter(MatchAward.match_id.in_(match_ids)).delete(synchronize_session=False)
        db.query(MatchEvent).filter(MatchEvent.match_id.in_(match_ids)).delete(synchronize_session=False)
        db.query(MatchPlayerStats).filter(MatchPlayerStats.match_id.in_(match_ids)).delete(synchronize_session=False)
        
        # Lineups
        lineup_ids = [l.id for l in db.query(MatchLineup).filter(MatchLineup.match_id.in_(match_ids)).all()]
        if lineup_ids:
            db.query(MatchLineupPlayer).filter(MatchLineupPlayer.lineup_id.in_(lineup_ids)).delete(synchronize_session=False)
            db.query(MatchLineup).filter(MatchLineup.id.in_(lineup_ids)).delete(synchronize_session=False)
            
        db.query(MatchResult).filter(MatchResult.match_id.in_(match_ids)).delete(synchronize_session=False)
        db.query(Match).filter(Match.id.in_(match_ids)).delete(synchronize_session=False)
        db.commit()
        print("Cleanup completed successfully")
except Exception as e:
    print(f"Error during cleanup: {e}")
finally:
    db.close()
