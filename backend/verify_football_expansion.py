import json
import urllib.request
import urllib.error
import time

BASE_URL = "http://localhost:8000"

def api_call(path, method="GET", data=None, token=None):
    url = f"{BASE_URL}{path}"
    headers = {"Content-Type": "application/json"}
    if token:
        headers["Authorization"] = f"Bearer {token}"
    
    body = json.dumps(data).encode("utf-8") if data else None
    req = urllib.request.Request(url, data=body, headers=headers, method=method)
    
    try:
        with urllib.request.urlopen(req) as response:
            return json.loads(response.read().decode("utf-8")), response.getcode()
    except urllib.error.HTTPError as e:
        content = e.read().decode("utf-8")
        try:
            return json.loads(content), e.code
        except:
            return content, e.code

def run_tests():
    print("--- 1. Registering Users ---")
    timestamp = int(time.time())
    
    # Coach
    coach_data = {
        "name": "Test Coach",
        "email": f"coach_{timestamp}@example.com",
        "password": "password123",
        "role": "COACH"
    }
    coach, status = api_call("/auth/register", "POST", coach_data)
    print(f"Coach Registration: {status}")
    if status != 201: print(f"Error: {coach}")
    coach_token = coach.get("access_token") if isinstance(coach, dict) else None
    
    # Youth Player
    child_data = {
        "name": "Youth Player",
        "email": f"youth_{timestamp}@example.com",
        "password": "password123",
        "role": "PLAYER_YOUTH",
        "date_of_birth": "2015-05-05"
    }
    child, status = api_call("/auth/register", "POST", child_data)
    print(f"Youth Registration: {status}")
    child_id = child.get("id") if isinstance(child, dict) else None
    
    # Parent
    parent_data = {
        "name": "Test Parent",
        "email": f"parent_{timestamp}@example.com",
        "password": "password123",
        "role": "PARENT"
    }
    parent, status = api_call("/auth/register", "POST", parent_data)
    print(f"Parent Registration: {status}")
    parent_token = parent.get("access_token") if isinstance(parent, dict) else None
    
    print("\n--- 2. Parent-Child Linking ---")
    link, status = api_call(f"/users/link-child/{child_id}", "POST", token=parent_token)
    print(f"Link Result: {status} - {link.get('message') if isinstance(link, dict) else link}")
    
    children, status = api_call("/users/my-children", "GET", token=parent_token)
    print(f"My Children Roster: {status} - Count: {len(children) if isinstance(children, list) else 'Error'}")
    
    print("\n--- 3. Academy & Team Creation ---")
    acad_data = {
        "name": "Test Academy",
        "city": "London",
        "address": "123 Wembley St"
    }
    academy, status = api_call("/academies", "POST", acad_data, token=coach_token)
    print(f"Academy Creation: {status}")
    academy_id = academy.get("id") if isinstance(academy, dict) else None
    
    # Create U11 Team
    team_data = {
        "name": "Thunder U11",
        "birth_year": 2015,
        "coach_id": str(coach.get("id")) if isinstance(coach, dict) else None
    }
    team, status = api_call(f"/clubs/academies/{academy_id}/teams", "POST", team_data, token=coach_token)
    print(f"Team Creation (U11): {status}")
    team_id = team.get("id") if isinstance(team, dict) else None
    
    print("\n--- 4. Age Validation ---")
    # Add 10yo child (born 2015) - Should succeed
    add, status = api_call(f"/teams/{team_id}/players/{child_id}", "POST", token=coach_token)
    print(f"Add 10yo to U11: {status}")
    
    print("\n--- 5. Tournament Creation (RBAC) ---")
    tour_data = {
        "name": "Expansion Cup",
        "location": "Central Park",
        "start_date": "2026-06-01",
        "end_date": "2026-06-05",
        "format": "Group + Knockout",
        "allowed_age_categories": ["U11", "U13"],
        "registration_open": "2026-04-01",
        "registration_close": "2026-05-15"
    }
    tour, status = api_call("/tournaments", "POST", tour_data, token=coach_token)
    print(f"Tournament Creation by COACH: {status}")
    
    print("\nVerification Finished!")

if __name__ == "__main__":
    run_tests()
