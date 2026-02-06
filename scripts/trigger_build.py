#!/usr/bin/env python3
"""
Trigger Xcode Cloud Build
"""
import jwt
import time
import requests
import json
from pathlib import Path

# API Configuration
KEY_ID = "GCUK756CLY"
ISSUER_ID = "ff0ebed6-af79-487f-a9a9-4625e2d7ddcb"
KEY_FILE = Path.home() / ".appstoreconnect" / "AuthKey_GCUK756CLY.p8"

def generate_token():
    """Generate JWT token for App Store Connect API"""
    with open(KEY_FILE, 'r') as f:
        private_key = f.read()

    token = jwt.encode(
        {
            'iss': ISSUER_ID,
            'exp': int(time.time()) + 1200,
            'aud': 'appstoreconnect-v1'
        },
        private_key,
        algorithm='ES256',
        headers={
            'kid': KEY_ID,
            'typ': 'JWT'
        }
    )
    return token

def make_request(endpoint, method='GET', data=None):
    """Make authenticated request to App Store Connect API"""
    token = generate_token()
    headers = {
        'Authorization': f'Bearer {token}',
        'Content-Type': 'application/json'
    }

    url = f'https://api.appstoreconnect.apple.com/v1/{endpoint}'

    if method == 'GET':
        response = requests.get(url, headers=headers)
    elif method == 'POST':
        response = requests.post(url, headers=headers, json=data)

    return response

def get_workflow_id():
    """Get the first workflow ID"""
    # Get CI products
    response = make_request('ciProducts')
    if response.status_code != 200:
        print(f"❌ Error getting CI products: {response.status_code}")
        return None

    products = response.json()['data']
    if not products:
        print("❌ No CI products found")
        return None

    product_id = products[0]['id']

    # Get workflows
    response = make_request(f'ciProducts/{product_id}/workflows')
    if response.status_code != 200:
        print(f"❌ Error getting workflows: {response.status_code}")
        return None

    workflows = response.json()['data']
    if not workflows:
        print("❌ No workflows found")
        return None

    return workflows[0]['id']

def trigger_build(workflow_id, branch='main'):
    """Trigger a build for the specified workflow"""
    # Simplified version - let Xcode Cloud use workflow's default branch
    data = {
        'data': {
            'type': 'ciBuildRuns',
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

    response = make_request('ciBuildRuns', method='POST', data=data)

    if response.status_code == 201:
        build = response.json()['data']
        print(f"\n✅ Build triggered successfully!")
        print(f"   Build ID: {build['id']}")
        print(f"   Number: {build['attributes'].get('number', 'N/A')}")
        print(f"\n📱 Check progress at: https://appstoreconnect.apple.com/")
        return build
    else:
        print(f"\n❌ Error triggering build: {response.status_code}")
        print(response.text)
        return None

def list_recent_builds(workflow_id, limit=5):
    """List recent builds for a workflow"""
    response = make_request(f'ciWorkflows/{workflow_id}/buildRuns?limit={limit}&sort=-number')

    if response.status_code == 200:
        builds = response.json()['data']
        print(f"\n📋 Recent Builds ({len(builds)}):\n")
        for build in builds:
            attrs = build['attributes']
            print(f"  Build #{attrs.get('number', 'N/A')}")
            print(f"    Status: {attrs.get('executionProgress', 'N/A')}")
            print(f"    Result: {attrs.get('completionStatus', 'N/A')}")
            print(f"    Started: {attrs.get('startedDate', 'N/A')}")
            print()
        return builds
    else:
        print(f"❌ Error listing builds: {response.status_code}")
        return None

if __name__ == '__main__':
    import sys

    print("🚀 Xcode Cloud Build Trigger\n")

    workflow_id = get_workflow_id()
    if not workflow_id:
        sys.exit(1)

    print(f"Found workflow ID: {workflow_id}\n")

    # List recent builds first
    list_recent_builds(workflow_id)

    # Ask for confirmation
    if len(sys.argv) > 1 and sys.argv[1] == '--trigger':
        branch = sys.argv[2] if len(sys.argv) > 2 else 'main'
        print(f"Triggering build for branch: {branch}...")
        trigger_build(workflow_id, branch)
    else:
        print("💡 To trigger a new build, run:")
        print("   python3 scripts/trigger_build.py --trigger [branch]")
        print("\nExample:")
        print("   python3 scripts/trigger_build.py --trigger main")
