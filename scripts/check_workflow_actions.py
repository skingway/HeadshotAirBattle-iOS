#!/usr/bin/env python3
import jwt, time, requests, json
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

def make_request(endpoint, method='GET', data=None):
    token = generate_token()
    headers = {'Authorization': f'Bearer {token}', 'Content-Type': 'application/json'}
    url = f'https://api.appstoreconnect.apple.com/v1/{endpoint}'
    if method == 'GET':
        return requests.get(url, headers=headers)
    elif method == 'PATCH':
        return requests.patch(url, headers=headers, json=data)

# Get workflow details
print("🔍 Checking workflow configuration...\n")
response = make_request('ciProducts')
product_id = response.json()['data'][0]['id']

response = make_request(f'ciProducts/{product_id}/workflows')
workflows = response.json()['data']
workflow = workflows[0]
workflow_id = workflow['id']

print(f"📋 Workflow: {workflow['attributes']['name']}")
print(f"   ID: {workflow_id}\n")

# Get workflow actions
response = make_request(f'ciWorkflows/{workflow_id}/buildActions')
if response.status_code == 200:
    actions = response.json()['data']
    print(f"🎬 Build Actions ({len(actions)}):")
    for action in actions:
        attrs = action['attributes']
        print(f"   - {attrs.get('actionType', 'N/A')}: {attrs.get('name', 'N/A')}")
    print()
else:
    print("   No build actions configured\n")

# Check for macOS build action (Archive)
print("💡 To upload to TestFlight, you need:")
print("   1. Archive action in the workflow")
print("   2. TestFlight post-action configured")
print("\n📝 Current workflow likely needs configuration in App Store Connect:")
print("   1. Visit: https://appstoreconnect.apple.com/")
print("   2. Go to: Apps → HeadshotAirBattle → Xcode Cloud")
print("   3. Edit the 'Default' workflow")
print("   4. In 'Archive' section:")
print("      - Enable 'Archive - iOS'")
print("      - Select deployment preparation")
print("   5. In 'Post-Actions' section:")
print("      - Add 'TestFlight Internal Testing'")
print("      - Or 'TestFlight External Testing'")
print("   6. Save the workflow")
