import os

def main():
    filepath = 'backend/app/tournaments/services.py'
    with open(filepath, 'r', encoding='utf-8') as f:
        content = f.read()

    # 1. Initialize all_match_starts specifically in generate_group_stage_schedule
    target1 = """    match_count = 0
    # Timing config
    current_time = tournament.start_time or tournament.start_date"""
    
    replacement1 = """    match_count = 0
    all_match_starts = []
    # Timing config
    current_time = tournament.start_time or tournament.start_date"""
    
    if target1 in content and "all_match_starts" not in content:
        content = content.replace(target1, replacement1)
        print("all_match_starts initialized specifically!")

    # 2. Append to all_match_starts in slot loop
    target2 = """            slots_def.append({
                "slot_index": slot_index,
                "field_uuid": field_uuid,
                "match_start": match_start
            })
            slot_index += 1"""
            
    replacement2 = """            slots_def.append({
                "slot_index": slot_index,
                "field_uuid": field_uuid,
                "match_start": match_start
            })
            all_match_starts.append(match_start)
            slot_index += 1"""
    if target2 in content and "all_match_starts.append" not in content:
        content = content.replace(target2, replacement2)
        print("all_match_starts populated!")

    # 3. Append playoff pre-generation before db.commit()
    target3 = """        # Pad slot_index to next clean multiple of num_fields for next round
        if slot_index % num_fields != 0:
            slot_index = ((slot_index // num_fields) + 1) * num_fields
            
    db.commit()"""

    replacement3 = """        # Pad slot_index to next clean multiple of num_fields for next round
        if slot_index % num_fields != 0:
            slot_index = ((slot_index // num_fields) + 1) * num_fields
            
    # Pre-create Playoff matches (Semis, Finals, Placements) if exactly 2 groups
    if num_groups == 2:
        import uuid
        max_match_time = max(all_match_starts) if all_match_starts else current_time
        playoff_start_date = max_match_time + timedelta(minutes=match_duration + 30)
        
        sf1_id = uuid.uuid4()
        sf2_id = uuid.uuid4()
        final_id = uuid.uuid4()
        third_place_id = uuid.uuid4()
        
        sf1_field = uuid.UUID(field_ids[0]) if field_ids else None
        sf2_field = uuid.UUID(field_ids[1 % num_fields]) if field_ids else None
        
        sf1_time = playoff_start_date
        if num_fields > 1:
            sf2_time = playoff_start_date
        else:
            sf2_time = playoff_start_date + timedelta(minutes=match_duration)
            
        division_id = approved_teams[0].division_id if approved_teams else None
        
        # SF 1: A1 vs B2
        sf1 = Match(
            id=sf1_id,
            tournament_id=tournament_id,
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
            tournament_id=tournament_id,
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
        
        # Final and 3rd place: same day, 30 mins after Semifinals finish
        final_date = playoff_start_date + timedelta(minutes=match_duration + 30)
        
        final_match = Match(
            id=final_id,
            tournament_id=tournament_id,
            division_id=division_id,
            home_team_id=None,
            away_team_id=None,
            match_date=final_date + timedelta(minutes=match_duration),
            field_id=sf1_field,
            status=MatchStatus.DRAFT,
            round_number=2,
            bracket_position=0
        )
        
        third_place_match = Match(
            id=third_place_id,
            tournament_id=tournament_id,
            division_id=division_id,
            home_team_id=None,
            away_team_id=None,
            match_date=final_date,
            field_id=sf1_field,
            status=MatchStatus.DRAFT,
            round_number=2,
            bracket_position=1
        )
        
        db.add_all([sf1, sf2, final_match, third_place_match])
        
        # Consolation/placement matches
        if num_teams >= 6:
            m5 = Match(
                id=uuid.uuid4(),
                tournament_id=tournament_id,
                division_id=division_id,
                home_team_id=None,
                away_team_id=None,
                match_date=sf1_time,
                field_id=uuid.UUID(field_ids[2 % num_fields]) if num_fields > 2 and field_ids else sf1_field,
                status=MatchStatus.DRAFT,
                round_number=1,
                bracket_position=2
            )
            db.add(m5)
            
        if num_teams >= 8:
            m7 = Match(
                id=uuid.uuid4(),
                tournament_id=tournament_id,
                division_id=division_id,
                home_team_id=None,
                away_team_id=None,
                match_date=sf2_time,
                field_id=uuid.UUID(field_ids[3 % num_fields]) if num_fields > 3 and field_ids else sf2_field,
                status=MatchStatus.DRAFT,
                round_number=1,
                bracket_position=3
            )
            db.add(m7)
            
    db.commit()"""

    if target3 in content and "Pre-create Playoff matches" not in content:
        content = content.replace(target3, replacement3)
        print("Playoff pre-generation added to group stage generation!")
    else:
        print("Playoff target not found or already added!")

    with open(filepath, 'w', encoding='utf-8') as f:
        f.write(content)
    print("Done editing generate group stage schedule!")

if __name__ == '__main__':
    main()
