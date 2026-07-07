from app.database import SessionLocal
from app.tournaments.models import Tournament, TournamentSeries

db = SessionLocal()

print("--- TOURNAMENT SERIES ---")
series = db.query(TournamentSeries).all()
for s in series:
    print(f"Series ID: {s.id} | Name: {s.name} | City: {s.city}")

print("\n--- TOURNAMENTS ---")
tournaments = db.query(Tournament).all()
for t in tournaments:
    print(f"Tournament ID: {t.id} | Name: {t.name} | Series ID: {t.series_id} | Location: {t.location} | Format: {t.format}")

db.close()
