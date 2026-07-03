---
description: Create or resynchronize ARCHITECTURE.md (constitution + map) outside a run — initial bootstrap, resync after out-of-TIE changes, or restructuring.
---

The user wants to work on this repo's `ARCHITECTURE.md` (constitution + map).

Their input is: $ARGUMENTS

Invoke the `tie:map` skill now and follow it exactly, treating `$ARGUMENTS` as
context for what changed or what to build.

This is the out-of-run entry point, for three cases only: initial creation of
`ARCHITECTURE.md`, resynchronization after code changed outside TIE, and
restructuring a map that has grown bloated. During a run, map updates are
automatic and incremental at the orchestrator's `map_update` step — this
command is not needed there.

Creation and large restructures require user confirmation before writing; the
map is itself a synchronization target. Do not start, resume, or modify any
run from this command.
