#!/bin/bash
# HeadshotAirBattle-iOS Project Setup Script
# Run this to generate the Xcode project

echo "=== HeadshotAirBattle-iOS Setup ==="

# Check for xcodegen
if ! command -v xcodegen &> /dev/null; then
    echo "xcodegen not found. Installing via Homebrew..."
    brew install xcodegen
fi

# Generate Xcode project
echo "Generating Xcode project..."
cd "$(dirname "$0")"
xcodegen generate

echo ""
echo "=== Setup Complete ==="
echo ""
echo "Next steps:"
echo "1. Copy GoogleService-Info.plist to HeadshotAirBattle/Resources/"
echo "   (Get it from Firebase Console > Project Settings > iOS app)"
echo "2. Open HeadshotAirBattle.xcodeproj in Xcode"
echo "3. Select your Development Team in Signing & Capabilities"
echo "4. Build and run (Cmd+R)"
echo ""
echo "NOTE: The app requires a GoogleService-Info.plist to connect to Firebase."
echo "Without it, the app will run in offline mode."
