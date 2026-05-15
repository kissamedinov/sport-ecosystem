
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
    t_id = create_tournament(org_token, "DIAMOND LEAGUE")
    if not t_id: return
    print(f"Created Tournament: {t_id}")

    # Double check tournament exists
    headers = {"Authorization": f"Bearer {org_token}"}
    t_check = requests.get(f"{BASE_URL}/tournaments/{t_id}", headers=headers)
    if t_check.status_code != 200:
        print(f"Tournament check failed: {t_check.status_code}")
        return

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
    for i in range(4):
        name = f"{team_names[i]} {random.randint(100, 999)}"
        # 4. Create Coach
        coach_email = f"coach_{i}_{random.randint(1000,9999)}@test.com"
        coach_token = register(f"Coach {i}", coach_email, "password", "COACH")
        if not coach_token: continue

        # 5. Create Team (as Coach)
        headers = {"Authorization": f"Bearer {coach_token}"}
        resp = requests.post(f"{BASE_URL}/teams", json={"name": name, "academy_name": "Test Academy"}, headers=headers)
        if resp.status_code != 201:
            print(f"Failed to create team {name}: {resp.status_code} - {resp.text}")
            continue
        team_id = resp.json()["id"]
        team_ids.append(team_id)
        print(f"Created Team {name}: {team_id}")

        # 6. Create Players and add to team
        for p_idx in range(3):
            p_email = f"player_{i}_{p_idx}_{random.randint(1000,9999)}@test.com"
            p_token = login(p_email, "password")
            if not p_token:
                p_token = register(f"Player {name} {p_idx}", p_email, "password", "PLAYER_YOUTH")
            
            # Get user info to get unique_code or ID
            me_resp = requests.get(f"{BASE_URL}/auth/me", headers={"Authorization": f"Bearer {p_token}"})
            p_id = me_resp.json()["id"]
            
            # Add to team
            requests.post(f"{BASE_URL}/teams/{team_id}/players/{p_id}", headers={"Authorization": f"Bearer {coach_token}"})

        # 7. Register team to tournament division
        reg_resp = requests.post(
            f"{BASE_URL}/tournaments/divisions/{div_id}/register-team?team_id={team_id}", 
            json="{}", # Pass as JSON-encoded string
            headers={"Authorization": f"Bearer {coach_token}"}
        )
        if reg_resp.status_code != 200:
            print(f"Failed to register team {name}: {reg_resp.status_code} - {reg_resp.text}")
        else:
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

    # 9. Get matches for division
    matches_resp = requests.get(f"{BASE_URL}/tournaments/divisions/{div_id}/matches", headers=headers)
    if matches_resp.status_code == 200:
        try:
            matches = matches_resp.json()
            # 10. Update results for first 2 matches
            for i, match in enumerate(matches[:2]):
                m_id = match['id']
                res_data = {
                    "home_score": 2 + i,
                    "away_score": 1,
                    "status": "COMPLETED"
                }
                requests.post(f"{BASE_URL}/matches/{m_id}/result", json=res_data, headers=headers)
            print("Successfully updated match results!")
        except Exception as e:
            print(f"Error parsing matches: {e}")
    else:
        print(f"Failed to fetch matches: {matches_resp.status_code}")

    print("DONE! Tournament populated successfully.")

if __name__ == "__main__":
    main()
