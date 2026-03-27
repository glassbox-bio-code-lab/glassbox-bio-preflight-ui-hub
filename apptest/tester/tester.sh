#!/bin/bash
set -euo pipefail

fail() {
  echo "TEST FAILED: $*" >&2
  exit 1
}

run_check() {
  local name="$1"
  local command="$2"
  local expected="$3"

  echo "Running check: ${name}"
  local actual
  actual="$(sh -lc "${command}")" || fail "${name} command failed"

  if [[ "${actual}" != "${expected}" ]]; then
    fail "${name} expected '${expected}' but got '${actual}'"
  fi

  echo "Check passed: ${name}"
}

: "${APP_BASE_URL:?APP_BASE_URL is required}"

run_check \
  "Health endpoint returns ok" \
  "curl -fsSL \"${APP_BASE_URL}/api/health\" | jq -r '.status'" \
  "ok"

run_check \
  "Config endpoint reports in-cluster mode" \
  "curl -fsSL \"${APP_BASE_URL}/api/config\" | jq -r '.inCluster'" \
  "true"

run_check \
  "Module registry exposes the canonical computational entry" \
  "curl -fsSL \"${APP_BASE_URL}/api/modules\" | jq -r '.modules[] | select(.id==\"computational\") | .id' | head -n1" \
  "computational"

echo "All verification checks passed."
