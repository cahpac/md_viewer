#!/usr/bin/env bash
set -euo pipefail

# Create a DMG file for distribution
# Usage: ./scripts/create_dmg.sh

APP_NAME="md_viewer_xcode"
APP_PATH=".build/xcode/Build/Products/Release/${APP_NAME}.app"
DMG_DIR=".build/dmg"
TEMP_DMG="${DMG_DIR}/temp.dmg"
FINAL_DMG=".build/${APP_NAME}.dmg"
VOLUME_NAME="MD Viewer"
ICON_FILE="md_viewer_xcode/md_viewer_xcode/Assets.xcassets/AppIcon.appiconset/icon_512.png"

# Get version from the app's Info.plist
VERSION=$(defaults read "$(pwd)/${APP_PATH}/Contents/Info.plist" CFBundleShortVersionString)
FINAL_DMG=".build/md_viewer_${VERSION}.dmg"

echo "Creating DMG for ${APP_NAME} v${VERSION}..."

# Check if app exists
if [ ! -d "$APP_PATH" ]; then
    echo "Error: App not found at $APP_PATH"
    echo "Please build the app first with: xcodebuild -project md_viewer_xcode/md_viewer_xcode.xcodeproj -scheme md_viewer_xcode -configuration Release clean build"
    exit 1
fi

# Clean up old DMG files
echo "Cleaning up old DMG files..."
rm -rf "$DMG_DIR" "$FINAL_DMG"
mkdir -p "$DMG_DIR"

# Copy app to DMG directory
echo "Copying app to DMG staging directory..."
cp -R "$APP_PATH" "$DMG_DIR/"

# Create symbolic link to Applications folder
echo "Creating Applications symlink..."
ln -s /Applications "$DMG_DIR/Applications"

# Calculate size needed for DMG (app size + 50MB padding)
APP_SIZE=$(du -sm "$APP_PATH" | cut -f1)
DMG_SIZE=$((APP_SIZE + 50))

echo "Creating temporary DMG (${DMG_SIZE}MB)..."
hdiutil create -srcfolder "$DMG_DIR" -volname "$VOLUME_NAME" -fs HFS+ \
    -fsargs "-c c=64,a=16,e=16" -format UDRW -size ${DMG_SIZE}m "$TEMP_DMG"

# Mount the temporary DMG
echo "Mounting temporary DMG..."
MOUNT_OUTPUT=$(hdiutil attach -readwrite -noverify -noautoopen "$TEMP_DMG" | tail -1)
MOUNT_DIR=$(echo "$MOUNT_OUTPUT" | awk '{for(i=3;i<=NF;i++) printf "%s%s", $i, (i<NF?" ":"") }')

echo "Mounted at: $MOUNT_DIR"

# Verify mount point exists
if [ ! -d "$MOUNT_DIR" ]; then
    echo "Error: Failed to mount DMG at expected location: '$MOUNT_DIR'"
    echo "Mount output: $MOUNT_OUTPUT"
    exit 1
fi

# Set custom icon on the DMG volume if icon file exists
if [ -f "$ICON_FILE" ]; then
    echo "Converting PNG to ICNS for DMG volume icon..."
    TEMP_ICNS="${DMG_DIR}/VolumeIcon.icns"

    # Create iconset from the 512x512 PNG
    ICONSET_DIR="${DMG_DIR}/VolumeIcon.iconset"
    mkdir -p "$ICONSET_DIR"

    # Generate different sizes for the iconset
    sips -z 16 16     "$ICON_FILE" --out "${ICONSET_DIR}/icon_16x16.png" > /dev/null 2>&1
    sips -z 32 32     "$ICON_FILE" --out "${ICONSET_DIR}/icon_16x16@2x.png" > /dev/null 2>&1
    sips -z 32 32     "$ICON_FILE" --out "${ICONSET_DIR}/icon_32x32.png" > /dev/null 2>&1
    sips -z 64 64     "$ICON_FILE" --out "${ICONSET_DIR}/icon_32x32@2x.png" > /dev/null 2>&1
    sips -z 128 128   "$ICON_FILE" --out "${ICONSET_DIR}/icon_128x128.png" > /dev/null 2>&1
    sips -z 256 256   "$ICON_FILE" --out "${ICONSET_DIR}/icon_128x128@2x.png" > /dev/null 2>&1
    sips -z 256 256   "$ICON_FILE" --out "${ICONSET_DIR}/icon_256x256.png" > /dev/null 2>&1
    sips -z 512 512   "$ICON_FILE" --out "${ICONSET_DIR}/icon_256x256@2x.png" > /dev/null 2>&1
    sips -z 512 512   "$ICON_FILE" --out "${ICONSET_DIR}/icon_512x512.png" > /dev/null 2>&1
    cp "$ICON_FILE" "${ICONSET_DIR}/icon_512x512@2x.png"

    # Convert iconset to icns
    iconutil -c icns "$ICONSET_DIR" -o "$TEMP_ICNS"

    # Copy icon to volume
    cp "$TEMP_ICNS" "$MOUNT_DIR/.VolumeIcon.icns"

    # Set custom icon attribute on volume
    SetFile -c icnC "$MOUNT_DIR/.VolumeIcon.icns"
    SetFile -a C "$MOUNT_DIR"

    echo "Applied custom icon to DMG volume"
else
    echo "Warning: Icon file not found at $ICON_FILE, skipping custom icon"
fi

# Configure Finder view settings
echo "Configuring Finder view settings..."
echo '
   tell application "Finder"
     tell disk "'${VOLUME_NAME}'"
           open
           set current view of container window to icon view
           set toolbar visible of container window to false
           set statusbar visible of container window to false
           set the bounds of container window to {100, 100, 600, 400}
           set viewOptions to the icon view options of container window
           set arrangement of viewOptions to not arranged
           set icon size of viewOptions to 128
           set background picture of viewOptions to file ".background:background.png"
           set position of item "'${APP_NAME}'.app" of container window to {150, 150}
           set position of item "Applications" of container window to {350, 150}
           close
           open
           update without registering applications
           delay 2
     end tell
   end tell
' | osascript || true

# Unmount the temporary DMG
echo "Unmounting DMG..."
hdiutil detach "$MOUNT_DIR"

# Convert to final compressed DMG
echo "Converting to compressed DMG..."
hdiutil convert "$TEMP_DMG" -format UDZO -imagekey zlib-level=9 -o "$FINAL_DMG"

# Clean up
echo "Cleaning up temporary files..."
rm -rf "$DMG_DIR"

echo ""
echo "✓ DMG created successfully: $FINAL_DMG"
echo "  Version: $VERSION"
ls -lh "$FINAL_DMG"
