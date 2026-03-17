from pydantic import BaseModel
from uuid import UUID
from datetime import datetime
from typing import List, Optional

class MatchHistoryItem(BaseModel):
    match_id: UUID
    tournament_name: str
    opponent: str
    goals: int
    assists: int
    yellow_cards: int
    red_cards: int
    is_best_player: bool
    date: Optional[datetime]

class PlayerCareerStatsBase(BaseModel):
    matches_played: int
    goals: int
    assists: int
    yellow_cards: int
    red_cards: int
    # minutes_played removed
    pass
    best_player_awards: int
    rating: float

class PlayerCareerStatsResponse(PlayerCareerStatsBase):
    player_id: UUID

    class Config:
        from_attributes = True
