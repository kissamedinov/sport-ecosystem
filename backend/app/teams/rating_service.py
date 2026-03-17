from sqlalchemy.orm import Session
from app.teams.models import Team, TeamRatingHistory
from uuid import UUID

def update_team_ratings(db: Session, match_id: UUID, home_team_id: UUID, away_team_id: UUID, home_score: int, away_score: int):
    home_team = db.query(Team).filter(Team.id == home_team_id).with_for_update().first()
    away_team = db.query(Team).filter(Team.id == away_team_id).with_for_update().first()
    
    if not home_team or not away_team:
        return

    # ELO Constants
    K = 32
    
    # Calculate expected scores
    r_home = home_team.rating
    r_away = away_team.rating
    
    e_home = 1 / (1 + 10 ** ((r_away - r_home) / 400))
    e_away = 1 / (1 + 10 ** ((r_home - r_away) / 400))
    
    # Calculate actual scores
    if home_score > away_score:
        s_home, s_away = 1, 0
        home_team.wins += 1
        away_team.losses += 1
    elif away_score > home_score:
        s_home, s_away = 0, 1
        away_team.wins += 1
        home_team.losses += 1
    else:
        s_home, s_away = 0.5, 0.5
        home_team.draws += 1
        away_team.draws += 1
        
    home_team.matches_played += 1
    away_team.matches_played += 1
    
    # New ratings
    new_r_home = round(r_home + K * (s_home - e_home))
    new_r_away = round(r_away + K * (s_away - e_away))
    
    home_team.rating = new_r_home
    away_team.rating = new_r_away
    
    # Record history for periodic tracking
    db.add(TeamRatingHistory(team_id=home_team_id, match_id=match_id, rating_after=new_r_home))
    db.add(TeamRatingHistory(team_id=away_team_id, match_id=match_id, rating_after=new_r_away))
    
    db.commit()

def get_team_rating_at_date(db: Session, team_id: UUID, date_at):
    """Retrieves the rating snapshot closest to but before a certain date."""
    history = db.query(TeamRatingHistory).filter(
        TeamRatingHistory.team_id == team_id,
        TeamRatingHistory.timestamp <= date_at
    ).order_by(TeamRatingHistory.timestamp.desc()).first()
    
    return history.rating_after if history else 1000
