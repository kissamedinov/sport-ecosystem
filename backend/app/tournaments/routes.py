from fastapi import APIRouter, Depends, status, Body, HTTPException
from sqlalchemy.orm import Session
from typing import List, Optional, Dict, Any
from uuid import UUID

from app.database import get_db
from app.users.models import User, Role
from app.common.dependencies import get_current_user, require_coach, require_tournament_organizer
from app.tournaments import schemas, services
from app.tournaments.models import RegistrationStatus, Season
from app.clubs.models import ChildProfile

router = APIRouter(prefix="/tournaments", tags=["Tournaments"])



@router.post("/series", response_model=schemas.TournamentSeriesResponse, status_code=status.HTTP_201_CREATED)
def create_series(
    series_in: schemas.TournamentSeriesCreate,
    db: Session = Depends(get_db),
    current_user: User = Depends(require_tournament_organizer)
):
    return services.create_tournament_series(db=db, series_in=series_in)

@router.get("/series", response_model=List[schemas.TournamentSeriesResponse])
def get_tournament_series(db: Session = Depends(get_db)):
    return services.get_tournament_series(db=db)

#  Editions (Tournaments) 

@router.post("", response_model=schemas.TournamentResponse, status_code=status.HTTP_201_CREATED)
def create_tournament(
    tournament_in: schemas.TournamentCreate,
    db: Session = Depends(get_db),
    current_user: User = Depends(require_tournament_organizer)
):
    return services.create_tournament(db=db, tournament_in=tournament_in, current_user=current_user)

@router.get("", response_model=List[schemas.TournamentResponse])
def get_tournaments(
    season: Optional[Season] = None,
    year: Optional[int] = None,
    city: Optional[str] = None,
    mine: bool = False,
    db: Session = Depends(get_db),
    current_user: Optional[User] = Depends(get_current_user)
):
    user_id = current_user.id if mine and current_user else None
    tournaments = services.get_tournaments(db=db, season=season, year=year, city=city, current_user_id=user_id)
    return tournaments if tournaments is not None else []

# Tournament Divisions 

@router.post("/divisions", response_model=schemas.TournamentDivisionResponse, status_code=status.HTTP_201_CREATED)
def create_division(
    division_in: schemas.TournamentDivisionCreate,
    db: Session = Depends(get_db),
    current_user: User = Depends(require_tournament_organizer)
):
    return services.create_tournament_division(db=db, division_in=division_in)

@router.get("/{edition_id}/divisions", response_model=List[schemas.TournamentDivisionResponse])
def get_divisions(edition_id: UUID, db: Session = Depends(get_db)):
    return services.get_tournament_divisions(db=db, edition_id=edition_id)

@router.patch("/divisions/{division_id}", response_model=schemas.TournamentDivisionResponse)
def update_division(
    division_id: UUID,
    division_in: schemas.TournamentDivisionUpdate,
    db: Session = Depends(get_db),
    current_user: User = Depends(require_tournament_organizer)
):
    return services.update_tournament_division(db=db, division_id=division_id, division_in=division_in)

@router.delete("/divisions/{division_id}")
def delete_division(
    division_id: UUID,
    db: Session = Depends(get_db),
    current_user: User = Depends(require_tournament_organizer)
):
    return services.delete_tournament_division(db=db, division_id=division_id)

@router.get("/series/{series_name}", response_model=List[schemas.TournamentResponse])
def get_tournaments_by_series(series_name: str, db: Session = Depends(get_db)):
    return services.get_tournaments_by_series(db=db, series_name=series_name)

@router.get("/{id}", response_model=schemas.TournamentDetailResponse)
def get_tournament(id: UUID, db: Session = Depends(get_db)):
    return services.get_tournament_by_id(db=db, tournament_id=id)

@router.patch("/{id}", response_model=schemas.TournamentResponse)
def update_tournament(
    id: UUID,
    tournament_in: schemas.TournamentUpdate,
    db: Session = Depends(get_db),
    current_user: User = Depends(require_tournament_organizer)
):
    return services.update_tournament(db=db, tournament_id=id, tournament_in=tournament_in)

# Team Registration 

@router.post("/divisions/{division_id}/register-team", response_model=schemas.TournamentTeamResponse)
def register_team(
    division_id: UUID, 
    team_id: UUID, 
    registration_data: Optional[Dict[str, Any]] = Body(None),
    db: Session = Depends(get_db), 
    current_user: User = Depends(get_current_user)
):
    import json
    data_str = json.dumps(registration_data) if registration_data else "{}"
    return services.register_tournament_team(db, division_id, team_id, data_str, current_user)

@router.get("/{id}/teams", response_model=List[schemas.TournamentTeamResponse])
def get_tournament_teams(id: UUID, db: Session = Depends(get_db)):
    return services.get_tournament_teams(db, id)

@router.patch("/{tournament_id}/teams/{team_id}", response_model=schemas.TournamentTeamResponse)
def update_team_status(
    tournament_id: UUID, 
    team_id: UUID, 
    status: Optional[RegistrationStatus] = None, 
    registration_data: Optional[str] = None,
    db: Session = Depends(get_db), 
    current_user: User = Depends(require_tournament_organizer)
):
    return services.update_tournament_team_status(db, tournament_id, team_id, status, registration_data)

