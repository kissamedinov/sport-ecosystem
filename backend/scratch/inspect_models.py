from app.database import SessionLocal
from app.tournaments.models import TournamentTeam, TournamentStandings, TournamentGroup, TournamentGroupTeam
from app.matches.models import Match
from uuid import UUID

db = SessionLocal()
print("TournamentTeam cols:", [c.name for c in TournamentTeam.__table__.columns])
print("TournamentStandings cols:", [c.name for c in TournamentStandings.__table__.columns])
print("TournamentGroup cols:", [c.name for c in TournamentGroup.__table__.columns])
print("TournamentGroupTeam cols:", [c.name for c in TournamentGroupTeam.__table__.columns])
print("Match cols:", [c.name for c in Match.__table__.columns])
db.close()
