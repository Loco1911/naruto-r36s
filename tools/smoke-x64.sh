#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd -- "$SCRIPT_DIR/.." && pwd)"
TIMEOUT_SECONDS="${SMOKE_TIMEOUT_SECONDS:-25}"

cd "$REPO_ROOT"

if [[ ! -x ./Ikemen_GO_Linux ]]; then
  echo "smoke-x64: missing executable ./Ikemen_GO_Linux" >&2
  exit 1
fi

set +e
timeout "$TIMEOUT_SECONDS" ./Ikemen_GO_Linux -updatechar -updatestage -windowed -nosound -nomusic "$@"
status=$?
set -e

case "$status" in
  0)
    echo "smoke-x64: Ikemen exited cleanly"
    ;;
  124)
    echo "smoke-x64: timeout reached after ${TIMEOUT_SECONDS}s; treating this as success because the UI stayed alive"
    ;;
  *)
    echo "smoke-x64: Ikemen failed with exit code $status" >&2
    exit "$status"
    ;;
esac
