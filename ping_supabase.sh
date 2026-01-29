#!/usr/bin/env bash
# Ping one or more Supabase project endpoints to keep them warm.
#
# Supports unlimited projects via environment variables:
#   Primary:
#     SUPABASE_URL=https://xxxx.supabase.co
#     SUPABASE_KEY=...
#     (optional) SUPABASE_ENDPOINT_PATH=/health
#     (optional) SUPABASE_TARGET_URL=https://.../health
#
#   Additional projects (unlimited):
#     SUPABASE_URL_2=...
#     SUPABASE_KEY_2=...
#     SUPABASE_URL_3=...
#     SUPABASE_KEY_3=...
#     ...etc
#
# The script auto-loads a local .env file when present.
# It writes logs to $LOG_FILE (default: ./ping.log) and also prints to stdout.

set -euo pipefail

# --- Load .env if present ---
if [[ -f .env ]]; then
  set -a
  # shellcheck disable=SC1091
  source .env
  set +a
fi

# --- Defaults ---
DEFAULT_PROJECT_REF="fpoxvfuxgtlyphowqdgf"
DEFAULT_SUPABASE_URL="https://${DEFAULT_PROJECT_REF}.supabase.co"
ENDPOINT_PATH="${SUPABASE_ENDPOINT_PATH:-/health}"

# Where to append logs (also printed to terminal via tee)
LOG_FILE="${LOG_FILE:-./ping.log}"

timestamp() {
  date +"%Y-%m-%dT%H:%M:%S%z"
}

resolve_var() {
  local var_name="$1"
  printf '%s' "${!var_name:-}"
}

log_info() {
  local msg="$1"
  echo "[$(timestamp)] ${msg}" | tee -a "$LOG_FILE"
}

log_error() {
  local msg="$1"
  echo "[$(timestamp)] ${msg}" | tee -a "$LOG_FILE" >&2
}

ping_project() {
  local suffix="$1" # "" or "_2" or "_3" etc.

  local url_var="SUPABASE_URL${suffix}"
  local key_var="SUPABASE_KEY${suffix}"
  local anon_var="SUPABASE_ANON_KEY${suffix}"
  local endpoint_var="SUPABASE_ENDPOINT_PATH${suffix}"
  local target_var="SUPABASE_TARGET_URL${suffix}"

  local supabase_url
  supabase_url="$(resolve_var "${url_var}")"

  # If primary vars not set, fall back to default URL for the base project ref
  if [[ -z "${supabase_url}" && -z "${suffix}" ]]; then
    supabase_url="${DEFAULT_SUPABASE_URL}"
  fi

  # If still empty for non-primary suffix, treat as "not configured"
  if [[ -z "${supabase_url}" ]]; then
    return 2
  fi

  local endpoint_path
  endpoint_path="$(resolve_var "${endpoint_var}")"
  endpoint_path="${endpoint_path:-${ENDPOINT_PATH}}"

  local target_url
  target_url="$(resolve_var "${target_var}")"
  target_url="${target_url:-${supabase_url%/}${endpoint_path}}"

  local key_value
  key_value="$(resolve_var "${key_var}")"
  if [[ -z "${key_value}" ]]; then
    key_value="$(resolve_var "${anon_var}")"
  fi

  local -a header_args=("-s" "-o" "/dev/null" "-w" "%{http_code}")
  if [[ -n "${key_value}" ]]; then
    header_args+=("-H" "apikey: ${key_value}" "-H" "Authorization: Bearer ${key_value}")
  fi

  # curl prints the http code; grep verifies success codes
  if curl "${header_args[@]}" "${target_url}" | grep -qE "^(200|204)$"; then
    log_info "SUCCESS ${target_url} ${key_value:+(auth header set)}"
    return 0
  fi

  local status=$?
  log_error "FAILURE ${target_url} ${key_value:+(auth header set)}"
  return "${status}"
}

failures=0

# --- Always ping the primary ("" suffix) ---
ping_project "" || failures=$((failures + 1))

# --- Discover unlimited suffixes dynamically ---
# Look for any environment variables like:
#   SUPABASE_URL_4, SUPABASE_KEY_12, SUPABASE_TARGET_URL_3, SUPABASE_ENDPOINT_PATH_7, SUPABASE_ANON_KEY_9, ...
suffixes=()

while IFS= read -r var; do
  if [[ "$var" =~ ^SUPABASE_(URL|KEY|ANON_KEY|TARGET_URL|ENDPOINT_PATH)_(.+)$ ]]; then
    suffix="_${BASH_REMATCH[2]}"
    suffixes+=("$suffix")
  fi
done < <(compgen -v)

# De-dupe + sort suffixes
if ((${#suffixes[@]} > 0)); then
  IFS=$'\n' suffixes=($(printf "%s\n" "${suffixes[@]}" | sort -u))
  unset IFS
fi

for suffix in "${suffixes[@]}"; do
  if ping_project "${suffix}"; then
    continue
  fi
  status=$?
  if [[ ${status} -eq 2 ]]; then
    continue
  fi
  failures=$((failures + 1))
done

if [[ ${failures} -gt 0 ]]; then
  exit 1
fi
