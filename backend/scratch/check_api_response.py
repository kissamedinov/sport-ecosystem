import json
import urllib.request

try:
    url = 'http://localhost:8000/tournaments/46bdeb91-c2cd-43b9-9a4e-35892b3d1652/matches'
    with urllib.request.urlopen(url, timeout=5) as r:
        data = json.load(r)
    playoff = [m for m in data if not m.get('group_id')]
    print(f'TOTAL MATCHES: {len(data)}, PLAYOFF: {len(playoff)}')
    for m in playoff[:4]:
        print(f"  round={m.get('round_number')} pos={m.get('bracket_position')} field_name={m.get('field_name')}")
except Exception as e:
    print(f"Error: {e}")
