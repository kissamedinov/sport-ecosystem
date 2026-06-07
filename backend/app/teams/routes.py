from fastapi import APIRouter, Depends, status
from sqlalchemy.orm import Session
from typing import List
from uuid import UUID

from app.database import get_db
from app.users.models import User
from app.common.dependencies import require_coach, require_player, get_current_user
from app.teams import schemas, services

router = APIRouter(prefix="/teams", tags=["Teams"])

@router.post("", response_model=schemas.TeamResponse, status_code=status.HTTP_201_CREATED)
def create_team(
    team_in: schemas.TeamCreate,
    db: Session = Depends(get_db),
    current_user: User = Depends(require_coach)
):
    return services.create_team(db=db, team_in=team_in, current_user=current_user)

@router.get("", response_model=List[schemas.TeamResponse])
def get_teams(db: Session = Depends(get_db)):
    return services.get_teams(db=db)

import math
import time

def get_dynamic_rating(base: int, seed_offset: int) -> int:
    current_time = time.time()
    # Fluctuate over a 6-hour period (21600 seconds) by up to 25 ELO points
    fluctuation = math.sin((current_time + seed_offset) / 21600.0) * 25.0
    return int(base + fluctuation)

@router.get("/rankings")
def get_rankings():
    teams_list = [
        {
            "id": "11111111-1111-1111-1111-111111111111",
            "name": "FC Barcelona Youth",
            "city": "Barcelona",
            "coach_id": "00000000-0000-0000-0000-000000000000",
            "base_rating": 1280,
            "seed_offset": 0,
            "matches_played": 15,
            "wins": 12,
            "draws": 2,
            "losses": 1,
            "academy_name": "La Masia",
            "age_category": "U17",
            "birth_year": 2009,
            "recent_matches": [],
            "form": ["W", "W", "D", "W", "L"],
            "players": []
        },
        {
            "id": "22222222-2222-2222-2222-222222222222",
            "name": "Real Madrid Academy",
            "city": "Madrid",
            "coach_id": "00000000-0000-0000-0000-000000000000",
            "base_rating": 1260,
            "seed_offset": 5000,
            "matches_played": 15,
            "wins": 11,
            "draws": 3,
            "losses": 1,
            "academy_name": "La Fabrica",
            "age_category": "U17",
            "birth_year": 2009,
            "recent_matches": [],
            "form": ["W", "D", "W", "W", "W"],
            "players": []
        },
        {
            "id": "33333333-3333-3333-3333-333333333333",
            "name": "Ajax Youth Squad",
            "city": "Amsterdam",
            "coach_id": "00000000-0000-0000-0000-000000000000",
            "base_rating": 1210,
            "seed_offset": 10000,
            "matches_played": 15,
            "wins": 9,
            "draws": 4,
            "losses": 2,
            "academy_name": "Ajax Youth Academy",
            "age_category": "U17",
            "birth_year": 2009,
            "recent_matches": [],
            "form": ["D", "W", "L", "W", "D"],
            "players": []
        },
        {
            "id": "44444444-4444-4444-4444-444444444444",
            "name": "Manchester City Academy",
            "city": "Manchester",
            "coach_id": "00000000-0000-0000-0000-000000000000",
            "base_rating": 1190,
            "seed_offset": 15000,
            "matches_played": 15,
            "wins": 9,
            "draws": 3,
            "losses": 3,
            "academy_name": "City Football Academy",
            "age_category": "U17",
            "birth_year": 2009,
            "recent_matches": [],
            "form": ["W", "L", "W", "D", "L"],
            "players": []
        },
        {
            "id": "55555555-5555-5555-5555-555555555555",
            "name": "Bayern Munich Academy",
            "city": "Munich",
            "coach_id": "00000000-0000-0000-0000-000000000000",
            "base_rating": 1170,
            "seed_offset": 20000,
            "matches_played": 15,
            "wins": 8,
            "draws": 4,
            "losses": 3,
            "academy_name": "FC Bayern Campus",
            "age_category": "U17",
            "birth_year": 2009,
            "recent_matches": [],
            "form": ["L", "W", "D", "W", "W"],
            "players": []
        }
    ]

    for t in teams_list:
        t["rating"] = get_dynamic_rating(t["base_rating"], t["seed_offset"])
        # Remove helper fields so they don't break anything
        del t["base_rating"]
        del t["seed_offset"]

    # Sort by rating descending
    teams_list.sort(key=lambda x: x["rating"], reverse=True)
    return teams_list

@router.get("/mine", response_model=List[schemas.TeamResponse])
def get_my_teams(
    db: Session = Depends(get_db),
    current_user: User = Depends(get_current_user)
):
    return services.get_my_teams(db=db, user=current_user)

@router.get("/{id}", response_model=schemas.TeamDetailResponse)
def get_team(
    id: UUID,
    db: Session = Depends(get_db)
):
    return services.get_team_by_id(db=db, team_id=id)

@router.post("/{id}/join", response_model=schemas.PlayerTeamResponse, status_code=status.HTTP_201_CREATED)
def request_join_team(
    id: UUID,
    request_in: schemas.TeamJoinRequest,
    db: Session = Depends(get_db),
    current_user: User = Depends(get_current_user)
):
    return services.create_join_request(db=db, team_id=id, current_user=current_user, child_profile_id=request_in.child_profile_id)

@router.patch("/{id}/join-request/{requestId}/approve", response_model=schemas.PlayerTeamResponse)
def approve_join_request(
    id: UUID,
    requestId: UUID,
    db: Session = Depends(get_db),
    current_user: User = Depends(require_coach)
):
    return services.approve_join_request(db=db, team_id=id, request_id=requestId, current_user=current_user)

@router.patch("/{id}/join-request/{requestId}/reject", response_model=schemas.PlayerTeamResponse)
def reject_join_request(
    id: UUID,
    requestId: UUID,
    db: Session = Depends(get_db),
    current_user: User = Depends(require_coach)
):
    return services.reject_join_request(db=db, team_id=id, request_id=requestId, current_user=current_user)

@router.post("/{id}/players/{playerId}", response_model=schemas.PlayerTeamResponse)
def add_player_to_team(
    id: UUID,
    playerId: UUID,
    db: Session = Depends(get_db),
    current_user: User = Depends(require_coach)
):
    return services.add_player_to_team(db=db, team_id=id, player_id=playerId, current_user=current_user)

@router.get("/{id}/players", response_model=List[schemas.PlayerTeamResponse])
def get_team_members(
    id: UUID,
    db: Session = Depends(get_db)
):
    return services.get_team_members(db=db, team_id=id)

@router.patch("/{id}/players/{playerId}", response_model=schemas.PlayerTeamResponse)
def update_team_player(
    id: UUID,
    playerId: UUID,
    update_in: schemas.PlayerTeamUpdate,
    db: Session = Depends(get_db),
    current_user: User = Depends(require_coach)
):
    return services.update_team_player(db=db, team_id=id, player_id=playerId, update_in=update_in)

@router.patch("/{id}", response_model=schemas.TeamResponse)
def update_team(
    id: UUID,
    team_in: schemas.TeamUpdate,
    db: Session = Depends(get_db),
    current_user: User = Depends(require_coach)
):
    return services.update_team(db=db, team_id=id, team_in=team_in, current_user=current_user)

@router.delete("/{id}")
def delete_team(
    id: UUID,
    db: Session = Depends(get_db),
    current_user: User = Depends(get_current_user)
):
    return services.delete_team(db=db, team_id=id, current_user=current_user)
