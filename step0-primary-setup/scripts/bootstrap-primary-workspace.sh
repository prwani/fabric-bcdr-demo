#!/usr/bin/env bash

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ROOT_DIR="$(cd "${SCRIPT_DIR}/../.." && pwd)"
NOTEBOOK_FILE="${SCRIPT_DIR}/../notebooks/seed-sample-data.ipynb"

FABRIC_API="https://api.fabric.microsoft.com/v1"
POLL_TIMEOUT=900
ITEM_TIMEOUT=300

WORKSPACE_NAME=""
WORKSPACE_DESCRIPTION="Primary BCDR demo workspace"
CAPACITY_ID=""
CAPACITY_DISPLAY_NAME=""

LAKEHOUSE_NAME="bcdr_demo_lakehouse"
WAREHOUSE_NAME="bcdr_demo_warehouse"
NOTEBOOK_NAME="bcdr_seed_sample_data"
PIPELINE_NAME="bcdr_demo_pipeline"
SPARK_JOB_NAME="bcdr_demo_spark_job"

RUN_SEED_NOTEBOOK=true
ENABLE_GIT=false
GIT_PROVIDER=""
GIT_OWNER=""
GIT_REPOSITORY_NAME=""
GIT_BRANCH="main"
GIT_DIRECTORY=""
GIT_CONNECTION_ID=""
GIT_ORGANIZATION=""
GIT_PROJECT=""
GIT_CUSTOM_DOMAIN=""
GIT_INITIALIZATION_STRATEGY="PreferWorkspace"
GIT_COMMIT_COMMENT="Bootstrap primary Fabric BCDR demo workspace"

DRY_RUN=false

CYAN='\033[0;36m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
GRAY='\033[0;90m'
NC='\033[0m'

info()    { echo -e "${GRAY}[INFO] $1${NC}" >&2; }
success() { echo -e "${GREEN}[OK]   $1${NC}" >&2; }
warn()    { echo -e "${YELLOW}[WARN] $1${NC}" >&2; }
fail()    { echo -e "${RED}[ERR]  $1${NC}" >&2; exit 1; }

usage() {
  cat <<'EOF'
Usage:
  bootstrap-primary-workspace.sh \
    --capacity-display-name <fabric-capacity-display-name> \
    --workspace-name <workspace-name> \
    [--workspace-description <text>] \
    [--capacity-id <fabric-capacity-uuid>] \
    [--lakehouse-name <name>] \
    [--warehouse-name <name>] \
    [--notebook-name <name>] \
    [--pipeline-name <name>] \
    [--spark-job-name <name>] \
    [--skip-seed-notebook] \
    [--git-provider github|azure-devops] \
    [--git-owner <github-owner>] \
    [--git-repository-name <repository-name>] \
    [--git-branch <branch>] \
    [--git-directory <directory>] \
    [--git-connection-id <configured-connection-id>] \
    [--git-organization <ado-organization>] \
    [--git-project <ado-project>] \
    [--git-custom-domain <ghe-domain>] \
    [--git-initialization-strategy PreferWorkspace|PreferRemote|None] \
    [--git-commit-comment <comment>] \
    [--timeout <seconds>] \
    [--dry-run]
EOF
}

need_cmd() {
  command -v "$1" >/dev/null 2>&1 || fail "Required command not found: $1"
}

