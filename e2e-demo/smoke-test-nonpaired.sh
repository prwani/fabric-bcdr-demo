#!/usr/bin/env bash

set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"

exec "${ROOT_DIR}/step4-restore-full-function/validation/validate-recovery.sh" "$@"
