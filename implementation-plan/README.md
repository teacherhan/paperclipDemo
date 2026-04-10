# AI SaaS Company Implementation Plan for Paperclip

This folder contains a complete, copy-ready blueprint to set up an AI SaaS company in Paperclip.

## What this plan creates

- Company mission and goal hierarchy
- Org chart and role definitions
- Agent instruction files (`AGENT.md` style role prompts)
- Skills operating playbooks for each department
- Project and issue backlog (first 25 issues)
- Budget policy and governance policy
- Routine schedule and weekly operating cadence
- Step-by-step execution checklist for Paperclip operators

## Folder layout

- `IMPLEMENTATION-STEPS.md` — exact setup sequence in Paperclip UI
- `COMPANY-BLUEPRINT.md` — high-level company shape, goals, KPIs
- `ISSUES-BACKLOG.csv` — import-friendly issue starter backlog
- `AUTOMATION.md` — one-command automation and API bootstrap guidance
- `HOSTINGER-VPS-RUNBOOK.md` — remote VPS execution guide
- `ops/BUDGETS.md` — monthly budget + control policy
- `ops/APPROVALS-POLICY.md` — governance and approval gates
- `ops/ROUTINES.md` — recurring schedule for CEO/teams
- `agents/` — role-specific agent instruction files
- `skills/` — operational skills playbooks by function
- `templates/` — reusable issue and report templates

## Fast start

1. Read `COMPANY-BLUEPRINT.md`.
2. Follow `IMPLEMENTATION-STEPS.md` top to bottom.
3. Copy agent role files from `agents/` into your adapter configs.
4. Import/create issues from `ISSUES-BACKLOG.csv`.
5. Apply budget + approvals from `ops/` docs.
6. Start heartbeats using `ops/ROUTINES.md`.

## Fully automated option

If you want one-command setup, use:

```bash
./implementation-plan/scripts/bootstrap-signalforge.sh
```

See `AUTOMATION.md` for authenticated mode, dry-run mode, and adapter options.
