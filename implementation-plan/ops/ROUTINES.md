# Routines and Heartbeat Cadence

## Default cadence

- ceo_01: every 4 hours
- cto_01: every 2 hours
- eng_fe_01: every 90 minutes
- eng_be_01: every 90 minutes
- qa_rel_01: every 3 hours
- cmo_01: every 2 hours
- growth_01: every 90 minutes
- support_01: every 90 minutes

## Routine definitions

### CEO Strategic Review
- Frequency: every 4h
- Inputs: dashboard metrics, blocked issues, budget alerts, approvals
- Outputs: reprioritized issue list, executive delegation comments

### Engineering Sprint Loop
- Frequency: every 90m–2h
- Inputs: assigned issues, parent goal context, release checklist
- Outputs: code changes, implementation notes, unblock requests

### Growth Experiment Loop
- Frequency: every 90m–2h
- Inputs: channel metrics, copy variants, CAC/CVR trends
- Outputs: new experiments, kill/scale decisions, attribution notes

### Support Triage Loop
- Frequency: every 90m
- Inputs: new user feedback, unresolved issues, FAQ gaps
- Outputs: responses, escalations, documentation updates

## Safety controls

- Pause any routine exceeding budget thresholds without demonstrable output.
- Require board approval for changes to pricing, billing, or secrets.

