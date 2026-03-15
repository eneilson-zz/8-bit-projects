#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_DIR="$(dirname "$SCRIPT_DIR")"
BIN_DIR="$PROJECT_DIR/bin"

KICKASS_JAR="/Applications/KickAssembler/KickAss.jar"
JAVA="/usr/bin/java"
CARTCONV="/opt/homebrew/bin/cartconv"

mkdir -p "$BIN_DIR"

echo "=== Assembling main_cart.asm ==="
"$JAVA" -jar "$KICKASS_JAR" \
    "$PROJECT_DIR/main_cart.asm" \
    -odir "$BIN_DIR" \
    -o main_cart.prg \
    -debugdump \
    -vicesymbols \
    2>&1 | tee "$BIN_DIR/buildlog-crt.txt"

if [[ ${PIPESTATUS[0]} -ne 0 ]]; then
    echo "Assembly FAILED — see $BIN_DIR/buildlog-crt.txt"
    exit 1
fi

echo "=== Converting PRG → CRT ==="
"$CARTCONV" \
    -p \
    -t normal \
    -i "$BIN_DIR/main_cart.prg" \
    -o "$BIN_DIR/stash-it.crt" \
    -n "Stash-It"

echo "=== Done: $BIN_DIR/stash-it.crt ==="