get_fabric_token() {
  local resource
  for resource in "https://api.fabric.microsoft.com" "https://analysis.windows.net/powerbi/api"; do
    if TOKEN_CANDIDATE="$(az account get-access-token --resource "$resource" --query accessToken -o tsv 2>/dev/null)" && [[ -n "$TOKEN_CANDIDATE" ]]; then
      echo "$TOKEN_CANDIDATE"
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

api_post() {
  local path="$1"
  local payload="${2:-}"

  if [[ -n "$payload" ]]; then
    curl -sS -w $'\n%{http_code}' -X POST "${FABRIC_API}${path}" \
      -H "Authorization: Bearer ${TOKEN}" \
      -H "Content-Type: application/json" \
      -d "$payload"
  else
    curl -sS -w $'\n%{http_code}' -X POST "${FABRIC_API}${path}" \
      -H "Authorization: Bearer ${TOKEN}" \
      -H "Content-Type: application/json"
  fi
}

parse_http_code() {
  tail -n 1
}

parse_http_body() {
  sed '$d'
}

require_success() {
  local http_code="$1"
  local body="$2"
  local action="$3"

  if [[ "$http_code" -lt 200 || "$http_code" -ge 300 ]]; then
    fail "${action} failed (HTTP ${http_code}): ${body}"
  fi
}

find_workspace_json() {
  api_get "/workspaces" | jq -c --arg n "$WORKSPACE_NAME" '.value[]? | select(.displayName == $n)'
}

find_item_id() {
  local item_type="$1"
  local display_name="$2"

  curl -sS -f "${FABRIC_API}/workspaces/${WORKSPACE_ID}/items?type=${item_type}" \
    -H "Authorization: Bearer ${TOKEN}" \
    -H "Content-Type: application/json" 2>/dev/null | \
    jq -r --arg n "$display_name" '.value[]? | select(.displayName == $n) | .id // empty' | \
    head -n 1
}

wait_for_item_id() {
  local item_type="$1"
  local display_name="$2"
  local timeout="${3:-$ITEM_TIMEOUT}"
  local elapsed=0
  local id=""

  while [[ "$elapsed" -lt "$timeout" ]]; do
    id="$(find_item_id "$item_type" "$display_name" || true)"
    if [[ -n "$id" ]]; then
      echo "$id"
      return 0
    fi

    sleep 5
    elapsed=$((elapsed + 5))
  done

  fail "Timed out waiting for ${item_type} '${display_name}' to appear"
}

resolve_capacity_id() {
  if [[ -n "$CAPACITY_ID" ]]; then
    return
  fi

  [[ -n "$CAPACITY_DISPLAY_NAME" ]] || fail "Either --capacity-id or --capacity-display-name is required"

  info "Resolving Fabric capacity ID for '${CAPACITY_DISPLAY_NAME}'..."
  CAPACITY_ID="$(
    api_get "/capacities" |
      jq -r --arg n "$CAPACITY_DISPLAY_NAME" '.value[]? | select(.displayName == $n and .state == "Active") | .id // empty' |
      head -n 1
  )"

  [[ -n "$CAPACITY_ID" ]] || fail "Could not resolve an active Fabric capacity with display name '${CAPACITY_DISPLAY_NAME}'"
  success "Fabric capacity ID: ${CAPACITY_ID}"
}

ensure_workspace() {
  local workspace_json current_capacity_id resp http_code body payload

  workspace_json="$(find_workspace_json || true)"
  if [[ -n "$workspace_json" ]]; then
    WORKSPACE_ID="$(jq -r '.id' <<<"$workspace_json")"
    current_capacity_id="$(jq -r '.capacityId // empty' <<<"$workspace_json")"
    info "Workspace '${WORKSPACE_NAME}' already exists (id: ${WORKSPACE_ID})"

    if [[ -n "$CAPACITY_ID" && "$current_capacity_id" != "$CAPACITY_ID" ]]; then
      info "Assigning workspace to Fabric capacity ${CAPACITY_ID}..."
      payload="$(jq -nc --arg capacityId "$CAPACITY_ID" '{capacityId:$capacityId}')"
      resp="$(api_post "/workspaces/${WORKSPACE_ID}/assignToCapacity" "$payload")"
      http_code="$(parse_http_code <<<"$resp")"
      body="$(parse_http_body <<<"$resp")"
      require_success "$http_code" "$body" "Assign workspace to capacity"
      success "Workspace assigned to target capacity"
    fi

    return
  fi

  info "Creating workspace '${WORKSPACE_NAME}'..."
  payload="$(jq -nc \
    --arg displayName "$WORKSPACE_NAME" \
    --arg description "$WORKSPACE_DESCRIPTION" \
    --arg capacityId "$CAPACITY_ID" \
    '{
      displayName: $displayName,
      description: $description,
      capacityId: $capacityId
    }'
  )"

  resp="$(api_post "/workspaces" "$payload")"
  http_code="$(parse_http_code <<<"$resp")"
  body="$(parse_http_body <<<"$resp")"
  require_success "$http_code" "$body" "Create workspace"

  WORKSPACE_ID="$(
    jq -r '.id // empty' <<<"$body"
  )"

  if [[ -z "$WORKSPACE_ID" ]]; then
    WORKSPACE_ID="$(
      api_get "/workspaces" |
        jq -r --arg n "$WORKSPACE_NAME" '.value[]? | select(.displayName == $n) | .id // empty' |
        head -n 1
    )"
  fi

  [[ -n "$WORKSPACE_ID" ]] || fail "Workspace was created but no workspace ID could be resolved"
  success "Workspace ready (id: ${WORKSPACE_ID})"
}

