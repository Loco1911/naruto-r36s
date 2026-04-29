#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
DEBUG_ROOT="$ROOT_DIR/tools/debug-rootfs"

export PATH="$DEBUG_ROOT/usr/bin:$PATH"
export LD_LIBRARY_PATH="$DEBUG_ROOT/usr/lib/x86_64-linux-gnu:$DEBUG_ROOT/lib/x86_64-linux-gnu:$DEBUG_ROOT/usr/lib64:$DEBUG_ROOT/lib64${LD_LIBRARY_PATH:+:$LD_LIBRARY_PATH}"
export VALGRIND_LIB="$DEBUG_ROOT/usr/libexec/valgrind"
export GOTRACEBACK="${GOTRACEBACK:-crash}"

mkdir -p "$ROOT_DIR/debug"

