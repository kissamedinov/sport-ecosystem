from app.database import SessionLocal
from app.matches.models import Match, MatchResult
from app.tournaments.standings_service import update_standings
from app.tournaments.models import TournamentTeam
from uuid import UUID

db = SessionLocal()
T_ID = UUID('46bdeb91-c2cd-43b9-9a4e-35892b3d1652')

try:
    print("Resetting matches...")
    # 1. Reset the 4 group stage matches
    group_match_ids = [
        UUID('53d92058-bc7e-4389-9cf5-2d0890283d25'),  # Commandos vs Kultegin
        UUID('3ebf5326-d36b-480e-b78f-5101c95286d2'),  # IM vs Kultegin
        UUID('5ffd4fcc-ea11-464a-989d-b3ff45ad9a62'),  # Sairan vs Kultegin
        UUID('a7ee4deb-9d28-4ac2-878a-627155824e2b')   # Fc Arda vs Legacy
    ]
    
    for m_id in group_match_ids:
        m = db.query(Match).filter(Match.id == m_id).first()
        if m:
            m.home_score = 0
            m.away_score = 0
            m.status = 'SCHEDULED'
            
        # Delete results
        db.query(MatchResult).filter(MatchResult.match_id == m_id).delete()
        
    # 2. Reset the 6 playoff matches
    playoff_match_ids = [
        UUID('377b52c8-ee15-497b-98c0-3ba9535407c4'),  # Semifinal 1
        UUID('dc247b0e-0397-443f-a755-9c220f072124'),  # Semifinal 2
        UUID('63cc68ed-5576-4f3e-936e-2e0a816f48de'),  # 5-6th
        UUID('f544bfdd-4c6c-4d5c-beff-536a3ca877c4'),  # 7-8th
        UUID('34f770c7-8cf4-42d2-8ab2-d6e50892e529'),  # Final
        UUID('6cf1685a-305d-4c9e-8e80-850f16795d17')   # 3rd Place
    ]
    
    for m_id in playoff_match_ids:
        m = db.query(Match).filter(Match.id == m_id).first()
        if m:
            m.home_team_id = None
            m.away_team_id = None
            m.home_score = 0
            m.away_score = 0
            m.status = 'DRAFT'
            
        # Delete results
        db.query(MatchResult).filter(MatchResult.match_id == m_id).delete()
        
    db.commit()
    print("Reset match fields and deleted match results successfully.")
    
    # 3. Recalculate standings for all teams in Group A and Group B
    t_teams = db.query(TournamentTeam).filter(TournamentTeam.tournament_id == T_ID).all()
    print(f"Recalculating standings for {len(t_teams)} teams...")
    for tt in t_teams:
        update_standings(db, T_ID, tt.team_id)
        
    db.commit()
    print("Recalculated standings successfully!")
    
except Exception as e:
    db.rollback()
    print(f"Error during resetting: {e}")
finally:
    db.close()
