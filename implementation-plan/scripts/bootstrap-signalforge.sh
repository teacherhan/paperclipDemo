#!/usr/bin/env bash
set -euo pipefail

# Fully automated bootstrap for the SignalForge AI company blueprint.
#
# Usage:
#   ./implementation-plan/scripts/bootstrap-signalforge.sh
#
# Optional env:
#   PAPERCLIP_BASE_URL=http://localhost:3100/api
#   PAPERCLIP_TOKEN=<bearer-token>
#   PAPERCLIP_COOKIE="session_cookie_name=session_cookie_value"
#   PAPERCLIP_ADAPTER_TYPE=codex_local
#   PAPERCLIP_DRY_RUN=true
#   PAPERCLIP_SKIP_TLS_VERIFY=true

BASE_URL="${PAPERCLIP_BASE_URL:-http://localhost:3100/api}"
TOKEN="${PAPERCLIP_TOKEN:-}"
COOKIE="${PAPERCLIP_COOKIE:-}"
ADAPTER_TYPE="${PAPERCLIP_ADAPTER_TYPE:-codex_local}"
DRY_RUN="${PAPERCLIP_DRY_RUN:-false}"
SKIP_TLS_VERIFY="${PAPERCLIP_SKIP_TLS_VERIFY:-false}"

COMPANY_NAME="SignalForge AI"
COMPANY_DESCRIPTION="AI SaaS company focused on meeting summary automation and early revenue traction."

require_bin() {
  if ! command -v "$1" >/dev/null 2>&1; then
    echo "Missing dependency: $1" >&2
    exit 1
  fi
}

require_bin curl
require_bin jq

AUTH_ARGS=()
if [[ -n "$TOKEN" ]]; then
  AUTH_ARGS=(-H "Authorization: Bearer $TOKEN")
elif [[ -n "$COOKIE" ]]; then
  AUTH_ARGS=(-H "Cookie: $COOKIE")
fi

CURL_ARGS=(-fsS)
if [[ "$SKIP_TLS_VERIFY" == "true" ]]; then
  CURL_ARGS+=(-k)
fi

api_get() {
  local path="$1"
  if [[ "$DRY_RUN" == "true" ]]; then
    echo "[]"
    return 0
  fi
  curl "${CURL_ARGS[@]}" "${AUTH_ARGS[@]}" "$BASE_URL$path"
}

api_post() {
  local path="$1"
  local body="$2"
  if [[ "$DRY_RUN" == "true" ]]; then
    echo "[DRY_RUN] POST $path"
    echo "$body" | jq . >/dev/null
    return 0
  fi
  curl "${CURL_ARGS[@]}" "${AUTH_ARGS[@]}" -H "Content-Type: application/json" -X POST "$BASE_URL$path" -d "$body"
}

preflight() {
  if [[ "$DRY_RUN" == "true" ]]; then
    echo "Preflight skipped (dry run mode)."
    return
  fi

  if [[ "$BASE_URL" != */api ]]; then
    echo "Warning: PAPERCLIP_BASE_URL usually ends with /api (current: $BASE_URL)." >&2
  fi

  echo "Running API preflight against $BASE_URL/health ..."
  local health
  health="$(curl "${CURL_ARGS[@]}" "${AUTH_ARGS[@]}" "$BASE_URL/health" || true)"
  if [[ -z "$health" ]]; then
    echo "Preflight failed: could not reach $BASE_URL/health" >&2
    exit 1
  fi
  echo "Preflight OK: $(echo "$health" | jq -c . 2>/dev/null || echo "$health")"
}

find_company_id() {
  api_get "/companies" | jq -r --arg name "$COMPANY_NAME" '.[] | select(.name == $name) | .id' | head -n1
}

ensure_company() {
  local existing
  existing="$(find_company_id || true)"
  if [[ -n "$existing" && "$existing" != "null" ]]; then
    echo "$existing"
    return
  fi

  local body
  body=$(jq -nc --arg name "$COMPANY_NAME" --arg description "$COMPANY_DESCRIPTION" '{name:$name, description:$description, budgetMonthlyCents:0}')

  if [[ "$DRY_RUN" == "true" ]]; then
    echo "dry-run-company-id"
    return
  fi

  api_post "/companies" "$body" | jq -r '.id'
}

