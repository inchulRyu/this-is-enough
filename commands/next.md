---
description: Manually nudge the orchestrator to perform the next workflow step. Normally not needed (the orchestrator runs autonomously) — use only when a previous run stopped and you want to continue without changing anything else.
---

The user wants the orchestrator to perform the next workflow step.

If `agents_workspace/run_state.json` exists and `blocked = false`, invoke
`tie:resume`. The orchestrator's resume logic will determine the correct next
owner and continue.

If `blocked = true`, do not advance. Output the open blocker (read from
`agents_workspace/blockers.md`) and instruct the user to use
`/tie:resume <answer>` to provide a decision.

If `agents_workspace/run_state.json` does not exist, this is not a continuable
workflow. Suggest `/tie:start <requirement>`.
