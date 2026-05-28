---
description: Draft or refine a ThisIsEnough requirement before starting an implementation run. Writes agents_workspace/drafts/.../requirement.md and default volatile-state gitignore rules; does not create active_run or runs.
---

The user wants help preparing a ThisIsEnough requirement draft before starting
implementation.

Their input is: $ARGUMENTS

Invoke the `tie:requirements` skill now and follow it exactly. Do not start or
resume a workflow run. Do not create or modify `agents_workspace/active_run`.
Do not create `agents_workspace/runs/`, `roadmap.md`, `run_state.json`, or phase
artifacts. Do not choose validation profiles or create `validation_intent.md`
or `current_state.md` from this command.

When the skill uses bundled templates, resolve bundled reference paths relative
to the installed ThisIsEnough skills bundle, not relative to the user's project
working directory.
