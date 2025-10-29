#!/usr/bin/env bash
set -euo pipefail

# Notarize a .app or .dmg using notarytool and staple the ticket.
# Prereqs:
#   xcrun notarytool store-credentials AC_PASSWORD --apple-id you@example.com --team-id YOUR_TEAM_ID --password 'app-specific-password'
# Usage:
#   scripts/notarize.sh path/to/MDViewer.dmg
#   scripts/notarize.sh .build/export/md_viewer_xcode.app

if [[ $# -lt 1 ]]; then
  echo "Usage: $0 <path-to-app-or-dmg>" >&2
  exit 64
fi

INPUT_PATH="$1"
if [[ ! -e "$INPUT_PATH" ]]; then
  echo "Error: file not found: $INPUT_PATH" >&2
  exit 66
fi

EXT="${INPUT_PATH##*.}"
TMPZIP=""
TARGET="$INPUT_PATH"

if [[ "$EXT" == "app" ]]; then
  TMPZIP="${INPUT_PATH%.app}.zip"
  echo "Zipping app to $TMPZIP"
  /usr/bin/ditto -c -k --sequesterRsrc --keepParent "$INPUT_PATH" "$TMPZIP"
  TARGET="$TMPZIP"
fi

echo "Submitting to notary service..."
xcrun notarytool submit "$TARGET" --keychain-profile AC_PASSWORD --wait

if [[ "$EXT" == "app" ]]; then
  echo "Stapling to .app"
  xcrun stapler staple "$INPUT_PATH"
  xcrun stapler validate "$INPUT_PATH"
else
  echo "Stapling to .dmg"
  xcrun stapler staple "$INPUT_PATH"
  xcrun stapler validate "$INPUT_PATH"
fi

echo "Notarization complete."

