import uuid
from sqlalchemy import create_engine
from sqlalchemy.orm import sessionmaker
from app.database import Base
from app.tournaments.models import (
    TournamentSeries, Tournament, TournamentDivision, 
    TournamentTeam, Season, TournamentFormat, RegistrationStatus
)
from app.matches.models import Match, MatchStatus
from app.users.models import User
from app.teams.models import Team
from datetime import date, datetime
from app.tournaments.services import generate_knockout_schedule, update_match_result

SQLALCHEMY_DATABASE_URL = "postgresql://postgres:postgres@localhost:5432/sportseco"
engine = create_engine(SQLALCHEMY_DATABASE_URL)
SessionLocal = sessionmaker(autocommit=False, autoflush=False, bind=engine)
db = SessionLocal()

def test_playoff_bracket():
    print("Testing Playoff Bracket Generation & Advancement...")
    
    # 1. Create Organizer
    organizer = db.query(User).filter(User.email == "test_org@test.com").first()
    if not organizer:
        organizer = User(name="Test Organizer", email="test_org@test.com", password_hash="hash")
        db.add(organizer)
        db.flush()

    # 2. Create Series
    series = TournamentSeries(
        name="Test Series", 
        organizer_id=organizer.id, 
        city="Astana", 
        description="Test Bracket League"
    )
    db.add(series)
    db.flush()

    # 3. Create Edition (Knockout format)
    edition = Tournament(
        series_id=series.id,
        name="Knockout Cup 2026",
        year=2026,
        season=Season.SPRING,
        location="Astana Arena",
        start_date=date(2026, 4, 1),
        end_date=date(2026, 4, 5),
        registration_open=date(2026, 3, 1),
        registration_close=date(2026, 3, 31),
        format=TournamentFormat.KNOCKOUT,
        num_fields=2,
        match_half_duration=15,
        halftime_break_duration=5,
        break_between_matches=5,
        created_by=organizer.id,
        age_category="2016"
    )
    db.add(edition)
    db.flush()

    # 4. Create Division
    division = TournamentDivision(
        tournament_edition_id=edition.id,
        birth_year=2016,
        max_teams=8
    )
    db.add(division)
    db.flush()

    # 5. Create 5 approved Teams
    teams = []
    for i in range(5):
        team = Team(name=f"Team {i+1}", birth_year=2016, coach_id=organizer.id)
        db.add(team)
        db.flush()
        teams.append(team)
        
        reg = TournamentTeam(
            division_id=division.id,
            tournament_id=edition.id,
            team_id=team.id,
            registered_by=organizer.id,
            status=RegistrationStatus.APPROVED
        )
        db.add(reg)
        db.flush()
    
    print("5 teams registered and approved.")

    # 6. Generate Bracket
    res = generate_knockout_schedule(db, edition.id)
    print(f"Generation Result: {res}")
    
    # 7. Check generated matches
    matches = db.query(Match).filter(Match.tournament_id == edition.id).order_by(Match.round_number.desc(), Match.bracket_position).all()
    print(f"Total generated matches: {len(matches)}")
    for m in matches:
        print(f"Match ID: {m.id} | Round: {m.round_number} | Pos: {m.bracket_position} | Home: {m.home_team.name if m.home_team else 'BYE/TBD'} | Away: {m.away_team.name if m.away_team else 'BYE/TBD'} | Next Match: {m.next_match_id}")

    # For 5 teams:
    # K = 4, has_preliminary = True, max_round = 3 (Finals).
    # Round 1: 1 match (Team 1 vs Team 2).
    # Round 2: 2 matches.
    #   - Match 0: Home is Winner of Round 1 Match 0, Away is Team 3.
    #   - Match 1: Home is Team 4, Away is Team 5.
    # Round 3: 1 match (Finals).
    
    # Let's find Round 1 Match 0:
    r1_match = [m for m in matches if m.round_number == 1 and m.bracket_position == 0][0]
    print(f"\nSimulating Round 1 Match 0: {r1_match.home_team.name} vs {r1_match.away_team.name}")
    
    # Set result (home team wins)
    update_match_result(db, r1_match.id, home_score=2, away_score=1)
    
    # Check if the winner advanced to Round 2 Match 0 (Home slot, because bracket_position of r1_match is 0)
    db.expire_all()
    r2_match_0 = db.query(Match).filter(Match.tournament_id == edition.id, Match.round_number == 2, Match.bracket_position == 0).first()
    print(f"Round 2 Match 0 Home Team: {r2_match_0.home_team.name if r2_match_0.home_team else 'TBD'}")
    
    if r2_match_0.home_team_id == r1_match.home_team_id:
        print("SUCCESS: Winner successfully advanced to next round home slot!")
    else:
        print("FAILURE: Winner did not advance correctly.")
        
    db.rollback()
    print("Test complete. Rolled back changes.")

if __name__ == "__main__":
    test_playoff_bracket()
