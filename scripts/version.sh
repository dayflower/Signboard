#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ROOT_DIR="$(cd "${SCRIPT_DIR}/.." && pwd)"
VERSION_FILE="${ROOT_DIR}/VERSION"
SWIFT_VERSION_FILE="${ROOT_DIR}/Sources/SignboardCore/SignboardCoreModels.swift"
SEMVER_REGEX='^(0|[1-9][0-9]*)\.(0|[1-9][0-9]*)\.(0|[1-9][0-9]*)$'

die() {
    echo "$*" >&2
    exit 1
}

validate_semver() {
    local version="${1:-}"
    if [[ -z "${version}" ]]; then
        die "Version is required."
    fi
    if [[ ! "${version}" =~ ${SEMVER_REGEX} ]]; then
        die "Invalid semantic version: ${version}. Expected major.minor.patch."
    fi
}

read_version() {
    if [[ ! -f "${VERSION_FILE}" ]]; then
        die "VERSION file not found: ${VERSION_FILE}"
    fi

    local line_count
    line_count="$(awk 'END { print NR }' "${VERSION_FILE}")"
    if [[ "${line_count}" -ne 1 ]]; then
        die "VERSION file must contain exactly one line."
    fi

    local version
    version="$(
        awk 'NR==1 { gsub(/^[[:space:]]+|[[:space:]]+$/, "", $0); print; exit }' "${VERSION_FILE}"
    )"
    validate_semver "${version}"
    printf '%s\n' "${version}"
}

write_version() {
    local version="${1:-}"
    validate_semver "${version}"
    printf '%s\n' "${version}" > "${VERSION_FILE}"
}

read_swift_version() {
    if [[ ! -f "${SWIFT_VERSION_FILE}" ]]; then
        die "Swift version source file not found: ${SWIFT_VERSION_FILE}"
    fi

    local version
    version="$(
        sed -nE 's/^[[:space:]]*public static let current = "([^"]+)".*/\1/p' \
            "${SWIFT_VERSION_FILE}" | head -n 1
    )"
    if [[ -z "${version}" ]]; then
        die "Could not resolve SignboardVersion.current from ${SWIFT_VERSION_FILE}"
    fi
    validate_semver "${version}"
    printf '%s\n' "${version}"
}

sync_swift_version() {
    local target_version="${1:-$(read_version)}"
    validate_semver "${target_version}"

    local tmp_file
    tmp_file="$(mktemp)"

    if awk -v version="${target_version}" '
        BEGIN {
            replaced = 0
        }
        {
            if (!replaced && $0 ~ /^[[:space:]]*public static let current = "[^"]+"/) {
                prefix = ""
                if (match($0, /^[[:space:]]*/)) {
                    prefix = substr($0, RSTART, RLENGTH)
                }
                print prefix "public static let current = \"" version "\""
                replaced = 1
                next
            }
            print
        }
        END {
            if (!replaced) {
                exit 42
            }
        }
    ' "${SWIFT_VERSION_FILE}" > "${tmp_file}"; then
        :
    else
        local status=$?
        rm -f "${tmp_file}"
        if [[ "${status}" -eq 42 ]]; then
            die "Could not find SignboardVersion.current declaration in ${SWIFT_VERSION_FILE}"
        fi
        exit "${status}"
    fi

    cat "${tmp_file}" > "${SWIFT_VERSION_FILE}"
    rm -f "${tmp_file}"
}

assert_consistent() {
    local version
    local swift_version
    version="$(read_version)"
    swift_version="$(read_swift_version)"

    if [[ "${version}" != "${swift_version}" ]]; then
        die "Version mismatch: VERSION=${version}, SignboardVersion.current=${swift_version}"
    fi
}

next_version() {
    local bump_type="${1:-}"
    local version="${2:-$(read_version)}"
    validate_semver "${version}"

    local major minor patch
    IFS='.' read -r major minor patch <<< "${version}"

    case "${bump_type}" in
        major)
            major=$((major + 1))
            minor=0
            patch=0
            ;;
        minor)
            minor=$((minor + 1))
            patch=0
            ;;
        patch)
            patch=$((patch + 1))
            ;;
        *)
            die "Unsupported bump type: ${bump_type}. Use major, minor, or patch."
            ;;
    esac

    printf '%s.%s.%s\n' "${major}" "${minor}" "${patch}"
}

usage() {
    cat <<'EOF'
Usage:
  scripts/version.sh current
  scripts/version.sh swift-current
  scripts/version.sh validate [version]
  scripts/version.sh next <major|minor|patch> [version]
  scripts/version.sh write <version>
  scripts/version.sh sync-swift [version]
  scripts/version.sh assert-consistent
EOF
}

main() {
    local command="${1:-}"
    case "${command}" in
        current)
            if [[ "$#" -ne 1 ]]; then
                usage
                exit 1
            fi
            read_version
            ;;
        swift-current)
            if [[ "$#" -ne 1 ]]; then
                usage
                exit 1
            fi
            read_swift_version
            ;;
        validate)
            case "$#" in
                1)
                    validate_semver "$(read_version)"
                    ;;
                2)
                    validate_semver "${2}"
                    ;;
                *)
                    usage
                    exit 1
                    ;;
            esac
            ;;
        next)
            case "$#" in
                2)
                    next_version "${2}"
                    ;;
                3)
                    next_version "${2}" "${3}"
                    ;;
                *)
                    usage
                    exit 1
                    ;;
            esac
            ;;
        write)
            if [[ "$#" -ne 2 ]]; then
                usage
                exit 1
            fi
            write_version "${2}"
            ;;
        sync-swift)
            case "$#" in
                1)
                    sync_swift_version
                    ;;
                2)
                    sync_swift_version "${2}"
                    ;;
                *)
                    usage
                    exit 1
                    ;;
            esac
            ;;
        assert-consistent)
            if [[ "$#" -ne 1 ]]; then
                usage
                exit 1
            fi
            assert_consistent
            ;;
        *)
            usage
            exit 1
            ;;
    esac
}

if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    main "$@"
fi
