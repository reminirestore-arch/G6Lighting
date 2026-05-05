#!/bin/bash
# One-shot helper to grab a clean screenshot of the G6 Lighting popover for the README.
#
# Usage: ./assets/capture.sh
#
# Workflow:
#   1. Run this script.
#   2. You get 5 seconds — click the lightbulb in the menu bar to open the popover.
#   3. The window picker activates (no crosshair). Click the popover.
#   4. Screenshot saved to assets/screenshot.png with no shadow.

set -euo pipefail
cd "$(dirname "$0")/.."

OUT="assets/screenshot.png"
DELAY=5

echo "==> You have $DELAY seconds to open the G6 Lighting popover."
echo "    (click the lightbulb in the menu bar)"
echo ""
for i in $(seq $DELAY -1 1); do
    printf "    %d... " "$i"
    sleep 1
done
echo ""
echo "==> Now click the popover window."

# -W: window pick mode (no crosshair, just click the window).
# -o: omit window shadow.
# -t png: PNG format.
screencapture -W -o -t png "$OUT"

if [ -f "$OUT" ] && [ -s "$OUT" ]; then
    echo ""
    echo "==> Saved: $OUT ($(du -h "$OUT" | cut -f1))"
    echo "    Preview: open $OUT"
    echo "    When happy: git add assets/screenshot.png && git commit"
else
    echo ""
    echo "==> Cancelled or empty file."
fi
