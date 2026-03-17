from sqlalchemy.orm import Session
from fastapi import HTTPException, status
from uuid import UUID
from typing import List, Dict

from app.matches.models import Match, MatchPlayerStats, MatchLineup, MatchLineupPlayer
from app.stats.models import PlayerCareerStats
from app.users.models import User

def update_player_match_stats(
    db: Session, 
    match_id: UUID, 
    stats_list: List[Dict]
):
    match = db.query(Match).filter(Match.id == match_id).first()
    if not match:
        raise HTTPException(status_code=404, detail="Match not found")
        
    # Check if a best player is already set or if multiple are provided
    best_player_count = sum(1 for s in stats_list if s.get("is_best_player", False))
    if best_player_count > 1:
        raise HTTPException(status_code=400, detail="Only one best player allowed per match")
        
    for stats_data in stats_list:
        p_id = stats_data["player_id"]
        team_id = stats_data["team_id"]
        
        # Verify player was in the lineup
        lineup = db.query(MatchLineup).filter(MatchLineup.match_id == match_id, MatchLineup.team_id == team_id).first()
        if not lineup:
            raise HTTPException(status_code=400, detail=f"No lineup submitted for team {team_id} in this match")
            
        lp = db.query(MatchLineupPlayer).filter(MatchLineupPlayer.lineup_id == lineup.id, MatchLineupPlayer.player_id == p_id).first()
        if not lp:
             raise HTTPException(status_code=400, detail=f"Player {p_id} was not in the match lineup")

        # Create or update stats
        stats = db.query(MatchPlayerStats).filter(
            MatchPlayerStats.match_id == match_id, 
            MatchPlayerStats.player_id == p_id
        ).first()
        
        if not stats:
            stats = MatchPlayerStats(match_id=match_id, player_id=p_id, team_id=team_id)
            db.add(stats)
            
        stats.goals = stats_data.get("goals", 0)
        stats.assists = stats_data.get("assists", 0)
        stats.yellow_cards = stats_data.get("yellow_cards", 0)
        stats.red_cards = stats_data.get("red_cards", 0)
        # minutes_played removed
        stats.is_best_player = stats_data.get("is_best_player", False)
        
        # Trigger Notifications
        from app.notifications.match_notifications import notify_stats_updated, notify_best_player
        notify_stats_updated(p_id, match_id)
        if stats.is_best_player:
            notify_best_player(p_id, match_id)
        
        # Auto-update Career Stats
        update_career_stats(db, p_id)
        
    db.commit()
    return {"message": "Match stats updated successfully"}

def update_career_stats(db: Session, player_id: UUID):
    career = db.query(PlayerCareerStats).filter(PlayerCareerStats.player_id == player_id).first()
    if not career:
        career = PlayerCareerStats(player_id=player_id)
        db.add(career)
        
    # Aggregate all match stats
    all_stats = db.query(MatchPlayerStats).filter(MatchPlayerStats.player_id == player_id).all()
    
    career.matches_played = len(all_stats)
    career.goals = sum(s.goals for s in all_stats)
    career.assists = sum(s.assists for s in all_stats)
    career.yellow_cards = sum(s.yellow_cards for s in all_stats)
    career.red_cards = sum(s.red_cards for s in all_stats)
    # minutes_played removed
    pass
    
    # Simple average rating if ratings were provided (optional extension)
    ratings = [s.rating for s in all_stats if s.rating is not None]
    if ratings:
        career.rating = sum(ratings) / len(ratings)
