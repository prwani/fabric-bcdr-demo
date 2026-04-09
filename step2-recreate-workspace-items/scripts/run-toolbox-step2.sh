#!/usr/bin/env bash

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd "${SCRIPT_DIR}/../.." && pwd)"
TOOLBOX_ROOT="${REPO_ROOT}/../fabric-toolbox"
TOOLBOX_REPO_URL="https://github.com/prwani/fabric-toolbox"
CHECK_LOCAL=false

usage() {
  cat <<EOF
Usage:
  $(basename "$0") [--toolbox-root <path>] [--check]

Print the exact Step 2 assets to run from prwani/fabric-toolbox.
EOF
}

check_file() {
  local path="$1"
  [[ -f "$path" ]] || {
    echo "Missing toolbox file: $path" >&2
    return 1
  }
}

while [[ $# -gt 0 ]]; do
  case "$1" in
    --toolbox-root) TOOLBOX_ROOT="${2:-}"; shift 2 ;;
    --check) CHECK_LOCAL=true; shift ;;
    -h|--help) usage; exit 0 ;;
    *) echo "Unknown argument: $1" >&2; usage >&2; exit 1 ;;
  esac
done

DR_NOTEBOOK="${TOOLBOX_ROOT}/accelerators/BCDR/02 - Run In DR.ipynb"
UTILS_NOTEBOOK="${TOOLBOX_ROOT}/accelerators/BCDR/workspaceutils.ipynb"
RECREATE_ARTIFACTS="${TOOLBOX_ROOT}/accelerators/data-warehouse-backup-and-recovery/_RecoveryScripts/RecreateArtifacts.ps1"

if [[ "$CHECK_LOCAL" == true ]]; then
  check_file "$DR_NOTEBOOK"
  check_file "$UTILS_NOTEBOOK"
  check_file "$RECREATE_ARTIFACTS"
fi

cat <<EOF
Step 2 toolbox references
=========================

Fork repo:
  ${TOOLBOX_REPO_URL}

Primary recovery notebook:
  Local: ${DR_NOTEBOOK}
  URL:   ${TOOLBOX_REPO_URL}/blob/main/accelerators/BCDR/02%20-%20Run%20In%20DR.ipynb

Supporting utilities:
  Local: ${UTILS_NOTEBOOK}
  URL:   ${TOOLBOX_REPO_URL}/blob/main/accelerators/BCDR/workspaceutils.ipynb

Warehouse-oriented alternative:
  Local: ${RECREATE_ARTIFACTS}
  URL:   ${TOOLBOX_REPO_URL}/blob/main/accelerators/data-warehouse-backup-and-recovery/_RecoveryScripts/RecreateArtifacts.ps1
EOF
