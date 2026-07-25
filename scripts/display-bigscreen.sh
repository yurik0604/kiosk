#!/usr/bin/env bash
#
# display-bigscreen.sh
#
# Zoom OUT the display of a connected Android device so a Flutter app lays out
# like it would on a big screen / kiosk. Lowering the DPI gives the app more
# logical dp space, so more of the UI fits (physical pixels are unchanged).
#
# Usage:
#   ./scripts/display-bigscreen.sh                 # default: density 160
#   ./scripts/display-bigscreen.sh 140             # custom density (lower = more zoomed out)
#   ./scripts/display-bigscreen.sh 160 1600x720    # custom density + force pixel size (landscape kiosk)
#   DEVICE=R9ZY907EFZR ./scripts/display-bigscreen.sh   # target a specific device
#
# Overrides PERSIST across reboots. Run ./scripts/display-reset.sh to restore.

set -euo pipefail

DENSITY="${1:-160}"
SIZE="${2:-}"

# --- pick a device ---------------------------------------------------------
if [[ -n "${DEVICE:-}" ]]; then
  SERIAL="$DEVICE"
else
  DEVICES=$(adb devices | awk 'NR>1 && $2=="device" {print $1}')
  COUNT=$(printf '%s\n' "$DEVICES" | grep -c .)
  if [[ "$COUNT" -eq 0 ]]; then
    echo "error: no device connected (adb devices shows none in 'device' state)" >&2
    exit 1
  elif [[ "$COUNT" -gt 1 ]]; then
    echo "error: multiple devices connected. Set DEVICE=<serial>:" >&2
    printf '  %s\n' "$DEVICES" >&2
    exit 1
  fi
  SERIAL="$DEVICES"
fi

ADB=(adb -s "$SERIAL")

# --- show baseline ---------------------------------------------------------
echo "Device: $SERIAL"
echo "Before:"
echo "  $("${ADB[@]}" shell wm size | tr -d '\r')"
echo "  $("${ADB[@]}" shell wm density | tr -d '\r')"

# --- apply overrides -------------------------------------------------------
echo
echo "Applying density $DENSITY..."
"${ADB[@]}" shell wm density "$DENSITY"

if [[ -n "$SIZE" ]]; then
  echo "Applying size $SIZE..."
  "${ADB[@]}" shell wm size "$SIZE"
fi

# --- confirm ---------------------------------------------------------------
echo
echo "After:"
echo "  $("${ADB[@]}" shell wm size | tr -d '\r')"
echo "  $("${ADB[@]}" shell wm density | tr -d '\r')"
echo
echo "Done. To restore the device, run: ./scripts/display-reset.sh"
