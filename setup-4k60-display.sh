#!/usr/bin/env bash
set -euo pipefail

# Modeline for 3840x2160 @ 59.97Hz (CVT-RB 533MHz pixel clock)
# This stays strictly under the Intel Haswell i915 CDCLK limit (540 MHz)
MODE_NAME="3840x2160_rb"
OUTPUT="${1:-DP-1}"

echo "Configuring ${OUTPUT} for 4K@60Hz (CVT-RB 533MHz)..."

xrandr --newmode "${MODE_NAME}" 533.00 3840 3888 3920 4000 2160 2163 2168 2222 +hsync -vsync 2>/dev/null || true
xrandr --addmode "${OUTPUT}" "${MODE_NAME}" 2>/dev/null || true
xrandr --output "${OUTPUT}" --mode "${MODE_NAME}"

echo "Successfully set ${OUTPUT} to 3840x2160 @ 60Hz!"
