#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_DIR="$(dirname "$SCRIPT_DIR")"
TEST_DIR="$PROJECT_DIR/test"
BIN_DIR="$PROJECT_DIR/bin/test"

KICKASS_JAR="/Applications/KickAssembler/KickAss.jar"
JAVA="/usr/bin/java"

mkdir -p "$BIN_DIR"

for SRC in "$TEST_DIR"/*.asm; do
    NAME="$(basename "$SRC" .asm)"
    echo "=== Assembling $NAME.asm ==="
    "$JAVA" -jar "$KICKASS_JAR" \
        "$SRC" \
        -odir "$BIN_DIR" \
        -o "$BIN_DIR/$NAME.prg" \
        2>&1 | tee "$BIN_DIR/buildlog-$NAME.txt"
    if [[ ${PIPESTATUS[0]} -ne 0 ]]; then
        echo "FAILED: $NAME"
        exit 1
    fi
    echo "  → $BIN_DIR/$NAME.prg"
done

echo "=== All tests built ==="
