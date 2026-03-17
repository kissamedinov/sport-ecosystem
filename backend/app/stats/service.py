from sqlalchemy.orm import Session
from uuid import UUID
from typing import List, Optional

from app.stats.models import PlayerMatchStats, PlayerCareerStats
from app.stats.history_service import get_player_match_history


def get_player_career_stats(db: Session, player_id: UUID) -> Optional[PlayerCareerStats]:
    return db.query(PlayerCareerStats).filter(PlayerCareerStats.player_id == player_id).first()


# Re-export history function
def get_match_history(db: Session, player_id: UUID) -> List[dict]:
    return get_player_match_history(db, player_id)
