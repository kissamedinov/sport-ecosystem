import sys
import os

# Add backend directory to sys.path
backend_dir = "/root/sport-ecosystem/backend"
sys.path.append(backend_dir)

from app.database import SessionLocal
from app.matches.models import Match, MatchResult
from app.teams.models import Team

db = SessionLocal()
try:
    matches = db.query(Match).all()
    print("Found matches in database:")
    for m in matches:
        home = db.query(Team).filter(Team.id == m.home_team_id).first()
        away = db.query(Team).filter(Team.id == m.away_team_id).first()
        home_name = home.name if home else 'None'
        away_name = away.name if away else 'None'
        
        home_score = m.result.home_score if m.result else 0
        away_score = m.result.away_score if m.result else 0
        print(f"Match ID: {m.id} | Status: {m.status} | Home: {home_name} | Away: {away_name} | Score: {home_score}:{away_score}")
        
        if m.status in ['FINISHED', 'LIVE']:
            print(f"--> Resetting match {m.id} status to SCHEDULED")
            m.status = "SCHEDULED"
            if m.result:
                print(f"    Deleting MatchResult {m.result.id}")
                db.delete(m.result)
            
    db.commit()
    print("Database committed successfully.")
finally:
    db.close()
