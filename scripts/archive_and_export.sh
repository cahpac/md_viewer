#!/usr/bin/env bash
set -euo pipefail

# Archive and export a Developer ID signed build.
# Edit TEAM_ID or pass TEAM_ID env var.

PROJ="md_viewer_xcode/md_viewer_xcode.xcodeproj"
SCHEME="md_viewer_xcode"
CONFIG="Release"
DERIVED=".build/xcode"
ARCHIVE_PATH=".build/archive/${SCHEME}.xcarchive"
EXPORT_PATH=".build/export"
EXPORT_PLIST="scripts/exportOptions.developer-id.plist"

TEAM_ID_DEFAULT="YOUR_TEAM_ID"
TEAM_ID="${TEAM_ID:-$TEAM_ID_DEFAULT}"

if [[ "$TEAM_ID" == "YOUR_TEAM_ID" ]]; then
  echo "Warning: set TEAM_ID env var or edit scripts/exportOptions.developer-id.plist" >&2
fi

echo "Updating export options with TEAM_ID=$TEAM_ID"
/usr/libexec/PlistBuddy -c "Set :teamID $TEAM_ID" "$EXPORT_PLIST" 2>/dev/null || true

echo "Cleaning derived data at $DERIVED"
rm -rf "$DERIVED" "$ARCHIVE_PATH" "$EXPORT_PATH" || true

echo "Archiving..."
xcodebuild -project "$PROJ" -scheme "$SCHEME" -configuration "$CONFIG" \
  -derivedDataPath "$DERIVED" -archivePath "$ARCHIVE_PATH" archive \
  CODE_SIGN_STYLE=Automatic DEVELOPMENT_TEAM="$TEAM_ID" | xcbeautify || true

echo "Exporting..."
xcodebuild -exportArchive -archivePath "$ARCHIVE_PATH" -exportOptionsPlist "$EXPORT_PLIST" -exportPath "$EXPORT_PATH"

echo "Export complete → $EXPORT_PATH"

