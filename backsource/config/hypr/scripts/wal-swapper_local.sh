#!/bin/bash
set -o pipefail

# Bloquear para evitar múltiples ejecuciones simultáneas
exec 200>/tmp/wallpaper_script.lock
flock -n 200 || {
  echo "Script ya en ejecución, se omite esta corrida"
  exit 0
}

CACHE_DIR="${XDG_CACHE_HOME:-$HOME/.cache}/wallhaven"
MIN_SECONDS_BETWEEN_RUNS="${WALLHAVEN_MIN_SECONDS_BETWEEN_RUNS:-8}"
RUN_STAMP_FILE="$CACHE_DIR/.last_run"
WALLPAPER_DIR="${WALLPAPER_DIR:-$HOME/Imágenes/fdp/v00/}"
DRY_RUN="${WAL_SWAPPER_DRY_RUN:-0}"
HYPR_RELOAD_TIMEOUT="${HYPR_RELOAD_TIMEOUT:-5}"
PYWAL_CACHE_TIMEOUT="${PYWAL_CACHE_TIMEOUT:-15}"

mkdir -p "$CACHE_DIR"

log() {
  echo "[wal-swapper] $*"
}

is_dry_run() {
  [[ "$DRY_RUN" == "1" ]]
}

run_cmd() {
  if is_dry_run; then
    log "DRY-RUN: $*"
    return 0
  fi

  "$@"
}

ensure_awww_ready() {
  local cache_dir

  if is_dry_run; then
    log "DRY-RUN: se omite validación de awww"
    return 0
  fi

  if ! command -v awww >/dev/null 2>&1; then
    echo "awww no esta instalado" >&2
    return 1
  fi

  cache_dir="${XDG_CACHE_HOME:-$HOME/.cache}/awww"
  mkdir -p "$cache_dir"

  if ! awww query >/dev/null 2>&1; then
    if command -v systemctl >/dev/null 2>&1; then
      systemctl --user start awww.service >/dev/null 2>&1 || true
      sleep 0.2
    fi
  fi

  if ! awww query >/dev/null 2>&1; then
    echo "awww-daemon no esta disponible" >&2
    return 1
  fi

  return 0
}

should_skip_recent_run() {
  local now
  local last_run=0

  now="$(date +%s)"

  if [[ -f "$RUN_STAMP_FILE" ]]; then
    last_run="$(stat -c %Y "$RUN_STAMP_FILE" 2>/dev/null || echo 0)"
  fi

  if ((now - last_run < MIN_SECONDS_BETWEEN_RUNS)); then
    return 0
  fi

  touch "$RUN_STAMP_FILE"
  return 1
}

if should_skip_recent_run; then
  echo "Ejecución omitida por anti-rebote (${MIN_SECONDS_BETWEEN_RUNS}s)"
  exit 0
fi

if ! command -v wal >/dev/null 2>&1; then
  echo "wal no esta instalado" >&2
  exit 1
fi

if [[ ! -d "$WALLPAPER_DIR" ]]; then
  echo "No existe la carpeta de wallpapers: $WALLPAPER_DIR" >&2
  exit 1
fi

log "Buscando wallpapers en: $WALLPAPER_DIR"

SELECTED_WALLPAPER=$(find "$WALLPAPER_DIR" -type f \( -iname "*.jpg" -o -iname "*.png" -o -iname "*.jpeg" \) | shuf -n 1)
if [[ -z "$SELECTED_WALLPAPER" ]]; then
  echo "No se encontro un wallpaper valido en $WALLPAPER_DIR" >&2
  exit 1
fi

ensure_awww_ready || exit 1

if ! run_cmd awww img "$SELECTED_WALLPAPER" --transition-type any; then
  echo "No se pudo aplicar wallpaper con awww" >&2
  exit 1
fi