#  Scheduling & Matches 

@router.get("/{id}/matches", response_model=List[schemas.TournamentMatchResponse])
def get_tournament_matches(id: UUID, db: Session = Depends(get_db)):
    return services.get_tournament_matches(db, id)

@router.post("/{id}/generate-schedule")
def generate_schedule(id: UUID, db: Session = Depends(get_db), current_user: User = Depends(require_tournament_organizer)):
    return services.generate_tournament_schedule(db, id)

@router.post("/{id}/generate-playoffs")
def generate_playoffs(id: UUID, db: Session = Depends(get_db), current_user: User = Depends(require_tournament_organizer)):
    return services.generate_playoffs_from_groups(db, id)

@router.post("/{id}/finalize-schedule")
def finalize_schedule(id: UUID, db: Session = Depends(get_db), current_user: User = Depends(require_tournament_organizer)):
    return services.finalize_tournament_schedule(db, id)

@router.get("/{id}/groups")
def get_groups(id: UUID, db: Session = Depends(get_db)):
    return services.get_tournament_groups(db, id)

@router.post("/{id}/groups/draw")
def draw_groups(
    id: UUID, 
    req: schemas.GroupDrawRequest, 
    db: Session = Depends(get_db), 
    current_user: User = Depends(require_tournament_organizer)
):
    return services.draw_tournament_groups(db, id, req.num_groups, req.assignments)

@router.post("/{id}/swap-teams")
def swap_teams(
    id: UUID,
    team_a_id: UUID = Body(...),
    team_b_id: UUID = Body(...),
    db: Session = Depends(get_db),
    current_user: User = Depends(require_tournament_organizer)
):
    return services.swap_teams_in_groups(db, id, team_a_id, team_b_id)

@router.patch("/matches/{match_id}/result", response_model=schemas.TournamentMatchResponse)
def update_match_result(
    match_id: UUID, 
    home_score: int, 
    away_score: int, 
    db: Session = Depends(get_db), 
    current_user: User = Depends(require_tournament_organizer)
):
    return services.update_match_result(db, match_id, home_score, away_score)

@router.patch("/matches/{match_id}", response_model=schemas.TournamentMatchResponse)
def update_match_details(
    match_id: UUID,
    details: Dict[str, Any] = Body(...),
    db: Session = Depends(get_db),
    current_user: User = Depends(require_tournament_organizer)
):
    return services.update_match_details(db, match_id, details)

#  Standings & Stats 

@router.get("/{id}/standings", response_model=List[schemas.TournamentStandingsResponse])
def get_tournament_standings(id: UUID, db: Session = Depends(get_db)):
    return services.get_tournament_standings(db, id)

@router.get("/{id}/leaderboards")
def get_tournament_leaderboards(id: UUID, db: Session = Depends(get_db)):
    return services.get_tournament_leaderboards(db, id)

@router.post("/match-stats")
def record_match_stats(
    match_id: UUID,
    child_profile_id: UUID,
    stats: schemas.MatchPlayerStatsCreate,
    db: Session = Depends(get_db),
    current_user: User = Depends(require_tournament_organizer)
):
    return services.record_match_player_stats(db, match_id, child_profile_id, stats.model_dump())

@router.post("/awards", response_model=schemas.TournamentAwardResponse)
def assign_award(
    award_in: schemas.TournamentAwardCreate,
    db: Session = Depends(get_db),
    current_user: User = Depends(require_tournament_organizer)
):
    return services.assign_tournament_award(db, award_in)

@router.get("/player/{player_id}/awards", response_model=List[schemas.TournamentAwardResponse])
def get_player_awards(player_id: UUID, db: Session = Depends(get_db)):
    try:
        # Check if player_id is linked_user_id or direct child_profile_id
        profile = db.query(ChildProfile).filter(ChildProfile.linked_user_id == player_id).first()
        if not profile:
            profile = db.query(ChildProfile).filter(ChildProfile.id == player_id).first()
        
        if not profile:
            raise HTTPException(status_code=404, detail="Child Profile not found")
            
        return services.get_player_awards(db, profile.id)
    except HTTPException as e:
        raise e
    except Exception as e:
        print(f"CRITICAL ERROR in get_player_awards: {str(e)}")
        import traceback
        traceback.print_exc()
        raise HTTPException(status_code=500, detail="Internal Server Error")
@router.post("/teams/{tt_id}/squad", response_model=dict)
def add_to_squad(
    tt_id: UUID,
    squad_in: schemas.TournamentSquadCreate,
    db: Session = Depends(get_db),
    current_user: User = Depends(require_coach)
):
    return services.add_to_tournament_squad(db, tt_id, squad_in, current_user)

@router.get("/teams/{tt_id}/squad", response_model=List[schemas.TournamentSquadMemberResponse])
def get_squad(tt_id: UUID, db: Session = Depends(get_db)):
    return services.get_tournament_squad(db, tt_id)

@router.delete("/teams/{tt_id}/squad/{profile_id}")
def remove_from_squad(
    tt_id: UUID,
    profile_id: UUID,
    db: Session = Depends(get_db),
    current_user: User = Depends(require_coach)
):
    return services.remove_from_tournament_squad(db, tt_id, profile_id, current_user)
