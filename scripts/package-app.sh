#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ROOT_DIR="$(cd "${SCRIPT_DIR}/.." && pwd)"

CONFIGURATION="${CONFIGURATION:-release}"
DIST_DIR="${DIST_DIR:-${ROOT_DIR}/dist}"
APP_NAME="${APP_NAME:-SignboardApp}"
APP_IDENTIFIER="${APP_IDENTIFIER:-com.dayflower.signboard}"
RESOURCE_BUNDLE_NAME="${RESOURCE_BUNDLE_NAME:-Signboard_SignboardApp.bundle}"
CREATE_ZIP="${CREATE_ZIP:-0}"
SKIP_BUILD="${SKIP_BUILD:-0}"

APP_BUNDLE_PATH="${DIST_DIR}/${APP_NAME}.app"
ZIP_PATH="${DIST_DIR}/${APP_NAME}.zip"
CACHE_DIR="${ROOT_DIR}/.build/local-cache"
VERSION_SOURCE="${ROOT_DIR}/Sources/SignboardCore/SignboardCoreModels.swift"

mkdir -p "${CACHE_DIR}/swiftpm-module-cache" "${CACHE_DIR}/clang-module-cache"
export SWIFTPM_MODULECACHE_OVERRIDE="${CACHE_DIR}/swiftpm-module-cache"
export CLANG_MODULE_CACHE_PATH="${CACHE_DIR}/clang-module-cache"

if [[ "${SKIP_BUILD}" != "1" ]]; then
    swift build -c "${CONFIGURATION}" --product SignboardApp
    swift build -c "${CONFIGURATION}" --product signboard
fi

BIN_PATH="$(swift build -c "${CONFIGURATION}" --show-bin-path)"
GUI_EXECUTABLE_PATH="${BIN_PATH}/SignboardApp"
CLI_EXECUTABLE_PATH="${BIN_PATH}/signboard"
RESOURCE_BUNDLE_PATH="${BIN_PATH}/${RESOURCE_BUNDLE_NAME}"

for path in "${GUI_EXECUTABLE_PATH}" "${CLI_EXECUTABLE_PATH}" "${RESOURCE_BUNDLE_PATH}"; do
    if [[ ! -e "${path}" ]]; then
        echo "Expected build output not found: ${path}" >&2
        exit 1
    fi
done

DEFAULT_VERSION="$(sed -nE 's/^[[:space:]]*public static let current = "([^"]+)".*/\1/p' "${VERSION_SOURCE}" | head -n 1)"
if [[ -z "${DEFAULT_VERSION}" ]]; then
    echo "Could not resolve default app version from ${VERSION_SOURCE}" >&2
    exit 1
fi

APP_VERSION="${APP_VERSION:-${DEFAULT_VERSION}}"
APP_BUILD_VERSION="${APP_BUILD_VERSION:-${APP_VERSION}}"

rm -rf "${APP_BUNDLE_PATH}"
mkdir -p "${APP_BUNDLE_PATH}/Contents/MacOS" "${APP_BUNDLE_PATH}/Contents/Resources"

install -m 755 "${GUI_EXECUTABLE_PATH}" "${APP_BUNDLE_PATH}/Contents/MacOS/SignboardApp"
install -m 755 "${CLI_EXECUTABLE_PATH}" "${APP_BUNDLE_PATH}/Contents/MacOS/signboard"
cp -R "${RESOURCE_BUNDLE_PATH}" "${APP_BUNDLE_PATH}/Contents/Resources/${RESOURCE_BUNDLE_NAME}"

cat > "${APP_BUNDLE_PATH}/Contents/Info.plist" <<PLIST
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
    <key>CFBundleDevelopmentRegion</key>
    <string>en</string>
    <key>CFBundleDisplayName</key>
    <string>${APP_NAME}</string>
    <key>CFBundleExecutable</key>
    <string>SignboardApp</string>
    <key>CFBundleIdentifier</key>
    <string>${APP_IDENTIFIER}</string>
    <key>CFBundleInfoDictionaryVersion</key>
    <string>6.0</string>
    <key>CFBundleName</key>
    <string>${APP_NAME}</string>
    <key>CFBundlePackageType</key>
    <string>APPL</string>
    <key>CFBundleShortVersionString</key>
    <string>${APP_VERSION}</string>
    <key>CFBundleVersion</key>
    <string>${APP_BUILD_VERSION}</string>
    <key>LSMinimumSystemVersion</key>
    <string>13.0</string>
    <key>NSPrincipalClass</key>
    <string>NSApplication</string>
</dict>
</plist>
PLIST

if [[ "${CREATE_ZIP}" == "1" ]]; then
    rm -f "${ZIP_PATH}"
    ditto -c -k --sequesterRsrc --keepParent "${APP_BUNDLE_PATH}" "${ZIP_PATH}"
fi

echo "Created ${APP_BUNDLE_PATH}"
if [[ "${CREATE_ZIP}" == "1" ]]; then
    echo "Created ${ZIP_PATH}"
fi
