#!/bin/bash
set -euo pipefail

PROJECT_DIR="$(cd "$(dirname "$0")" && pwd)"
APP_NAME="G6Lighting"
BUILD_DIR="$PROJECT_DIR/.build"
BUNDLE_DIR="$PROJECT_DIR/$APP_NAME.app"

cd "$PROJECT_DIR"

echo "==> Compiling release binary..."
swift build -c release --arch arm64

BINARY_PATH="$BUILD_DIR/arm64-apple-macosx/release/$APP_NAME"
if [ ! -f "$BINARY_PATH" ]; then
    echo "ERROR: binary not found at $BINARY_PATH"
    exit 1
fi

echo "==> Assembling .app bundle..."
rm -rf "$BUNDLE_DIR"
mkdir -p "$BUNDLE_DIR/Contents/MacOS"
mkdir -p "$BUNDLE_DIR/Contents/Resources"

cp "$BINARY_PATH" "$BUNDLE_DIR/Contents/MacOS/$APP_NAME"
chmod +x "$BUNDLE_DIR/Contents/MacOS/$APP_NAME"

cat > "$BUNDLE_DIR/Contents/Info.plist" <<EOF
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
    <key>CFBundleDisplayName</key>
    <string>G6 Lighting</string>
    <key>CFBundleExecutable</key>
    <string>$APP_NAME</string>
    <key>CFBundleIdentifier</key>
    <string>local.g6lighting</string>
    <key>CFBundleInfoDictionaryVersion</key>
    <string>6.0</string>
    <key>CFBundleName</key>
    <string>$APP_NAME</string>
    <key>CFBundlePackageType</key>
    <string>APPL</string>
    <key>CFBundleShortVersionString</key>
    <string>0.1.0</string>
    <key>CFBundleVersion</key>
    <string>1</string>
    <key>LSMinimumSystemVersion</key>
    <string>13.0</string>
    <key>LSUIElement</key>
    <true/>
    <key>NSHighResolutionCapable</key>
    <true/>
</dict>
</plist>
EOF

# Ad-hoc sign so macOS treats it as a complete app (not required, but cleaner).
codesign --force --sign - --timestamp=none "$BUNDLE_DIR" 2>/dev/null || true

echo "==> Done: $BUNDLE_DIR"
echo "    Run with:  open \"$BUNDLE_DIR\""
echo "    Or:        \"$BUNDLE_DIR/Contents/MacOS/$APP_NAME\""
echo "    Tests:     swift run G6LightingTestRunner --testing-library swift-testing"
