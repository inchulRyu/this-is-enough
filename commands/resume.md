---
description: Resume the active ThisIsEnough workflow run. Reads agents_workspace/active_run, then continues from that run's state.
---

Invoke the `tie:resume` skill now and follow it exactly.

Resume in lean mode: keep `current_state.md` as a short handoff, do not treat
a missing `validation_intent.md` as a problem unless `run_state.json` explicitly
says optional preflight is the current step, and preserve the rule that only an
Evaluator `pass` can complete a phase. Continue appending to
`telemetry.jsonl`; if an older run lacks telemetry, let resume/orchestrator
create it when safe and do not treat the missing file as corruption.

If the user provided text after the command (`$ARGUMENTS`), treat it as their
answer to any open blocker recorded in the active run's `blockers.md`. The
resume skill will mark the blocker resolved and continue from the interrupted
step when the answer resolves the blocker.

If there is no open blocker and the user provided arguments, treat them as
additional context that supplements the existing requirements — append to
the active run's `requirement.md` under `## Updates` with an ISO timestamp
before continuing.

If `agents_workspace/active_run` is missing or points at a run without
`run_state.json`, this is not a resume. Tell the user there is no workflow to
resume in this directory and suggest `/tie:start <requirement>` instead. Do not
start a new workflow from the resume command.
