#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
OUT_DIR="${ROOT_DIR}/bin"
SRC_FILE="${ROOT_DIR}/ramboard_test.asm"
PRG_FILE="${OUT_DIR}/ramboard test.prg"
D64_FILE="${OUT_DIR}/ramboard test.d64"

# Override with KICKASS_JAR if you keep the jar somewhere else.
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

mkdir -p "${OUT_DIR}"

# Emit PRG + VICE symbols + generic symbols, and capture the full build log.
# -o sets the explicit output path so the .prg keeps its spaced filename.
java -jar "${KICKASS_JAR}" "${SRC_FILE}" -o "${PRG_FILE}" -showmem -symbolfile -vicesymbols | tee "${OUT_DIR}/buildlog.txt"

# Package the PRG onto a fresh .d64 (LOAD"*",8,1-loadable) if c1541 is present.
if command -v c1541 >/dev/null 2>&1; then
  c1541 -format "ramboard,rt" d64 "${D64_FILE}" -write "${PRG_FILE}" "ramboard test" >/dev/null
  echo "Wrote disk image: ${D64_FILE}"
else
  echo "c1541 not found (ships with VICE); skipped .d64 packaging."
fi