ensure_simple_item() {
  local endpoint="$1"
  local item_type="$2"
  local display_name="$3"
  local description="$4"
  local existing_id resp http_code body payload

  existing_id="$(find_item_id "$item_type" "$display_name" || true)"
  if [[ -n "$existing_id" ]]; then
    info "${item_type} '${display_name}' already exists (id: ${existing_id})"
    echo "$existing_id"
    return
  fi

  payload="$(jq -nc --arg displayName "$display_name" --arg description "$description" '{displayName:$displayName, description:$description}')"
  resp="$(api_post "/workspaces/${WORKSPACE_ID}/${endpoint}" "$payload")"
  http_code="$(parse_http_code <<<"$resp")"
  body="$(parse_http_body <<<"$resp")"
  require_success "$http_code" "$body" "Create ${item_type}"

  success "${item_type} '${display_name}' requested"
  wait_for_item_id "$item_type" "$display_name"
}

render_notebook_base64() {
  python3 - "$NOTEBOOK_FILE" "$LAKEHOUSE_NAME" <<'PY'
import base64
import pathlib
import sys

path = pathlib.Path(sys.argv[1])
lakehouse_name = sys.argv[2]
content = path.read_text(encoding="utf-8").replace("__LAKEHOUSE_NAME__", lakehouse_name)
print(base64.b64encode(content.encode("utf-8")).decode("ascii"), end="")
PY
}

ensure_notebook() {
  local existing_id notebook_b64 payload resp http_code body

  notebook_b64="$(render_notebook_base64)"
  existing_id="$(find_item_id "Notebook" "$NOTEBOOK_NAME" || true)"

  if [[ -n "$existing_id" ]]; then
    info "Updating notebook '${NOTEBOOK_NAME}'..."
    payload="$(jq -nc \
      --arg payload "$notebook_b64" \
      '{
        definition: {
          format: "ipynb",
          parts: [
            {
              path: "notebook-content.ipynb",
              payload: $payload,
              payloadType: "InlineBase64"
            }
          ]
        }
      }'
    )"

    resp="$(api_post "/workspaces/${WORKSPACE_ID}/items/${existing_id}/updateDefinition" "$payload")"
    http_code="$(parse_http_code <<<"$resp")"
    body="$(parse_http_body <<<"$resp")"
    require_success "$http_code" "$body" "Update notebook definition"
    NOTEBOOK_ID="$existing_id"
    success "Notebook '${NOTEBOOK_NAME}' updated"
    return
  fi

  info "Creating notebook '${NOTEBOOK_NAME}'..."
  payload="$(jq -nc \
    --arg displayName "$NOTEBOOK_NAME" \
    --arg description "Seeds synthetic sample data into the primary lakehouse for the Fabric BCDR demo." \
    --arg notebookPayload "$notebook_b64" \
    '{
      displayName: $displayName,
      description: $description,
      definition: {
        format: "ipynb",
        parts: [
          {
            path: "notebook-content.ipynb",
            payload: $notebookPayload,
            payloadType: "InlineBase64"
          }
        ]
      }
    }'
  )"

  resp="$(api_post "/workspaces/${WORKSPACE_ID}/notebooks" "$payload")"
  http_code="$(parse_http_code <<<"$resp")"
  body="$(parse_http_body <<<"$resp")"
  require_success "$http_code" "$body" "Create notebook"

  NOTEBOOK_ID="$(wait_for_item_id "Notebook" "$NOTEBOOK_NAME")"
  success "Notebook ready (id: ${NOTEBOOK_ID})"
}

