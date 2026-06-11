#!/bin/bash
set -o pipefail

# Bloquear para evitar multiples ejecuciones simultaneas
exec 200>/tmp/wallpaper_script.lock
flock -n 200 || {
  echo "Script ya en ejecucion, se omite esta corrida"
  exit 0
}

# Configuracion de la busqueda online
WALLHAVEN_API_URL="https://wallhaven.cc/api/v1/search"
WALLHAVEN_API_KEY="${WALLHAVEN_API_KEY:-}"
WALLHAVEN_QUERY="${WALLHAVEN_QUERY:-nature}"
WALLHAVEN_MIN_RES="${WALLHAVEN_MIN_RES:-1920x1080}"
WALLHAVEN_RATIOS="${WALLHAVEN_RATIOS:-16x9}"
WALLHAVEN_CATEGORIES="${WALLHAVEN_CATEGORIES:-100}"
WALLHAVEN_PURITY="${WALLHAVEN_PURITY:-100}"
WALLHAVEN_SORTING="${WALLHAVEN_SORTING:-random}" # random, toplist, date_added, relevance, views, favorites
WALLHAVEN_ORDER="${WALLHAVEN_ORDER:-desc}" # desc, asc
WALLHAVEN_TOP_RANGE="${WALLHAVEN_TOP_RANGE:-1M}" # 1D, 1W, 1M, 3M, 6M, 1Y
WALLHAVEN_AUTH_METHOD="${WALLHAVEN_AUTH_METHOD:-header}" # header, query
WALLHAVEN_API_RETRIES="${WALLHAVEN_API_RETRIES:-3}"
WALLHAVEN_API_BACKOFF_SECONDS="${WALLHAVEN_API_BACKOFF_SECONDS:-5}"
WALLHAVEN_MIN_API_INTERVAL_MS="${WALLHAVEN_MIN_API_INTERVAL_MS:-1400}"
WALLHAVEN_RANDOM_MIN_POOL="${WALLHAVEN_RANDOM_MIN_POOL:-24}"
WALLHAVEN_RANDOM_TOPLIST_FALLBACK="${WALLHAVEN_RANDOM_TOPLIST_FALLBACK:-1}"

CACHE_DIR="${XDG_CACHE_HOME:-$HOME/.cache}/wallhaven"
WALLPAPER_CACHE_DIR="$CACHE_DIR/images"
HISTORY_FILE="$CACHE_DIR/recent_ids"
LAST_ID_FILE="$CACHE_DIR/last_id"
MAX_RECENT_IDS="${WALLHAVEN_MAX_RECENT:-800}"
CACHE_CLEAN_INTERVAL="${WALLHAVEN_CACHE_CLEAN_INTERVAL:-21600}" # segundos (6h)
CACHE_MAX_AGE_DAYS="${WALLHAVEN_CACHE_MAX_AGE_DAYS:-7}"
CACHE_CLEAN_STAMP_FILE="$CACHE_DIR/.last_cache_cleanup"
WALLHAVEN_MAX_PAGES="${WALLHAVEN_MAX_PAGES:-5}"
MIN_SECONDS_BETWEEN_RUNS="${WALLHAVEN_MIN_SECONDS_BETWEEN_RUNS:-8}"
RUN_STAMP_FILE="$CACHE_DIR/.last_run"
CURL_API_TIMEOUT="${WALLHAVEN_CURL_API_TIMEOUT:-20}"
CURL_DOWNLOAD_TIMEOUT="${WALLHAVEN_CURL_DOWNLOAD_TIMEOUT:-60}"
API_RATE_LIMIT_STAMP_FILE="$CACHE_DIR/.last_api_call"
DRY_RUN="${WAL_SWAPPER_DRY_RUN:-0}"
HYPR_RELOAD_TIMEOUT="${HYPR_RELOAD_TIMEOUT:-5}"
PYWAL_CACHE_TIMEOUT="${PYWAL_CACHE_TIMEOUT:-15}"

