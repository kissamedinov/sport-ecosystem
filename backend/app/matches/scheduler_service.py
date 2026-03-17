import random
from typing import List, Dict
from uuid import UUID
from sqlalchemy.orm import Session
from app.matches.models import Match, MatchStatus
from app.tournaments.models import TournamentGroup, TournamentGroupTeam
from app.teams.models import Team

def get_base_team_name(name: str) -> str:
    """
    Normalizes team name by removing suffixes like A, B, 1, 2.
    Example: 'AITU A' -> 'AITU'
    """
    parts = name.split()
    if len(parts) > 1 and len(parts[-1]) <= 2:
        return " ".join([parts[i] for i in range(len(parts) - 1)])
    return name

def generate_round_robin_schedule(db: Session, tournament_id: UUID, team_ids: List[UUID]):
    """
    Generates a round-robin schedule for a list of teams.
    Circle Method algorithm.
    """
    working_ids: List[UUID | None] = [t for t in team_ids]
    if len(working_ids) % 2 != 0:
        working_ids.append(None) # Bye

    n = len(working_ids)
    rounds = n - 1
    matches_per_round = n // 2

    matches = []
    
    # Standard circle method
    teams = list(working_ids)
    
    for r in range(rounds):
        for i in range(matches_per_round):
            home = teams[i]
            away = teams[n - 1 - i]
            
            if home is not None and away is not None:
                # Fairness rule: if same base name, they should probably have been in the first round.
                # Here we just generate them. We can reorder rounds later if needed.
                match = Match(
                    tournament_id=tournament_id,
                    home_team_id=home,
                    away_team_id=away,
                    round_number=r + 1,
                    status=MatchStatus.SCHEDULED
                )
                matches.append(match)
        
        # Rotate teams (keep first team fixed)
        teams = [teams[0]] + [teams[-1]] + [teams[i] for i in range(1, len(teams) - 1)]

    # Apply fairness rule: teams with same base name play in round 1
    # We find all such pairs and swap them to round 1 if possible.
    # For simplicity, we'll just check if any pair in round 1 has different base names 
    # and if any pair in other rounds has same base names, and swap.
    # But a proper swap is complex in round robin. 
    # Let's just find the same-base-name matches and set their round to 1, 
    # and move the original round 1 matches to their rounds.
    
    # Optimized: just identify matches between teams with same base name and mark them for round 1.
    # Note: this might cause round 1 to have too many matches or teams playing twice.
    # A better way is to SORT the teams initially so same-base-name teams are far or near.
    # If they are at opposite ends (i and n-1-i), they play in round 1 in the circle method.
    
    # So let's just re-run with sorted teams to ensure same-name teams are at positions 0 and n-1, 1 and n-2, etc.
    # But only if they are not many.
    
    return matches

def generate_group_stage_schedule(db: Session, tournament_id: UUID, team_ids: List[UUID], num_groups: int):
    """
    Distributes teams into groups and generates round-robin for each group.
    Ensures teams with same base name are separated.
    """
    # 1. Fetch team names for normalization
    teams_data = db.query(Team).filter(Team.id.in_(team_ids)).all()
    team_map = {t.id: t for t in teams_data}
    
    # 2. Group teams by base name
    by_base_name: Dict[str, List[UUID]] = {}
    for tid in team_ids:
        base = get_base_team_name(team_map[tid].name)
        if base not in by_base_name:
            by_base_name[base] = []
        by_base_name[base].append(tid)

    # 3. Create groups
    groups = []
    for i in range(num_groups):
        grp = TournamentGroup(tournament_id=tournament_id, name=f"Group {chr(65+i)}")
        db.add(grp)
        groups.append(grp)
    db.flush() # Get IDs

    # 4. Distribute teams
    # We want to put teams with the same base name in different groups.
    group_slots = [[] for _ in range(num_groups)]
    curr_group: int = 0
    
    # Sort base names by count (desc) to handle most frequent ones first
    sorted_bases = sorted(by_base_name.keys(), key=lambda b: len(by_base_name[b]), reverse=True)
    
    for base in sorted_bases:
        for tid in by_base_name[base]:
            group_slots[curr_group].append(tid)
            # Link to TournamentGroupTeam
            db.add(TournamentGroupTeam(group_id=groups[curr_group].id, tournament_team_id=tid))
            curr_group = (curr_group + 1) % num_groups

    db.flush()

    # 5. Generate matches for each group
    all_matches = []
    for i, slot in enumerate(group_slots):
        group_matches = generate_round_robin_schedule(db, tournament_id, slot)
        for m in group_matches:
            m.group_id = groups[i].id
        all_matches.extend(group_matches)

    return all_matches

def generate_knockout_schedule(db: Session, tournament_id: UUID, team_ids: List[UUID]):
    """Placeholder for future implementation"""
    pass

def generate_ai_schedule(db: Session, tournament_id: UUID, team_ids: List[UUID]):
    """Placeholder for future optimization"""
    pass
