#!/bin/sh

# Xcode Cloud Post-Clone Script
# This script runs after the repository is cloned but before the build starts

set -e

echo "🔧 Creating Firebase placeholder config for CI builds..."

# Debug: Print environment variables
echo "CI_WORKSPACE: $CI_WORKSPACE"
echo "CI_PRIMARY_REPOSITORY_PATH: $CI_PRIMARY_REPOSITORY_PATH"
echo "PWD: $(pwd)"

# Determine the correct path
if [ -n "$CI_PRIMARY_REPOSITORY_PATH" ]; then
    REPO_PATH="$CI_PRIMARY_REPOSITORY_PATH"
elif [ -n "$CI_WORKSPACE" ]; then
    REPO_PATH="$CI_WORKSPACE"
else
    REPO_PATH="$(pwd)"
fi

echo "Using repository path: $REPO_PATH"

# Create Resources directory if it doesn't exist
RESOURCES_DIR="$REPO_PATH/HeadshotAirBattle/Resources"
echo "Creating directory: $RESOURCES_DIR"
mkdir -p "$RESOURCES_DIR"

# Create GoogleService-Info.plist placeholder
CONFIG_FILE="$RESOURCES_DIR/GoogleService-Info.plist"
echo "Creating config file: $CONFIG_FILE"

cat > "$CONFIG_FILE" << 'EOF'
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

if [ -f "$CONFIG_FILE" ]; then
    echo "✅ Firebase config created successfully"
    ls -la "$CONFIG_FILE"
else
    echo "❌ Failed to create Firebase config"
    exit 1
fi

echo "✅ Post-clone script completed"