mkdir -p "$WALLPAPER_CACHE_DIR"

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

url_encode() {
  printf '%s' "$1" | jq -sRr @uri
}

validate_wallhaven_config() {
  if [[ ! "$WALLHAVEN_CATEGORIES" =~ ^[01]{3}$ ]]; then
    echo "WALLHAVEN_CATEGORIES invalido: $WALLHAVEN_CATEGORIES (usa 3 bits, ej: 010)" >&2
    return 1
  fi

  if [[ ! "$WALLHAVEN_PURITY" =~ ^[01]{3}$ ]]; then
    echo "WALLHAVEN_PURITY invalido: $WALLHAVEN_PURITY (usa 3 bits, ej: 100)" >&2
    return 1
  fi

  if [[ ! "$WALLHAVEN_SORTING" =~ ^(date_added|relevance|random|views|favorites|toplist)$ ]]; then
    echo "WALLHAVEN_SORTING invalido: $WALLHAVEN_SORTING" >&2
    return 1
  fi

  if [[ ! "$WALLHAVEN_ORDER" =~ ^(desc|asc)$ ]]; then
    echo "WALLHAVEN_ORDER invalido: $WALLHAVEN_ORDER" >&2
    return 1
  fi

  if [[ "$WALLHAVEN_SORTING" == "toplist" && ! "$WALLHAVEN_TOP_RANGE" =~ ^(1[dD]|3[dD]|1[wW]|1[mM]|3[mM]|6[mM]|1[yY])$ ]]; then
    echo "WALLHAVEN_TOP_RANGE invalido para toplist: $WALLHAVEN_TOP_RANGE" >&2
    return 1
  fi

  if [[ "$WALLHAVEN_PURITY" =~ ^[01]{2}1$ && -z "$WALLHAVEN_API_KEY" ]]; then
    echo "WALLHAVEN_PURITY requiere NSFW y no hay API key" >&2
    return 1
  fi

  if [[ ! "$WALLHAVEN_AUTH_METHOD" =~ ^(header|query)$ ]]; then
    echo "WALLHAVEN_AUTH_METHOD invalido: $WALLHAVEN_AUTH_METHOD (usa header o query)" >&2
    return 1
  fi

  if [[ ! "$WALLHAVEN_API_RETRIES" =~ ^[0-9]+$ || "$WALLHAVEN_API_RETRIES" -lt 1 ]]; then
    echo "WALLHAVEN_API_RETRIES invalido: $WALLHAVEN_API_RETRIES" >&2
    return 1
  fi

  if [[ ! "$WALLHAVEN_MIN_API_INTERVAL_MS" =~ ^[0-9]+$ ]]; then
    echo "WALLHAVEN_MIN_API_INTERVAL_MS invalido: $WALLHAVEN_MIN_API_INTERVAL_MS" >&2
    return 1
  fi

  return 0
}

throttle_wallhaven_requests() {
  local now_ns
  local last_ns=0
  local min_ns
  local elapsed_ns
  local wait_ns
  local wait_s

  now_ns="$(date +%s%N 2>/dev/null || printf '%s000000000' "$(date +%s)")"
  min_ns=$((WALLHAVEN_MIN_API_INTERVAL_MS * 1000000))

  if [[ -f "$API_RATE_LIMIT_STAMP_FILE" ]]; then
    last_ns="$(cat "$API_RATE_LIMIT_STAMP_FILE" 2>/dev/null || echo 0)"
  fi

  if [[ "$last_ns" =~ ^[0-9]+$ ]]; then
    elapsed_ns=$((now_ns - last_ns))
    if ((elapsed_ns < min_ns)); then
      wait_ns=$((min_ns - elapsed_ns))
      wait_s="$(awk -v ns="$wait_ns" 'BEGIN { printf "%.3f", ns / 1000000000 }')"
      sleep "$wait_s"
    fi
  fi

  date +%s%N >"$API_RATE_LIMIT_STAMP_FILE" 2>/dev/null || date +%s | awk '{printf "%s000000000", $0}' >"$API_RATE_LIMIT_STAMP_FILE"
}

