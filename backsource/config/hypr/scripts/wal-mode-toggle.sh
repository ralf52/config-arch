#!/bin/bash
set -euo pipefail

MODE_FILE="${XDG_CACHE_HOME:-$HOME/.cache}/wallhaven/mode"
mkdir -p "$(dirname "$MODE_FILE")"

current_mode="online"
if [[ -f "$MODE_FILE" ]]; then
  current_mode="$(tr '[:upper:]' '[:lower:]' < "$MODE_FILE")"
fi

case "$current_mode" in
  online)
    new_mode="local"
    ;;
  local)
    new_mode="online"
    ;;
  *)
    new_mode="online"
    ;;
esac

printf "%s\n" "$new_mode" > "$MODE_FILE"

if command -v notify-send >/dev/null 2>&1; then
  notify-send "Wallpaper mode" "Modo activo: $new_mode"
fi
