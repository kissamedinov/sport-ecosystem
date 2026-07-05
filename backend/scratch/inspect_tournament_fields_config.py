from app.database import SessionLocal
from app.tournaments.models import Tournament
from uuid import UUID

db = SessionLocal()
T_ID = UUID('46bdeb91-c2cd-43b9-9a4e-35892b3d1652')
t = db.query(Tournament).filter(Tournament.id == T_ID).first()
if t:
    print(f"Tournament {t.name}:")
    print(f"  num_fields={t.num_fields}")
    print(f"  field_ids={getattr(t, 'field_ids', 'No field_ids')}")
db.close()
