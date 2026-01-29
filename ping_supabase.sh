#!/usr/bin/env bash
# Ping a Supabase project endpoint to keep it warm.
#
# Usage:
#   SUPABASE_URL=https://fpoxvfuxgtlyphowqdgf.supabase.co \
#   SUPABASE_KEY=... ./ping_supabase.sh
#
# Optional overrides:
#   SUPABASE_ENDPOINT_PATH=/health         # defaults to /health
#   SUPABASE_TARGET_URL=https://.../health # takes precedence over SUPABASE_ENDPOINT_PATH
#
# The script will automatically load a local .env file when present so you can keep
# your credentials in one place.

set -euo pipefail

if [[ -f .env ]]; then
  set -a
  # shellcheck disable=SC1091
  source .env
  set +a
fi

DEFAULT_PROJECT_REF="fpoxvfuxgtlyphowqdgf"
DEFAULT_SUPABASE_URL="https://${DEFAULT_PROJECT_REF}.supabase.co"

ENDPOINT_PATH="${SUPABASE_ENDPOINT_PATH:-/health}"

timestamp() {
  date +"%Y-%m-%dT%H:%M:%S%z"
}

resolve_var() {
  local var_name="$1"
  printf '%s' "${!var_name:-}"
}

build_header_args() {
  local key_value="$1"
  local -a headers=("-s")
  if [[ -n "${key_value}" ]]; then
    headers+=("-H" "apikey: ${key_value}" "-H" "Authorization: Bearer ${key_value}")
  fi
  printf '%s\n' "${headers[@]}"
}

ping_project() {
  local suffix="$1"
  local url_var="SUPABASE_URL${suffix}"
  local key_var="SUPABASE_KEY${suffix}"
  local anon_var="SUPABASE_ANON_KEY${suffix}"
  local endpoint_var="SUPABASE_ENDPOINT_PATH${suffix}"
  local target_var="SUPABASE_TARGET_URL${suffix}"

  local supabase_url
  supabase_url="$(resolve_var "${url_var}")"
  if [[ -z "${supabase_url}" && -z "${suffix}" ]]; then
    supabase_url="${DEFAULT_SUPABASE_URL}"
  fi
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

  mapfile -t header_args < <(build_header_args "${key_value}")

  if curl -o /dev/null -w "%{http_code}" "${header_args[@]}" "${target_url}" | grep -qE "^(200|204)"; then
    echo "[$(timestamp)] Supabase ping succeeded: ${target_url}" \
      "${key_value:+(auth header set)}"
    return 0
  fi

  local status=$?
  echo "[$(timestamp)] Supabase ping failed: ${target_url}" \
    "${key_value:+(auth header set)}" >&2
  return "${status}"
}

failures=0

ping_project "" || failures=$((failures + 1))

for suffix in _2 _3; do
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