run_seed_notebook() {
  local resp http_code body job_resp job_status failure_reason elapsed=0 interval=10

  info "Triggering notebook '${NOTEBOOK_NAME}'..."
  resp="$(api_post "/workspaces/${WORKSPACE_ID}/items/${NOTEBOOK_ID}/jobs/instances?jobType=RunNotebook" '{"executionData":{}}')"
  http_code="$(parse_http_code <<<"$resp")"
  body="$(parse_http_body <<<"$resp")"
  require_success "$http_code" "$body" "Trigger notebook run"

  info "Polling notebook run status (timeout: ${POLL_TIMEOUT}s)..."
  while [[ "$elapsed" -lt "$POLL_TIMEOUT" ]]; do
    job_resp="$(
      curl -sS -f "${FABRIC_API}/workspaces/${WORKSPACE_ID}/items/${NOTEBOOK_ID}/jobs/instances" \
        -H "Authorization: Bearer ${TOKEN}" \
        -H "Content-Type: application/json" 2>/dev/null || echo '{"value":[]}'
    )"

    job_status="$(jq -r '[.value[]?] | sort_by(.startTimeUtc) | last | .status // "Unknown"' <<<"$job_resp")"

    case "$job_status" in
      Completed|Succeeded)
        success "Notebook run completed"
        return
        ;;
      Failed|Cancelled)
        failure_reason="$(jq -r '[.value[]?] | sort_by(.startTimeUtc) | last | .failureReason // "unknown"' <<<"$job_resp")"
        fail "Notebook run ${job_status}: ${failure_reason}"
        ;;
      Unknown|null)
        info "Waiting for job instance to appear (${elapsed}s elapsed)"
        ;;
      *)
        info "Notebook status: ${job_status} (${elapsed}s elapsed)"
        ;;
    esac

    sleep "$interval"
    elapsed=$((elapsed + interval))
  done

  fail "Notebook run did not finish within ${POLL_TIMEOUT}s"
}

connect_git_if_requested() {
  local payload resp http_code body error_code init_payload init_resp init_http init_body required_action workspace_head commit_payload commit_resp commit_http commit_body

  if [[ "$ENABLE_GIT" != true ]]; then
    return
  fi

  info "Connecting workspace to Git..."

  case "$GIT_PROVIDER" in
    github)
      [[ -n "$GIT_OWNER" ]] || fail "--git-owner is required for GitHub"
      [[ -n "$GIT_REPOSITORY_NAME" ]] || fail "--git-repository-name is required for GitHub"
      [[ -n "$GIT_CONNECTION_ID" ]] || fail "--git-connection-id is required for GitHub configured connections"

      payload="$(jq -nc \
        --arg ownerName "$GIT_OWNER" \
        --arg repositoryName "$GIT_REPOSITORY_NAME" \
        --arg branchName "$GIT_BRANCH" \
        --arg directoryName "$GIT_DIRECTORY" \
        --arg connectionId "$GIT_CONNECTION_ID" \
        --arg customDomainName "$GIT_CUSTOM_DOMAIN" \
        '{
          gitProviderDetails:
            ({
              ownerName: $ownerName,
              repositoryName: $repositoryName,
              branchName: $branchName,
              gitProviderType: "GitHub"
            }
            + (if $directoryName != "" then {directoryName: $directoryName} else {} end)
            + (if $customDomainName != "" then {customDomainName: $customDomainName} else {} end)),
          myGitCredentials: {
            source: "ConfiguredConnection",
            connectionId: $connectionId
          }
        }'
      )"
      ;;
    azure-devops)
      [[ -n "$GIT_ORGANIZATION" ]] || fail "--git-organization is required for Azure DevOps"
      [[ -n "$GIT_PROJECT" ]] || fail "--git-project is required for Azure DevOps"
      [[ -n "$GIT_REPOSITORY_NAME" ]] || fail "--git-repository-name is required for Azure DevOps"

      payload="$(jq -nc \
        --arg organizationName "$GIT_ORGANIZATION" \
        --arg projectName "$GIT_PROJECT" \
        --arg repositoryName "$GIT_REPOSITORY_NAME" \
        --arg branchName "$GIT_BRANCH" \
        --arg directoryName "$GIT_DIRECTORY" \
        --arg connectionId "$GIT_CONNECTION_ID" \
        '({
            gitProviderDetails:
              ({
                organizationName: $organizationName,
                projectName: $projectName,
                repositoryName: $repositoryName,
                branchName: $branchName,
                gitProviderType: "AzureDevOps"
              }
              + (if $directoryName != "" then {directoryName: $directoryName} else {} end))
          }
          + (if $connectionId != "" then {
              myGitCredentials: {
                source: "ConfiguredConnection",
                connectionId: $connectionId
              }
            } else {} end))'
      )"
      ;;
    *)
      fail "Unsupported git provider: ${GIT_PROVIDER}"
      ;;
  esac

  resp="$(api_post "/workspaces/${WORKSPACE_ID}/git/connect" "$payload")"
  http_code="$(parse_http_code <<<"$resp")"
  body="$(parse_http_body <<<"$resp")"

  if [[ "$http_code" -ge 200 && "$http_code" -lt 300 ]]; then
    success "Workspace connected to Git"
  else
    error_code="$(jq -r '.errorCode // empty' <<<"$body" 2>/dev/null || true)"
    if [[ "$error_code" == "WorkspaceAlreadyConnectedToGit" ]]; then
      warn "Workspace is already connected to Git; continuing"
    else
      fail "Git connect failed (HTTP ${http_code}): ${body}"
    fi
  fi

  info "Initializing Git connection..."
  init_payload="$(jq -nc --arg strategy "$GIT_INITIALIZATION_STRATEGY" '{initializationStrategy:$strategy}')"
  init_resp="$(api_post "/workspaces/${WORKSPACE_ID}/git/initializeConnection" "$init_payload")"
  init_http="$(parse_http_code <<<"$init_resp")"
  init_body="$(parse_http_body <<<"$init_resp")"
  require_success "$init_http" "$init_body" "Initialize Git connection"

  required_action="$(jq -r '.requiredAction // "None"' <<<"$init_body")"
  workspace_head="$(jq -r '.workspaceHead // empty' <<<"$init_body")"

  case "$required_action" in
    None)
      success "Git connection initialized; no additional action required"
      ;;
    CommitToGit)
      [[ -n "$workspace_head" ]] || fail "Git initialization returned CommitToGit without workspaceHead"
      info "Committing workspace contents to Git..."
      commit_payload="$(jq -nc \
        --arg workspaceHead "$workspace_head" \
        --arg comment "$GIT_COMMIT_COMMENT" \
        '{mode:"All", workspaceHead:$workspaceHead, comment:$comment}')"
      commit_resp="$(api_post "/workspaces/${WORKSPACE_ID}/git/commitToGit" "$commit_payload")"
      commit_http="$(parse_http_code <<<"$commit_resp")"
      commit_body="$(parse_http_body <<<"$commit_resp")"
      require_success "$commit_http" "$commit_body" "Commit workspace to Git"
      success "Workspace committed to Git"
      ;;
    UpdateFromGit)
      warn "Git initialization requires UpdateFromGit. The remote directory already contains content."
      warn "No automatic pull was performed because this bootstrap flow treats the workspace as the source of truth."
      ;;
    *)
      warn "Unexpected Git initialization action: ${required_action}"
      ;;
  esac
}

