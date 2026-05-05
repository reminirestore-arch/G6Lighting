#!/bin/bash
set -euo pipefail

PROJECT_DIR="$(cd "$(dirname "$0")" && pwd)"
APP_NAME="G6Lighting"
BUILD_DIR="$PROJECT_DIR/.build"
BUNDLE_DIR="$PROJECT_DIR/$APP_NAME.app"
INSTALL_DIR="/Applications"
INSTALLED_APP="$INSTALL_DIR/$APP_NAME.app"
DMG_PATH="$PROJECT_DIR/$APP_NAME.dmg"

cd "$PROJECT_DIR"

usage() {
    cat <<EOF
Usage: $0 [command]

Commands:
  build       Compile and assemble G6Lighting.app in the project directory.
              (Default if no command is given.)
  install     Build, then copy G6Lighting.app to /Applications and clear the
              quarantine attribute. After install, the app is available in
              Spotlight, Launchpad, and Finder → Applications.
  uninstall   Remove G6Lighting from /Applications. The login-item registration
              is removed by the user via System Settings → General → Login Items.
  dmg         Build, then package G6Lighting.app into a distributable .dmg.
  clean       Delete .build/ and the local G6Lighting.app bundle.
  help        Show this message.

Examples:
  ./build.sh                # build only
  ./build.sh install        # build + copy to /Applications
  ./build.sh dmg            # build + create G6Lighting.dmg for sharing
EOF
}

build_app() {
    echo "==> Compiling release binary..."
    swift build -c release --arch arm64

    local binary_path="$BUILD_DIR/arm64-apple-macosx/release/$APP_NAME"
    if [ ! -f "$binary_path" ]; then
        echo "ERROR: binary not found at $binary_path" >&2
        exit 1
    fi

    echo "==> Assembling .app bundle..."
    rm -rf "$BUNDLE_DIR"
    mkdir -p "$BUNDLE_DIR/Contents/MacOS"
    mkdir -p "$BUNDLE_DIR/Contents/Resources"

    cp "$binary_path" "$BUNDLE_DIR/Contents/MacOS/$APP_NAME"
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
    <string>14.0</string>
    <key>LSUIElement</key>
    <true/>
    <key>NSHighResolutionCapable</key>
    <true/>
</dict>
</plist>
EOF

    # Ad-hoc sign so macOS treats it as a complete app (not required, but cleaner).
    codesign --force --sign - --timestamp=none "$BUNDLE_DIR" 2>/dev/null || true

    echo "==> Built: $BUNDLE_DIR"
}

stop_running_instance() {
    if pgrep -x "$APP_NAME" >/dev/null 2>&1; then
        echo "==> Stopping running $APP_NAME instance..."
        pkill -x "$APP_NAME" 2>/dev/null || true
        sleep 1
    fi
}

install_app() {
    build_app
    stop_running_instance

    if [ ! -w "$INSTALL_DIR" ]; then
        echo "ERROR: $INSTALL_DIR is not writable. Run with sudo or install to ~/Applications." >&2
        exit 1
    fi

    echo "==> Installing to $INSTALLED_APP..."
    rm -rf "$INSTALLED_APP"
    cp -R "$BUNDLE_DIR" "$INSTALLED_APP"

    # Strip quarantine so first launch doesn't prompt Gatekeeper.
    xattr -dr com.apple.quarantine "$INSTALLED_APP" 2>/dev/null || true

    # Refresh Launch Services so Spotlight/Launchpad pick it up immediately.
    /System/Library/Frameworks/CoreServices.framework/Frameworks/LaunchServices.framework/Support/lsregister \
        -f "$INSTALLED_APP" 2>/dev/null || true

    echo ""
    echo "==> Installed."
    echo "    Launch from:  Spotlight (⌘-space, type 'G6')"
    echo "                  Launchpad"
    echo "                  Finder → Applications"
    echo "    Or right now: open -a $APP_NAME"
}

uninstall_app() {
    if [ ! -d "$INSTALLED_APP" ]; then
        echo "Not installed: $INSTALLED_APP"
        exit 0
    fi
    stop_running_instance
    echo "==> Removing $INSTALLED_APP..."
    rm -rf "$INSTALLED_APP"
    echo "==> Removed."
    echo "    To stop auto-launch at login, also visit:"
    echo "    System Settings → General → Login Items → uncheck G6Lighting"
}

create_dmg() {
    build_app
    rm -f "$DMG_PATH"

    local staging
    staging="$(mktemp -d)"
    cp -R "$BUNDLE_DIR" "$staging/"
    ln -s /Applications "$staging/Applications"

    echo "==> Creating $DMG_PATH..."
    hdiutil create \
        -volname "$APP_NAME" \
        -srcfolder "$staging" \
        -ov \
        -format UDZO \
        "$DMG_PATH" >/dev/null

    rm -rf "$staging"
    echo "==> Done: $DMG_PATH"
    echo "    Recipients open the DMG and drag $APP_NAME.app to Applications."
    echo "    First launch will need: xattr -dr com.apple.quarantine /Applications/$APP_NAME.app"
}

clean() {
    echo "==> Cleaning..."
    rm -rf "$BUILD_DIR" "$BUNDLE_DIR" "$DMG_PATH"
    echo "==> Done."
}

cmd="${1:-build}"
case "$cmd" in
    build)     build_app ;;
    install)   install_app ;;
    uninstall) uninstall_app ;;
    dmg)       create_dmg ;;
    clean)     clean ;;
    help|-h|--help) usage ;;
    *)
        echo "Unknown command: $cmd" >&2
        usage
        exit 1
        ;;
esac
