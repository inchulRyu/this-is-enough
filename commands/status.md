---
description: Show the current status of the ThisIsEnough workflow in this directory. Read-only — no changes, no dispatches.
---

Invoke the `tie:status` skill now. Resolve the active run through
`agents_workspace/active_run`, read state from that run directory, output the
status block, and stop. Do not modify any file. Do not dispatch any subagent.
Do not start any work.

Report concise state as-is. Missing optional phase artifacts, including
`validation_intent.md`, are not status errors unless the run's machine state
requires them. Missing `telemetry.jsonl` in an older run is also not an error;
if telemetry exists, status may include only a concise timing summary derived
from it.

If `active_run` is missing or points at a run without `run_state.json`, say so
and suggest `/tie:start <requirement>`.
