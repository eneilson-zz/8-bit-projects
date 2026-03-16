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

SYMBOLS="$BIN_DIR/main_cart.vs"
# Optional: pass a test PRG as first argument to autoload (but not autostart)
AUTOLOAD="${1:-}"

exec "$VICE" \
    -default \
    -VICIIfilter 0 \
    -cartcrt "$CRT" \
    -reu \
    -reusize 512 \
    ${SYMBOLS:+-moncommands "$SYMBOLS"} \
    ${AUTOLOAD:+-autoload "$AUTOLOAD"}
