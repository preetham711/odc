#!/usr/bin/env bash
# build_ios_release.sh
# Builds the iOS release IPA and copies it to releases/ios/ODC_Tracker.ipa
#
# Usage (from project root on macOS):
#   chmod +x scripts/build_ios_release.sh
#   ./scripts/build_ios_release.sh
#
# Prerequisites:
#   - macOS with Xcode 15+
#   - Flutter SDK installed
#   - Apple Developer account configured in Xcode
#   - ios/Runner/GoogleService-Info.plist present
#   - lib/firebase_options.dart updated with real iOS values
#
# See releases/ios/IOS_INSTALL_GUIDE.md for full step-by-step instructions.

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(dirname "$SCRIPT_DIR")"
RELEASES_IOS="$PROJECT_ROOT/releases/ios"
DEST_IPA="$RELEASES_IOS/ODC_Tracker.ipa"
SOURCE_IPA="$PROJECT_ROOT/build/ios/ipa/odc_tracker_ai.ipa"

echo ""
echo "=================================================="
echo "  ODC Tracker AI — iOS Release Build"
echo "=================================================="
echo ""

# Sanity checks
if [[ "$(uname)" != "Darwin" ]]; then
    echo "ERROR: iOS builds require macOS. This script cannot run on $(uname)."
    echo "Transfer the project to a Mac and run this script there."
    exit 1
fi

if ! command -v flutter &> /dev/null; then
    echo "ERROR: flutter not found. Install Flutter and add it to PATH."
    echo "See: https://flutter.dev/docs/get-started/install/macos"
    exit 1
fi

if ! command -v xcodebuild &> /dev/null; then
    echo "ERROR: xcodebuild not found. Install Xcode from the Mac App Store."
    exit 1
fi

PLIST_PATH="$PROJECT_ROOT/ios/Runner/GoogleService-Info.plist"
if [[ ! -f "$PLIST_PATH" ]]; then
    echo "ERROR: GoogleService-Info.plist not found at:"
    echo "  $PLIST_PATH"
    echo ""
    echo "Download it from Firebase Console → your project → iOS app → GoogleService-Info.plist"
    echo "Then add it to Xcode: right-click Runner group → Add Files to Runner → tick Copy Items."
    exit 1
fi

# Ensure releases/ios exists
mkdir -p "$RELEASES_IOS"

# Step 1 — Get packages
echo "[1/4] Running: flutter pub get"
cd "$PROJECT_ROOT"
flutter pub get

# Step 2 — Install CocoaPods dependencies
echo ""
echo "[2/4] Running: pod install (in ios/)"
cd "$PROJECT_ROOT/ios"
pod install --repo-update
cd "$PROJECT_ROOT"

# Step 3 — Build IPA
echo ""
echo "[3/4] Running: flutter build ipa --release"
flutter build ipa --release

if [[ ! -f "$SOURCE_IPA" ]]; then
    echo ""
    echo "ERROR: Expected IPA not found at:"
    echo "  $SOURCE_IPA"
    echo "Check the build output above for errors."
    exit 1
fi

# Step 4 — Copy to releases
echo ""
echo "[4/4] Copying IPA to releases/ios/ODC_Tracker.ipa"
cp "$SOURCE_IPA" "$DEST_IPA"

SIZE_KB=$(du -k "$DEST_IPA" | cut -f1)
SIZE_MB=$(echo "scale=1; $SIZE_KB/1024" | bc)

echo ""
echo "=================================================="
echo "  Build complete!"
echo "=================================================="
echo ""
echo "  Output: releases/ios/ODC_Tracker.ipa"
echo "  Size:   ${SIZE_MB} MB"
echo ""
echo "Next steps:"
echo "  1. Upload to App Store Connect via Transporter:"
echo "       xcrun altool --upload-app --type ios --file \"$DEST_IPA\" \\"
echo "                    --username YOUR_APPLE_ID --password @keychain:AC_PASSWORD"
echo "  2. In App Store Connect → TestFlight → create a group and invite testers."
echo "  3. Testers install TestFlight from the App Store, then install ODC Tracker AI."
echo ""
echo "See releases/ios/IOS_INSTALL_GUIDE.md for full distribution instructions."
echo ""
