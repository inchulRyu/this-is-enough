---
description: Manually nudge the orchestrator to perform the next workflow step. Normally not needed (the orchestrator runs autonomously) — use only when a previous run stopped and you want to continue without changing anything else.
---

The user wants the orchestrator to perform the next workflow step.

Resolve the active run through `agents_workspace/active_run`.

Continue the existing lean workflow state. Do not create or require
`validation_intent.md` unless the resume logic determines optional preflight is
the next risk-based step, and never mark a phase complete without an Evaluator
`pass`. Continue run telemetry in `telemetry.jsonl` when present; missing
telemetry in an older run is not a blocker.

If the active run's `run_state.json` exists and `blocked = false`, invoke
`tie:resume`. The orchestrator's resume logic will determine the correct next
owner and continue.

If `blocked = true`, do not advance. Output the open blocker from the active
run's `blockers.md` and instruct the user to use `/tie:resume <answer>` to
provide a decision.

If `active_run` is missing or points at a run without `run_state.json`, this is
not a continuable workflow. Suggest `/tie:start <requirement>`.
