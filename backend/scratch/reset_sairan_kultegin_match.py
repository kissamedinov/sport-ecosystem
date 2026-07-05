from app.database import SessionLocal
from app.matches.models import Match, MatchResult
from app.tournaments.models import TournamentStandings
from uuid import UUID

db = SessionLocal()
M_ID = UUID('5ffd4fcc-ea11-464a-989d-b3ff45ad9a62')
T_ID = UUID('46bdeb91-c2cd-43b9-9a4e-35892b3d1652')
SAIRAN_ID = UUID('5347712b-201a-46a9-93b3-222fc3f7e6ba')
KULTEGIN_ID = UUID('548ee50c-449d-461e-a37c-1db07cd3fbe0')

try:
    # 1. Reset match
    m = db.query(Match).filter(Match.id == M_ID).first()
    if m:
        print(f"Match status before reset: {m.status}, score {m.home_score}:{m.away_score}")
        m.status = 'SCHEDULED'
        m.home_score = 0
        m.away_score = 0
    else:
        print("Match not found!")
        
    # 2. Delete MatchResult
    deleted_count = db.query(MatchResult).filter(MatchResult.match_id == M_ID).delete()
    print(f"Deleted {deleted_count} MatchResult rows.")
    
    # 3. Reset Sairan standings
    st_sairan = db.query(TournamentStandings).filter(
        TournamentStandings.tournament_id == T_ID,
        TournamentStandings.team_id == SAIRAN_ID
    ).first()
    if st_sairan:
        print(f"Sairan standings before reset: played={st_sairan.played}, pts={st_sairan.points}")
        st_sairan.played = 2
        st_sairan.wins = 1
        st_sairan.draws = 0
        st_sairan.losses = 1
        st_sairan.goals_for = 7
        st_sairan.goals_against = 5
        st_sairan.goal_difference = 2
        st_sairan.points = 3
        
    # 4. Reset Kultegin standings
    st_kultegin = db.query(TournamentStandings).filter(
        TournamentStandings.tournament_id == T_ID,
        TournamentStandings.team_id == KULTEGIN_ID
    ).first()
    if st_kultegin:
        print(f"Kultegin standings before reset: played={st_kultegin.played}, pts={st_kultegin.points}")
        st_kultegin.played = 0
        st_kultegin.wins = 0
        st_kultegin.draws = 0
        st_kultegin.losses = 0
        st_kultegin.goals_for = 0
        st_kultegin.goals_against = 0
        st_kultegin.goal_difference = 0
        st_kultegin.points = 0
        
    db.commit()
    print("Reset completed successfully!")
except Exception as e:
    db.rollback()
    print(f"Error: {e}")
finally:
    db.close()
