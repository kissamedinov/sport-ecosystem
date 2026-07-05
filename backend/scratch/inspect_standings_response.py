import urllib.request
import json

url = "http://localhost:8000/tournaments/46bdeb91-c2cd-43b9-9a4e-35892b3d1652/standings"
with urllib.request.urlopen(url) as r:
    data = json.loads(r.read().decode())

print("Standings:")
for s in data:
    print(f"team_name={s.get('team_name')} group_id={s.get('group_id')} group_name={s.get('group_name')}")
