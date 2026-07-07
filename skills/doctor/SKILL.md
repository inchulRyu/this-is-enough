---
name: doctor
user-invocable: false
description: Diagnose and safely repair TIE workflow state under .tie/; detects v0.3-era state and advises migration; read-only unless a repair is unambiguous.
---

# tie:doctor — state diagnosis and safe repair

The user wants to inspect or fix ThisIsEnough workflow state. Operate only on
`.tie/`, plus two named exceptions: the `.gitignore` rule and a user-confirmed
ARCHITECTURE.md promotion. Do not start or resume workflow work, and do not
dispatch subagents.

## Ground rules

- `diagnose` is always read-only. Never delete workflow state; never overwrite
  non-empty content except via a safe repair below, previous content preserved.
- Never invent requirements, plan content, verdicts, or user decisions. When
  state is ambiguous, stop and ask — ambiguity is not a judgment call.

## Modes

| Mode       | Behavior                                                                  |
| ---------- | ------------------------------------------------------------------------- |
| default    | Diagnose, then repair only what is unambiguous and safe. Use this when the requested mode is unclear. |
| `diagnose` | Read-only. Report classification, findings, and safe next actions.         |
| `repair`   | Apply the safe repairs below. Re-diagnose first; stop if not repairable.   |

## v0.4 layout

```text
.tie/
  active_run               # text pointer: runs/<run-id>
  drafts/<draft-id>.md     # single file per draft (no directory)
  runs/<run-id>/
    requirement.md  plan.md  verification.md  log.md  state.json
```

- `active_run` holds a workspace-relative pointer `runs/<run-id>`, resolved as
  `.tie/<pointer>`. Reject absolute paths, `..`, symlink escapes, or anything
  that resolves outside `.tie/` after canonical path resolution.
- Run IDs must be safe basenames: ASCII letters, digits, periods, underscores,
  hyphens; no slashes, no `..`, no leading dot, not empty.
- `state.json` fields: `run_id`, `status` (`not_started | in_progress |
  blocked | completed | aborted`), `step` (`plan | implement | verify | fix |
  reframe | map_update | checkpoint | complete`), `owner` (`orchestrator |
  planner | implementer | verifier`), `current_item`, `approved_at`,
  `fix_loops`, `reframe_loops`, `blocked`, `next_action`. No other fields.
  A missing `reframe_loops` in a pre-v0.4.5 run is not damage — treat it
  as 0 and add it only when writing the file for another repair.
- A **viable run** is a directory under `.tie/runs/` with a safe-basename name
  containing `requirement.md` and a parseable `state.json`.

## Diagnose

Read in this order: `.tie/` children → `drafts/` (count only; never repair,
promote, or delete drafts) → `active_run` → each `runs/<run-id>/state.json` →
the active run's five files → v0.3-era markers (below) → the `.gitignore`
rules for `.tie`.

Classify as exactly one of:

- `healthy_v04` — pointer resolves safely, run files consistent. An
  `active_run` pointing at a `completed` run is healthy, not stale.
- `repairable_v04` — every inconsistency matches a safe repair below.
- `v03_state_present` — v0.3-era state found (alone or beside v0.4 state).
- `no_workflow_state` — no `.tie/` state beyond, at most, drafts. Report the
  draft count and how to continue them.
- `ambiguous_or_risky` — anything else. Stop and ask; edit nothing.

## Safe repairs

Each repair is allowed only when the new content is fully derivable from
canonical state — never invented. Every repair is recorded as a `[복구]` entry
appended to the run's `log.md` stating exactly what changed and why (when no
run log exists — e.g. a lone `.gitignore` swap — state the change in the final
report instead), and overwritten non-empty content is additionally preserved
via a timestamped backup inside the run directory.

- `active_run` missing, and exactly one viable run exists → recreate it as
  `runs/<run-id>`.
- `active_run` points to a missing directory, and exactly one viable run
  exists → repoint it to that run.
- `state.json` fields missing or stale where the correct value is derivable
  from the run directory (e.g. `run_id` from the directory name) → fill them.
- `status` is `completed` but `step` is not `complete` → set `step` to
  `complete`.
- `blocked` is true but `log.md` has no open `[블로커]` entry → stop and ask,
  unless a single blocker is clearly reconstructable from `next_action` and
  the latest log entries; then append it as a `[블로커]` entry and note the
  reconstruction in the `[복구]` entry.
- `.gitignore` still carries the v0.3 three-rule set (`.tie/drafts/`,
  `.tie/runs/`, `.tie/active_run`) → replace it with the single rule `.tie/`.
  v0.4 classifications only — never while v0.3 state is present (see below).
- `log.md` missing from an otherwise consistent run → create it from the
  bundled template under `references/file-templates/` (resolved relative to
  the installed skills bundle, never the user's project).
- `verification.md` missing while `state.json.step` is `plan` or `implement`
  (no verdict has existed yet) → create it from the bundled template. At
  `verify`, `fix`, or later, a missing `verification.md` means a real verdict
  was lost and cannot be derived — classify `ambiguous_or_risky` and stop.

## Unsafe — stop and ask

- More than one viable run could be the active run.
- `state.json` is invalid JSON after work has started.
- `requirement.md` is missing from the active run.
- Any pointer or path escape: absolute, `..`, symlink, or resolving outside
  `.tie/`.
- Any change that would overwrite or delete non-empty content without an
  explicit safe-repair rule above.

## v0.3 state

v0.3 markers: root-layout files directly under `.tie/` (`requirements.md`,
`roadmap.md`, `current_state.md`, `run_state.json`, `telemetry.jsonl`, ...),
run directories
containing `run_state.json` or `phases/`, or `.tie/project_memory.md`.

Do NOT auto-convert, and apply NO repairs while v0.3 state is present — the
three-rule `.gitignore` is part of the v0.3 layout, so even that swap is
advice here, not a repair. Instead:

- Report exactly what was found.
- Advise finishing in-progress v0.3 runs with the v0.3 plugin, or restarting
  them as fresh v0.4 runs. Completed v0.3 runs stay as read-only history.
- If `.tie/project_memory.md` exists, offer to promote its content into
  ARCHITECTURE.md's constitution sections — only with explicit user
  confirmation, and always preserving the original file.

## Report

End every invocation with:

```text
ThisIsEnough doctor

Classification: <classification>
Active run: <none | runs/<run-id> | invalid: reason>
Drafts: <count>

Findings:
- <finding>

Actions:
- <repair performed | none>

Stopped because:
- <only when an action was unsafe>
```

Suggest `/tie:status`, `/tie:resume`, or `/tie:start` only when appropriate.
