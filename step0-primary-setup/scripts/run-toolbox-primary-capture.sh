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

Prints the exact toolbox assets to run after the primary workspace is bootstrapped.

Options:
  --toolbox-root <path>  Local clone of prwani/fabric-toolbox
  --check                Fail if the expected toolbox files do not exist locally
  -h, --help             Show this help
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

PRIMARY_NOTEBOOK="${TOOLBOX_ROOT}/accelerators/BCDR/01 - Run In Primary.ipynb"
UTILS_NOTEBOOK="${TOOLBOX_ROOT}/accelerators/BCDR/workspaceutils.ipynb"
DW_SECURITY_SQL="${TOOLBOX_ROOT}/accelerators/data-warehouse-backup-and-recovery/_BackupScripts/ScriptFabricDWSecurity.sql"
WORKSPACE_PERMS_PS1="${TOOLBOX_ROOT}/accelerators/data-warehouse-backup-and-recovery/_BackupScripts/ScriptWorkspacePermissions.ps1"

if [[ "$CHECK_LOCAL" == true ]]; then
  check_file "$PRIMARY_NOTEBOOK"
  check_file "$UTILS_NOTEBOOK"
  check_file "$DW_SECURITY_SQL"
  check_file "$WORKSPACE_PERMS_PS1"
fi

cat <<EOF
Toolbox primary capture references
=================================

Fork repo:
  ${TOOLBOX_REPO_URL}

Local toolbox root:
  ${TOOLBOX_ROOT}

Run these after the primary workspace and sample data are ready:

1. Capture Fabric recovery metadata
   Local: ${PRIMARY_NOTEBOOK}
   URL:   ${TOOLBOX_REPO_URL}/blob/main/accelerators/BCDR/01%20-%20Run%20In%20Primary.ipynb

2. Supporting notebook utilities
   Local: ${UTILS_NOTEBOOK}
   URL:   ${TOOLBOX_REPO_URL}/blob/main/accelerators/BCDR/workspaceutils.ipynb

3. Script warehouse security for replay
   Local: ${DW_SECURITY_SQL}
   URL:   ${TOOLBOX_REPO_URL}/blob/main/accelerators/data-warehouse-backup-and-recovery/_BackupScripts/ScriptFabricDWSecurity.sql

4. Script workspace permissions for replay
   Local: ${WORKSPACE_PERMS_PS1}
   URL:   ${TOOLBOX_REPO_URL}/blob/main/accelerators/data-warehouse-backup-and-recovery/_BackupScripts/ScriptWorkspacePermissions.ps1
EOF
