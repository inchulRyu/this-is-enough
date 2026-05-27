---
description: Start a ThisIsEnough autonomous workflow run for the requirement or draft path that follows. Creates or updates the active run under agents_workspace/runs/ and hands off to the orchestrator.
---

The user is starting a new ThisIsEnough workflow.

Their requirement is: $ARGUMENTS

Invoke the `tie:orchestrator` skill now and follow it exactly. Treat the
requirement above as the initial user request for intake unless there is an
active incomplete run or the arguments reference a draft requirement file. Do
not start implementing anything before the orchestrator's intake → clarify →
roadmap flow has produced the active run's `requirement.md` and `roadmap.md`.

Preserve runtime invariants: workflow artifacts stay concise,
`validation_intent.md` is optional risk preflight for complex or risky phases
only, validation uses the lightest validation profile and lowest L0-L5 level
that gives confidence, no phase is complete without an Evaluator `pass`, and
run timing belongs in the active run's append-only `telemetry.jsonl` rather
than markdown artifacts.

Before bootstrapping, classify `$ARGUMENTS`:

- If it references `agents_workspace/drafts/<draft-id>/requirement.md`, treat it
  as a draft start. This command layer must not read draft content, write run
  state, write `active_run`, or delete the draft. Hand the draft path to the
  orchestrator and require the orchestrator's draft promotion sequence.
- Otherwise treat `$ARGUMENTS` as a raw requirement or an update to an active
  incomplete run.

Resolve the active run through `agents_workspace/active_run`:

- If `$ARGUMENTS` references a draft and either no active run exists or the
  active run's `run_state.json` says `project_status = completed` and
  `current_step` indicates project completion, tell the orchestrator to start
  from that draft.
  For draft starts, `active_run` must be written only after the draft copy,
  minimum state files, and source-draft changelog entry are verified. After
  `active_run` is written, the orchestrator must delete the source draft
  directory and verify it no longer exists, or record the concrete no-delete
  reason in the new run.
- If no active run exists for a non-draft requirement, create a new run under
  `agents_workspace/runs/<run-id>/`, write `agents_workspace/active_run` to
  `runs/<run-id>`, ensure `agents_workspace/project_memory.md` exists, ensure
  `<run-dir>/telemetry.jsonl` is initialized for append-only telemetry, ensure
  the default volatile-state `.gitignore` rules exist, replace a broad
  `agents_workspace/` ignore rule unless the user explicitly wants no workflow
  files committed, and bootstrap there.
- If the active run's `run_state.json` says `project_status = completed` and
  `current_step` indicates project completion for a non-draft requirement,
  create a new run for this requirement and overwrite `active_run`.
- If the active run is `in_progress` or `blocked`, do NOT create a new run.
  If "$ARGUMENTS" references a draft, leave the draft untouched and report that
  the current active run must be completed or resolved before starting a new run
  from a draft. Do not append the draft path to the active run. Otherwise invoke
  `tie:resume` and treat "$ARGUMENTS" as an update to that run.
