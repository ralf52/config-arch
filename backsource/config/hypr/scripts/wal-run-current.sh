#!/bin/bash
set -euo pipefail

MODE_FILE="${XDG_CACHE_HOME:-$HOME/.cache}/wallhaven/mode"
ONLINE_SCRIPT="$HOME/.config/hypr/scripts/wal-swapper_online.sh"
LOCAL_SCRIPT="$HOME/.config/hypr/scripts/wal-swapper_local.sh"

mode="online"
if [[ -f "$MODE_FILE" ]]; then
  mode="$(tr '[:upper:]' '[:lower:]' <"$MODE_FILE")"
fi

case "$mode" in
local)
  bash "$LOCAL_SCRIPT"
  ;;
online | *)
  bash "$ONLINE_SCRIPT"
  ;;
esac
