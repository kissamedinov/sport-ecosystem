from app.database import SessionLocal
from app.matches.models import Match
from app.tournaments.models import TournamentGroup
from uuid import UUID

db = SessionLocal()
TOURNAMENT_ID = UUID('46bdeb91-c2cd-43b9-9a4e-35892b3d1652')

# Get all groups
groups = db.query(TournamentGroup).filter(TournamentGroup.tournament_id == TOURNAMENT_ID).all()
print("Groups:")
for g in groups:
    print(f"  id={g.id}  name={g.name}")

# Get matches per group
group_ids = sorted([g.id for g in groups], key=str)
print(f"\nSorted group IDs:")
for i, gid in enumerate(group_ids):
    letter = chr(65 + i)  # A, B, C...
    matches = db.query(Match).filter(Match.group_id == gid).all()
    team_names = set()
    for m in matches:
        if m.home_team_id:
            team_names.add(str(m.home_team_id)[:8])
        if m.away_team_id:
            team_names.add(str(m.away_team_id)[:8])
    print(f"  ГРУППА {letter}: {gid}  (matches={len(matches)})")

db.close()
