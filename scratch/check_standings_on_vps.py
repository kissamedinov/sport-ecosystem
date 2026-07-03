import uuid
from app.database import SessionLocal
from app.tournaments.models import Tournament, TournamentTeam, TournamentStandings, TournamentDivision
from app.teams.models import Team

db = SessionLocal()
try:
    t_id = uuid.UUID("cb521583-b9e2-442f-8938-47ab625aee12")
    tournament = db.query(Tournament).filter(Tournament.id == t_id).first()
    if not tournament:
        print("Tournament not found")
    else:
        print(f"Tournament Name: {tournament.name}")
        
        print("\nTournament Standings:")
        standings = db.query(TournamentStandings).filter(TournamentStandings.tournament_id == t_id).all()
        for s in standings:
            team = db.query(Team).filter(Team.id == s.team_id).first()
            div = db.query(TournamentDivision).filter(TournamentDivision.id == s.division_id).first()
            print(f"  Team: {team.name if team else 'Unknown'} ({s.team_id}), Division: {div.name if div else 'None'} ({s.division_id}), Played: {s.played}, Points: {s.points}")
            
        print("\nTournament Teams:")
        teams = db.query(TournamentTeam).filter(TournamentTeam.tournament_id == t_id).all()
        for tt in teams:
            team = db.query(Team).filter(Team.id == tt.team_id).first()
            div = db.query(TournamentDivision).filter(TournamentDivision.id == tt.division_id).first()
            print(f"  Team: {team.name if team else 'Unknown'} ({tt.team_id}), Status: {tt.status}, Division: {div.name if div else 'None'} ({tt.division_id})")
finally:
    db.close()
