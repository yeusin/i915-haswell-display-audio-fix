#!/usr/bin/env bash
set -euo pipefail

OUTPUT="${1:-DP-1}"

echo "Registering custom display modes for Intel Haswell (${OUTPUT})..."

# 1. 3008x1692 @ 60Hz (CVT-RB 330.50MHz) - Standard macOS HiDPI scaling mode
xrandr --newmode "3008x1692" 330.50 3008 3056 3088 3168 1692 1695 1700 1741 +hsync -vsync 2>/dev/null || true
xrandr --addmode "${OUTPUT}" "3008x1692" 2>/dev/null || true
xrandr --addmode "eDP-1" "3008x1692" 2>/dev/null || true

# 2. 3840x2160 @ 60Hz (CVT-RB 533.00MHz) - Under 540MHz Haswell CDCLK cap
xrandr --newmode "3840x2160_rb" 533.00 3840 3888 3920 4000 2160 2163 2168 2222 +hsync -vsync 2>/dev/null || true
xrandr --addmode "${OUTPUT}" "3840x2160_rb" 2>/dev/null || true

# Apply 3840x2160_rb by default, or apply specified mode if passed as 2nd arg
TARGET_MODE="${2:-3840x2160_rb}"
xrandr --output "${OUTPUT}" --mode "${TARGET_MODE}"

echo "Successfully configured ${OUTPUT} (Active mode: ${TARGET_MODE})!"
