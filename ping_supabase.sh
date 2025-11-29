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

SUPABASE_URL="${SUPABASE_URL:-${DEFAULT_SUPABASE_URL}}"
ENDPOINT_PATH="${SUPABASE_ENDPOINT_PATH:-/health}"
TARGET_URL="${SUPABASE_TARGET_URL:-${SUPABASE_URL%/}${ENDPOINT_PATH}}"

header_args=("-s")
if [[ -n "${SUPABASE_KEY:-${SUPABASE_ANON_KEY:-}}" ]]; then
  key_value="${SUPABASE_KEY:-${SUPABASE_ANON_KEY}}"
  header_args+=("-H" "apikey: ${key_value}" "-H" "Authorization: Bearer ${key_value}")
fi

timestamp() {
  date +"%Y-%m-%dT%H:%M:%S%z"
}

if curl -o /dev/null -w "%{http_code}" "${header_args[@]}" "${TARGET_URL}" | grep -qE "^(200|204)"; then
  echo "[$(timestamp)] Supabase ping succeeded: ${TARGET_URL}" \
    "${SUPABASE_KEY:+(auth header set)}${SUPABASE_ANON_KEY:+(auth header set)}"
else
  status=$?
  echo "[$(timestamp)] Supabase ping failed: ${TARGET_URL}" \
    "${SUPABASE_KEY:+(auth header set)}${SUPABASE_ANON_KEY:+(auth header set)}" >&2
  exit ${status}
fi