from app.database import SessionLocal
from app.tournaments.models import Tournament
from app.tournaments.models import TournamentTeam
from app.teams.models import Team

db = SessionLocal()

tournaments = db.query(Tournament).all()
print("All Tournaments in DB:")
for t in tournaments:
    tt_count = db.query(TournamentTeam).filter(TournamentTeam.tournament_id == t.id).count()
    print(f"  id={t.id} name={t.name} teams_count={tt_count}")
    
db.close()
