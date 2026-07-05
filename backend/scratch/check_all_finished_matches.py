from app.database import SessionLocal
from app.matches.models import Match
from app.tournaments.models import Tournament

db = SessionLocal()

tournaments = db.query(Tournament).all()
for t in tournaments:
    finished_count = db.query(Match).filter(Match.tournament_id == t.id, Match.status == 'FINISHED').count()
    total_count = db.query(Match).filter(Match.tournament_id == t.id).count()
    print(f"Tournament: id={t.id} name={t.name} total_matches={total_count} finished_matches={finished_count}")
    
db.close()
