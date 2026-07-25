#!/usr/bin/env bash
#
# display-reset.sh
#
# Restore a connected Android device's display to its factory density and size,
# undoing any overrides applied by display-bigscreen.sh.
#
# Usage:
#   ./scripts/display-reset.sh
#   DEVICE=R9ZY907EFZR ./scripts/display-reset.sh   # target a specific device

set -euo pipefail

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

echo "Device: $SERIAL"
echo "Resetting display size and density to factory defaults..."
"${ADB[@]}" shell wm density reset
"${ADB[@]}" shell wm size reset

echo
echo "After:"
echo "  $("${ADB[@]}" shell wm size | tr -d '\r')"
echo "  $("${ADB[@]}" shell wm density | tr -d '\r')"
echo
echo "Restored."
