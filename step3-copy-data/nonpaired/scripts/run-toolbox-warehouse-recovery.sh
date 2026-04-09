#!/usr/bin/env bash

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd "${SCRIPT_DIR}/../../.." && pwd)"
TOOLBOX_ROOT="${REPO_ROOT}/../fabric-toolbox"
TOOLBOX_REPO_URL="https://github.com/prwani/fabric-toolbox"
CHECK_LOCAL=false

usage() {
  cat <<EOF
Usage:
  $(basename "$0") [--toolbox-root <path>] [--check]

Print the warehouse recovery assets to use from prwani/fabric-toolbox for the non-paired flow.
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

INGEST_SQL="${TOOLBOX_ROOT}/accelerators/data-warehouse-backup-and-recovery/_RecoveryScripts/IngestDataIntoDeployedWarehouse.sql"
RECREATE_ARTIFACTS="${TOOLBOX_ROOT}/accelerators/data-warehouse-backup-and-recovery/_RecoveryScripts/RecreateArtifacts.ps1"

if [[ "$CHECK_LOCAL" == true ]]; then
  check_file "$INGEST_SQL"
  check_file "$RECREATE_ARTIFACTS"
fi

cat <<EOF
Non-paired warehouse recovery references
=======================================

Fork repo:
  ${TOOLBOX_REPO_URL}

Use the storage-restored data in a staging lakehouse, then apply the standard warehouse recovery helpers:

1. Recreate warehouse-oriented artifacts if needed
   Local: ${RECREATE_ARTIFACTS}
   URL:   ${TOOLBOX_REPO_URL}/blob/main/accelerators/data-warehouse-backup-and-recovery/_RecoveryScripts/RecreateArtifacts.ps1

2. Generate warehouse ingest commands from the staging lakehouse
   Local: ${INGEST_SQL}
   URL:   ${TOOLBOX_REPO_URL}/blob/main/accelerators/data-warehouse-backup-and-recovery/_RecoveryScripts/IngestDataIntoDeployedWarehouse.sql
EOF
