#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd -- "$SCRIPT_DIR/.." && pwd)"

cd "$REPO_ROOT"

if [[ ! -x ./Ikemen_GO_Linux ]]; then
  echo "run-x64: missing executable ./Ikemen_GO_Linux" >&2
  exit 1
fi

exec ./Ikemen_GO_Linux "$@"
