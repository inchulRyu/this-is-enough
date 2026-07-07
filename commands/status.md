---
description: Read-only snapshot of where the active ThisIsEnough workflow run currently stands. Takes no action.
argument-hint: ''
disable-model-invocation: true
---

Load and follow the ThisIsEnough **tie:status** skill for this repository. It is strictly read-only: resolve `.tie/active_run`, summarize the run's state and any open blocker, and take no other action — no file writes, no repairs, no subagent dispatches.

$ARGUMENTS
