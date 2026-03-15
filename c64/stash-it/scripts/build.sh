#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
SRC_FILE="${1:-${ROOT_DIR}/main_cart.asm}"

"${ROOT_DIR}/scripts/build-crt.sh" "${SRC_FILE}"
SKIP_BUILD=1 "${ROOT_DIR}/scripts/run-retro-crt.sh" "${SRC_FILE}"
