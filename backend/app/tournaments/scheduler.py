from sqlalchemy.orm import Session
from fastapi import HTTPException, status
from uuid import UUID
from typing import List
import random

from app.tournaments.models import Tournament, TournamentFormat, TournamentGroup, TournamentGroupTeam, TournamentTeam
from app.matches.models import Match, MatchStatus
from app.teams.models import Team
from app.academies.models import Academy # To check academy of team coach or owner?
# Actually tournament team is linked to Team, Team is linked to coach (User)
# Need to check Academy owners or Club creators

def generate_matches(db: Session, tournament_id: UUID):
    tournament = db.query(Tournament).filter(Tournament.id == tournament_id).first()
    if not tournament:
        raise HTTPException(status_code=404, detail="Tournament not found")
        
    teams = db.query(TournamentTeam).filter(TournamentTeam.tournament_id == tournament_id).all()
    if not teams:
        raise HTTPException(status_code=400, detail="No teams registered for this tournament")
        
    if tournament.format == TournamentFormat.LEAGUE:
        _generate_league_matches(db, tournament_id, teams)
    elif tournament.format == TournamentFormat.GROUP_STAGE:
        _generate_group_stage_matches(db, tournament_id, teams)
    elif tournament.format == TournamentFormat.KNOCKOUT:
        _generate_knockout_bracket(db, tournament_id, teams)
        
    db.commit()
    return {"message": "Matches generated successfully"}

def _generate_league_matches(db: Session, tournament_id: UUID, tt_list: List[TournamentTeam]):
    # Round robin
    for i in range(len(tt_list)):
        for j in range(i + 1, len(tt_list)):
            match = Match(
                tournament_id=tournament_id,
                home_team_id=tt_list[i].team_id,
                away_team_id=tt_list[j].team_id,
                status=MatchStatus.SCHEDULED,
                round_number=1
            )
            db.add(match)

def _generate_group_stage_matches(db: Session, tournament_id: UUID, tt_list: List[TournamentTeam]):
    # For now, simplify: 2 groups
    group_a = TournamentGroup(tournament_id=tournament_id, name="Group A")
    group_b = TournamentGroup(tournament_id=tournament_id, name="Group B")
    db.add(group_a)
    db.add(group_b)
    db.flush()
    
    # Distribution Rule: Teams from same organization spread out
    # Heuristic: same coach or similar name implies same organization
    tt_list.sort(key=lambda x: _get_org_id(db, x.team_id)) 
    
    for idx, tt in enumerate(tt_list):
        group = group_a if idx % 2 == 0 else group_b
        mapping = TournamentGroupTeam(group_id=group.id, tournament_team_id=tt.id)
        db.add(mapping)
        
    db.flush()
    
    # Generate round robin for each group
    for g in [group_a, group_b]:
        group_tt_ids = [m.tournament_team_id for m in db.query(TournamentGroupTeam).filter(TournamentGroupTeam.group_id == g.id).all()]
        group_tts = [tt for tt in tt_list if tt.id in group_tt_ids]
        _generate_league_matches(db, tournament_id, group_tts)

def _get_org_id(db: Session, team_id: UUID):
    team = db.query(Team).filter(Team.id == team_id).first()
    # Simple heuristic: coach_id is the organizational link for now
    return str(team.coach_id)

def _generate_knockout_bracket(db: Session, tournament_id: UUID, tt_list: List[TournamentTeam]):
    # Placeholder for knockout bracket generation
    pass
