---
description: Resume an interrupted ThisIsEnough workflow run. Reads agents_workspace/ state and continues from the correct step.
---

Invoke the `tie:resume` skill now and follow it exactly.

If the user provided text after the command (`$ARGUMENTS`), treat it as their
answer to any open blocker recorded in `agents_workspace/blockers.md`. The
resume skill will mark the blocker resolved and continue from the interrupted
step.

If there is no open blocker and the user provided arguments, treat them as
additional context that supplements the existing requirements — append to
`agents_workspace/requirements.md` under a new `## User updates (resume)`
section before continuing.

If `agents_workspace/run_state.json` does not exist, this is not a resume.
Tell the user there is no workflow to resume in this directory and suggest
`/tie:start <requirement>` instead. Do not start a new workflow from the resume
command.