ensure_goal() {
  local company_id="$1"
  local title="$2"
  local level="$3"
  local parent_id="$4"
  local description="$5"

  local existing
  existing=$(api_get "/companies/${company_id}/goals" | jq -r --arg title "$title" '.[] | select(.title == $title) | .id' | head -n1)
  if [[ -n "$existing" && "$existing" != "null" ]]; then
    echo "$existing"
    return
  fi

  local body
  if [[ -n "$parent_id" ]]; then
    body=$(jq -nc --arg title "$title" --arg description "$description" --arg level "$level" --arg parentId "$parent_id" '{title:$title,description:$description,level:$level,parentId:$parentId,status:"active"}')
  else
    body=$(jq -nc --arg title "$title" --arg description "$description" --arg level "$level" '{title:$title,description:$description,level:$level,status:"active"}')
  fi

  if [[ "$DRY_RUN" == "true" ]]; then
    echo "dry-run-goal-$(echo "$title" | tr ' ' '-' | tr '[:upper:]' '[:lower:]')"
    return
  fi

  api_post "/companies/${company_id}/goals" "$body" | jq -r '.id'
}

ensure_agent() {
  local company_id="$1"
  local key="$2"
  local name="$3"
  local role="$4"
  local title="$5"
  local reports_to_id="$6"
  local budget_cents="$7"

  local existing
  existing=$(api_get "/companies/${company_id}/agents" | jq -r --arg name "$name" '.[] | select(.name == $name) | .id' | head -n1)
  if [[ -n "$existing" && "$existing" != "null" ]]; then
    echo "$existing"
    return
  fi

  local body
  if [[ -n "$reports_to_id" ]]; then
    body=$(jq -nc \
      --arg name "$name" \
      --arg role "$role" \
      --arg title "$title" \
      --arg reportsTo "$reports_to_id" \
      --arg adapterType "$ADAPTER_TYPE" \
      --argjson budget "$budget_cents" \
      '{name:$name, role:$role, title:$title, reportsTo:$reportsTo, adapterType:$adapterType, adapterConfig:{}, budgetMonthlyCents:$budget}')
  else
    body=$(jq -nc \
      --arg name "$name" \
      --arg role "$role" \
      --arg title "$title" \
      --arg adapterType "$ADAPTER_TYPE" \
      --argjson budget "$budget_cents" \
      '{name:$name, role:$role, title:$title, adapterType:$adapterType, adapterConfig:{}, budgetMonthlyCents:$budget}')
  fi

  if [[ "$DRY_RUN" == "true" ]]; then
    echo "dry-run-agent-$key"
    return
  fi

  api_post "/companies/${company_id}/agents" "$body" | jq -r '.id // .agent.id'
}

ensure_project() {
  local company_id="$1"
  local name="$2"
  local goal_id="$3"
  local lead_agent_id="$4"
  local description="$5"

  local existing
  existing=$(api_get "/companies/${company_id}/projects" | jq -r --arg name "$name" '.[] | select(.name == $name) | .id' | head -n1)
  if [[ -n "$existing" && "$existing" != "null" ]]; then
    echo "$existing"
    return
  fi

  local body
  body=$(jq -nc \
    --arg name "$name" \
    --arg description "$description" \
    --arg goalId "$goal_id" \
    --arg leadAgentId "$lead_agent_id" \
    '{name:$name,description:$description,goalId:$goalId,leadAgentId:$leadAgentId,status:"planned"}')

  if [[ "$DRY_RUN" == "true" ]]; then
    echo "dry-run-project-$(echo "$name" | tr ' ' '-' | tr '[:upper:]' '[:lower:]')"
    return
  fi

  api_post "/companies/${company_id}/projects" "$body" | jq -r '.id'
}

ensure_issue() {
  local company_id="$1"
  local title="$2"
  local description="$3"
  local goal_id="$4"
  local project_id="$5"
  local parent_id="$6"
  local assignee_id="$7"
  local priority="$8"

  local existing
  existing=$(api_get "/companies/${company_id}/issues" | jq -r --arg title "$title" '.[] | select(.title == $title) | .id' | head -n1)
  if [[ -n "$existing" && "$existing" != "null" ]]; then
    echo "$existing"
    return
  fi

  local body
  body=$(jq -nc \
    --arg title "$title" \
    --arg description "$description" \
    --arg goalId "$goal_id" \
    --arg projectId "$project_id" \
    --arg parentId "$parent_id" \
    --arg assigneeAgentId "$assignee_id" \
    --arg priority "$priority" \
    '{title:$title,description:$description,goalId:$goalId,projectId:$projectId,parentId:$parentId,assigneeAgentId:$assigneeAgentId,priority:$priority,status:"backlog"}')

  if [[ "$DRY_RUN" == "true" ]]; then
    echo "dry-run-issue-$(echo "$title" | tr ' ' '-' | tr '[:upper:]' '[:lower:]' | cut -c1-40)"
    return
  fi

  api_post "/companies/${company_id}/issues" "$body" | jq -r '.id'
}

echo "==> Bootstrapping SignalForge AI via ${BASE_URL}"
preflight
company_id="$(ensure_company)"
echo "Company: $company_id"

