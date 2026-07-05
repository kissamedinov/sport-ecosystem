import os
from uuid import UUID
from sqlalchemy import select
from sqlalchemy.orm import Session
from app.database import SessionLocal
from app.tournaments.models import Tournament
from app.matches.models import Match

def main():
    db = SessionLocal()
    try:
        tournaments = db.query(Tournament).order_by(Tournament.created_at.desc()).limit(5).all()
        print("LAST 5 TOURNAMENTS:")
        for t in tournaments:
            match_count = db.query(Match).filter(Match.tournament_id == t.id).count()
            group_match_count = db.query(Match).filter(Match.tournament_id == t.id, Match.group_id != None).count()
            playoff_match_count = db.query(Match).filter(Match.tournament_id == t.id, Match.group_id == None).count()
            print(f"ID: {t.id} | Name: {t.name} | Format: {t.format} | Matches: {match_count} (Groups: {group_match_count}, Playoff: {playoff_match_count})")
    finally:
        db.close()

if __name__ == '__main__':
    main()
