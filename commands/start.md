---
description: Start a ThisIsEnough autonomous workflow run for the requirement that follows. Creates or updates the active run under agents_workspace/runs/ and hands off to the orchestrator.
---

The user is starting a new ThisIsEnough workflow.

Their requirement is: $ARGUMENTS

Invoke the `tie:orchestrator` skill now and follow it exactly. Treat the
requirement above as the initial user request for intake unless there is an
active incomplete run. Do not start implementing anything before the
orchestrator's intake → clarify → roadmap flow has produced the active run's
`requirement.md` and `roadmap.md`.

Resolve the active run through `agents_workspace/active_run`:

- If no active run exists, create a new run under
  `agents_workspace/runs/<run-id>/`, write `agents_workspace/active_run` to
  `runs/<run-id>`, and bootstrap there.
- If the active run's `run_state.json` says `project_status = completed` and
  `current_step` indicates project completion, create a new run for this
  requirement and overwrite `active_run`.
- If the active run is `in_progress` or `blocked`, do NOT create a new run.
  Invoke `tie:resume` and treat "$ARGUMENTS" as an update to that run.
