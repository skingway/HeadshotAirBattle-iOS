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

print("⏱️  Xcode Cloud 使用统计\n")

# Get recent builds
response = make_request('ciProducts')
product_id = response.json()['data'][0]['id']

response = make_request(f'ciProducts/{product_id}/workflows')
workflow_id = response.json()['data'][0]['id']

response = make_request(f'ciWorkflows/{workflow_id}/buildRuns?limit=10&sort=-number')
builds = response.json()['data']

total_minutes = 0
successful = 0
failed = 0

print("📊 最近的构建:\n")
for build in builds:
    attrs = build['attributes']
    num = attrs.get('number', 'N/A')
    status = attrs.get('completionStatus', 'N/A')
    
    started = attrs.get('startedDate')
    finished = attrs.get('finishedDate')
    
    duration = 0
    if started and finished:
        from datetime import datetime
        start_time = datetime.fromisoformat(started.replace('Z', '+00:00'))
        end_time = datetime.fromisoformat(finished.replace('Z', '+00:00'))
        duration = (end_time - start_time).total_seconds() / 60
        total_minutes += duration
        
    if status == 'SUCCEEDED':
        successful += 1
        status_icon = '✅'
    elif status == 'FAILED':
        failed += 1
        status_icon = '❌'
    else:
        status_icon = '⏳'
        
    print(f"  Build #{num}: {status_icon} {status} ({duration:.1f} 分钟)")

print(f"\n📈 统计:")
print(f"   成功: {successful}")
print(f"   失败: {failed}")
print(f"   总耗时: {total_minutes:.1f} 分钟")
print(f"   剩余额度: {1500 - total_minutes:.1f} / 1500 分钟/月")
print(f"\n💡 Build #25-28 失败很快（1-3分钟），消耗很少")
print(f"   Build #29 成功（~10分钟）但没上传 TestFlight")
print(f"   Build #30 将归档并上传（预计 15分钟）")
