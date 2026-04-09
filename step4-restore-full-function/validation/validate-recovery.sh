#!/usr/bin/env bash

set -euo pipefail

FABRIC_API="https://api.fabric.microsoft.com/v1"
CAPACITY_ID=""
CAPACITY_DISPLAY_NAME=""
WORKSPACE_ID=""
WORKSPACE_NAME=""
LAKEHOUSE_NAME=""
WAREHOUSE_NAME=""
NOTEBOOK_NAME=""
PIPELINE_NAME=""
SPARK_JOB_NAME=""

usage() {
  cat <<'EOF'
Usage:
  validate-recovery.sh \
    [--capacity-id <uuid> | --capacity-display-name <name>] \
    [--workspace-id <uuid> | --workspace-name <name>] \
    [--lakehouse-name <name>] \
    [--warehouse-name <name>] \
    [--notebook-name <name>] \
    [--pipeline-name <name>] \
    [--spark-job-name <name>]
EOF
}

need_cmd() {
  command -v "$1" >/dev/null 2>&1 || {
    echo "Required command not found: $1" >&2
    exit 1
  }
}

get_fabric_token() {
  local resource candidate
  for resource in "https://api.fabric.microsoft.com" "https://analysis.windows.net/powerbi/api"; do
    if candidate="$(az account get-access-token --resource "$resource" --query accessToken -o tsv 2>/dev/null)" && [[ -n "$candidate" ]]; then
      echo "$candidate"
      return 0
    fi
  done

  return 1
}

api_get() {
  local path="$1"
  curl -sS -f "${FABRIC_API}${path}" \
    -H "Authorization: Bearer ${TOKEN}" \
    -H "Content-Type: application/json"
}

resolve_capacity_id() {
  if [[ -n "$CAPACITY_ID" ]]; then
    return
  fi

  [[ -n "$CAPACITY_DISPLAY_NAME" ]] || return

  CAPACITY_ID="$(
    api_get "/capacities" |
      jq -r --arg n "$CAPACITY_DISPLAY_NAME" '.value[]? | select(.displayName == $n) | .id // empty' |
      head -n 1
  )"
}

resolve_workspace_id() {
  if [[ -n "$WORKSPACE_ID" ]]; then
    return
  fi

  [[ -n "$WORKSPACE_NAME" ]] || return

  WORKSPACE_ID="$(
    api_get "/workspaces" |
      jq -r --arg n "$WORKSPACE_NAME" '.value[]? | select(.displayName == $n) | .id // empty' |
      head -n 1
  )"
}

workspace_json() {
  api_get "/workspaces" | jq -c --arg id "$WORKSPACE_ID" '.value[]? | select(.id == $id)'
}

item_report() {
  local item_type="$1"
  local display_name="$2"

  if [[ -z "$display_name" || -z "$WORKSPACE_ID" ]]; then
    jq -nc --arg type "$item_type" --arg expected "$display_name" '{type:$type, expected:$expected, found:null, id:null}'
    return
  fi

  curl -sS -f "${FABRIC_API}/workspaces/${WORKSPACE_ID}/items?type=${item_type}" \
    -H "Authorization: Bearer ${TOKEN}" \
    -H "Content-Type: application/json" 2>/dev/null | \
    jq -c --arg type "$item_type" --arg expected "$display_name" '
      (.value[]? | select(.displayName == $expected) | {type:$type, expected:$expected, found:true, id:.id}) // {type:$type, expected:$expected, found:false, id:null}
    ' | head -n 1
}

while [[ $# -gt 0 ]]; do
  case "$1" in
    --capacity-id) CAPACITY_ID="${2:-}"; shift 2 ;;
    --capacity-display-name) CAPACITY_DISPLAY_NAME="${2:-}"; shift 2 ;;
    --workspace-id) WORKSPACE_ID="${2:-}"; shift 2 ;;
    --workspace-name) WORKSPACE_NAME="${2:-}"; shift 2 ;;
    --lakehouse-name) LAKEHOUSE_NAME="${2:-}"; shift 2 ;;
    --warehouse-name) WAREHOUSE_NAME="${2:-}"; shift 2 ;;
    --notebook-name) NOTEBOOK_NAME="${2:-}"; shift 2 ;;
    --pipeline-name) PIPELINE_NAME="${2:-}"; shift 2 ;;
    --spark-job-name) SPARK_JOB_NAME="${2:-}"; shift 2 ;;
    -h|--help) usage; exit 0 ;;
    *) echo "Unknown argument: $1" >&2; usage >&2; exit 1 ;;
  esac
done

need_cmd az
need_cmd curl
need_cmd jq
az account show >/dev/null 2>&1 || {
  echo "Azure CLI is not logged in. Run: az login" >&2
  exit 1
}

TOKEN="$(get_fabric_token)" || {
  echo "Could not acquire a Fabric access token with Azure CLI." >&2
  exit 1
}

resolve_capacity_id
resolve_workspace_id

WORKSPACE_JSON="$(if [[ -n "$WORKSPACE_ID" ]]; then workspace_json; fi)"
WORKSPACE_ASSIGNED_CAPACITY="$(jq -r '.capacityId // empty' <<<"${WORKSPACE_JSON:-{}}")"

LAKEHOUSE_REPORT="$(item_report "Lakehouse" "$LAKEHOUSE_NAME")"
WAREHOUSE_REPORT="$(item_report "Warehouse" "$WAREHOUSE_NAME")"
NOTEBOOK_REPORT="$(item_report "Notebook" "$NOTEBOOK_NAME")"
PIPELINE_REPORT="$(item_report "DataPipeline" "$PIPELINE_NAME")"
SPARK_JOB_REPORT="$(item_report "SparkJobDefinition" "$SPARK_JOB_NAME")"

jq -nc \
  --arg capacityId "$CAPACITY_ID" \
  --arg capacityDisplayName "$CAPACITY_DISPLAY_NAME" \
  --arg workspaceId "$WORKSPACE_ID" \
  --arg workspaceName "$WORKSPACE_NAME" \
  --arg workspaceAssignedCapacity "$WORKSPACE_ASSIGNED_CAPACITY" \
  --argjson lakehouse "$LAKEHOUSE_REPORT" \
  --argjson warehouse "$WAREHOUSE_REPORT" \
  --argjson notebook "$NOTEBOOK_REPORT" \
  --argjson pipeline "$PIPELINE_REPORT" \
  --argjson sparkJob "$SPARK_JOB_REPORT" \
  '{
    capacity: {
      expectedId: ($capacityId | if . == "" then null else . end),
      expectedDisplayName: ($capacityDisplayName | if . == "" then null else . end),
      resolved: ($capacityId != "")
    },
    workspace: {
      id: ($workspaceId | if . == "" then null else . end),
      displayName: ($workspaceName | if . == "" then null else . end),
      found: ($workspaceId != ""),
      assignedCapacityId: ($workspaceAssignedCapacity | if . == "" then null else . end),
      capacityMatches: (
        if $capacityId == "" or $workspaceAssignedCapacity == "" then null
        else $workspaceAssignedCapacity == $capacityId
        end
      )
    },
    artifacts: {
      lakehouse: $lakehouse,
      warehouse: $warehouse,
      notebook: $notebook,
      dataPipeline: $pipeline,
      sparkJobDefinition: $sparkJob
    },
    nextSteps: [
      "Run step4-restore-full-function/validation/validate-recovery.ipynb in the target workspace to validate lakehouse tables and row counts.",
      "Run step4-restore-full-function/validation/validate-warehouse.sql in the target warehouse SQL editor to validate warehouse tables and row counts."
    ]
  }'
