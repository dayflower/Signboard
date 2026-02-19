#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ROOT_DIR="$(cd "${SCRIPT_DIR}/.." && pwd)"
source "${SCRIPT_DIR}/version.sh"

usage() {
    cat <<'EOF'
Usage:
  scripts/tag-merged-release.sh [version]

If version is omitted, VERSION on main is used.
EOF
}

require_clean_worktree() {
    if ! git diff --quiet || ! git diff --cached --quiet; then
        die "Working tree is not clean. Commit or stash changes before tagging."
    fi
}

main() {
    if [[ "$#" -gt 1 ]]; then
        usage
        exit 1
    fi

    local requested_version="${1:-}"
    if [[ -n "${requested_version}" ]]; then
        validate_semver "${requested_version}"
    fi

    cd "${ROOT_DIR}"
    require_clean_worktree

    git switch main
    git pull --ff-only

    assert_consistent

    local main_version
    main_version="$(read_version)"
    if [[ -n "${requested_version}" && "${requested_version}" != "${main_version}" ]]; then
        die "Requested version (${requested_version}) does not match VERSION on main (${main_version})."
    fi

    local version_to_tag="${main_version}"
    local tag_name="v${version_to_tag}"

    if git show-ref --verify --quiet "refs/tags/${tag_name}"; then
        die "Local tag already exists: ${tag_name}"
    fi
    if git ls-remote --exit-code --tags origin "refs/tags/${tag_name}" > /dev/null 2>&1; then
        die "Remote tag already exists: ${tag_name}"
    fi

    git tag "${tag_name}"
    git push origin "${tag_name}"

    echo "Created lightweight tag ${tag_name} on main HEAD and pushed to origin."
}

main "$@"
