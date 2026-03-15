#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_DIR="$(dirname "$SCRIPT_DIR")"
BIN_DIR="$PROJECT_DIR/bin"

VICE="/opt/homebrew/bin/x64sc"
CRT="$BIN_DIR/stash-it.crt"

if [[ ! -f "$CRT" ]]; then
    echo "ERROR: $CRT not found — run build-crt.sh first"
    exit 1
fi

exec "$VICE" \
    -default \
    -cartcrt "$CRT" \
    -reu \
    -reusize 512
