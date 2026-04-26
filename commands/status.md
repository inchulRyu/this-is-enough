---
description: Show the current status of the ThisIsEnough workflow in this directory. Read-only — no changes, no dispatches.
---

Invoke the `tie:status` skill now. Read state from `agents_workspace/`,
output the status block, and stop. Do not modify any file. Do not dispatch
any subagent. Do not start any work.

If `agents_workspace/run_state.json` does not exist, say so and suggest
`/tie:start <requirement>`.
