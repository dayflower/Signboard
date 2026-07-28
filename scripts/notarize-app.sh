#!/usr/bin/env bash
# Submits the packaged app bundle to Apple's notary service and staples the
# resulting ticket into the bundle, so Gatekeeper accepts it on machines that
# have never seen the app and without network access.
#
# The bundle must already be signed with a Developer ID identity and the
# hardened runtime: run scripts/package-app.sh with CODESIGN_IDENTITY set first.
#
# Credentials come from an App Store Connect API key:
#   NOTARY_KEY_ID     Key ID of the key
#   NOTARY_ISSUER_ID  Issuer ID of the team
#   NOTARY_KEY_PATH   Path to the AuthKey_*.p8 private key
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ROOT_DIR="$(cd "${SCRIPT_DIR}/.." && pwd)"

DIST_DIR="${DIST_DIR:-${ROOT_DIR}/dist}"
APP_NAME="${APP_NAME:-SignboardApp}"
APP_BUNDLE_PATH="${DIST_DIR}/${APP_NAME}.app"

: "${NOTARY_KEY_ID:?NOTARY_KEY_ID is required}"
: "${NOTARY_ISSUER_ID:?NOTARY_ISSUER_ID is required}"
: "${NOTARY_KEY_PATH:?NOTARY_KEY_PATH is required}"

if [[ ! -d "${APP_BUNDLE_PATH}" ]]; then
    echo "App bundle not found: ${APP_BUNDLE_PATH} (run scripts/package-app.sh first)" >&2
    exit 1
fi

# notarytool only accepts zip/pkg/dmg, so submit a throwaway archive. The ticket
# it issues is stapled to the .app itself afterwards, which means any archive
# built for distribution has to be created after this script runs.
TMP_DIR="$(mktemp -d)"
trap 'rm -rf "${TMP_DIR}"' EXIT
ditto -c -k --sequesterRsrc --keepParent "${APP_BUNDLE_PATH}" "${TMP_DIR}/${APP_NAME}.zip"

# --wait exits non-zero unless the submission comes back Accepted. It prints the
# submission id, so `xcrun notarytool log <id> --key ...` explains a rejection.
xcrun notarytool submit "${TMP_DIR}/${APP_NAME}.zip" \
    --key "${NOTARY_KEY_PATH}" \
    --key-id "${NOTARY_KEY_ID}" \
    --issuer "${NOTARY_ISSUER_ID}" \
    --wait

xcrun stapler staple "${APP_BUNDLE_PATH}"
# Confirm Gatekeeper would let the app run from the stapled ticket alone.
xcrun stapler validate "${APP_BUNDLE_PATH}"
spctl --assess --type execute --verbose=4 "${APP_BUNDLE_PATH}"

echo "Notarized ${APP_BUNDLE_PATH}"
