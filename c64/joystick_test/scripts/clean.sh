#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
OUT_DIR="${ROOT_DIR}/bin"

if [[ -d "${OUT_DIR}" ]]; then
  rm -f "${OUT_DIR}"/*.prg \
        "${OUT_DIR}"/*.dbg \
        "${OUT_DIR}"/*.vs  \
        "${OUT_DIR}"/*.sym \
        "${OUT_DIR}"/buildlog.txt
  echo "Cleaned ${OUT_DIR}"
else
  echo "Nothing to clean."
fi
