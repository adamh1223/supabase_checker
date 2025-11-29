#!/usr/bin/env bash
# Ping a Supabase project endpoint to keep it warm.
#
# Usage:
#   SUPABASE_PROJECT_REF=fpoxvfuxgtlyphowqdgf ./ping_supabase.sh
#
# Optional:
#   SUPABASE_ANON_KEY=... ./ping_supabase.sh
#     Adds an Authorization header for private endpoints.
#
set -euo pipefail

PROJECT_REF="${SUPABASE_PROJECT_REF:-fpoxvfuxgtlyphowqdgf}"
BASE_URL="https://${PROJECT_REF}.supabase.co"
ENDPOINT_PATH="${SUPABASE_ENDPOINT_PATH:-/health}"
TARGET_URL="${SUPABASE_TARGET_URL:-${BASE_URL}${ENDPOINT_PATH}}"

header_args=()
if [[ -n "${SUPABASE_ANON_KEY:-}" ]]; then
  header_args+=("-H" "apikey: ${SUPABASE_ANON_KEY}" "-H" "Authorization: Bearer ${SUPABASE_ANON_KEY}")
fi

timestamp() {
  date +"%Y-%m-%dT%H:%M:%S%z"
}

if curl -s -o /dev/null -w "%{http_code}" "${header_args[@]}" "${TARGET_URL}" | grep -qE "^(200|204)"; then
  echo "[$(timestamp)] Supabase ping succeeded: ${TARGET_URL}" \
    "${SUPABASE_ANON_KEY:+(auth header set)}"
else
  status=$?
  echo "[$(timestamp)] Supabase ping failed: ${TARGET_URL}" \
    "${SUPABASE_ANON_KEY:+(auth header set)}" >&2
  exit ${status}
fi
