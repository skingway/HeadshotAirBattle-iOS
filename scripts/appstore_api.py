#!/usr/bin/env python3
"""
App Store Connect API Helper
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
            'exp': int(time.time()) + 1200,  # 20 minutes
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

def list_apps():
    """List all apps in App Store Connect"""
    response = make_request('apps')
    if response.status_code == 200:
        data = response.json()
        print(f"\n✅ API Connection Successful!")
        print(f"\nFound {len(data['data'])} app(s):\n")
        for app in data['data']:
            attrs = app['attributes']
            print(f"  - Name: {attrs['name']}")
            print(f"    Bundle ID: {attrs['bundleId']}")
            print(f"    SKU: {attrs['sku']}")
            print(f"    App ID: {app['id']}")
            print()
        return data['data']
    else:
        print(f"❌ Error: {response.status_code}")
        print(response.text)
        return None

def get_ci_products():
    """Get Xcode Cloud products"""
    response = make_request('ciProducts')
    if response.status_code == 200:
        data = response.json()
        print(f"\n📦 Xcode Cloud Products: {len(data['data'])}")
        for product in data['data']:
            attrs = product['attributes']
            print(f"  - Name: {attrs.get('name', 'N/A')}")
            print(f"    Product Type: {attrs.get('productType', 'N/A')}")
            print(f"    Product ID: {product['id']}")
            print()
        return data['data']
    else:
        print(f"❌ Error getting CI products: {response.status_code}")
        return None

if __name__ == '__main__':
    print("🔐 Connecting to App Store Connect API...")
    apps = list_apps()

    if apps:
        print("\n🔍 Checking Xcode Cloud configuration...")
        ci_products = get_ci_products()

def get_workflows(product_id):
    """Get all workflows for a CI product"""
    response = make_request(f'ciProducts/{product_id}/workflows')
    if response.status_code == 200:
        data = response.json()
        print(f"\n⚙️  Workflows: {len(data['data'])}")
        for workflow in data['data']:
            attrs = workflow['attributes']
            print(f"  - Name: {attrs.get('name', 'N/A')}")
            print(f"    Description: {attrs.get('description', 'N/A')}")
            print(f"    Enabled: {attrs.get('isEnabled', False)}")
            print(f"    Workflow ID: {workflow['id']}")
            print()
        return data['data']
    else:
        print(f"❌ Error getting workflows: {response.status_code}")
        print(response.text)
        return None

def get_scm_repositories():
    """Get connected SCM repositories"""
    response = make_request('scmRepositories')
    if response.status_code == 200:
        data = response.json()
        print(f"\n🔗 Connected Repositories: {len(data['data'])}")
        for repo in data['data']:
            attrs = repo['attributes']
            print(f"  - URL: {attrs.get('repositoryUrl', 'N/A')}")
            print(f"    Owner: {attrs.get('ownerName', 'N/A')}")
            print(f"    Repo ID: {repo['id']}")
            print()
        return data['data']
    else:
        print(f"❌ Error getting repositories: {response.status_code}")
        return None

# Run additional checks
print("\n🔗 Checking connected repositories...")
repos = get_scm_repositories()

if ci_products:
    product_id = ci_products[0]['id']
    workflows = get_workflows(product_id)

    if not workflows or len(workflows) == 0:
        print("\n⚠️  No workflows found. You need to:")
        print("   1. Connect your GitHub repository in App Store Connect")
        print("   2. Create a workflow in Xcode or App Store Connect")
    else:
        print("\n✅ Workflows are configured!")
