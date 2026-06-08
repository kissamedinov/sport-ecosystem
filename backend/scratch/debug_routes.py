import os
from dotenv import load_dotenv
from uuid import UUID

from app.database import SessionLocal
from app.academies import services

load_dotenv()
db = SessionLocal()
try:
    academy_id = UUID("3e6e81de-1b98-4894-a569-cda6e03b4558")
    user_id = UUID("dd156779-2313-4a8a-babf-7fe6281d0199")
    
    print("Testing get_academy_teams:")
    teams = services.get_academy_teams(db, academy_id, user_id=user_id)
    print(f"Returned teams count: {len(teams)}")
    for t in teams:
        print(f"  - Team: {t.name} (id: {t.id}), academy_id: {t.academy_id}")

    print("\nTesting get_academy_players:")
    players = services.get_academy_players(db, academy_id, user_id=user_id)
    print(f"Returned players count: {len(players)}")
    for p in players:
        print(f"  - Player ID: {p.id}, status: {p.status}")
finally:
    db.close()
