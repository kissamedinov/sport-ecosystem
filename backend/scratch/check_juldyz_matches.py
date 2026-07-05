from app.database import SessionLocal
from app.matches.models import Match
from app.tournaments.models import Tournament
from uuid import UUID

db = SessionLocal()

for t_name in ["Juldyz Test", "Juldyz Ball", "Juldyz Ball Cup"]:
    t = db.query(Tournament).filter(Tournament.name == t_name).first()
    if t:
        count = db.query(Match).filter(Match.tournament_id == t.id).count()
        print(f"Tournament: name={t_name} id={t.id} match_count={count}")
    else:
        print(f"Tournament {t_name} not found")
        
db.close()
