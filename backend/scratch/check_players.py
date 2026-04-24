
import os
from dotenv import load_dotenv
from sqlalchemy import create_engine
from sqlalchemy.orm import sessionmaker
from app.users.models import User, UserRole, Role

load_dotenv()

SQLALCHEMY_DATABASE_URL = os.getenv("DATABASE_URL", "postgresql://postgres:postgres@localhost:5432/sportseco")
engine = create_engine(SQLALCHEMY_DATABASE_URL)
SessionLocal = sessionmaker(bind=engine)
db = SessionLocal()

try:
    player_roles = [Role.PLAYER_CHILD, Role.PLAYER_YOUTH]
    players = db.query(User).join(UserRole).filter(UserRole.role.in_(player_roles)).all()
    print(f"TOTAL PLAYERS FOUND: {len(players)}")
    for p in players:
        print(f"- {p.name} (ID: {p.id})")
finally:
    db.close()
