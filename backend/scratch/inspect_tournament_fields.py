from app.database import SessionLocal
from app.tournaments.models import Tournament
from uuid import UUID

db = SessionLocal()
T_ID = UUID('46bdeb91-c2cd-43b9-9a4e-35892b3d1652')

t = db.query(Tournament).filter(Tournament.id == T_ID).first()
if t:
    print(f"Tournament: id={t.id} name={t.name} stage={t.stage} status={t.status}")
else:
    print("Tournament not found")
    
db.close()
