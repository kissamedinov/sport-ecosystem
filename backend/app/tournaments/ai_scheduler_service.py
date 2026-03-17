import random
import uuid
from datetime import datetime, timedelta
from typing import List, Dict, Optional, Set, Tuple
from sqlalchemy.orm import Session
from app.tournaments.models import Tournament, TournamentFormat, TournamentGroup, TournamentGroupTeam, TournamentTeam, TournamentMatch
from app.teams.models import Team

def _get_base_team_name(name: str) -> str:
    """
    Normalizes team name by removing common suffixes.
    Example: 'Academy U12 A' -> 'Academy U12'
    """
    suffixes = ['A', 'B', 'C', '1', '2', '3', 'RED', 'BLUE', 'WHITE']
    parts = name.upper().split()
    if len(parts) > 1 and parts[-1] in suffixes:
        return " ".join([parts[i] for i in range(len(parts) - 1)])
    return name.upper()

def _are_sister_teams(team1: Team, team2: Team) -> bool:
    """
    Checks if two teams belong to the same academy or have similar names.
    """
    if team1.academy_id and team1.academy_id == team2.academy_id:
        return True
    return _get_base_team_name(team1.name) == _get_base_team_name(team2.name)

def generate_sophisticated_schedule(db: Session, tournament_id: uuid.UUID) -> Optional[List[TournamentMatch]]:
    tournament = db.query(Tournament).filter(Tournament.id == tournament_id).first()
    if not tournament:
        return None

    # Load teams
    tournament_teams = db.query(TournamentTeam).filter(TournamentTeam.tournament_id == tournament_id).all()
    if not tournament_teams:
        return None
    
    team_ids: List[uuid.UUID] = [tt.team_id for tt in tournament_teams]
    teams = db.query(Team).filter(Team.id.in_(team_ids)).all()
    team_map: Dict[uuid.UUID, Team] = {t.id: t for t in teams}

    # Timing Configuration
    match_duration = (tournament.match_half_duration * 2) + tournament.halftime_break_duration
    slot_duration = match_duration + tournament.break_between_matches
    
    start_time = tournament.start_time or datetime.combine(tournament.start_date, datetime.min.time())

    # 1. Pairing Generation
    pairings: List[Tuple[Optional[uuid.UUID], Optional[uuid.UUID]]] = []
    if tournament.format == TournamentFormat.LEAGUE:
        pairings = _generate_league_pairings(team_ids, team_map)
    elif tournament.format == TournamentFormat.GROUP_STAGE:
        pairings = _generate_group_pairings(db, tournament, team_ids, team_map)
    
    # 2. Slot Allocation
    matches = _allocate_slots(
        tournament, 
        pairings, 
        start_time, 
        slot_duration, 
        tournament.num_fields,
        tournament.minimum_rest_slots
    )

    # 3. Save to DB
    for m in matches:
        db.add(m)
    
    db.commit()

    # Notify involved parties
    from app.notifications.match_notifications import notify_match_scheduled
    for m in matches:
        notify_match_scheduled(db, m.id)

    return matches

def _generate_league_pairings(team_ids: List[uuid.UUID], team_map: Dict[uuid.UUID, Team]) -> List[Tuple[Optional[uuid.UUID], Optional[uuid.UUID]]]:
    """Round Robin pairings, with sister teams playing first."""
    working_ids: List[Optional[uuid.UUID]] = [t for t in team_ids]
    if len(working_ids) % 2 != 0:
        working_ids.append(None) # Bye

    n = len(working_ids)
    rounds = n - 1
    matches_per_round = n // 2
    
    all_pairings: List[List[Tuple[Optional[uuid.UUID], Optional[uuid.UUID]]]] = []
    
    for r in range(rounds):
        round_pairings = []
        for i in range(matches_per_round):
            home = working_ids[i]
            away = working_ids[n - 1 - i]
            if home and away:
                round_pairings.append((home, away))
        all_pairings.append(round_pairings)
        # Rotate
        working_ids = [working_ids[0]] + [working_ids[-1]] + [working_ids[i] for i in range(1, len(working_ids) - 1)]

    sister_matches = []
    other_matches = []
    
    for round_list in all_pairings:
        for p in round_list:
            t1_id, t2_id = p
            if t1_id and t2_id and t1_id in team_map and t2_id in team_map:
                if _are_sister_teams(team_map[t1_id], team_map[t2_id]):
                    sister_matches.append(p)
                else:
                    other_matches.append(p)
    
    return sister_matches + other_matches

