import urllib.request, urllib.error, json, sys

BASE_URL = "http://localhost:8000"

def post_json(url, data):
    req = urllib.request.Request(
        url,
        data=json.dumps(data).encode(),
        headers={"Content-Type": "application/json"},
        method="POST"
    )
    try:
        with urllib.request.urlopen(req) as r:
            return r.status, json.loads(r.read())
    except urllib.error.HTTPError as e:
        return e.code, json.loads(e.read())

def get_json(url, token=None):
    req = urllib.request.Request(url)
    if token:
        req.add_header("Authorization", f"Bearer {token}")
    try:
        with urllib.request.urlopen(req) as r:
            return r.status, json.loads(r.read())
    except urllib.error.HTTPError as e:
        return e.code, json.loads(e.read())

results = []

# 1. Root
code, data = get_json(f"{BASE_URL}/")
results.append(("GET /", code, "PASS" if code == 200 else "FAIL"))

# 2. Register a coach
import time
ts = int(time.time())
code, data = post_json(f"{BASE_URL}/auth/register", {
    "name": "Test Coach",
    "email": f"coach{ts}@test.com",
    "password": "TestPass123!",
    "role": "COACH",
    "date_of_birth": "1990-01-01"
})
results.append(("POST /auth/register (COACH)", code, "PASS" if code == 201 else "FAIL"))
coach_token = data.get("access_token", "")
coach_id = data.get("id", "")

# 3. /auth/me
code, data = get_json(f"{BASE_URL}/auth/me", token=coach_token)
results.append(("GET /auth/me", code, "PASS" if code == 200 else "FAIL"))

# 4. GET /tournaments
code, data = get_json(f"{BASE_URL}/tournaments")
results.append(("GET /tournaments", code, "PASS" if code == 200 else "FAIL"))

# 5. GET /teams
code, data = get_json(f"{BASE_URL}/teams")
results.append(("GET /teams", code, "PASS" if code == 200 else "FAIL"))

# 6. POST /teams (create team as coach)
code, data = post_json(f"{BASE_URL}/teams", {"name": f"Test Team {ts}", "age_category": "U13"})
results.append(("POST /teams (no auth, expect 401)", code, "PASS" if code == 401 else "FAIL"))

# 7. Create team with auth
import urllib.request
req = urllib.request.Request(
    f"{BASE_URL}/teams",
    data=json.dumps({"name": f"Test Team {ts}", "age_category": "U13"}).encode(),
    headers={"Content-Type": "application/json", "Authorization": f"Bearer {coach_token}"},
    method="POST"
)
try:
    with urllib.request.urlopen(req) as r:
        code, data = r.status, json.loads(r.read())
except urllib.error.HTTPError as e:
    code, data = e.code, json.loads(e.read())
results.append(("POST /teams (COACH auth)", code, "PASS" if code == 201 else f"FAIL - {data}"))
team_id = data.get("id", "")

# 8. GET /teams/{id}
if team_id:
    code, data = get_json(f"{BASE_URL}/teams/{team_id}")
    results.append((f"GET /teams/{{id}}", code, "PASS" if code == 200 else f"FAIL - {data}"))

# Print results
print("\n===== ENDPOINT TEST RESULTS =====")
all_pass = True
for test_name, status_code, result in results:
    icon = "✓" if result.startswith("PASS") else "✗"
    if not result.startswith("PASS"):
        all_pass = False
    print(f"{icon} [{status_code}] {test_name}: {result}")

print(f"\n{'ALL TESTS PASSED' if all_pass else 'SOME TESTS FAILED'}")
