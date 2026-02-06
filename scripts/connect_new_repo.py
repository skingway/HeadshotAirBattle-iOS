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
    elif method == 'POST':
        return requests.post(url, headers=headers, json=data)
    elif method == 'PATCH':
        return requests.patch(url, headers=headers, json=data)

# Check if new repo exists
print("🔍 Checking for HeadshotAirBattle-iOS repository...")
response = make_request('scmRepositories')
repos = response.json()['data']

new_repo_id = None
for repo in repos:
    attrs = repo['attributes']
    if attrs.get('repositoryName') == 'HeadshotAirBattle-iOS':
        new_repo_id = repo['id']
        print(f"\n✅ Found new repository!")
        print(f"   Repository: {attrs.get('ownerName')}/{attrs.get('repositoryName')}")
        print(f"   ID: {new_repo_id}")
        break

if not new_repo_id:
    print("\n❌ New repository not connected to Xcode Cloud yet.")
    print("\n📝 You need to connect it first:")
    print("   1. Visit: https://appstoreconnect.apple.com/")
    print("   2. Go to your app → Xcode Cloud")
    print("   3. Click 'Manage' or 'Settings'")
    print("   4. Connect the HeadshotAirBattle-iOS repository")
    print("\nOr I can try to connect it via API (experimental)...")
else:
    print("\n🔧 Updating workflow to use new repository...")
    
    # Get workflow
    response = make_request('ciProducts')
    product_id = response.json()['data'][0]['id']
    
    response = make_request(f'ciProducts/{product_id}/workflows')
    workflow_id = response.json()['data'][0]['id']
    
    # Update workflow repository
    data = {
        'data': {
            'type': 'ciWorkflows',
            'id': workflow_id,
            'relationships': {
                'repository': {
                    'data': {
                        'type': 'scmRepositories',
                        'id': new_repo_id
                    }
                }
            }
        }
    }
    
    response = make_request(f'ciWorkflows/{workflow_id}', method='PATCH', data=data)
    if response.status_code == 200:
        print("✅ Workflow updated successfully!")
    else:
        print(f"❌ Error: {response.status_code}")
        print(response.text)