def _generate_group_pairings(db: Session, tournament: Tournament, team_ids: List[uuid.UUID], team_map: Dict[uuid.UUID, Team]) -> List[Tuple[Optional[uuid.UUID], Optional[uuid.UUID]]]:
    groups = db.query(TournamentGroup).filter(TournamentGroup.tournament_id == tournament.id).all()
    if not groups:
        num_groups = 2
        groups = []
        for i in range(num_groups):
            grp = TournamentGroup(tournament_id=tournament.id, name=f"Group {chr(65+i)}")
            db.add(grp)
            groups.append(grp)
        db.flush()
    
    num_groups = len(groups)
    by_base: Dict[str, List[uuid.UUID]] = {}
    for tid in team_ids:
        base = _get_base_team_name(team_map[tid].name)
        if base not in by_base:
            by_base[base] = []
        by_base[base].append(tid)
    
    sorted_bases = sorted(by_base.keys(), key=lambda b: len(by_base[b]), reverse=True)
    
    group_slots: List[List[uuid.UUID]] = [[] for _ in range(num_groups)]
    curr_grp: int = 0
    for base in sorted_bases:
        for tid in by_base[base]:
            group_slots[curr_grp].append(tid)
            db.add(TournamentGroupTeam(group_id=groups[curr_grp].id, tournament_team_id=tid))
            curr_grp = (curr_grp + 1) % num_groups
    db.flush()

    all_pairings = []
    for slot in group_slots:
        if len(slot) > 1:
            all_pairings.extend(_generate_league_pairings(slot, team_map))
    
    return all_pairings

def _allocate_slots(
    tournament: Tournament, 
    pairings: List[Tuple[Optional[uuid.UUID], Optional[uuid.UUID]]], 
    initial_start: datetime, 
    slot_minutes: int, 
    num_fields: int,
    min_rest: int
) -> List[TournamentMatch]:
    matches: List[TournamentMatch] = []
    team_last_slot: Dict[uuid.UUID, int] = {}
    team_fields_used: Dict[uuid.UUID, Set[uuid.UUID]] = {}
    
    field_ids = [uuid.uuid5(uuid.NAMESPACE_DNS, f"field_{i}") for i in range(num_fields)]
    
    current_slot_index: int = 0
    current_time = initial_start
    pool = list(pairings)
    
    while pool:
        for f_idx in range(num_fields):
            f_id = field_ids[f_idx]
            found_pair_idx = -1
            best_rotation_idx = -1
            
            for i, pair in enumerate(pool):
                t1, t2 = pair
                if not t1 or not t2: continue
                
                can_play_t1 = t1 not in team_last_slot or team_last_slot[t1] + min_rest < current_slot_index
                can_play_t2 = t2 not in team_last_slot or team_last_slot[t2] + min_rest < current_slot_index
                
                currently_playing: Set[uuid.UUID] = set()
                for m in matches:
                    if getattr(m, '_slot', -1) == current_slot_index:
                        if m.home_team_id: currently_playing.add(m.home_team_id)
                        if m.away_team_id: currently_playing.add(m.away_team_id)
                
                if can_play_t1 and can_play_t2 and t1 not in currently_playing and t2 not in currently_playing:
                    t1_used = f_id in team_fields_used.get(t1, set())
                    t2_used = f_id in team_fields_used.get(t2, set())
                    
                    if not t1_used or not t2_used:
                        best_rotation_idx = i
                        break
                    elif found_pair_idx == -1:
                        found_pair_idx = i
            
            final_idx = best_rotation_idx if best_rotation_idx != -1 else found_pair_idx
            
            if final_idx != -1:
                p = pool.pop(final_idx)
                t1_id, t2_id = p
                if t1_id and t2_id:
                    m = TournamentMatch(
                        tournament_id=tournament.id,
                        home_team_id=t1_id,
                        away_team_id=t2_id,
                        start_time=current_time,
                        end_time=current_time + timedelta(minutes=tournament.match_half_duration * 2 + tournament.halftime_break_duration),
                        field_number=f_idx + 1
                        # Note: group_id can be added similarly if generating group stages directly handled here
                    )
                    setattr(m, '_slot', current_slot_index)
                    matches.append(m)
                    
                    team_last_slot[t1_id] = current_slot_index
                    team_last_slot[t2_id] = current_slot_index
                    
                    if t1_id not in team_fields_used: team_fields_used[t1_id] = set()
                    if t2_id not in team_fields_used: team_fields_used[t2_id] = set()
                    team_fields_used[t1_id].add(f_id)
                    team_fields_used[t2_id].add(f_id)
            
        current_slot_index = current_slot_index + 1
        current_time = current_time + timedelta(minutes=slot_minutes)
        if tournament.end_time and current_time + timedelta(minutes=slot_minutes) > tournament.end_time:
            break
        if current_slot_index > 5000: break

    return matches
