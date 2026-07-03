---
description: Diagnose or safely repair ThisIsEnough state under .tie/. Diagnose is read-only; repair acts only when the safe action is unambiguous.
---

Invoke the `tie:doctor` skill now and follow it exactly.

Arguments: $ARGUMENTS

Supported modes are `diagnose` and `repair`. If `$ARGUMENTS` starts with one
of those, pass that mode to the skill; otherwise default to diagnose first,
then repair only when the safe action is unambiguous.

`diagnose` is read-only. `repair` may only fix inconsistencies inside `.tie/`
(the `active_run` pointer, run `state.json`, the 5-file run layout), plus one
exception: replacing the old v0.3 three-rule gitignore set with the single
rule `.tie/`. Each fix is logged as `[복구]` in the run's `log.md`.

If v0.3 state is detected (phase directories, `roadmap.md`, `run_state.json`,
`project_memory.md`, `telemetry.jsonl`), report it and advise the migration
steps the skill defines — never auto-convert; migration actions need explicit
user confirmation. The gitignore rule swap above is the one v0.3 leftover
repaired automatically.

Do not start or resume workflow work. Do not dispatch subagents. Stop and ask
before overwriting, deleting, guessing missing requirements, or choosing
between multiple possible runs.
