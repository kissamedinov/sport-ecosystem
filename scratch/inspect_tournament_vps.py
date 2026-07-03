import uuid
from app.database import SessionLocal
from app.tournaments.models import Tournament, TournamentTeam
from app.matches.models import Match
from app.teams.models import Team

db = SessionLocal()
try:
    t_id = uuid.UUID("cb521583-b9e2-442f-8938-47ab625aee12")
    tournament = db.query(Tournament).filter(Tournament.id == t_id).first()
    if not tournament:
        print("Tournament not found")
    else:
        print(f"Tournament Name: {tournament.name}")
        print(f"Format: {tournament.format}")
        print(f"Num Fields: {tournament.num_fields}")
        print(f"Field IDs: {getattr(tournament, 'field_ids', None)}")
        
        teams = db.query(TournamentTeam).filter(TournamentTeam.tournament_id == t_id).all()
        print(f"\nApproved Teams count: {len(teams)}")
        for tt in teams:
            team = db.query(Team).filter(Team.id == tt.team_id).first()
            print(f"  Team ID: {tt.team_id}, Name: {team.name if team else 'Unknown'}, Status: {tt.status}")
            
        matches = db.query(Match).filter(Match.tournament_id == t_id).order_by(Match.match_date).all()
        print(f"\nMatches count: {len(matches)}")
        for m in matches:
            home = db.query(Team).filter(Team.id == m.home_team_id).first()
            away = db.query(Team).filter(Team.id == m.away_team_id).first()
            home_name = home.name if home else "None"
            away_name = away.name if away else "None"
            print(f"  Match ID: {m.id}, Date: {m.match_date}, Round: {m.round_number}, Home: {home_name} ({m.home_team_id}), Away: {away_name} ({m.away_team_id}), Field: {m.field_id}")
finally:
    db.close()
