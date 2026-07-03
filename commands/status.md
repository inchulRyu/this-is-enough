---
description: Show the current status of the ThisIsEnough workflow in this directory. Read-only — no edits, no dispatches.
---

Invoke the `tie:status` skill now and follow it exactly.

Resolve the active run through `.tie/active_run`, read `state.json` and the
last `log.md` entry from that run directory, output the concise status block,
and stop. This command is strictly read-only: do not modify any file, do not
dispatch any subagent, and do not start or resume any work.

If `.tie/active_run` is missing or points at a run without `state.json`, say
so and suggest `/tie:start <requirement>`, or `/tie:requirements` to draft
first.
