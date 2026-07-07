import uuid
from app.database import SessionLocal
from app.tournaments.models import Tournament, TournamentSeries

db = SessionLocal()

# 1. Create a tournament series
series_name = "Egida Regular Championship"
organizer_id = uuid.UUID("56cfe898-95f0-4736-bbe3-131a6e9d2c4f")
city = "Astana"
description = "Регулярный юношеский чемпионат под эгидой Egida"

print(f"Creating Tournament Series: {series_name}...")
new_series = TournamentSeries(
    id=uuid.uuid4(),
    name=series_name,
    organizer_id=organizer_id,
    city=city,
    description=description,
)
db.add(new_series)
db.flush() # Get the new_series ID

# 2. Associate "Juldyz Ball Cup" with this series
tournament_id = uuid.UUID("46bdeb91-c2cd-43b9-9a4e-35892b3d1652")
tournament = db.query(Tournament).filter(Tournament.id == tournament_id).first()

if tournament:
    print(f"Associating Tournament '{tournament.name}' (ID: {tournament.id}) with Series '{series_name}' (ID: {new_series.id})...")
    tournament.series_id = new_series.id
    db.commit()
    print("Success! Changes committed to database.")
else:
    print(f"Error: Tournament with ID {tournament_id} not found!")
    db.rollback()

db.close()
