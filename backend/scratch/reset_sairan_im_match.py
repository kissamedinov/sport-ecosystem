import psycopg2
import os
from dotenv import load_dotenv

load_dotenv('backend/.env')

def main():
    db_url = os.getenv('DATABASE_URL')
    print("Connecting to:", db_url)
    conn = psycopg2.connect(db_url)
    conn.autocommit = True
    cursor = conn.cursor()
    
    # 1. Find Sairan and IM teams
    cursor.execute("SELECT id, name FROM teams WHERE name LIKE %s OR name LIKE %s", ('%SAIRAN%', '%IM%'))
    teams = cursor.fetchall()
    print("Teams found:", teams)
    
    if len(teams) < 2:
        # Try finding team name matching "Invictus" for IM
        cursor.execute("SELECT id, name FROM teams WHERE name LIKE %s OR name LIKE %s", ('%SAIRAN%', '%INVICTUS%'))
        teams = cursor.fetchall()
        print("Fallback Teams found:", teams)
        
    if len(teams) < 2:
        print("Could not find both teams locally in the database.")
        conn.close()
        return
        
    team_ids = [t[0] for t in teams]
    
    # 2. Find matches between them
    cursor.execute("""
        SELECT m.id, t1.name, t2.name, m.tournament_id
        FROM matches m
        JOIN teams t1 ON m.home_team_id = t1.id
        JOIN teams t2 ON m.away_team_id = t2.id
        WHERE (m.home_team_id = %s AND m.away_team_id = %s)
           OR (m.home_team_id = %s AND m.away_team_id = %s)
    """, (team_ids[0], team_ids[1], team_ids[1], team_ids[0]))
    matches = cursor.fetchall()
    print("Matches found:", matches)
    
    for m in matches:
        match_id = m[0]
        tournament_id = m[3]
        print(f"Resetting match {match_id} ({m[1]} vs {m[2]})...")
        
        # Delete MatchResult
        cursor.execute("DELETE FROM match_results WHERE match_id = %s", (match_id,))
        
        # Reset Match Status to SCHEDULED
        cursor.execute("UPDATE matches SET status = 'SCHEDULED' WHERE id = %s", (match_id,))
        
        # Update Standings if tournament_id is set
        if tournament_id:
            # Let's import the update_standings using python from the venv
            print("Standings need to be updated. You can do this by running backend server and viewing/refreshing the table.")
            # Or we can run standard updates
            # Let's delete the tournament standings entry or update it
            # Deleting standings entries for these teams will force recalculation
            cursor.execute("DELETE FROM tournament_standings WHERE tournament_id = %s AND (team_id = %s OR team_id = %s)", (tournament_id, team_ids[0], team_ids[1]))
            print("Deleted old standings entries to force recalculation.")
            
    print("Local reset completed successfully.")
    conn.close()

if __name__ == '__main__':
    main()
