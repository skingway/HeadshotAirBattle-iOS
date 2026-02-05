#!/bin/sh

# Xcode Cloud Post-Clone Script
# This script runs after the repository is cloned but before the build starts

set -e

echo "🔧 Creating Firebase placeholder config for CI builds..."

# Create Resources directory if it doesn't exist
mkdir -p "$CI_WORKSPACE/HeadshotAirBattle/Resources"

# Create GoogleService-Info.plist placeholder
cat > "$CI_WORKSPACE/HeadshotAirBattle/Resources/GoogleService-Info.plist" << 'EOF'
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
  <key>CLIENT_ID</key>
  <string>placeholder-client-id</string>
  <key>REVERSED_CLIENT_ID</key>
  <string>com.googleusercontent.apps.placeholder</string>
  <key>API_KEY</key>
  <string>placeholder-api-key</string>
  <key>GCM_SENDER_ID</key>
  <string>123456789</string>
  <key>PLIST_VERSION</key>
  <string>1</string>
  <key>BUNDLE_ID</key>
  <string>com.headshotairbattle</string>
  <key>PROJECT_ID</key>
  <string>placeholder-project</string>
  <key>STORAGE_BUCKET</key>
  <string>placeholder-project.appspot.com</string>
  <key>IS_ADS_ENABLED</key>
  <false/>
  <key>IS_ANALYTICS_ENABLED</key>
  <false/>
  <key>IS_APPINVITE_ENABLED</key>
  <false/>
  <key>IS_GCM_ENABLED</key>
  <true/>
  <key>IS_SIGNIN_ENABLED</key>
  <true/>
  <key>GOOGLE_APP_ID</key>
  <string>1:123456789:ios:placeholder</string>
  <key>DATABASE_URL</key>
  <string>https://placeholder-project.firebaseio.com</string>
</dict>
</plist>
EOF

echo "✅ Firebase config created successfully"

# List the file to confirm
ls -la "$CI_WORKSPACE/HeadshotAirBattle/Resources/GoogleService-Info.plist"

echo "✅ Post-clone script completed"
