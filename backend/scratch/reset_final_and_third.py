from app.database import SessionLocal
from app.matches.models import Match, MatchResult
from uuid import UUID

db = SessionLocal()
final_id = UUID('34f770c7-8cf4-42d2-8ab2-d6e50892e529')
third_id = UUID('6cf1685a-305d-4c9e-8e80-850f16795d17')

try:
    # 1. Reset Final Match
    f_match = db.query(Match).filter(Match.id == final_id).first()
    if f_match:
        f_match.status = 'SCHEDULED'
        f_match.home_team_id = None
        f_match.away_team_id = None
        f_match.home_score = 0
        f_match.away_score = 0
        print("Reset Final Match in DB.")
        
    db.query(MatchResult).filter(MatchResult.match_id == final_id).delete()
    
    # 2. Reset 3rd Place Match
    t_match = db.query(Match).filter(Match.id == third_id).first()
    if t_match:
        t_match.status = 'SCHEDULED'
        t_match.home_team_id = None
        t_match.away_team_id = None
        t_match.home_score = 0
        t_match.away_score = 0
        print("Reset 3rd Place Match in DB.")
        
    db.query(MatchResult).filter(MatchResult.match_id == third_id).delete()
    
    db.commit()
    print("Successfully committed reset!")
except Exception as e:
    db.rollback()
    print(f"Error: {e}")
finally:
    db.close()
