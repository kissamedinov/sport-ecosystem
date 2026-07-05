from app.database import SessionLocal
from app.tournaments.models import TournamentStandings
from uuid import UUID

db = SessionLocal()
T_ID = UUID('46bdeb91-c2cd-43b9-9a4e-35892b3d1652')
KULTEGIN_TEAM_ID = UUID('548ee50c-449d-461e-a37c-1db07cd3fbe0')

st = db.query(TournamentStandings).filter(
    TournamentStandings.tournament_id == T_ID,
    TournamentStandings.team_id == KULTEGIN_TEAM_ID
).first()

if st:
    print("Updating Kultegin standings values to match restored match results...")
    st.played = 3
    st.wins = 3
    st.draws = 0
    st.losses = 0
    st.goals_for = 3
    st.goals_against = 0
    st.goal_difference = 3
    st.points = 9
    db.commit()
    print("Updated successfully!")
else:
    print("Kultegin standing row not found!")
    
db.close()
