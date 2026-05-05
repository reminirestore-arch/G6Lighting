#!/bin/bash
# Convert assets/AppIcon-1024.png into a multi-resolution AppIcon.icns.
# macOS apps need every standard size (16…1024 pt + @2x variants) for the icon
# to look crisp in Finder, Dock, Mission Control, and Spotlight.

set -euo pipefail
cd "$(dirname "$0")/.."

SRC="assets/AppIcon-1024.png"
ICONSET="assets/AppIcon.iconset"
OUT="assets/AppIcon.icns"

if [ ! -f "$SRC" ]; then
    echo "ERROR: $SRC not found. Run: swift assets/make-icon.swift" >&2
    exit 1
fi

rm -rf "$ICONSET"
mkdir -p "$ICONSET"

# Apple's required iconset sizes
declare -a sizes=(
    "16:icon_16x16.png"
    "32:icon_16x16@2x.png"
    "32:icon_32x32.png"
    "64:icon_32x32@2x.png"
    "128:icon_128x128.png"
    "256:icon_128x128@2x.png"
    "256:icon_256x256.png"
    "512:icon_256x256@2x.png"
    "512:icon_512x512.png"
    "1024:icon_512x512@2x.png"
)

for entry in "${sizes[@]}"; do
    px="${entry%%:*}"
    name="${entry##*:}"
    sips -z "$px" "$px" "$SRC" --out "$ICONSET/$name" >/dev/null
done

iconutil -c icns "$ICONSET" -o "$OUT"
rm -rf "$ICONSET"

echo "==> Created: $OUT ($(du -h "$OUT" | cut -f1))"
