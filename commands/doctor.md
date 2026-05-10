---
description: Diagnose, safely repair, or migrate ThisIsEnough workspace state under agents_workspace/. Defaults to auto-diagnose and only edits when the safe action is unambiguous.
---

Invoke the `tie:doctor` skill now and follow it exactly.

Arguments: `$ARGUMENTS`

Supported modes are `diagnose`, `repair`, and `migrate`. If `$ARGUMENTS`
starts with one of those modes, pass that mode to the skill. Otherwise use the
doctor skill's default mode: diagnose first, then repair or migrate only when
the safe action is unambiguous.

`diagnose` is read-only. `repair` may only fix inconsistencies inside the
current `agents_workspace/active_run` plus `agents_workspace/runs/<run-id>/`
schema. `migrate` may only upgrade the old root workflow layout into
`agents_workspace/runs/<run-id>/` when no conflicting active-run layout exists.
Keep repairs compact: `current_state.md` should remain a short handoff, and a
missing `validation_intent.md` is not an inconsistency unless the machine state
explicitly requires optional preflight.

Do not start or resume workflow work. Do not dispatch subagents. Stop and ask
the user before overwriting, deleting, guessing missing requirements, or
choosing between multiple possible runs.