update_nvim_colors() {
  local socket
  local -a sockets=()

  if command -v nvr >/dev/null 2>&1; then
    while IFS= read -r socket; do
      sockets+=("$socket")
    done < <(nvr --serverlist 2>/dev/null || true)
  fi

  while IFS= read -r socket; do
    sockets+=("$socket")
  done < <(find /tmp "/run/user/$UID" -type s -name "nvim*" 2>/dev/null || true)

  if ((${#sockets[@]} == 0)); then
    return 0
  fi

  while IFS= read -r socket; do
    nvim --server "$socket" --remote-expr "execute('silent! colorscheme pywal')" >/dev/null 2>&1 || true
    nvim --server "$socket" --remote-send '<Cmd>silent! doautocmd ColorScheme<CR>' >/dev/null 2>&1 || true
  done < <(printf '%s\n' "${sockets[@]}" | awk 'NF' | sort -u)
}

refresh_gtk_theme() {
  local fallback_theme="Breeze-Dark"
  local target_theme="Breeze-Dark-Simple-wall"

  if ! command -v gsettings >/dev/null 2>&1; then
    echo "gsettings no esta disponible; se omite refresco de tema GTK" >&2
    return 0
  fi

  gsettings set org.gnome.desktop.interface gtk-theme "$fallback_theme" >/dev/null 2>&1 || true
  sleep 0.1
  gsettings set org.gnome.desktop.interface gtk-theme "$target_theme" >/dev/null 2>&1 || true
}

refresh_kde_colorscheme() {
  local fallback_scheme="BreezeDark"
  local target_scheme="BreezeDarkPywal"

  if ! command -v plasma-apply-colorscheme >/dev/null 2>&1; then
    echo "plasma-apply-colorscheme no esta disponible; se omite refresco de esquema KDE" >&2
    return 0
  fi

  plasma-apply-colorscheme "$fallback_scheme" >/dev/null 2>&1 || true
  sleep 0.1
  plasma-apply-colorscheme "$target_scheme" >/dev/null 2>&1 || true
}

wait_for_pywal_cache() {
  local start_epoch="$1"
  local timeout_s="${PYWAL_CACHE_TIMEOUT:-15}"
  local cache_dir="${XDG_CACHE_HOME:-$HOME/.cache}/wal"
  local colors_file="$cache_dir/colors"
  local xrdb_file="$cache_dir/colors.Xresources"
  local seq_file="$cache_dir/sequences"
  local now
  local colors_mtime=0
  local xrdb_mtime=0
  local seq_mtime=0
  local inotify_rc=1

  if [[ ! "$timeout_s" =~ ^[0-9]+$ || "$timeout_s" -lt 1 ]]; then
    timeout_s=15
  fi

  if [[ -f "$colors_file" ]]; then
    colors_mtime="$(stat -c %Y "$colors_file" 2>/dev/null || echo 0)"
  fi

  if [[ -f "$xrdb_file" ]]; then
    xrdb_mtime="$(stat -c %Y "$xrdb_file" 2>/dev/null || echo 0)"
  fi

  if [[ -f "$seq_file" ]]; then
    seq_mtime="$(stat -c %Y "$seq_file" 2>/dev/null || echo 0)"
  fi

  # Si pywal ya dejó la caché actualizada, no bloqueamos nada.
  if ((colors_mtime >= start_epoch && xrdb_mtime >= start_epoch && seq_mtime >= start_epoch)); then
    return 0
  fi

  if command -v inotifywait >/dev/null 2>&1; then
    timeout "$timeout_s" inotifywait -qq -m -e close_write,create,moved_to --format '%f' "$cache_dir" |
      while IFS= read -r changed; do
        case "$changed" in
          colors|colors.Xresources|sequences)
            if [[ -f "$colors_file" ]]; then
              colors_mtime="$(stat -c %Y "$colors_file" 2>/dev/null || echo 0)"
            fi

            if [[ -f "$xrdb_file" ]]; then
              xrdb_mtime="$(stat -c %Y "$xrdb_file" 2>/dev/null || echo 0)"
            fi

            if [[ -f "$seq_file" ]]; then
              seq_mtime="$(stat -c %Y "$seq_file" 2>/dev/null || echo 0)"
            fi

            if ((colors_mtime >= start_epoch && xrdb_mtime >= start_epoch && seq_mtime >= start_epoch)); then
              break
            fi
            ;;
        esac
      done
    inotify_rc=$?

    if ((inotify_rc == 0)); then
      return 0
    fi
  fi

  now="$(date +%s)"
  if ((now - start_epoch <= timeout_s)); then
    if [[ -f "$colors_file" ]]; then
      colors_mtime="$(stat -c %Y "$colors_file" 2>/dev/null || echo 0)"
    fi

    if [[ -f "$xrdb_file" ]]; then
      xrdb_mtime="$(stat -c %Y "$xrdb_file" 2>/dev/null || echo 0)"
    fi

    if [[ -f "$seq_file" ]]; then
      seq_mtime="$(stat -c %Y "$seq_file" 2>/dev/null || echo 0)"
    fi

    if ((colors_mtime >= start_epoch && xrdb_mtime >= start_epoch && seq_mtime >= start_epoch)); then
      return 0
    fi
  fi

  echo "No se confirmo actualización completa de ~/.cache/wal dentro de ${timeout_s}s" >&2
  return 1
}

# Verificar que los archivos existen antes de continuar
if is_dry_run; then
  log "DRY-RUN: wal -n -e -i $SELECTED_WALLPAPER"
fi

WAL_START_EPOCH="$(date +%s)"

if is_dry_run || wal -n -e -i "$SELECTED_WALLPAPER"; then # Generar paleta de colores
  if ! is_dry_run; then
    wait_for_pywal_cache "$WAL_START_EPOCH" || exit 1
  fi

  ## Recargar servicios

  # waybar
  #if pgrep -x waybar >/dev/null 2>&1; then
  #  run_cmd killall -SIGUSR2 waybar # reiniciar paleta de barra
  #else
  #  log "waybar no esta corriendo; se omite SIGUSR2"
  #fi
  # systemctl --user restart --now waybar.service

  # swaync
  if command -v systemctl >/dev/null 2>&1 && systemctl --user status swaync.service >/dev/null 2>&1; then
    run_cmd systemctl --user restart swaync.service
  else
    log "swaync.service no disponible; se omite restart"
  fi

  # nvim
  update_nvim_colors

  # Forzar refresco del tema GTK en la sesion actual
  refresh_gtk_theme

  # Forzar refresco del esquema de color KDE en la sesion actual
  refresh_kde_colorscheme

  # hyprland (pywal lo recarga mal)
  if command -v hyprctl >/dev/null 2>&1; then
    if is_dry_run; then
      log "DRY-RUN: timeout ${HYPR_RELOAD_TIMEOUT}s hyprctl reload"
    else
      if ! timeout "$HYPR_RELOAD_TIMEOUT" hyprctl reload; then
        echo "hyprctl reload falló o superó ${HYPR_RELOAD_TIMEOUT}s" >&2
      fi
    fi
  else
    log "hyprctl no disponible; se omite reload"
  fi

  # Aplicar colores a X resources
  if [[ -n "$DISPLAY" ]] && command -v xrdb >/dev/null 2>&1; then
    run_cmd xrdb -merge ~/.cache/wal/colors.Xresources
  else
    log "Sesion Wayland pura o xrdb ausente; se omite Xresources"
  fi

  # Recargar terminales kitty
  if pgrep -x kitty >/dev/null 2>&1; then
    run_cmd killall -SIGUSR1 kitty
  else
    log "kitty no esta corriendo; se omite SIGUSR1"
  fi
else
  echo "wal falló, se omiten recargas" >&2
  exit 1
fi