print_summary() {
  jq -nc \
    --arg workspaceId "$WORKSPACE_ID" \
    --arg workspaceName "$WORKSPACE_NAME" \
    --arg capacityId "$CAPACITY_ID" \
    --arg lakehouseName "$LAKEHOUSE_NAME" \
    --arg warehouseName "$WAREHOUSE_NAME" \
    --arg notebookName "$NOTEBOOK_NAME" \
    --arg pipelineName "$PIPELINE_NAME" \
    --arg sparkJobName "$SPARK_JOB_NAME" \
    '{
      workspace: {
        id: $workspaceId,
        displayName: $workspaceName,
        capacityId: $capacityId
      },
      artifacts: {
        lakehouse: $lakehouseName,
        warehouse: $warehouseName,
        notebook: $notebookName,
        dataPipeline: $pipelineName,
        sparkJobDefinition: $sparkJobName
      },
      nextSteps: [
        "Run step0-primary-setup/sql/seed-warehouse.sql in the Fabric warehouse SQL editor or another TDS client.",
        "Run fabric-toolbox/accelerators/BCDR/01 - Run In Primary.ipynb after the sample environment is ready."
      ]
    }'
}

while [[ $# -gt 0 ]]; do
  case "$1" in
    --workspace-name) WORKSPACE_NAME="${2:-}"; shift 2 ;;
    --workspace-description) WORKSPACE_DESCRIPTION="${2:-}"; shift 2 ;;
    --capacity-id) CAPACITY_ID="${2:-}"; shift 2 ;;
    --capacity-display-name) CAPACITY_DISPLAY_NAME="${2:-}"; shift 2 ;;
    --lakehouse-name) LAKEHOUSE_NAME="${2:-}"; shift 2 ;;
    --warehouse-name) WAREHOUSE_NAME="${2:-}"; shift 2 ;;
    --notebook-name) NOTEBOOK_NAME="${2:-}"; shift 2 ;;
    --pipeline-name) PIPELINE_NAME="${2:-}"; shift 2 ;;
    --spark-job-name) SPARK_JOB_NAME="${2:-}"; shift 2 ;;
    --skip-seed-notebook) RUN_SEED_NOTEBOOK=false; shift ;;
    --git-provider) ENABLE_GIT=true; GIT_PROVIDER="${2:-}"; shift 2 ;;
    --git-owner) GIT_OWNER="${2:-}"; shift 2 ;;
    --git-repository-name) GIT_REPOSITORY_NAME="${2:-}"; shift 2 ;;
    --git-branch) GIT_BRANCH="${2:-}"; shift 2 ;;
    --git-directory) GIT_DIRECTORY="${2:-}"; shift 2 ;;
    --git-connection-id) GIT_CONNECTION_ID="${2:-}"; shift 2 ;;
    --git-organization) GIT_ORGANIZATION="${2:-}"; shift 2 ;;
    --git-project) GIT_PROJECT="${2:-}"; shift 2 ;;
    --git-custom-domain) GIT_CUSTOM_DOMAIN="${2:-}"; shift 2 ;;
    --git-initialization-strategy) GIT_INITIALIZATION_STRATEGY="${2:-}"; shift 2 ;;
    --git-commit-comment) GIT_COMMIT_COMMENT="${2:-}"; shift 2 ;;
    --timeout) POLL_TIMEOUT="${2:-}"; shift 2 ;;
    --dry-run) DRY_RUN=true; shift ;;
    -h|--help) usage; exit 0 ;;
    *) fail "Unknown argument: $1" ;;
  esac
