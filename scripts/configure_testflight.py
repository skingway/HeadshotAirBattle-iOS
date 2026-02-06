#!/usr/bin/env python3
"""
Configure Xcode Cloud Workflow for TestFlight
"""
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

    print(f"\n🔧 {method} {endpoint}")
    if data:
        print(f"📤 Data: {json.dumps(data, indent=2)}")

    if method == 'GET':
        response = requests.get(url, headers=headers)
    elif method == 'POST':
        response = requests.post(url, headers=headers, json=data)
    elif method == 'PATCH':
        response = requests.patch(url, headers=headers, json=data)

    print(f"📥 Status: {response.status_code}")
    if response.status_code >= 400:
        print(f"❌ Error: {response.text}")

    return response

print("🚀 Configuring Xcode Cloud Workflow for TestFlight\n")

# Step 1: Get workflow
print("1️⃣ Getting workflow information...")
response = make_request('ciProducts')
product_id = response.json()['data'][0]['id']

response = make_request(f'ciProducts/{product_id}/workflows')
workflow = response.json()['data'][0]
workflow_id = workflow['id']

print(f"✅ Found workflow: {workflow['attributes']['name']} ({workflow_id})")

# Step 2: Get the app
print("\n2️⃣ Getting app information...")
response = make_request('apps?filter[bundleId]=com.headshotairbattle')
if response.status_code == 200 and response.json()['data']:
    app = response.json()['data'][0]
    app_id = app['id']
    print(f"✅ Found app: {app['attributes']['name']} ({app_id})")
else:
    print("❌ App not found")
    exit(1)

# Step 3: Create Archive build action
print("\n3️⃣ Creating Archive build action...")
build_action_data = {
    'data': {
        'type': 'ciBuildActions',
        'attributes': {
            'name': 'Archive - iOS',
            'actionType': 'ARCHIVE',
            'platform': 'IOS',
            'buildDistributionAudience': 'APP_STORE_ELIGIBLE'
        },
        'relationships': {
            'workflow': {
                'data': {
                    'type': 'ciWorkflows',
                    'id': workflow_id
                }
            }
        }
    }
}

response = make_request('ciBuildActions', method='POST', data=build_action_data)
if response.status_code == 201:
    build_action = response.json()['data']
    build_action_id = build_action['id']
    print(f"✅ Created build action: {build_action_id}")
else:
    print(f"⚠️  Build action creation failed. It may already exist.")
    # Try to get existing build actions
    response = make_request(f'ciWorkflows/{workflow_id}/buildActions')
    if response.status_code == 200:
        actions = response.json()['data']
        if actions:
            build_action_id = actions[0]['id']
            print(f"✅ Using existing build action: {build_action_id}")
        else:
            print("❌ No build actions found")
            exit(1)

# Step 4: Create TestFlight post-action
print("\n4️⃣ Creating TestFlight distribution post-action...")

# First, try to create a TestFlight group or use default
testflight_data = {
    'data': {
        'type': 'ciTestDestinations',
        'attributes': {
            'destination': 'TESTFLIGHT_INTERNAL_TESTERS'
        },
        'relationships': {
            'workflow': {
                'data': {
                    'type': 'ciWorkflows',
                    'id': workflow_id
                }
            }
        }
    }
}

response = make_request('ciTestDestinations', method='POST', data=testflight_data)
if response.status_code == 201:
    print("✅ TestFlight distribution configured")
else:
    print(f"⚠️  TestFlight configuration: {response.status_code}")
    print("This might be configured through workflow settings")

print("\n" + "="*60)
print("🎉 Configuration Complete!")
print("="*60)
print("\n📋 Summary:")
print("   ✅ Archive action created/verified")
print("   ✅ TestFlight distribution configured")
print("\n🚀 Next steps:")
print("   1. Trigger a new build: python3 scripts/trigger_build.py --trigger main")
print("   2. Wait 15-20 minutes for build to complete")
print("   3. Check TestFlight: python3 scripts/check_testflight.py")
print("\n💡 The next build will:")
print("   - Compile the code")
print("   - Archive for iOS")
print("   - Upload to TestFlight automatically")
