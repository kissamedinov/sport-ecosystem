from app.database import SessionLocal
from app.tournaments.models import Tournament
from uuid import UUID

db = SessionLocal()
T_ID = UUID('46bdeb91-c2cd-43b9-9a4e-35892b3d1652')
t = db.query(Tournament).filter(Tournament.id == T_ID).first()
print(f"Tournament attributes:")
for attr in ['owner_id', 'created_by', 'organizer_id', 'creator_id']:
    print(f"  {attr}: {hasattr(t, attr)} (value={getattr(t, attr, None)})")
db.close()
