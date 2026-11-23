#!/usr/bin/env bash
# Usage: smoke-test.sh <base-url> [expected-version]
# Polls /health until it answers 200 (and, if given, reports the expected version).
set -euo pipefail

URL="${1:?usage: smoke-test.sh <base-url> [expected-version]}"
EXPECTED="${2:-}"

for i in $(seq 1 18); do
  BODY="$(curl -fsS --max-time 10 "${URL}/health" || true)"
  if [ -n "$BODY" ]; then
    if [ -z "$EXPECTED" ] || echo "$BODY" | grep -Eq "\"version\": ?\"${EXPECTED}\""; then
      echo "OK: ${BODY}"
      exit 0
    fi
  fi
  echo "attempt ${i}/18: not ready yet (${BODY:-no response})"
  sleep 10
done

echo "Smoke test FAILED for ${URL}" >&2
exit 1
