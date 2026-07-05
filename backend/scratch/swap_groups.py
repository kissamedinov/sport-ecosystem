from app.database import SessionLocal
from app.tournaments.models import TournamentGroup, TournamentGroupTeam, TournamentStandings
from app.matches.models import Match
from uuid import UUID

db = SessionLocal()

TOURNAMENT_ID = UUID('46bdeb91-c2cd-43b9-9a4e-35892b3d1652')
group_a_id = UUID('633957a0-2376-49a9-a3cf-4360bf7fee32')
group_b_id = UUID('1d2eb51b-112a-4681-94ce-55a4e1546b75')
temp_group_id = UUID('99999999-9999-9999-9999-999999999999')

try:
    # 1. Create a temporary group to satisfy FK constraints
    temp_group = TournamentGroup(id=temp_group_id, tournament_id=TOURNAMENT_ID, name="Temp Group")
    db.add(temp_group)
    db.flush() # flush to database so the ID exists before updates

    # 2. Update TournamentGroupTeam
    r1 = db.query(TournamentGroupTeam).filter(TournamentGroupTeam.group_id == group_a_id).update({TournamentGroupTeam.group_id: temp_group_id})
    r2 = db.query(TournamentGroupTeam).filter(TournamentGroupTeam.group_id == group_b_id).update({TournamentGroupTeam.group_id: group_a_id})
    r3 = db.query(TournamentGroupTeam).filter(TournamentGroupTeam.group_id == temp_group_id).update({TournamentGroupTeam.group_id: group_b_id})
    print(f"TournamentGroupTeam updated: {r1}, {r2}, {r3}")

    # 3. Update TournamentStandings
    s1 = db.query(TournamentStandings).filter(TournamentStandings.group_id == group_a_id).update({TournamentStandings.group_id: temp_group_id})
    s2 = db.query(TournamentStandings).filter(TournamentStandings.group_id == group_b_id).update({TournamentStandings.group_id: group_a_id})
    s3 = db.query(TournamentStandings).filter(TournamentStandings.group_id == temp_group_id).update({TournamentStandings.group_id: group_b_id})
    print(f"TournamentStandings updated: {s1}, {s2}, {s3}")

    # 4. Update Match
    m1 = db.query(Match).filter(Match.group_id == group_a_id).update({Match.group_id: temp_group_id})
    m2 = db.query(Match).filter(Match.group_id == group_b_id).update({Match.group_id: group_a_id})
    m3 = db.query(Match).filter(Match.group_id == temp_group_id).update({Match.group_id: group_b_id})
    print(f"Match updated: {m1}, {m2}, {m3}")

    # 5. Delete temporary group
    db.delete(temp_group)
    
    db.commit()
    print("Swap transaction committed successfully with temporary group!")
except Exception as e:
    db.rollback()
    print(f"Error during swap: {e}")
finally:
    db.close()
