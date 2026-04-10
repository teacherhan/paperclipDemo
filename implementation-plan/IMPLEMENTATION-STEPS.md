# Step-by-Step Implementation in Paperclip

This checklist is written for a board operator using Paperclip UI/API.

## Optional one-command automation

If you prefer to provision everything automatically (company + goals + agents + projects + starter issues), run:

```bash
./implementation-plan/scripts/bootstrap-signalforge.sh
```

See `AUTOMATION.md` for token-based authenticated mode and dry-run usage.

## 0) Prerequisites

- Install dependencies and start Paperclip:
  - `pnpm install`
  - `pnpm dev`
- Confirm health:
  - `curl http://localhost:3100/api/health`

## 1) Create company

1. Open onboarding.
2. Create company named `SignalForge AI`.
3. Add company mission from `COMPANY-BLUEPRINT.md`.
4. Confirm you can open the company dashboard.

## 2) Create top-level goals

Create these goals in order:

1. `G1: Reach 20 paying customers in 90 days`
2. `G1.1: Ship MVP v1 and stable onboarding`
3. `G1.2: Build 2 reliable acquisition channels`
4. `G1.3: Maintain support and onboarding quality`

Link G1.1, G1.2, and G1.3 as children of G1.

## 3) Create agents and reporting lines

Create the following agents with reports-to mapping:

- `ceo_01` (no manager)
- `cto_01` → reports to `ceo_01`
- `eng_fe_01` → reports to `cto_01`
- `eng_be_01` → reports to `cto_01`
- `qa_rel_01` → reports to `cto_01`
- `cmo_01` → reports to `ceo_01`
- `growth_01` → reports to `cmo_01`
- `support_01` → reports to `ceo_01`

For each agent:

1. Choose adapter type (`process` or `http`).
2. Paste corresponding role instruction from `agents/*.md` into adapter config.
3. Set initial heartbeat schedule from `ops/ROUTINES.md`.

## 4) Create projects

Create projects:

- `MVP Build` (lead: `cto_01`, linked to G1.1)
- `Growth Engine` (lead: `cmo_01`, linked to G1.2)
- `Customer Success` (lead: `support_01`, linked to G1.3)

## 5) Import or create issue backlog

Option A (manual): Create issues from `ISSUES-BACKLOG.csv`.
Option B (automation): Use API script against `/api/issues` with fields from CSV.

Required mappings:

- Assign exactly one assignee per issue.
- Link each issue to project and parent goal.
- Create parent umbrella issues before child tasks.

## 6) Configure budgets

Apply budget defaults from `ops/BUDGETS.md`.

- Set per-agent monthly caps.
- Configure warning thresholds.
- Turn on hard-stop policy.

## 7) Configure approvals and governance

Apply policy from `ops/APPROVALS-POLICY.md`.

Require board approval for:

- Pricing changes
- Production data deletion
- Secrets/provider changes
- Budget overrides above policy cap

## 8) Configure routines and heartbeat cadence

Follow `ops/ROUTINES.md`:

- CEO: strategic review cadence
- Engineering: build/test cadence
- Growth: experiment cadence
- Support: triage cadence

## 9) Launch operations

1. Start all non-paused agents.
2. Verify first heartbeat run per agent.
3. Check dashboard for run/cost/activity signals.
4. Fix any failed adapter configurations.

## 10) Weekly operating rhythm

Each Friday:

1. CEO publishes weekly board memo using template in `templates/WEEKLY-BOARD-MEMO.md`.
2. CTO/CMO reprioritize backlog.
3. Support summarizes top user pain points.
4. Board applies budget/approval policy updates if needed.

## 11) Definition of implementation complete

- Company, goals, projects, and agents exist
- Backlog of 25 issues created and assigned
- Budgets and approvals configured
- Routines enabled
- At least one successful run from every active agent
- Weekly memo process in place
