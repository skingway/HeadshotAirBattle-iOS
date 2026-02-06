#!/usr/bin/env python3
"""
Watch Xcode Cloud Build Progress
"""
import jwt, time, requests, sys
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

def get_build_status(build_id=None):
    # Get workflow
    response = make_request('ciProducts')
    product_id = response.json()['data'][0]['id']

    response = make_request(f'ciProducts/{product_id}/workflows')
    workflow_id = response.json()['data'][0]['id']

    # Get recent builds
    response = make_request(f'ciWorkflows/{workflow_id}/buildRuns?limit=5&sort=-number')
    builds = response.json()['data']

    return builds

def format_status(status):
    status_map = {
        'RUNNING': '🏃 运行中',
        'COMPLETE': '✅ 完成',
        'PENDING': '⏳ 等待中',
        'SCHEDULED': '📅 已安排'
    }
    return status_map.get(status, status)

def format_result(result):
    result_map = {
        'SUCCEEDED': '✅ 成功',
        'FAILED': '❌ 失败',
        'CANCELED': '🚫 已取消',
        'SKIPPED': '⏭️  已跳过'
    }
    return result_map.get(result, result or '进行中...')

if __name__ == '__main__':
    print("📊 Xcode Cloud Build Status\n")

    watch_mode = '--watch' in sys.argv

    while True:
        builds = get_build_status()

        if watch_mode:
            print("\033[2J\033[H")  # Clear screen
            print("📊 Xcode Cloud Build Status (自动刷新)\n")

        for build in builds:
            attrs = build['attributes']
            num = attrs.get('number', 'N/A')
            status = format_status(attrs.get('executionProgress', 'N/A'))
            result = format_result(attrs.get('completionStatus'))
            started = attrs.get('startedDate')
            started = started[:19].replace('T', ' ') if started else 'N/A'

            print(f"  Build #{num}")
            print(f"    状态: {status}")
            print(f"    结果: {result}")
            print(f"    开始: {started}")
            print()

        if not watch_mode:
            break

        print("按 Ctrl+C 停止监视...")
        time.sleep(10)

print("\n💡 提示：")
print("   查看一次: python3 scripts/watch_build.py")
print("   持续监视: python3 scripts/watch_build.py --watch")
print("   详细日志: https://appstoreconnect.apple.com/")
