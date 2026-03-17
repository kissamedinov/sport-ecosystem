import uuid
from sqlalchemy import create_engine
from sqlalchemy.orm import sessionmaker
from app.database import Base
from app.tournaments.models import (
    TournamentSeries, Tournament, TournamentDivision, 
    TournamentTeam, TournamentMatch, MatchStatus, 
    TournamentPlayerStats, TournamentAward, Season, TournamentFormat
)
from app.users.models import User, Role, PlayerProfile
from app.teams.models import Team
from datetime import date, datetime

# Setup Test DB (or use existing)
SQLALCHEMY_DATABASE_URL = "postgresql://postgres:postgres@localhost/postgres" # Adjust as needed
engine = create_engine(SQLALCHEMY_DATABASE_URL)
SessionLocal = sessionmaker(autocommit=False, autoflush=False, bind=engine)
db = SessionLocal()

def verify_hierarchy():
    print("Testing Tournament Hierarchy...")
    
    # 1. Create Organizer
    organizer = db.query(User).filter(User.email == "org@test.com").first()
    if not organizer:
        organizer = User(name="Organizer", email="org@test.com", password_hash="hash")
        db.add(organizer)
        db.flush()

    # 2. Create Series
    series = TournamentSeries(
        name="AKFL", 
        organizer_id=organizer.id, 
        city="Astana", 
        description="Elite Youth League"
    )
    db.add(series)
    db.flush()
    print(f"Created Series: {series.name}")

    # 3. Create Edition
    edition = Tournament(
        series_id=series.id,
        name="AKFL 2026 Spring",
        year=2026,
        season=Season.SPRING,
        location="Central Stadium",
        start_date=date(2026, 4, 1),
        end_date=date(2026, 6, 1),
        registration_open=date(2026, 3, 1),
        registration_close=date(2026, 3, 31),
        format=TournamentFormat.LEAGUE
    )
    db.add(edition)
    db.flush()
    print(f"Created Edition: {edition.name}")

    # 4. Create Division
    division = TournamentDivision(
        tournament_edition_id=edition.id,
        birth_year=2015,
        max_teams=16
    )
    db.add(division)
    db.flush()
    print(f"Created Division for birth year: {division.birth_year}")

    # 5. Create Team & Register
    coach = db.query(User).filter(User.email == "coach@test.com").first()
    if not coach:
        coach = User(name="Coach", email="coach@test.com", password_hash="hash")
        db.add(coach)
        db.flush()

    team = Team(name="Kairat 2015", coach_id=coach.id, birth_year=2015)
    db.add(team)
    db.flush()

    reg = TournamentTeam(
        division_id=division.id,
        tournament_id=edition.id,
        team_id=team.id,
        registered_by=coach.id,
        status="APPROVED"
    )
    db.add(reg)
    db.flush()
    print(f"Registered Team: {team.name}")

    # 6. Record Match & Stats
    player_user = db.query(User).filter(User.email == "player@test.com").first()
    if not player_user:
        player_user = User(name="Young Star", email="player@test.com", password_hash="hash")
        db.add(player_user)
        db.flush()

    profile = db.query(PlayerProfile).filter(PlayerProfile.user_id == player_user.id).first()
    if not profile:
        profile = PlayerProfile(user_id=player_user.id)
        db.add(profile)
        db.flush()

    match = TournamentMatch(
        division_id=division.id,
        tournament_id=edition.id,
        home_team_id=team.id,
        away_team_id=team.id, # Dummy away
        status=MatchStatus.SCHEDULED
    )
    db.add(match)
    db.flush()

    from app.tournaments.services import record_match_player_stats
    record_match_player_stats(db, match.id, profile.id, {"goals": 2, "assists": 1})
    print("Recorded match stats: 2 goals, 1 assist")

    # 7. Verify Aggregated Stats
    agg_stats = db.query(TournamentPlayerStats).filter(
        TournamentPlayerStats.division_id == division.id,
        TournamentPlayerStats.player_profile_id == profile.id
    ).first()
    if agg_stats and agg_stats.goals == 2:
        print("SUCCESS: Aggregated stats updated correctly!")
    else:
        print("FAILURE: Aggregated stats mismatch.")

    # 8. Assign Award
    award = TournamentAward(
        division_id=division.id,
        player_profile_id=profile.id,
        title="Top Scorer",
        description="Scored most goals in AKFL 2015 division"
    )
    db.add(award)
    db.flush()
    print(f"Assigned Award: {award.title}")

    # 9. Verify Profile Integration
    db.refresh(profile)
    if any(a.title == "Top Scorer" for a in profile.awards):
        print("SUCCESS: Award visible in Player Profile!")
    else:
        print("FAILURE: Award not linked to profile.")

    db.rollback() # Clean up
    print("Verification Complete.")

if __name__ == "__main__":
    verify_hierarchy()
