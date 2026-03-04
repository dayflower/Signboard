#!/usr/bin/env bash
set -euo pipefail

usage() {
    cat <<'EOF'
Usage:
  scripts/generate-icns.sh <source-png> <output-icns> [icon-name]
EOF
}

die() {
    echo "$*" >&2
    exit 1
}

resize_icon() {
    local source="$1"
    local destination="$2"
    local size="$3"
    sips -z "${size}" "${size}" "${source}" --out "${destination}" >/dev/null
}

if [[ "$#" -lt 2 || "$#" -gt 3 ]]; then
    usage
    exit 1
fi

SOURCE_PNG="$1"
OUTPUT_ICNS="$2"
ICON_NAME="${3:-AppIcon}"

if [[ ! -f "${SOURCE_PNG}" ]]; then
    die "Expected icon source not found: ${SOURCE_PNG}"
fi

if ! command -v sips >/dev/null 2>&1; then
    die "sips command not found."
fi

if ! command -v iconutil >/dev/null 2>&1; then
    die "iconutil command not found."
fi

OUTPUT_DIR="$(dirname "${OUTPUT_ICNS}")"
mkdir -p "${OUTPUT_DIR}"

ICON_TMP_ROOT="${ICON_TMP_ROOT:-${OUTPUT_DIR}}"
mkdir -p "${ICON_TMP_ROOT}"
TMP_DIR="$(mktemp -d "${ICON_TMP_ROOT%/}/generate-icns.XXXXXX")"
cleanup() {
    rm -rf "${TMP_DIR}"
}
trap cleanup EXIT

ICONSET_DIR="${TMP_DIR}/${ICON_NAME}.iconset"
mkdir -p "${ICONSET_DIR}"

resize_icon "${SOURCE_PNG}" "${ICONSET_DIR}/icon_16x16.png" 16
resize_icon "${SOURCE_PNG}" "${ICONSET_DIR}/icon_16x16@2x.png" 32
resize_icon "${SOURCE_PNG}" "${ICONSET_DIR}/icon_32x32.png" 32
resize_icon "${SOURCE_PNG}" "${ICONSET_DIR}/icon_32x32@2x.png" 64
resize_icon "${SOURCE_PNG}" "${ICONSET_DIR}/icon_128x128.png" 128
resize_icon "${SOURCE_PNG}" "${ICONSET_DIR}/icon_128x128@2x.png" 256
resize_icon "${SOURCE_PNG}" "${ICONSET_DIR}/icon_256x256.png" 256
resize_icon "${SOURCE_PNG}" "${ICONSET_DIR}/icon_256x256@2x.png" 512
resize_icon "${SOURCE_PNG}" "${ICONSET_DIR}/icon_512x512.png" 512
resize_icon "${SOURCE_PNG}" "${ICONSET_DIR}/icon_512x512@2x.png" 1024

iconutil --convert icns --output "${OUTPUT_ICNS}" "${ICONSET_DIR}"

if [[ ! -s "${OUTPUT_ICNS}" ]]; then
    die "Failed to generate icns: ${OUTPUT_ICNS}"
fi
