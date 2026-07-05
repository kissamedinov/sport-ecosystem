import os

def main():
    filepath = 'backend/app/matches/services.py'
    with open(filepath, 'r', encoding='utf-8') as f:
        content = f.read()

    # Define the helper functions if not already present
    if "def seed_playoffs_automatically" not in content:
        helper_target = "def reset_match_result(db: Session, match_id: UUID):"
        helper_replacement = """def seed_playoffs_automatically(db: Session, tournament_id: UUID):
    from app.tournaments.models import TournamentGroup, TournamentStandings
    from app.matches.models import Match
    
    # Get groups sorted alphabetically (Group A, Group B)
    groups = db.query(TournamentGroup).filter(TournamentGroup.tournament_id == tournament_id).all()
    if len(groups) != 2:
        return
        
    sorted_groups = sorted(groups, key=lambda g: g.name)
    group_a_id = sorted_groups[0].id
    group_b_id = sorted_groups[1].id
    
    # Get standings for both groups
    standings_a = db.query(TournamentStandings).filter(
        TournamentStandings.tournament_id == tournament_id,
        TournamentStandings.group_id == group_a_id
    ).order_by(
        TournamentStandings.points.desc(),
        TournamentStandings.goal_difference.desc(),
        TournamentStandings.goals_for.desc()
    ).all()
    
    standings_b = db.query(TournamentStandings).filter(
        TournamentStandings.tournament_id == tournament_id,
        TournamentStandings.group_id == group_b_id
    ).order_by(
        TournamentStandings.points.desc(),
        TournamentStandings.goal_difference.desc(),
        TournamentStandings.goals_for.desc()
    ).all()
    
    if len(standings_a) < 2 or len(standings_b) < 2:
        return
        
    A1_id = standings_a[0].team_id
    A2_id = standings_a[1].team_id
    B1_id = standings_b[0].team_id
    B2_id = standings_b[1].team_id
    
    # Update Semifinals:
    # SF 1: A1 vs B2 (bracket_position=0)
    sf1 = db.query(Match).filter(
        Match.tournament_id == tournament_id,
        Match.group_id.is_(None),
        Match.round_number == 1,
        Match.bracket_position == 0
    ).first()
    if sf1:
        sf1.home_team_id = A1_id
        sf1.away_team_id = B2_id
        
    # SF 2: B1 vs A2 (bracket_position=1)
    sf2 = db.query(Match).filter(
        Match.tournament_id == tournament_id,
        Match.group_id.is_(None),
        Match.round_number == 1,
        Match.bracket_position == 1
    ).first()
    if sf2:
        sf2.home_team_id = B1_id
        sf2.away_team_id = A2_id
        
    # Update 5-6th Place: A3 vs B3 (bracket_position=2)
    if len(standings_a) >= 3 and len(standings_b) >= 3:
        m5 = db.query(Match).filter(
            Match.tournament_id == tournament_id,
            Match.group_id.is_(None),
            Match.round_number == 1,
            Match.bracket_position == 2
        ).first()
        if m5:
            m5.home_team_id = standings_a[2].team_id
            m5.away_team_id = standings_b[2].team_id
            
    # Update 7-8th Place: A4 vs B4 (bracket_position=3)
    if len(standings_a) >= 4 and len(standings_b) >= 4:
        m7 = db.query(Match).filter(
            Match.tournament_id == tournament_id,
            Match.group_id.is_(None),
            Match.round_number == 1,
            Match.bracket_position == 3
        ).first()
        if m7:
            m7.home_team_id = standings_a[3].team_id
            m7.away_team_id = standings_b[3].team_id
            
    db.commit()

def update_next_playoff_match(db: Session, match: Match):
    from app.matches.models import MatchResult, Match
    
    result = db.query(MatchResult).filter(MatchResult.match_id == match.id).first()
    if not result:
        return
        
    winner_id = match.home_team_id if result.home_score >= result.away_score else match.away_team_id
    loser_id = match.away_team_id if result.home_score >= result.away_score else match.home_team_id
    
    # Find Final and 3rd Place matches:
    final_match = db.query(Match).filter(
        Match.tournament_id == match.tournament_id,
        Match.group_id.is_(None),
        Match.round_number == 2,
        Match.bracket_position == 0
    ).first()
    
    third_place_match = db.query(Match).filter(
        Match.tournament_id == match.tournament_id,
        Match.group_id.is_(None),
        Match.round_number == 2,
        Match.bracket_position == 1
    ).first()
    
    if match.bracket_position == 0:
        # Semifinal 1: updates Home teams
        if final_match:
            final_match.home_team_id = winner_id
        if third_place_match:
            third_place_match.home_team_id = loser_id
    elif match.bracket_position == 1:
        # Semifinal 2: updates Away teams
        if final_match:
            final_match.away_team_id = winner_id
        if third_place_match:
            third_place_match.away_team_id = loser_id
            
    db.commit()

def reset_match_result(db: Session, match_id: UUID):"""
        content = content.replace(helper_target, helper_replacement)
        print("Helpers appended to services.py!")
    else:
        print("Helpers already exist!")

    with open(filepath, 'w', encoding='utf-8') as f:
        f.write(content)
    print("Done!")

if __name__ == '__main__':
    main()
