from app.database import SessionLocal
from app.matches.models import Match, MatchResult, ResultStatus
from app.tournaments.models import TournamentStandings
from uuid import UUID, uuid4
from datetime import datetime

db = SessionLocal()

# Tournaments creator ID to satisfy the non-null constraint
ORGANIZER_ID = UUID('56cfe898-95f0-4736-bbe3-131a6e9d2c4f')
T_ID = UUID('46bdeb91-c2cd-43b9-9a4e-35892b3d1652')

# Map of match_id -> (home_score, away_score, status)
match_updates = {
    # Group A
    UUID('77e93d1f-fb63-466d-bffd-19dcbb2ff80c'): (4, 3, 'FINISHED'),  # Legacy vs Elsana (4 : 3)
    UUID('8414a233-d932-4c74-9aec-6809296fb3ff'): (7, 0, 'FINISHED'),  # Legacy vs FC ASU 1 (7 : 0)
    UUID('d0668674-8a5b-4777-b2aa-efdf61a618d8'): (0, 4, 'FINISHED'),  # Elsana vs Fc Arda (0 : 4)
    UUID('5e8e355b-4618-44ca-8f44-af9cd7f31626'): (3, 1, 'FINISHED'),  # Fc Arda vs FC ASU 1 (3 : 1)
    UUID('07cbb9ab-6315-45c5-974c-13b3d4e63e0d'): (0, 0, 'SCHEDULED'), # Elsana vs FC ASU 1
    UUID('a7ee4deb-9d28-4ac2-878a-627155824e2b'): (0, 0, 'SCHEDULED'), # Fc Arda vs Legacy

    # Group B
    UUID('f0e7e16e-97b4-4570-8250-b6333a7ecbaf'): (1, 5, 'FINISHED'),  # IM vs Commandos (1 : 5)
    UUID('a147aeca-36a3-4d98-b0f7-bb994951f0a4'): (3, 0, 'FINISHED'),  # Sairan vs IM (3 : 0)
    UUID('25ecfd79-e535-4087-8ba0-51d79eaf7747'): (5, 4, 'FINISHED'),  # Commandos vs Sairan (5 : 4)
    UUID('3ebf5326-d36b-480e-b78f-5101c95286d2'): (0, 0, 'SCHEDULED'), # IM vs Kultegin (unplayed)
    UUID('53d92058-bc7e-4389-9cf5-2d0890283d25'): (0, 0, 'SCHEDULED'), # Commandos vs Kultegin (unplayed)
    UUID('5ffd4fcc-ea11-464a-989d-b3ff45ad9a62'): (0, 0, 'SCHEDULED'), # Sairan vs Kultegin (unplayed)
}

# Standings values to update: team_id -> (played, wins, draws, losses, goals_for, goals_against, points)
standings_updates = {
    UUID('5d12225e-1aa7-4b36-9035-6801d9fd3627'): (2, 2, 0, 0, 11, 3, 6),  # Legacy
    UUID('a3f25f47-5d16-49a8-9b19-d2e552af2c48'): (2, 2, 0, 0, 7, 1, 6),   # Fc Arda
    UUID('cc0886c0-f31c-44a8-9e28-275007562e03'): (2, 0, 0, 2, 3, 8, 0),   # Elsana
    UUID('234a090e-f2be-49ea-86e2-29d08a109fd3'): (2, 0, 0, 2, 1, 10, 0),  # FC ASU 1
    
    UUID('eddaedcc-6c63-4960-805b-6b111bc65c43'): (2, 2, 0, 0, 10, 5, 6),  # Commandos
    UUID('5347712b-201a-46a9-93b3-222fc3f7e6ba'): (2, 1, 0, 1, 7, 5, 3),   # Sairan
    UUID('b4c8767c-61cf-43de-9c9a-fd129c0000e6'): (2, 0, 0, 2, 1, 8, 0),   # IM
    UUID('548ee50c-449d-461e-a37c-1db07cd3fbe0'): (0, 0, 0, 0, 0, 0, 0),   # Kultegin
}

try:
    # 1. Update Matches and MatchResults
    for m_id, (h_score, a_score, m_status) in match_updates.items():
        m = db.query(Match).filter(Match.id == m_id).first()
        if m:
            print(f"Updating match {m_id} to {m_status} ({h_score}:{a_score})")
            m.home_score = h_score
            m.away_score = a_score
            m.status = m_status
            
            # Delete any existing MatchResult first
            db.query(MatchResult).filter(MatchResult.match_id == m_id).delete()
            
            # If finished, insert a MatchResult record
            if m_status == 'FINISHED':
                db.add(MatchResult(
                    id=uuid4(),
                    match_id=m_id,
                    home_score=h_score,
                    away_score=a_score,
                    status=ResultStatus.FINAL,
                    submitted_by=ORGANIZER_ID,
                    created_at=datetime.utcnow()
                ))
        else:
            print(f"Match {m_id} not found in database!")

    # 2. Update TournamentStandings
    for team_id, (played, wins, draws, losses, gf, ga, pts) in standings_updates.items():
        st = db.query(TournamentStandings).filter(
            TournamentStandings.tournament_id == T_ID,
            TournamentStandings.team_id == team_id
        ).first()
        if st:
            print(f"Updating standings for team {team_id}: played={played}, pts={pts}")
            st.played = played
            st.wins = wins
            st.draws = draws
            st.losses = losses
            st.goals_for = gf
            st.goals_against = ga
            st.goal_difference = gf - ga
            st.points = pts
        else:
            print(f"Standings row for team {team_id} not found!")

    db.commit()
    print("Successfully restored exact scores from the photo and scheduled Kultegin matches!")
except Exception as e:
    db.rollback()
    print(f"Error during update: {e}")
finally:
    db.close()
