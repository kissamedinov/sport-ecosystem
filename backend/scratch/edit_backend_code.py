import os

def main():
    # 1. Update routes.py
    routes_path = 'backend/app/matches/routes.py'
    with open(routes_path, 'r', encoding='utf-8') as f:
        content = f.read()
        
    target1 = """@router.patch("/matches/{id}/finalize-result")
def finalize_result(
    id: UUID,
    db: Session = Depends(get_db),
    current_user: User = Depends(require_permission("EDIT_MATCH_STATS"))
):
    return services.finalize_match_result(db, id)"""

    replacement1 = """@router.patch("/matches/{id}/finalize-result")
def finalize_result(
    id: UUID,
    db: Session = Depends(get_db),
    current_user: User = Depends(require_permission("EDIT_MATCH_STATS"))
):
    return services.finalize_match_result(db, id)

@router.post("/matches/{id}/reset-result")
def reset_match_result(
    id: UUID,
    db: Session = Depends(get_db),
    current_user: User = Depends(require_permission("EDIT_MATCH_STATS"))
):
    return services.reset_match_result(db, id)"""

    if target1 in content and "reset_match_result" not in content:
        content = content.replace(target1, replacement1)
        with open(routes_path, 'w', encoding='utf-8') as f:
            f.write(content)
        print("routes.py updated!")
        
    # 2. Update services.py
    services_path = 'backend/app/matches/services.py'
    with open(services_path, 'r', encoding='utf-8') as f:
        content = f.read()
        
    target2 = """    return {"message": "Result finalized, ratings and standings updated successfully"}

def get_tournament_groups(db: Session, tournament_id: UUID):"""

    replacement2 = """    return {"message": "Result finalized, ratings and standings updated successfully"}

def reset_match_result(db: Session, match_id: UUID):
    from app.matches.models import MatchResult, MatchStatus
    from app.tournaments.standings_service import update_standings
    
    match = db.query(Match).filter(Match.id == match_id).first()
    if not match:
        raise HTTPException(status_code=404, detail="Match not found")
        
    result = db.query(MatchResult).filter(MatchResult.match_id == match_id).first()
    if result:
        db.delete(result)
        
    match.status = MatchStatus.SCHEDULED
    db.commit()
    
    if match.tournament_id:
        update_standings(db, match.tournament_id, match.home_team_id)
        update_standings(db, match.tournament_id, match.away_team_id)
        
    return {"message": "Match result reset successfully"}

def get_tournament_groups(db: Session, tournament_id: UUID):"""

    if target2 in content and "reset_match_result" not in content:
        content = content.replace(target2, replacement2)
        with open(services_path, 'w', encoding='utf-8') as f:
            f.write(content)
        print("services.py updated!")

if __name__ == '__main__':
    main()