# Goals
G1="$(ensure_goal "$company_id" "Reach 20 paying customers in 90 days" "company" "" "Top-level revenue and traction goal")"
G11="$(ensure_goal "$company_id" "Ship MVP v1 and stable onboarding" "team" "$G1" "Product delivery objective")"
G12="$(ensure_goal "$company_id" "Build 2 reliable acquisition channels" "team" "$G1" "Growth objective")"
G13="$(ensure_goal "$company_id" "Maintain support and onboarding quality" "team" "$G1" "Customer success objective")"
echo "Goals: $G1 $G11 $G12 $G13"

# Agents
declare -A AGENT_IDS
AGENT_IDS[ceo_01]="$(ensure_agent "$company_id" "ceo_01" "CEO — SignalForge" "ceo" "Chief Executive Officer" "" 8000)"
AGENT_IDS[cto_01]="$(ensure_agent "$company_id" "cto_01" "CTO — SignalForge" "cto" "Chief Technology Officer" "${AGENT_IDS[ceo_01]}" 12000)"
AGENT_IDS[eng_fe_01]="$(ensure_agent "$company_id" "eng_fe_01" "FE Engineer — SignalForge" "engineer" "Frontend Engineer" "${AGENT_IDS[cto_01]}" 15000)"
AGENT_IDS[eng_be_01]="$(ensure_agent "$company_id" "eng_be_01" "BE Engineer — SignalForge" "engineer" "Backend Engineer" "${AGENT_IDS[cto_01]}" 15000)"
AGENT_IDS[qa_rel_01]="$(ensure_agent "$company_id" "qa_rel_01" "QA Release — SignalForge" "qa" "QA and Release" "${AGENT_IDS[cto_01]}" 7500)"
AGENT_IDS[cmo_01]="$(ensure_agent "$company_id" "cmo_01" "CMO — SignalForge" "cmo" "Chief Marketing Officer" "${AGENT_IDS[ceo_01]}" 10000)"
AGENT_IDS[growth_01]="$(ensure_agent "$company_id" "growth_01" "Growth Exec — SignalForge" "general" "Growth Execution" "${AGENT_IDS[cmo_01]}" 15000)"
AGENT_IDS[support_01]="$(ensure_agent "$company_id" "support_01" "Support — SignalForge" "general" "Customer Success" "${AGENT_IDS[ceo_01]}" 7500)"

echo "Agents created/verified"

# Projects
MVP_PROJECT="$(ensure_project "$company_id" "MVP Build" "$G11" "${AGENT_IDS[cto_01]}" "Core product delivery")"
GROWTH_PROJECT="$(ensure_project "$company_id" "Growth Engine" "$G12" "${AGENT_IDS[cmo_01]}" "Acquisition experiments and channels")"
SUCCESS_PROJECT="$(ensure_project "$company_id" "Customer Success" "$G13" "${AGENT_IDS[support_01]}" "Onboarding and support quality")"

# Parent umbrella issues
P1="$(ensure_issue "$company_id" "Ship MVP v1 for beta users" "Umbrella parent for MVP execution" "$G11" "$MVP_PROJECT" "" "${AGENT_IDS[cto_01]}" "critical")"
P2="$(ensure_issue "$company_id" "Acquire first 100 qualified trials" "Umbrella parent for growth execution" "$G12" "$GROWTH_PROJECT" "" "${AGENT_IDS[cmo_01]}" "high")"
P3="$(ensure_issue "$company_id" "Establish support and retention baseline" "Umbrella parent for customer success execution" "$G13" "$SUCCESS_PROJECT" "" "${AGENT_IDS[support_01]}" "high")"
P4="$(ensure_issue "$company_id" "Board governance and operating rhythm" "Umbrella parent for leadership and governance" "$G1" "$SUCCESS_PROJECT" "" "${AGENT_IDS[ceo_01]}" "high")"

