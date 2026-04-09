#!/usr/bin/env bash

set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"

usage() {
cat <<EOF
Non-paired-region demo flow
===========================

1. Step 0: prepare the primary environment and schedule cross-region backups
   - docs: ${ROOT_DIR}/docs/nonpaired-region-guide.md
   - bootstrap: ${ROOT_DIR}/e2e-demo/run-primary-setup.sh
   - toolbox capture: ${ROOT_DIR}/step0-primary-setup/scripts/run-toolbox-primary-capture.sh

2. Step 1: provision the DR capacity
   - script: ${ROOT_DIR}/step1-provision-dr-capacity/scripts/provision-capacity.sh

3. Step 2: recreate workspaces and supported items from Git
   - docs: ${ROOT_DIR}/step2-recreate-workspace-items/README.md

4. Step 3: restore data from secondary-region storage backups
   - docs: ${ROOT_DIR}/step3-copy-data/nonpaired/README.md

5. Step 4: restore full function and validate
   - validator: ${ROOT_DIR}/step4-restore-full-function/validation/validate-recovery.sh

Commands:
  $(basename "$0") primary-setup [bootstrap args...]
  $(basename "$0") capture-primary [wrapper args...]
  $(basename "$0") provision-dr [provision args...]
  $(basename "$0") warehouse-recovery [wrapper args...]
  $(basename "$0") validate [validation args...]
EOF
}

case "${1:-}" in
  primary-setup)
    shift
    exec "${ROOT_DIR}/e2e-demo/run-primary-setup.sh" "$@"
    ;;
  capture-primary)
    shift
    exec "${ROOT_DIR}/step0-primary-setup/scripts/run-toolbox-primary-capture.sh" "$@"
    ;;
  provision-dr)
    shift
    exec "${ROOT_DIR}/step1-provision-dr-capacity/scripts/provision-capacity.sh" "$@"
    ;;
  warehouse-recovery)
    shift
    exec "${ROOT_DIR}/step3-copy-data/nonpaired/scripts/run-toolbox-warehouse-recovery.sh" "$@"
    ;;
  validate)
    shift
    exec "${ROOT_DIR}/step4-restore-full-function/validation/validate-recovery.sh" "$@"
    ;;
  ""|-h|--help|help)
    usage
    ;;
  *)
    echo "Unknown command: $1" >&2
    echo >&2
    usage >&2
    exit 1
    ;;
esac
