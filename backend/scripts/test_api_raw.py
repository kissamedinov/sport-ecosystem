import urllib.request
import sys
import json

def test_api():
    url = "http://localhost:8000/tournaments"
    print(f"Testing GET {url}...")
    try:
        with urllib.request.urlopen(url, timeout=5) as response:
            status = response.getcode()
            print(f"Status Code: {status}")
            if status == 200:
                data = json.loads(response.read().decode())
                print("SUCCESS: API returned 200 OK.")
                print(f"Response: {data}")
            else:
                print(f"FAILURE: API returned {status}")
    except Exception as e:
        print(f"ERROR: {e}")

if __name__ == "__main__":
    test_api()
 Riverside:
 Riverside:
