---
description: Continue a previously-interrupted ThisIsEnough workflow run. Resolves .tie/active_run and hands control to the orchestrator at the correct step.
argument-hint: '[optional answer to an open blocker]'
disable-model-invocation: true
---

Load and follow the ThisIsEnough **tie:resume** skill for this repository: resolve `.tie/active_run`, read the run's state, and continue at the correct step (handing off to the orchestrator when appropriate).

Treat everything below as the user's answer to any open blocker (it may be empty):

$ARGUMENTS
