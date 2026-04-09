#!/usr/bin/env bash

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
TEMPLATE_FILE="${SCRIPT_DIR}/../bicep/fabric-capacity.bicep"

SUBSCRIPTION_ID=""
RESOURCE_GROUP=""
CAPACITY_NAME=""
LOCATION=""
SKU_NAME="F2"
ADMIN_MEMBERS_CSV=""
TAGS_JSON="{}"
WHAT_IF=false
SKIP_PROVIDER_REGISTRATION=false

usage() {
  cat <<'EOF'
Usage:
  provision-capacity.sh \
    --subscription-id <subscription-id> \
    --resource-group <resource-group> \
    --capacity-name <capacity-name> \
    --location <azure-region> \
    --admin-members <user1@contoso.com,user2@contoso.com> \
    [--sku <F2|F4|F8|F16|F32|F64|F128|F256|F512|F1024|F2048>] \
    [--tags-json '{"key":"value"}'] \
    [--what-if] \
    [--skip-provider-registration]
EOF
}

fail() {
  echo "Error: $*" >&2
  exit 1
}

need_cmd() {
  command -v "$1" >/dev/null 2>&1 || fail "Required command not found: $1"
}

validate_capacity_name() {
  [[ "$1" =~ ^[a-z][a-z0-9]{2,62}$ ]] || fail "capacity name must match ^[a-z][a-z0-9]{2,62}$"
}

validate_tags_json() {
  local candidate="$1"
  if command -v jq >/dev/null 2>&1; then
    jq -e 'type == "object"' >/dev/null 2>&1 <<<"$candidate" || fail "--tags-json must be a JSON object"
  else
    [[ "$candidate" == \{* ]] || fail "--tags-json must be a JSON object string"
  fi
}

build_admin_members_json() {
  local csv="$1"
  local json="["
  local member trimmed
  IFS=',' read -r -a members <<<"$csv"

  [[ "${#members[@]}" -gt 0 ]] || fail "at least one admin member is required"

  for member in "${members[@]}"; do
    trimmed="${member//[[:space:]]/}"
    [[ -n "$trimmed" ]] || continue
    json+="\"${trimmed}\","
  done

  [[ "$json" != "[" ]] || fail "at least one non-empty admin member is required"
  ADMIN_MEMBERS_JSON="${json%,}]"
}

ensure_provider_registered() {
  local state
  state="$(az provider show --namespace Microsoft.Fabric --query registrationState -o tsv 2>/dev/null || true)"

  if [[ "$state" == "Registered" ]]; then
    return
  fi

  echo "Registering Microsoft.Fabric resource provider..."
  az provider register --namespace Microsoft.Fabric --wait >/dev/null
}

while [[ $# -gt 0 ]]; do
  case "$1" in
    --subscription-id)
      SUBSCRIPTION_ID="${2:-}"
      shift 2
      ;;
    --resource-group)
      RESOURCE_GROUP="${2:-}"
      shift 2
      ;;
    --capacity-name)
      CAPACITY_NAME="${2:-}"
      shift 2
      ;;
    --location)
      LOCATION="${2:-}"
      shift 2
      ;;
    --sku)
      SKU_NAME="${2:-}"
      shift 2
      ;;
    --admin-members)
      ADMIN_MEMBERS_CSV="${2:-}"
      shift 2
      ;;
    --tags-json)
      TAGS_JSON="${2:-}"
      shift 2
      ;;
    --what-if)
      WHAT_IF=true
      shift
      ;;
    --skip-provider-registration)
      SKIP_PROVIDER_REGISTRATION=true
      shift
      ;;
    -h|--help)
      usage
      exit 0
      ;;
    *)
      fail "Unknown argument: $1"
      ;;
  esac
done

need_cmd az
[[ -f "$TEMPLATE_FILE" ]] || fail "template not found: $TEMPLATE_FILE"
[[ -n "$SUBSCRIPTION_ID" ]] || fail "--subscription-id is required"
[[ -n "$RESOURCE_GROUP" ]] || fail "--resource-group is required"
[[ -n "$CAPACITY_NAME" ]] || fail "--capacity-name is required"
[[ -n "$LOCATION" ]] || fail "--location is required"
[[ -n "$ADMIN_MEMBERS_CSV" ]] || fail "--admin-members is required"

validate_capacity_name "$CAPACITY_NAME"
validate_tags_json "$TAGS_JSON"
build_admin_members_json "$ADMIN_MEMBERS_CSV"

az account show >/dev/null 2>&1 || fail "Azure CLI is not logged in. Run: az login"
az account set --subscription "$SUBSCRIPTION_ID"

if [[ "$SKIP_PROVIDER_REGISTRATION" != true ]]; then
  ensure_provider_registered
fi

DEPLOYMENT_NAME="fabric-capacity-${CAPACITY_NAME}"

deployment_args=(
  --name "$DEPLOYMENT_NAME"
  --resource-group "$RESOURCE_GROUP"
  --template-file "$TEMPLATE_FILE"
  --parameters "capacityName=$CAPACITY_NAME"
  --parameters "location=$LOCATION"
  --parameters "skuName=$SKU_NAME"
  --parameters "adminMembers=$ADMIN_MEMBERS_JSON"
  --parameters "tags=$TAGS_JSON"
)

if [[ "$WHAT_IF" == true ]]; then
  az deployment group what-if "${deployment_args[@]}"
  exit 0
fi

az deployment group create "${deployment_args[@]}" >/dev/null

az resource show \
  --subscription "$SUBSCRIPTION_ID" \
  --resource-group "$RESOURCE_GROUP" \
  --resource-type "Microsoft.Fabric/capacities" \
  --name "$CAPACITY_NAME" \
  --query '{id:id,name:name,location:location,type:type}' \
  -o json
