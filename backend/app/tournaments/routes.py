from fastapi import APIRouter, Depends, status, Body, HTTPException
from sqlalchemy.orm import Session
from typing import List, Optional
from uuid import UUID

from app.database import get_db
from app.users.models import User, Role
from app.common.dependencies import get_current_user, require_coach, require_tournament_organizer
from app.tournaments import schemas, services
from app.tournaments.models import RegistrationStatus, Season
from app.users.models import PlayerProfile

router = APIRouter(prefix="/tournaments", tags=["Tournaments"])

# --- Tournament Series ---

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

# --- Tournament Editions (Tournaments) ---

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
    db: Session = Depends(get_db)
):
    tournaments = services.get_tournaments(db=db, season=season, year=year)
    return tournaments if tournaments is not None else []

# --- Tournament Divisions ---

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

@router.get("/series/{series_name}", response_model=List[schemas.TournamentResponse])
def get_tournaments_by_series(series_name: str, db: Session = Depends(get_db)):
    return services.get_tournaments_by_series(db=db, series_name=series_name)

@router.get("/{id}", response_model=schemas.TournamentDetailResponse)
def get_tournament(id: UUID, db: Session = Depends(get_db)):
    return services.get_tournament_by_id(db=db, tournament_id=id)

# --- Team Registration ---

@router.post("/divisions/{division_id}/register-team", response_model=schemas.TournamentTeamResponse)
def register_team(
    division_id: UUID, 
    team_id: UUID, 
    registration_data: str = Body(...),
    db: Session = Depends(get_db), 
    current_user: User = Depends(require_coach)
):
    return services.register_tournament_team(db, division_id, team_id, registration_data, current_user)

@router.get("/{id}/teams", response_model=List[schemas.TournamentTeamResponse])
def get_tournament_teams(id: UUID, db: Session = Depends(get_db)):
    return services.get_tournament_teams(db, id)

@router.patch("/{tournament_id}/teams/{team_id}", response_model=schemas.TournamentTeamResponse)
def update_team_status(
    tournament_id: UUID, 
    team_id: UUID, 
    status: RegistrationStatus, 
    db: Session = Depends(get_db), 
    current_user: User = Depends(require_tournament_organizer)
):
    return services.update_tournament_team_status(db, tournament_id, team_id, status)

# --- Scheduling & Matches ---

@router.get("/{id}/matches", response_model=List[schemas.TournamentMatchResponse])
def get_tournament_matches(id: UUID, db: Session = Depends(get_db)):
    return services.get_tournament_matches(db, id)

@router.post("/{id}/generate-schedule")
def generate_schedule(id: UUID, db: Session = Depends(get_db), current_user: User = Depends(require_tournament_organizer)):
    return services.generate_league_schedule(db, id)

@router.patch("/matches/{match_id}/result", response_model=schemas.TournamentMatchResponse)
def update_match_result(
    match_id: UUID, 
    home_score: int, 
    away_score: int, 
    db: Session = Depends(get_db), 
    current_user: User = Depends(require_tournament_organizer)
):
    return services.update_match_result(db, match_id, home_score, away_score)

# --- Standings & Stats ---

@router.get("/{id}/standings", response_model=List[schemas.TournamentStandingsResponse])
def get_tournament_standings(id: UUID, db: Session = Depends(get_db)):
    return services.get_tournament_standings(db, id)

@router.post("/match-sheets", response_model=schemas.MatchSheetCreate)
def submit_match_sheet(
    sheet_in: schemas.MatchSheetCreate,
    db: Session = Depends(get_db),
    current_user: User = Depends(require_coach)
):
    return services.submit_match_sheet(db, sheet_in, current_user)

@router.post("/match-stats")
def record_match_stats(
    match_id: UUID,
    player_profile_id: UUID,
    stats: schemas.MatchPlayerStatsCreate,
    db: Session = Depends(get_db),
    current_user: User = Depends(require_tournament_organizer)
):
    return services.record_match_player_stats(db, match_id, player_profile_id, stats.model_dump())

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
        # Note: player_id here is user_id but we need profile_id for awards usually.
        # For now, assuming player_id passed is profile_id or retrieve profile.
        from app.users.models import PlayerProfile
        profile = db.query(PlayerProfile).filter(PlayerProfile.user_id == player_id).first()
        if not profile:
            profile = db.query(PlayerProfile).filter(PlayerProfile.id == player_id).first()
        
        if not profile:
            raise HTTPException(status_code=404, detail="Player Profile not found")
            
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
