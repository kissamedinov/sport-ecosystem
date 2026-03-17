import requests
import sys

def test_api():
    url = "http://localhost:8000/tournaments"
    print(f"Testing GET {url}...")
    try:
        response = requests.get(url, timeout=5)
        print(f"Status Code: {response.status_code}")
        if response.status_code == 200:
            print("SUCCESS: API returned 200 OK.")
            print(f"Response: {response.json()}")
        else:
            print(f"FAILURE: API returned {response.status_code}")
            print(f"Detail: {response.text}")
    except Exception as e:
        print(f"ERROR: {e}")

if __name__ == "__main__":
    test_api()
