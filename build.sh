#!/bin/bash
# Build script for Textly macOS app
# Workaround for macOS 26 beta CommandLineTools bug:
#   - SwiftBridging module is defined twice in CLT headers → fixed via -vfsoverlay
#   - VFS overlay silences the conflict so the compiler can proceed normally
set -e

APP_NAME="Textly"
BUNDLE_ID="com.textly.app"
SOURCES="Sources/Textly"
BUILD_DIR=".build/manual"
APP_BUNDLE="$BUILD_DIR/$APP_NAME.app"
SDK=$(xcrun --sdk macosx --show-sdk-path)

# Fix for CLT bug: module.modulemap and bridging.modulemap both define SwiftBridging
VFS_OVERLAY="$(mktemp /tmp/fix-bridging-XXXX.yaml)"
cat > "$VFS_OVERLAY" << 'YAML'
{
  "version": 0,
  "use-external-names": true,
  "case-sensitive": false,
  "roots": [
    {
      "name": "/Library/Developer/CommandLineTools/usr/include/swift/module.modulemap",
      "type": "file",
      "external-contents": "/dev/null"
    }
  ]
}
YAML

echo "Building $APP_NAME..."

mkdir -p "$APP_BUNDLE/Contents/MacOS"
mkdir -p "$APP_BUNDLE/Contents/Resources"

swiftc \
  -sdk "$SDK" \
  -target arm64-apple-macosx13.0 \
  -vfsoverlay "$VFS_OVERLAY" \
  -parse-as-library \
  "$SOURCES"/*.swift \
  -o "$APP_BUNDLE/Contents/MacOS/$APP_NAME"

rm -f "$VFS_OVERLAY"

# App icon
ICON_SRC="Sources/Textly/Assets/AppIcon.icns"
if [ -f "$ICON_SRC" ]; then
    cp "$ICON_SRC" "$APP_BUNDLE/Contents/Resources/AppIcon.icns"
fi

cat > "$APP_BUNDLE/Contents/Info.plist" << EOF
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
    <key>CFBundleExecutable</key>
    <string>$APP_NAME</string>
    <key>CFBundleIdentifier</key>
    <string>$BUNDLE_ID</string>
    <key>CFBundleName</key>
    <string>$APP_NAME</string>
    <key>CFBundleDisplayName</key>
    <string>$APP_NAME</string>
    <key>CFBundlePackageType</key>
    <string>APPL</string>
    <key>CFBundleShortVersionString</key>
    <string>1.5</string>
    <key>CFBundleVersion</key>
    <string>15</string>
    <key>LSMinimumSystemVersion</key>
    <string>13.0</string>
    <key>NSHighResolutionCapable</key>
    <true/>
    <key>CFBundleIconFile</key>
    <string>AppIcon</string>
    <key>NSPrincipalClass</key>
    <string>NSApplication</string>
    <key>NSSupportsAutomaticGraphicsSwitching</key>
    <true/>
</dict>
</plist>
EOF

echo ""
echo "Build succeeded: $APP_BUNDLE"
echo ""
echo "To run:  open $APP_BUNDLE"
echo "To install:  mv \"$APP_BUNDLE\" /Applications/"