# 25 starter issues
ensure_issue "$company_id" "Define MVP scope v1 (must/should/won't)" "Define MVP boundaries." "$G11" "$MVP_PROJECT" "$P1" "${AGENT_IDS[cto_01]}" "high" >/dev/null
ensure_issue "$company_id" "Create ADR-001 architecture decisions" "Record architecture decisions." "$G11" "$MVP_PROJECT" "$P1" "${AGENT_IDS[cto_01]}" "medium" >/dev/null
ensure_issue "$company_id" "Implement user auth and session flow" "Build auth/session foundation." "$G11" "$MVP_PROJECT" "$P1" "${AGENT_IDS[eng_be_01]}" "critical" >/dev/null
ensure_issue "$company_id" "Create onboarding wizard (time-to-value <5 min)" "Design and ship onboarding flow." "$G11" "$MVP_PROJECT" "$P1" "${AGENT_IDS[eng_fe_01]}" "critical" >/dev/null
ensure_issue "$company_id" "Build transcript/summary core pipeline" "Core summarization pipeline." "$G11" "$MVP_PROJECT" "$P1" "${AGENT_IDS[eng_be_01]}" "critical" >/dev/null
ensure_issue "$company_id" "Implement summary viewer with share/export" "Summary presentation UI." "$G11" "$MVP_PROJECT" "$P1" "${AGENT_IDS[eng_fe_01]}" "high" >/dev/null
ensure_issue "$company_id" "Integrate checkout, trial, and billing" "Billing and trial logic." "$G11" "$MVP_PROJECT" "$P1" "${AGENT_IDS[eng_be_01]}" "critical" >/dev/null
ensure_issue "$company_id" "Implement pricing page and plan selector" "Pricing UX." "$G11" "$MVP_PROJECT" "$P1" "${AGENT_IDS[eng_fe_01]}" "high" >/dev/null
ensure_issue "$company_id" "Add usage metering events" "Track billable usage." "$G11" "$MVP_PROJECT" "$P1" "${AGENT_IDS[eng_be_01]}" "high" >/dev/null
ensure_issue "$company_id" "Create reliability dashboard baseline" "Basic reliability telemetry." "$G11" "$MVP_PROJECT" "$P1" "${AGENT_IDS[qa_rel_01]}" "high" >/dev/null
ensure_issue "$company_id" "Define release checklist and rollback runbook" "Release safety process." "$G11" "$MVP_PROJECT" "$P1" "${AGENT_IDS[qa_rel_01]}" "high" >/dev/null
ensure_issue "$company_id" "Ship private beta RC1" "Prepare RC for beta users." "$G11" "$MVP_PROJECT" "$P1" "${AGENT_IDS[cto_01]}" "critical" >/dev/null
ensure_issue "$company_id" "Define ICP and value proposition matrix" "Target user and messaging." "$G12" "$GROWTH_PROJECT" "$P2" "${AGENT_IDS[cmo_01]}" "critical" >/dev/null
ensure_issue "$company_id" "Write homepage copy variants" "Draft conversion variants." "$G12" "$GROWTH_PROJECT" "$P2" "${AGENT_IDS[growth_01]}" "high" >/dev/null
ensure_issue "$company_id" "Publish landing page plus analytics" "Launch landing page." "$G12" "$GROWTH_PROJECT" "$P2" "${AGENT_IDS[growth_01]}" "critical" >/dev/null
ensure_issue "$company_id" "Set up 5-step outbound email sequence" "Create outbound program." "$G12" "$GROWTH_PROJECT" "$P2" "${AGENT_IDS[growth_01]}" "high" >/dev/null
ensure_issue "$company_id" "Launch paid experiment #1" "First paid growth experiment." "$G12" "$GROWTH_PROJECT" "$P2" "${AGENT_IDS[growth_01]}" "high" >/dev/null
ensure_issue "$company_id" "Launch paid experiment #2" "Second paid growth experiment." "$G12" "$GROWTH_PROJECT" "$P2" "${AGENT_IDS[growth_01]}" "high" >/dev/null
ensure_issue "$company_id" "Build weekly acquisition dashboard" "Acquisition metrics dashboard." "$G12" "$GROWTH_PROJECT" "$P2" "${AGENT_IDS[cmo_01]}" "high" >/dev/null
ensure_issue "$company_id" "Create referral loop experiment" "Referral mechanics test." "$G12" "$GROWTH_PROJECT" "$P2" "${AGENT_IDS[cmo_01]}" "medium" >/dev/null
ensure_issue "$company_id" "Design support triage taxonomy" "Support categorization system." "$G13" "$SUCCESS_PROJECT" "$P3" "${AGENT_IDS[support_01]}" "high" >/dev/null
ensure_issue "$company_id" "Publish FAQ and getting-started docs" "Self-serve support docs." "$G13" "$SUCCESS_PROJECT" "$P3" "${AGENT_IDS[support_01]}" "high" >/dev/null
ensure_issue "$company_id" "Create onboarding lifecycle email series" "Lifecycle onboarding emails." "$G13" "$SUCCESS_PROJECT" "$P3" "${AGENT_IDS[growth_01]}" "medium" >/dev/null
ensure_issue "$company_id" "Define churn-reason capture loop" "Capture churn reasons." "$G13" "$SUCCESS_PROJECT" "$P3" "${AGENT_IDS[support_01]}" "medium" >/dev/null
ensure_issue "$company_id" "CEO weekly board memo and risk report" "Weekly executive reporting." "$G1" "$SUCCESS_PROJECT" "$P4" "${AGENT_IDS[ceo_01]}" "high" >/dev/null

echo "==> Bootstrap completed"
echo "Company ID: $company_id"
echo "Projects: MVP=$MVP_PROJECT Growth=$GROWTH_PROJECT Success=$SUCCESS_PROJECT"
echo "Parent Issues: P1=$P1 P2=$P2 P3=$P3 P4=$P4"
