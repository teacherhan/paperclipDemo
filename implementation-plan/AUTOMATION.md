# Full Automation: Create SignalForge AI in Paperclip

Yes — you can fully automate the initial SaaS company setup.

This folder now includes a single bootstrap script that provisions:

- company
- goal hierarchy
- all 8 agents + reporting lines
- 3 projects
- 4 parent umbrella issues
- 25 starter implementation issues

## Script

`implementation-plan/scripts/bootstrap-signalforge.sh`

## Prerequisites

- Paperclip server running (`pnpm dev`)
- `curl` and `jq` installed
- Access to board API context

## Run (local trusted mode)

```bash
./implementation-plan/scripts/bootstrap-signalforge.sh
```

## Run (authenticated mode)

```bash
PAPERCLIP_TOKEN="<bearer-token>" \
./implementation-plan/scripts/bootstrap-signalforge.sh
```

## Optional flags

- `PAPERCLIP_BASE_URL` (default: `http://localhost:3100/api`)
- `PAPERCLIP_ADAPTER_TYPE` (default: `codex_local`)
- `PAPERCLIP_COOKIE="<cookie_name>=<cookie_value>"` for session-cookie auth
- `PAPERCLIP_DRY_RUN=true` to validate payload generation without writes
- `PAPERCLIP_SKIP_TLS_VERIFY=true` for self-signed TLS endpoints

## Idempotency

The script is idempotent by name/title lookup:

- reuses existing company/goals/agents/projects/issues when found
- only creates missing records

## What remains manual

- adapter credentials/login state (for actual agent execution)
- fine-tuning prompt bundles per agent
- production secrets/provider config

## VPS deployments (Hostinger)

For a Hostinger VPS deployment, see:

- `HOSTINGER-VPS-RUNBOOK.md`

If Paperclip is running in Docker on the VPS, use the host-mapped API URL in `PAPERCLIP_BASE_URL` (for example `http://127.0.0.1:3100/api`).