done

need_cmd az
need_cmd curl
need_cmd jq
need_cmd python3

[[ -n "$WORKSPACE_NAME" ]] || fail "--workspace-name is required"
[[ -n "$CAPACITY_ID" || -n "$CAPACITY_DISPLAY_NAME" ]] || fail "--capacity-id or --capacity-display-name is required"
[[ -f "$NOTEBOOK_FILE" ]] || fail "Notebook template not found: $NOTEBOOK_FILE"

if [[ "$DRY_RUN" == true ]]; then
  cat <<EOF
Primary bootstrap dry run
=========================
Workspace:           ${WORKSPACE_NAME}
Workspace desc:      ${WORKSPACE_DESCRIPTION}
Capacity ID:         ${CAPACITY_ID:-<resolve by display name>}
Capacity display:    ${CAPACITY_DISPLAY_NAME:-<not provided>}
Lakehouse:           ${LAKEHOUSE_NAME}
Warehouse:           ${WAREHOUSE_NAME}
Notebook:            ${NOTEBOOK_NAME}
Pipeline:            ${PIPELINE_NAME}
Spark job:           ${SPARK_JOB_NAME}
Run seed notebook:   ${RUN_SEED_NOTEBOOK}
Enable Git:          ${ENABLE_GIT}
Git provider:        ${GIT_PROVIDER:-<none>}
Git repository:      ${GIT_REPOSITORY_NAME:-<none>}
Git directory:       ${GIT_DIRECTORY:-<none>}
Git init strategy:   ${GIT_INITIALIZATION_STRATEGY}
EOF
  exit 0
fi

az account show >/dev/null 2>&1 || fail "Azure CLI is not logged in. Run: az login"
TOKEN="$(get_fabric_token)" || fail "Could not acquire a Fabric access token with Azure CLI"

resolve_capacity_id
ensure_workspace

LAKEHOUSE_ID="$(ensure_simple_item "lakehouses" "Lakehouse" "$LAKEHOUSE_NAME" "Primary demo lakehouse for the Fabric BCDR scenario.")"
WAREHOUSE_ID="$(ensure_simple_item "warehouses" "Warehouse" "$WAREHOUSE_NAME" "Primary demo warehouse for the Fabric BCDR scenario.")"
NOTEBOOK_ID=""
ensure_notebook
PIPELINE_ID="$(ensure_simple_item "dataPipelines" "DataPipeline" "$PIPELINE_NAME" "Sample pipeline artifact for BCDR recovery demonstrations.")"
SPARK_JOB_ID="$(ensure_simple_item "sparkJobDefinitions" "SparkJobDefinition" "$SPARK_JOB_NAME" "Sample Spark job definition artifact for BCDR recovery demonstrations.")"

if [[ "$RUN_SEED_NOTEBOOK" == true ]]; then
  run_seed_notebook
fi

connect_git_if_requested
print_summary
