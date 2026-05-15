
import requests
import json
import time
import random
from datetime import datetime, timedelta

BASE_URL = "http://207.154.222.151"

def login(email, password):
    resp = requests.post(f"{BASE_URL}/auth/login", json={"email": email, "password": password})
    if resp.status_code == 200:
        return resp.json()["access_token"]
    return None

def register(name, email, password, role):
    data = {
        "name": name,
        "email": email,
        "password": password,
        "role": role,
        "date_of_birth": "1990-01-01" if role in ["COACH", "CLUB_MANAGER", "TOURNAMENT_ORGANIZER"] else "2015-05-15",
        "phone": "+7707" + str(random.randint(1000000, 9999999))
    }
    resp = requests.post(f"{BASE_URL}/auth/register", json=data)
    if resp.status_code == 201:
        print(f"Registered {role}: {email}")
        return resp.json()["access_token"]
    else:
        print(f"Failed to register {email}: {resp.text}")
    return None

def create_tournament(token, name):
    headers = {"Authorization": f"Bearer {token}"}
    data = {
        "name": name,
        "description": "Premium youth tournament for 2015-2016 kids.",
        "location": "Astana, Kazakhstan",
        "start_date": (datetime.now() - timedelta(days=7)).strftime("%Y-%m-%d"),
        "end_date": (datetime.now() + timedelta(days=14)).strftime("%Y-%m-%d"),
        "registration_open": (datetime.now() - timedelta(days=30)).strftime("%Y-%m-%d"),
        "registration_close": (datetime.now() - timedelta(days=5)).strftime("%Y-%m-%d"),
        "format": "LEAGUE",
        "age_category": "2015",
        "match_half_duration": 20,
        "halftime_break_duration": 5,
        "break_between_matches": 10,
        "num_fields": 2,
        "surface_type": "ARTIFICIAL_TURF"
    }
    resp = requests.post(f"{BASE_URL}/tournaments", json=data, headers=headers)
    if resp.status_code == 201:
        return resp.json()["id"]
    print(f"Failed to create tournament: {resp.text}")
    return None

def create_team(token, name):
    headers = {"Authorization": f"Bearer {token}"}
    data = {
        "name": name,
        "description": f"Strong team {name}",
        "birth_year": 2015
    }
    resp = requests.post(f"{BASE_URL}/teams", json=data, headers=headers)
    if resp.status_code == 201:
        return resp.json()["id"]
    print(f"Failed to create team {name}: {resp.text}")
    return None

def register_team_to_tournament(token, tournament_id, team_id):
    headers = {"Authorization": f"Bearer {token}"}
    # We need to get divisions first
    div_resp = requests.get(f"{BASE_URL}/tournaments/{tournament_id}/divisions")
    if div_resp.status_code == 200 and div_resp.json():
        division_id = div_resp.json()[0]["id"]
    else:
        # If no divisions, the backend might handle it or we use tournament_id as division_id
        # Looking at routes.py: @router.post("/divisions/{division_id}/register-team")
        # Let's try to create a division first if none
        div_data = {
            "tournament_edition_id": tournament_id,
            "name": "2015 Gold Division",
            "birth_year": 2015,
            "format": "LEAGUE",
            "entry_fee": 15000
        }
        # This needs organizer token
        return None # Will handle in main
    
    resp = requests.post(f"{BASE_URL}/tournaments/divisions/{division_id}/register-team?team_id={team_id}", json="{}", headers=headers)
    if resp.status_code == 200:
        return True
    print(f"Failed to register team: {resp.text}")
    return False

def main():
    # 1. Login/Register Organizer (as ADMIN to avoid permission issues)
    org_token = login("organizer@test.com", "password")
    if not org_token:
        org_token = register("Tournament Admin", "organizer@test.com", "password", "ADMIN")
    
    if not org_token:
        print("Could not get organizer token")
        return

    # 2. Create Tournament
    t_id = create_tournament(org_token, "Aman Premium League")
    if not t_id: return
    print(f"Created Tournament: {t_id}")

    # Double check tournament exists
    headers = {"Authorization": f"Bearer {org_token}"}
    t_check = requests.get(f"{BASE_URL}/tournaments/{t_id}", headers=headers)
    print(f"Tournament check status: {t_check.status_code}")

    # 3. Create Division (as Organizer)
    headers = {"Authorization": f"Bearer {org_token}"}
    div_data = {
        "tournament_edition_id": t_id,
        "name": "Elite 2015 Division",
        "birth_year": 2015,
        "max_teams": 12,
        "entry_fee": 20000
    }
    div_resp = requests.post(f"{BASE_URL}/tournaments/divisions", json=div_data, headers=headers)
    if div_resp.status_code != 201:
        print(f"Failed to create division: {div_resp.status_code} - {div_resp.text}")
        return
    div_id = div_resp.json()["id"]
    print(f"Created Division: {div_id}")

    team_names = ["Red Dragons", "Blue Lions", "Golden Eagles", "White Wolves", "Green Tigers", "Silver Hawks"]
    random.shuffle(team_names)
    team_ids = []

    for i, name in enumerate(team_names[:4]): # Use 4 teams for league
        # 4. Register Coach
        coach_email = f"coach_{i}@test.com"
        coach_token = login(coach_email, "password")
        if not coach_token:
            coach_token = register(f"Coach {name}", coach_email, "password", "COACH")
        
        # 5. Create Team
        team_id = create_team(coach_token, name)
        team_ids.append(team_id)
        print(f"Created Team {name}: {team_id}")

        # 6. Create Players and add to team
        for p_idx in range(3):
            p_email = f"player_{i}_{p_idx}@test.com"
            p_token = login(p_email, "password")
            if not p_token:
                p_token = register(f"Player {name} {p_idx}", p_email, "password", "PLAYER_YOUTH")
            
            # Get user info to get unique_code or ID
            me_resp = requests.get(f"{BASE_URL}/auth/me", headers={"Authorization": f"Bearer {p_token}"})
            p_id = me_resp.json()["id"]
            
            # Add to team
            requests.post(f"{BASE_URL}/teams/{team_id}/players/{p_id}", headers={"Authorization": f"Bearer {coach_token}"})

        # 7. Register team to tournament division
        requests.post(f"{BASE_URL}/tournaments/divisions/{div_id}/register-team?team_id={team_id}", json="{}", headers={"Authorization": f"Bearer {coach_token}"})
        print(f"Registered {name} to tournament")

    # 8. Approve all teams (as Organizer)
    for team_id in team_ids:
        requests.patch(f"{BASE_URL}/tournaments/{t_id}/teams/{team_id}?status=APPROVED", headers=headers)
    print("Approved all teams")

    # 9. Generate and Finalize Schedule
    requests.post(f"{BASE_URL}/tournaments/{t_id}/generate-schedule", headers=headers)
    print("Generated Schedule")
    requests.post(f"{BASE_URL}/tournaments/{t_id}/finalize-schedule", headers=headers)
    print("Finalized Schedule")

    # 10. Record some results to simulate "middle of season"
    matches_resp = requests.get(f"{BASE_URL}/tournaments/{t_id}/matches")
    matches = matches_resp.json()
    
    # Let's finish first 2 matches
    for m in matches[:2]:
        m_id = m["id"]
        h_score = random.randint(0, 4)
        a_score = random.randint(0, 4)
        requests.patch(f"{BASE_URL}/tournaments/matches/{m_id}/result?home_score={h_score}&away_score={a_score}", headers=headers)
        print(f"Recorded match {m_id} result: {h_score}-{a_score}")

    print("DONE! Tournament populated successfully.")

if __name__ == "__main__":
    main()
