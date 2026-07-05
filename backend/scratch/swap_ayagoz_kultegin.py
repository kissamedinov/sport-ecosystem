from app.database import SessionLocal
from app.tournaments.models import TournamentGroupTeam, TournamentStandings, TournamentTeam
from app.matches.models import Match
from uuid import UUID

db = SessionLocal()

# Team and Tournament details
TOURNAMENT_ID = UUID('46bdeb91-c2cd-43b9-9a4e-35892b3d1652')
group_b_id = UUID('633957a0-2376-49a9-a3cf-4360bf7fee32')

# Team IDs
AYAGOZ_TEAM_ID = UUID('32192b38-a67c-458b-88ca-0af792ead1bb')
KULTEGIN_TEAM_ID = UUID('548ee50c-449d-461e-a37c-1db07cd3fbe0')

# TournamentTeam IDs
AYAGOZ_TT_ID = UUID('44021c2c-6a30-4926-a229-c4b922463e01')
KULTEGIN_TT_ID = UUID('95f23931-3571-4f84-a179-492a7c9511b1')

try:
    # 1. Update Match records: replace Ayagoz with Kultegin
    m_home = db.query(Match).filter(Match.tournament_id == TOURNAMENT_ID, Match.home_team_id == AYAGOZ_TEAM_ID).update({Match.home_team_id: KULTEGIN_TEAM_ID})
    m_away = db.query(Match).filter(Match.tournament_id == TOURNAMENT_ID, Match.away_team_id == AYAGOZ_TEAM_ID).update({Match.away_team_id: KULTEGIN_TEAM_ID})
    print(f"Updated matches: home={m_home}, away={m_away}")

    # 2. Update TournamentGroupTeam: assign Kultegin to Group B (replacing Ayagoz)
    gt = db.query(TournamentGroupTeam).filter(TournamentGroupTeam.tournament_team_id == AYAGOZ_TT_ID).first()
    if gt:
        print(f"Updating TournamentGroupTeam row {gt.id} from Ayagoz to Kultegin")
        gt.tournament_team_id = KULTEGIN_TT_ID
    else:
        # If not found, create new row
        db.add(TournamentGroupTeam(group_id=group_b_id, tournament_team_id=KULTEGIN_TT_ID))
        print("Created new TournamentGroupTeam row for Kultegin")

    # 3. Update TournamentStandings:
    # Set group_id for Kultegin to Group B
    st_kultegin = db.query(TournamentStandings).filter(
        TournamentStandings.tournament_id == TOURNAMENT_ID,
        TournamentStandings.team_id == KULTEGIN_TEAM_ID
    ).first()
    if st_kultegin:
        st_kultegin.group_id = group_b_id
        print("Updated Kultegin standings group_id to Group B")
    else:
        db.add(TournamentStandings(
            tournament_id=TOURNAMENT_ID,
            team_id=KULTEGIN_TEAM_ID,
            group_id=group_b_id,
            played=0, wins=0, draws=0, losses=0, goals_for=0, goals_against=0, goal_difference=0, points=0
        ))
        print("Created new standings row for Kultegin in Group B")

    # Delete Ayagoz standings row
    deleted_st = db.query(TournamentStandings).filter(
        TournamentStandings.tournament_id == TOURNAMENT_ID,
        TournamentStandings.team_id == AYAGOZ_TEAM_ID
    ).delete(synchronize_session=False)
    print(f"Deleted Ayagoz standings row count: {deleted_st}")

    db.commit()
    print("Successfully committed transaction swapping Ayagoz with Kultegin!")
except Exception as e:
    db.rollback()
    print(f"Error during swap: {e}")
finally:
    db.close()
