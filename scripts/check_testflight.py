#!/usr/bin/env python3
import jwt, time, requests
from pathlib import Path

KEY_ID = "GCUK756CLY"
ISSUER_ID = "ff0ebed6-af79-487f-a9a9-4625e2d7ddcb"
KEY_FILE = Path.home() / ".appstoreconnect" / "AuthKey_GCUK756CLY.p8"

def generate_token():
    with open(KEY_FILE, 'r') as f:
        private_key = f.read()
    return jwt.encode(
        {'iss': ISSUER_ID, 'exp': int(time.time()) + 1200, 'aud': 'appstoreconnect-v1'},
        private_key, algorithm='ES256', headers={'kid': KEY_ID, 'typ': 'JWT'}
    )

def make_request(endpoint):
    token = generate_token()
    headers = {'Authorization': f'Bearer {token}', 'Content-Type': 'application/json'}
    url = f'https://api.appstoreconnect.apple.com/v1/{endpoint}'
    return requests.get(url, headers=headers)

# Get app builds
print("🔍 Checking TestFlight builds...\n")
response = make_request('builds?limit=5&sort=-uploadedDate')

if response.status_code == 200:
    builds = response.json()['data']
    
    if builds:
        print(f"📦 Recent Builds ({len(builds)}):\n")
        for build in builds:
            attrs = build['attributes']
            print(f"  Version: {attrs.get('version', 'N/A')}")
            print(f"  Build Number: {attrs.get('buildNumber', 'N/A')}")
            print(f"  Processing State: {attrs.get('processingState', 'N/A')}")
            print(f"  Uploaded: {attrs.get('uploadedDate', 'N/A')[:19].replace('T', ' ')}")
            print()
    else:
        print("⏳ No builds in TestFlight yet. Please wait a few minutes...")
else:
    print(f"❌ Error: {response.status_code}")
    print(response.text)

print("\n💡 Next steps:")
print("   1. Wait for build to appear in TestFlight (5-10 min)")
print("   2. Download TestFlight app on your iPhone")
print("   3. Open TestFlight and find HeadshotAirBattle")
print("   4. Install and test!")
