#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ROOT_DIR="$(cd "${SCRIPT_DIR}/.." && pwd)"
source "${SCRIPT_DIR}/version.sh"

usage() {
    cat <<'EOF'
Usage:
  scripts/bump-version-pr.sh <major|minor|patch>
EOF
}

require_clean_worktree() {
    if ! git diff --quiet || ! git diff --cached --quiet; then
        die "Working tree is not clean. Commit or stash changes before running bump flow."
    fi
}

main() {
    if [[ "$#" -ne 1 ]]; then
        usage
        exit 1
    fi

    local bump_type="${1}"
    case "${bump_type}" in
        major | minor | patch) ;;
        *)
            die "Unsupported bump type: ${bump_type}. Use major, minor, or patch."
            ;;
    esac

    cd "${ROOT_DIR}"
    require_clean_worktree
    git switch main
    git pull --ff-only

    local current_version
    local next_version_value
    current_version="$(read_version)"
    next_version_value="$(next_version "${bump_type}" "${current_version}")"

    local branch_name="chore/bump-version-v${next_version_value}"
    local pr_title="chore: bump version to v${next_version_value}"

    if git show-ref --verify --quiet "refs/heads/${branch_name}"; then
        die "Local branch already exists: ${branch_name}"
    fi
    if git ls-remote --exit-code --heads origin "${branch_name}" > /dev/null 2>&1; then
        die "Remote branch already exists: ${branch_name}"
    fi

    git switch -c "${branch_name}"

    write_version "${next_version_value}"
    sync_swift_version "${next_version_value}"
    assert_consistent

    git add VERSION Sources/SignboardCore/SignboardCoreModels.swift
    git commit -m "${pr_title}"
    git push -u origin "${branch_name}"

    local pr_body
    pr_body=$(
        cat <<EOF
Automated version bump.

- Bump type: \`${bump_type}\`
- Version: \`${current_version}\` -> \`v${next_version_value}\`
- Updated files: \`VERSION\`, \`Sources/SignboardCore/SignboardCoreModels.swift\`
EOF
    )

    local pr_url
    pr_url="$(
        gh pr create \
            --base main \
            --head "${branch_name}" \
            --title "${pr_title}" \
            --label release \
            --body "${pr_body}"
    )"

    gh pr merge --auto --merge "${pr_url}"

    cat <<EOF
Created PR: ${pr_url}
Enabled auto-merge for ${pr_title}
EOF
}

main "$@"
