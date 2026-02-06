#!/usr/bin/env python3
"""
Check Xcode Cloud Workflow Configuration
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
    with open(KEY_FILE, 'r') as f:
        private_key = f.read()
    token = jwt.encode(
        {'iss': ISSUER_ID, 'exp': int(time.time()) + 1200, 'aud': 'appstoreconnect-v1'},
        private_key, algorithm='ES256', headers={'kid': KEY_ID, 'typ': 'JWT'}
    )
    return token

def make_request(endpoint):
    token = generate_token()
    headers = {'Authorization': f'Bearer {token}', 'Content-Type': 'application/json'}
    url = f'https://api.appstoreconnect.apple.com/v1/{endpoint}'
    return requests.get(url, headers=headers)

# Get repositories
print("🔍 Checking SCM Repositories...\n")
response = make_request('scmRepositories')
if response.status_code == 200:
    repos = response.json()['data']
    for repo in repos:
        repo_id = repo['id']
        attrs = repo['attributes']
        print(f"📦 Repository:")
        print(f"   ID: {repo_id}")
        print(f"   Owner: {attrs.get('ownerName', 'N/A')}")
        print(f"   Repository Name: {attrs.get('repositoryName', 'N/A')}")
        print(f"   URL: {attrs.get('httpCloneUrl', 'N/A')}")
        print(f"   SSH URL: {attrs.get('sshCloneUrl', 'N/A')}")
        print()

# Get workflows with details
print("\n⚙️  Checking Workflow Configuration...\n")
response = make_request('ciProducts')
if response.status_code == 200:
    products = response.json()['data']
    for product in products:
        product_id = product['id']

        # Get workflows
        response = make_request(f'ciProducts/{product_id}/workflows?include=repository')
        if response.status_code == 200:
            data = response.json()
            workflows = data['data']

            for workflow in workflows:
                workflow_id = workflow['id']
                attrs = workflow['attributes']

                print(f"🔧 Workflow: {attrs.get('name', 'N/A')}")
                print(f"   ID: {workflow_id}")
                print(f"   Description: {attrs.get('description', 'N/A')}")
                print(f"   Enabled: {attrs.get('isEnabled', False)}")
                print(f"   Branch: {attrs.get('branchStartCondition', {}).get('source', {}).get('branchName', 'N/A')}")

                # Get repository relationship
                if 'relationships' in workflow and 'repository' in workflow['relationships']:
                    repo_data = workflow['relationships']['repository'].get('data')
                    if repo_data:
                        repo_id = repo_data.get('id')
                        print(f"   Connected Repository ID: {repo_id}")

                        # Get repository details
                        repo_response = make_request(f'scmRepositories/{repo_id}')
                        if repo_response.status_code == 200:
                            repo_attrs = repo_response.json()['data']['attributes']
                            print(f"   Repository: {repo_attrs.get('ownerName', 'N/A')}/{repo_attrs.get('repositoryName', 'N/A')}")
                            print(f"   Clone URL: {repo_attrs.get('httpCloneUrl', 'N/A')}")

                print()

print("\n💡 GitHub Repositories:")
print("   Current project: https://github.com/skingway/HeadshotAirBattle-iOS")
