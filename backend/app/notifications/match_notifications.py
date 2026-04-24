from uuid import UUID
from app.database import SessionLocal
from app.notifications import service as notification_service
from app.notifications.models import NotificationType, EntityType

def notify_stats_updated(player_id: UUID, match_id: UUID):
    db = SessionLocal()
    try:
        notification_service.create_notification(
            db,
            user_ids=[player_id],
            notification_type=NotificationType.MATCH_RESULT,
            title="Stats Updated",
            message=f"Your stats for match {match_id} have been updated.",
            entity_type=EntityType.MATCH,
            entity_id=match_id
        )
    finally:
        db.close()

def notify_best_player(player_id: UUID, match_id: UUID):
    db = SessionLocal()
    try:
        notification_service.create_notification(
            db,
            user_ids=[player_id],
            notification_type=NotificationType.BEST_PLAYER,
            title="Best Player Award!",
            message=f"Congratulations! You were selected as the BEST PLAYER in match {match_id}!",
            entity_type=EntityType.MATCH,
            entity_id=match_id
        )
    finally:
        db.close()

def notify_match_scheduled(db: SessionLocal, match_id: UUID):
    from app.matches.models import Match
    from app.teams.models import Team, TeamMembership, MembershipStatus
    from app.users.models import ParentChildRelation
    
    match = db.query(Match).filter(Match.id == match_id).first()
    if not match:
        return

    # Teams involved
    team_ids = [match.home_team_id, match.away_team_id]
    teams = db.query(Team).filter(Team.id.in_(team_ids)).all()
    
    # Notify Coaches
    coach_ids = [team.coach_id for team in teams if team.coach_id]
    if coach_ids:
        notification_service.create_notification(
            db,
            user_ids=coach_ids,
            notification_type=NotificationType.MATCH_SCHEDULED,
            title="Match Scheduled",
            message=f"Your team has a new match scheduled for {match.match_date}.",
            entity_type=EntityType.MATCH,
            entity_id=match_id
        )

    # Notify Players and Parents
    memberships = db.query(TeamMembership).filter(
        TeamMembership.team_id.in_(team_ids), 
        TeamMembership.status == MembershipStatus.ACTIVE
    ).all()
    
    recipient_ids = []
    for member in memberships:
        p_id = member.user_id # Using user_id directly from membership
        recipient_ids.append(p_id)
        
        # Add Parents
        parent_relations = db.query(ParentChildRelation).filter(ParentChildRelation.child_id == p_id).all()
        for rel in parent_relations:
             recipient_ids.append(rel.parent_id)

    if recipient_ids:
        # Batch notification
        notification_service.create_notification(
            db,
            user_ids=list(set(recipient_ids)), # Unique IDs
            notification_type=NotificationType.MATCH_SCHEDULED,
            title="New Match Scheduled",
            message=f"Match scheduled for {match.match_date}.",
            entity_type=EntityType.MATCH,
            entity_id=match_id
        )
