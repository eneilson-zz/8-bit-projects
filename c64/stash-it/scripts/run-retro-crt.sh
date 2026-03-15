#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
OUT_DIR="${ROOT_DIR}/bin"
SRC_FILE="${1:-${ROOT_DIR}/main_cart.asm}"
BASE_NAME="$(basename "${SRC_FILE%.*}")"
CRT_FILE="${OUT_DIR}/stash-it.crt"
REU_FILE="${OUT_DIR}/stash-it-512k.reu"
DBG_FILE="${OUT_DIR}/${BASE_NAME}.dbg"
RETRO_BIN="/Applications/Retro Debugger.app/Contents/MacOS/Retro Debugger"

if [[ "${SKIP_BUILD:-0}" != "1" ]]; then
  "${ROOT_DIR}/scripts/build-crt.sh" "${SRC_FILE}"
fi

if [[ ! -f "${CRT_FILE}" ]]; then
  echo "Expected cartridge output was not found: ${CRT_FILE}"
  exit 1
fi

if [[ ! -x "${RETRO_BIN}" ]]; then
  echo "Retro Debugger executable not found at: ${RETRO_BIN}"
  exit 1
fi

if [[ ! -f "${REU_FILE}" ]]; then
  dd if=/dev/zero of="${REU_FILE}" bs=524288 count=1 >/dev/null 2>&1
fi

ARGS=(-c64)

if [[ "${RETRO_CLEAR_SETTINGS:-0}" == "1" ]]; then
  ARGS+=(-clearsettings)
fi

# Attach media first, then reset so boot happens with cartridge+REU present.
ARGS+=(-detacheverything -crt "${CRT_FILE}" -reu "${REU_FILE}" -reset)

if [[ -f "${DBG_FILE}" ]]; then
  ARGS+=(-debuginfo "${DBG_FILE}")
fi

exec "${RETRO_BIN}" "${ARGS[@]}"
