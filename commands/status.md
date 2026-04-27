---
description: Show the current status of the ThisIsEnough workflow in this directory. Read-only — no changes, no dispatches.
---

Invoke the `tie:status` skill now. Resolve the active run through
`agents_workspace/active_run`, read state from that run directory, output the
status block, and stop. Do not modify any file. Do not dispatch any subagent.
Do not start any work.

If `active_run` is missing or points at a run without `run_state.json`, say so
and suggest `/tie:start <requirement>`.
