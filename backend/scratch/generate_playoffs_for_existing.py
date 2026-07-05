import os
from uuid import UUID
from datetime import datetime, timedelta
import uuid
from app.database import SessionLocal
from app.tournaments.models import Tournament
from app.matches.models import Match, MatchStatus

def main():
    db = SessionLocal()
    try:
        t_id = UUID('46bdeb91-c2cd-43b9-9a4e-35892b3d1652')
        t = db.query(Tournament).filter(Tournament.id == t_id).first()
        if not t:
            print("Tournament not found!")
            return

        # Find existing group matches to get division, fields, and max date
        group_matches = db.query(Match).filter(Match.tournament_id == t_id, Match.group_id != None).all()
        if not group_matches:
            print("No group matches found!")
            return

        division_id = group_matches[0].division_id
        field_ids = list({m.field_id for m in group_matches if m.field_id is not None})
        all_dates = [m.match_date for m in group_matches if m.match_date is not None]
        max_date = max(all_dates) if all_dates else datetime.now()

        # Delete any existing playoff matches
        db.query(Match).filter(Match.tournament_id == t_id, Match.group_id == None).delete()

        # We schedule the playoffs to be after the last group stage match
        playoff_start_date = max_date + timedelta(minutes=45)

        sf1_id = uuid.uuid4()
        sf2_id = uuid.uuid4()
        final_id = uuid.uuid4()
        third_place_id = uuid.uuid4()

        sf1_field = field_ids[0] if field_ids else None
        sf2_field = field_ids[1 % len(field_ids)] if len(field_ids) > 1 else sf1_field

        sf1_time = playoff_start_date
        sf2_time = playoff_start_date

        # SF 1: A1 vs B2
        sf1 = Match(
            id=sf1_id,
            tournament_id=t_id,
            division_id=division_id,
            home_team_id=None,
            away_team_id=None,
            match_date=sf1_time,
            field_id=sf1_field,
            status=MatchStatus.DRAFT,
            round_number=1,
            bracket_position=0,
            next_match_id=final_id
        )

        # SF 2: B1 vs A2
        sf2 = Match(
            id=sf2_id,
            tournament_id=t_id,
            division_id=division_id,
            home_team_id=None,
            away_team_id=None,
            match_date=sf2_time,
            field_id=sf2_field,
            status=MatchStatus.DRAFT,
            round_number=1,
            bracket_position=1,
            next_match_id=final_id
        )

        # Final
        final_date = playoff_start_date + timedelta(minutes=45)
        final_match = Match(
            id=final_id,
            tournament_id=t_id,
            division_id=division_id,
            home_team_id=None,
            away_team_id=None,
            match_date=final_date,
            field_id=sf1_field,
            status=MatchStatus.DRAFT,
            round_number=2,
            bracket_position=0
        )

        # 3rd Place Match
        third_place_match = Match(
            id=third_place_id,
            tournament_id=t_id,
            division_id=division_id,
            home_team_id=None,
            away_team_id=None,
            match_date=final_date,
            field_id=sf2_field,
            status=MatchStatus.DRAFT,
            round_number=2,
            bracket_position=1
        )

        # Placement matches for 5-8th place
        sf5_id = uuid.uuid4()
        sf6_id = uuid.uuid4()
        f5_id = uuid.uuid4()
        f7_id = uuid.uuid4()

        # Semifinal 5-8: A3 vs B4
        sf5 = Match(
            id=sf5_id,
            tournament_id=t_id,
            division_id=division_id,
            home_team_id=None,
            away_team_id=None,
            match_date=playoff_start_date,
            field_id=sf1_field,
            status=MatchStatus.DRAFT,
            round_number=1,
            bracket_position=2,
            next_match_id=f5_id
        )

        # Semifinal 5-8: B3 vs A4
        sf6 = Match(
            id=sf6_id,
            tournament_id=t_id,
            division_id=division_id,
            home_team_id=None,
            away_team_id=None,
            match_date=playoff_start_date,
            field_id=sf2_field,
            status=MatchStatus.DRAFT,
            round_number=1,
            bracket_position=3,
            next_match_id=f5_id
        )

        # Final 5-6
        f5 = Match(
            id=f5_id,
            tournament_id=t_id,
            division_id=division_id,
            home_team_id=None,
            away_team_id=None,
            match_date=final_date,
            field_id=sf1_field,
            status=MatchStatus.DRAFT,
            round_number=2,
            bracket_position=2
        )

        # Final 7-8
        f7 = Match(
            id=f7_id,
            tournament_id=t_id,
            division_id=division_id,
            home_team_id=None,
            away_team_id=None,
            match_date=final_date,
            field_id=sf2_field,
            status=MatchStatus.DRAFT,
            round_number=2,
            bracket_position=3
        )

        db.add(sf1)
        db.add(sf2)
        db.add(final_match)
        db.add(third_place_match)
        db.add(sf5)
        db.add(sf6)
        db.add(f5)
        db.add(f7)

        db.commit()
        print("Playoff matches (SFs, Finals, Placement matches) successfully generated for existing tournament!")
    except Exception as e:
        db.rollback()
        print(f"Error: {e}")
    finally:
        db.close()

if __name__ == '__main__':
    main()
