#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
OUT_DIR="${ROOT_DIR}/bin"
SRC_FILE="${1:-${ROOT_DIR}/main_cart.asm}"
BASE_NAME="$(basename "${SRC_FILE%.*}")"
RAW_BIN_FILE="${OUT_DIR}/${BASE_NAME}.bin"
BIN_FILE="${OUT_DIR}/${BASE_NAME}.crt.bin"
CRT_FILE="${OUT_DIR}/stash-it.crt"
CRT_NAME="${CRT_NAME:-STASH-IT}"
CART_TYPE="${CART_TYPE:-normal}"

KICKASS_JAR="${KICKASS_JAR:-}"
if [[ -z "${KICKASS_JAR}" ]]; then
  if [[ -f "/Applications/KickAssembler/KickAss.jar" ]]; then
    KICKASS_JAR="/Applications/KickAssembler/KickAss.jar"
  elif [[ -f "${HOME}/bin/KickAss.jar" ]]; then
    KICKASS_JAR="${HOME}/bin/KickAss.jar"
  fi
fi

if [[ -z "${KICKASS_JAR}" || ! -f "${KICKASS_JAR}" ]]; then
  echo "KickAssembler jar not found."
  echo "Set KICKASS_JAR, for example:"
  echo "  export KICKASS_JAR=/Applications/KickAssembler/KickAss.jar"
  exit 1
fi

if ! command -v /opt/homebrew/bin/cartconv >/dev/null 2>&1 && ! command -v cartconv >/dev/null 2>&1; then
  echo "cartconv not found. Install VICE tools (cartconv)."
  exit 1
fi

CARTCONV_BIN="${CARTCONV_BIN:-}"
if [[ -z "${CARTCONV_BIN}" ]]; then
  if [[ -x "/opt/homebrew/bin/cartconv" ]]; then
    CARTCONV_BIN="/opt/homebrew/bin/cartconv"
  else
    CARTCONV_BIN="$(command -v cartconv)"
  fi
fi

mkdir -p "${OUT_DIR}"

java -jar "${KICKASS_JAR}" "${SRC_FILE}" -odir "${OUT_DIR}" -binfile -showmem -symbolfile -vicesymbols -debugdump \
  | tee "${OUT_DIR}/buildlog-crt.txt"

if [[ ! -f "${RAW_BIN_FILE}" ]]; then
  echo "Expected binary output not found: ${RAW_BIN_FILE}"
  exit 1
fi

RAW_BIN_SIZE="$(wc -c < "${RAW_BIN_FILE}")"
if [[ "${RAW_BIN_SIZE}" -eq 8192 ]]; then
  cp "${RAW_BIN_FILE}" "${BIN_FILE}"
elif [[ "${RAW_BIN_SIZE}" -eq 16384 ]]; then
  cp "${RAW_BIN_FILE}" "${BIN_FILE}"
elif [[ "${RAW_BIN_SIZE}" -eq 32768 ]]; then
  head -c 8192 "${RAW_BIN_FILE}" > "${BIN_FILE}"
  tail -c 8192 "${RAW_BIN_FILE}" >> "${BIN_FILE}"
else
  echo "Binary size is ${RAW_BIN_SIZE} bytes. Expected 8192, 16384, or 32768 (\$8000..\$FFFF with gap)."
  echo "Cannot create cartridge .crt from this image layout."
  exit 1
fi

"${CARTCONV_BIN}" -t "${CART_TYPE}" -i "${BIN_FILE}" -o "${CRT_FILE}" -n "${CRT_NAME}" >/dev/null
"${CARTCONV_BIN}" -f "${CRT_FILE}" | tee "${OUT_DIR}/crt-info.txt"

echo
echo "Created cartridge: ${CRT_FILE}"