fetch_wallhaven_json() {
  local url="$1"
  local attempt=1
  local response
  local body
  local http_code
  local curl_status
  local -a curl_args=()

  curl_args=(
    -sS
    --connect-timeout 8
    --max-time "$CURL_API_TIMEOUT"
    -w '\n%{http_code}'
  )

  if [[ -n "$WALLHAVEN_API_KEY" && "$WALLHAVEN_AUTH_METHOD" == "header" ]]; then
    curl_args+=(-H "X-API-Key: $WALLHAVEN_API_KEY")
  fi

  while ((attempt <= WALLHAVEN_API_RETRIES)); do
    throttle_wallhaven_requests
    response="$(curl "${curl_args[@]}" "$url" 2>/dev/null)"
    curl_status=$?

    if ((curl_status != 0)); then
      if ((attempt < WALLHAVEN_API_RETRIES)); then
        sleep "$WALLHAVEN_API_BACKOFF_SECONDS"
        ((attempt++))
        continue
      fi

      echo "No se pudo consultar la API de Wallhaven" >&2
      return 1
    fi

    http_code="${response##*$'\n'}"
    body="${response%$'\n'*}"

    case "$http_code" in
      200)
        printf '%s' "$body"
        return 0
        ;;
      400)
        echo "Wallhaven devolvio 400 (parametros invalidos)" >&2
        return 1
        ;;
      401)
        echo "Wallhaven devolvio 401 (API key invalida o acceso NSFW no autorizado)" >&2
        return 1
        ;;
      429)
        if ((attempt < WALLHAVEN_API_RETRIES)); then
          sleep "$WALLHAVEN_API_BACKOFF_SECONDS"
          ((attempt++))
          continue
        fi

        echo "Wallhaven devolvio 429 (rate limit alcanzado)" >&2
        return 1
        ;;
      *)
        echo "Wallhaven devolvio HTTP $http_code" >&2
        return 1
        ;;
    esac
  done

  return 1
}

