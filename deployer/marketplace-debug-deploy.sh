#!/bin/bash
set -euo pipefail
set -x

LOG_FILE="${LOG_FILE:-/tmp/marketplace-debug.log}"
TERMINATION_LOG="${TERMINATION_LOG:-/dev/termination-log}"
DEPLOY_SCRIPT="${DEPLOY_SCRIPT:-/bin/deploy.sh}"

mkdir -p "$(dirname "$LOG_FILE")"
touch "$LOG_FILE"
exec > >(tee -a "$LOG_FILE") 2>&1

emit_failure_summary() {
  local status="${1:-1}"
  if [ "$status" -ne 0 ]; then
    {
      echo "marketplace-debug-deploy.sh failed with exit code $status"
      echo
      echo "Last 200 log lines:"
      tail -200 "$LOG_FILE" || true
    } > "$TERMINATION_LOG" || true
  fi
}

trap 'emit_failure_summary "$?"' EXIT

echo "=== marketplace debug: environment ==="
env | sort

echo "=== marketplace debug: data roots ==="
ls -la /data || true
ls -la /data/chart || true
ls -la /data-test || true
ls -la /data-test/chart || true

echo "=== marketplace debug: schemas ==="
cat /data/schema.yaml || true
cat /data-test/schema.yaml || true

echo "=== marketplace debug: chart bundle contents ==="
tar -tzf /data/chart/chart-bundle.tar.gz || true
tar -tzf /data-test/chart/chart-bundle.tar.gz || true

echo "=== marketplace debug: deploy.sh ==="
head -200 "$DEPLOY_SCRIPT" || true

/bin/bash -x "$DEPLOY_SCRIPT"