ensure_wayland_env() {
  local runtime_dir
  local socket_name

  runtime_dir="${XDG_RUNTIME_DIR:-/run/user/$UID}"
  export XDG_RUNTIME_DIR="$runtime_dir"

  if [[ -n "${WAYLAND_DISPLAY:-}" && -S "$runtime_dir/$WAYLAND_DISPLAY" ]]; then
    return 0
  fi

  socket_name="$(find "$runtime_dir" -maxdepth 1 -type s -name 'wayland-*' -printf '%f\n' | sort | head -n 1)"
  if [[ -n "$socket_name" ]]; then
    export WAYLAND_DISPLAY="$socket_name"
  fi
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

cleanup_wallpaper_cache_if_needed() {
  local now
  local last_cleanup=0

  now="$(date +%s)"

  if [[ -f "$CACHE_CLEAN_STAMP_FILE" ]]; then
    last_cleanup="$(stat -c %Y "$CACHE_CLEAN_STAMP_FILE" 2>/dev/null || echo 0)"
  fi

  if ((now - last_cleanup < CACHE_CLEAN_INTERVAL)); then
    return 0
  fi

  find "$WALLPAPER_CACHE_DIR" -type f -mtime "+$CACHE_MAX_AGE_DAYS" -delete 2>/dev/null || true
  touch "$CACHE_CLEAN_STAMP_FILE"
}

build_query_url() {
  local effective_sorting
  local effective_order
  local encoded_query
  local url

  effective_sorting="${1:-$WALLHAVEN_SORTING}"
  effective_order="${2:-$WALLHAVEN_ORDER}"

  encoded_query="$(url_encode "$WALLHAVEN_QUERY")"

  url="$(printf "%s?q=%s&sorting=%s&order=%s&atleast=%s&categories=%s&purity=%s" \
    "$WALLHAVEN_API_URL" \
    "$encoded_query" \
    "$effective_sorting" \
    "$effective_order" \
    "$WALLHAVEN_MIN_RES" \
    "$WALLHAVEN_CATEGORIES" \
    "$WALLHAVEN_PURITY")"

  if [[ -n "$WALLHAVEN_RATIOS" ]]; then
    url="${url}&ratios=${WALLHAVEN_RATIOS}"
  fi

  if [[ "$effective_sorting" == "toplist" ]]; then
    url="${url}&topRange=${WALLHAVEN_TOP_RANGE}"
  fi

  printf "%s" "$url"
}

generate_seed() {
  local seed

  seed="$(tr -dc 'A-Za-z0-9' </dev/urandom | head -c 6)"
  if [[ -z "$seed" ]]; then
    seed="$(date +%N | cut -c 1-6)"
  fi

  if [[ ! "$seed" =~ ^[A-Za-z0-9]{6}$ ]]; then
    seed="AbC123"
  fi

  printf "%s" "$seed"
}

append_auth_param() {
  local url="$1"

  if [[ -n "$WALLHAVEN_API_KEY" && "$WALLHAVEN_AUTH_METHOD" == "query" ]]; then
    printf "%s&apikey=%s" "$url" "$WALLHAVEN_API_KEY"
  else
    printf "%s" "$url"
  fi
}

pick_new_wallpaper() {
  local api_url
  local fallback_url
  local page_url
  local json
  local id
  local candidate_id
  local path
  local ext
  local dest
  local page=1
  local last_page=1
  local last_id=""
  local seed=""
  local mode
  local -a ids=()
  local -a candidates=()
  local -a recent=()
  local tmp_history
  declare -A id_to_path=()

  fetch_pool() {
    local base_url="$1"
    local page=1
    local last_page=1

    while ((page <= WALLHAVEN_MAX_PAGES)); do
      page_url="$(append_auth_param "$base_url&page=$page")"
      json="$(fetch_wallhaven_json "$page_url")" || break

      if ! echo "$json" | jq -e '.data and (.data | type == "array")' >/dev/null 2>&1; then
        echo "Respuesta de Wallhaven invalida o inesperada" >&2
        break
      fi

      while IFS=$'\t' read -r candidate_id path; do
        [[ -z "$candidate_id" || "$candidate_id" == "null" ]] && continue
        [[ -z "$path" || "$path" == "null" ]] && continue

        if [[ -z "${id_to_path[$candidate_id]}" ]]; then
          ids+=("$candidate_id")
          id_to_path[$candidate_id]="$path"
        fi
      done < <(echo "$json" | jq -r '.data[] | [.id, .path] | @tsv')

      last_page="$(echo "$json" | jq -r '.meta.last_page // 1')"
      [[ "$last_page" =~ ^[0-9]+$ ]] || last_page=1
      ((page >= last_page)) && break

      ((page++))
      sleep 0.1
    done
  }

  api_url="$(build_query_url)"

  if [[ "$WALLHAVEN_SORTING" == "random" ]]; then
    seed="$(generate_seed)"
    api_url="${api_url}&seed=${seed}"
  fi

  if [[ -f "$LAST_ID_FILE" ]]; then
    last_id="$(head -n 1 "$LAST_ID_FILE")"
  fi

  fetch_pool "$api_url"

  if [[ "$WALLHAVEN_SORTING" == "random" && "$WALLHAVEN_RANDOM_TOPLIST_FALLBACK" == "1" && ${#ids[@]} -lt $WALLHAVEN_RANDOM_MIN_POOL ]]; then
    fallback_url="$(build_query_url "toplist" "$WALLHAVEN_ORDER")"
    fetch_pool "$fallback_url"
  fi

  if ((${#ids[@]} == 0)); then
    return 1
  fi

  if [[ -f "$HISTORY_FILE" ]]; then
    while IFS= read -r candidate_id; do
      [[ -n "$candidate_id" ]] && recent+=("$candidate_id")
    done <"$HISTORY_FILE"
  fi

  # Reinicia el historial cuando llega al limite para comenzar un nuevo ciclo.
  if ((${#recent[@]} >= MAX_RECENT_IDS)); then
    : >"$HISTORY_FILE"
    recent=()
  fi

  for mode in strict no_recent any; do
    candidates=()

    for candidate_id in "${ids[@]}"; do
      # Evita repetir inmediatamente el último wallpaper, incluso con pool agotado.
      if [[ -n "$last_id" && "$candidate_id" == "$last_id" ]]; then
        continue
      fi

      if [[ "$mode" == "strict" ]]; then
        if printf '%s\n' "${recent[@]}" | grep -Fxq "$candidate_id"; then
          continue
        fi
      elif [[ "$mode" == "no_recent" ]]; then
        :
      fi

      candidates+=("$candidate_id")
    done

    if ((${#candidates[@]} > 0)); then
      break
    fi
  done

  if ((${#candidates[@]} == 0)); then
    candidates=("${ids[@]}")
  fi

  id="$(printf '%s\n' "${candidates[@]}" | shuf -n 1)"

  if [[ -z "$id" || "$id" == "null" ]]; then
    return 1
  fi

  path="${id_to_path[$id]}"

  if [[ -z "$path" || "$path" == "null" ]]; then
    return 1
  fi

  ext="${path##*.}"
  ext="${ext%%\?*}"
  dest="$WALLPAPER_CACHE_DIR/${id}.${ext}"

  if [[ ! -f "$dest" ]]; then
    curl -fsSL --connect-timeout 8 --max-time "$CURL_DOWNLOAD_TIMEOUT" "$path" -o "$dest" || return 1
  fi

  tmp_history="$(mktemp)"
  {
    echo "$id"
    if [[ -f "$HISTORY_FILE" ]]; then
      cat "$HISTORY_FILE"
    fi
  } | awk 'NF && !seen[$0]++' | head -n "$MAX_RECENT_IDS" >"$tmp_history"
  mv "$tmp_history" "$HISTORY_FILE"
  printf '%s\n' "$id" >"$LAST_ID_FILE"

  echo "$dest"
  return 0
}

cleanup_wallpaper_cache_if_needed

if should_skip_recent_run; then
  echo "Ejecucion omitida por anti-rebote (${MIN_SECONDS_BETWEEN_RUNS}s)"
  exit 0
fi

if ! command -v wal >/dev/null 2>&1; then
  echo "wal no esta instalado" >&2
  exit 1
fi

if ! command -v jq >/dev/null 2>&1; then
  echo "jq no esta instalado" >&2
  exit 1
fi

if ! validate_wallhaven_config; then
  exit 1
fi

ensure_wayland_env
ensure_awww_ready || exit 1

SELECTED_WALLPAPER="$(pick_new_wallpaper)"

if [[ -z "$SELECTED_WALLPAPER" ]]; then
  echo "No se pudo obtener un wallpaper online" >&2
  exit 1
fi

# Aplicar wallpaper
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

if is_dry_run || wal -n -e -i "$SELECTED_WALLPAPER"; then
  if ! is_dry_run; then
    wait_for_pywal_cache "$WAL_START_EPOCH" || exit 1
  fi

  ## Recargar servicios

  # waybar ya no es necesario
  # if pgrep -x waybar >/dev/null 2>&1; then
  #  run_cmd killall -SIGUSR2 waybar # reiniciar paleta de barra
  # else
  #  log "waybar no esta corriendo; se omite SIGUSR2"
  #fi
  #systemctl --user restart --now waybar.service

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
