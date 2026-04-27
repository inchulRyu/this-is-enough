---
name: doctor
description: Use when the user asks to diagnose, repair, or migrate ThisIsEnough workflow state. Auto-diagnoses agents_workspace, supports diagnose/repair/migrate modes, safely repairs active-run layout inconsistencies, and migrates old root workflow state to runs/<run-id>/ only when unambiguous.
---

# tie:doctor — workspace state diagnosis and safe repair

The user wants to inspect, fix, or migrate ThisIsEnough workflow state. Operate
only on `agents_workspace/`. Do not start or resume workflow work, and do not
dispatch subagents.

## Modes

Accept these modes from the user's prompt or command arguments:

| Mode       | Behavior                                                                 |
| ---------- | ------------------------------------------------------------------------ |
| default    | Run `diagnose` first, then choose `repair` or `migrate` only when safe.   |
| `diagnose` | Read-only. Report health, layout, inconsistencies, and safe next actions. |
| `repair`   | Fix only safe inconsistencies inside the active-run layout.               |
| `migrate`  | Upgrade an old pre-active-run layout into the active-run layout.          |

If the requested mode is unclear, use default mode.

## Non-negotiable safety rules

- `diagnose` is always read-only.
- Never delete workflow state.
- Never overwrite a non-empty file or directory with unrelated content. Repairs
  may update known workflow state files only when the rule below explicitly
  allows it, the new content is derived from canonical state, and the previous
  content is preserved in a timestamped backup or summarized in `changelog.md`.
- Never invent product requirements, roadmap content, user decisions, or phase
  details.
- Never follow an `active_run` pointer outside `agents_workspace/`.
- Resolve candidate run paths canonically before writing. Reject absolute paths,
  `..`, symlinks, or any resolved path outside the canonical
  `agents_workspace/` directory.
- Never run ThisIsEnough against the repository while doctoring the state.
- Stop and ask the user when state is ambiguous, risky, corrupt beyond safe
  parsing, or would require choosing between conflicting runs.

## Layouts

Current layout:

```text
agents_workspace/
  active_run
  runs/<run-id>/
    requirement.md
    roadmap.md
    current_state.md
    run_state.json
    decisions.md
    changelog.md
    blockers.md          # only when blocked
    phases/
```

Old pre-active-run layout:

```text
agents_workspace/
  requirements.md
  roadmap.md
  current_state.md
  run_state.json
  decisions.md
  changelog.md
  blockers.md
  phases/
```

In the current layout, `agents_workspace/active_run` must contain a relative
pointer of the form `runs/<run-id>`.

Run IDs used by Doctor must be safe basenames: only ASCII letters, digits,
periods, underscores, and hyphens; no slashes, no `..`, no leading dot, and not
empty. If a legacy `run_state.json.run_id` fails this check, ignore it and
generate a fresh migration run ID.

## Diagnose

Read state in this order:

1. `agents_workspace/` existence and direct children.
2. `agents_workspace/active_run`, if present.
3. `agents_workspace/runs/*/run_state.json`, if present.
4. The active run's state files, if an active run resolves safely.
5. Old root-layout files directly under `agents_workspace/`, if present.

Classify the workspace as exactly one of:

- `healthy_current_layout`
- `repairable_current_layout`
- `migratable_old_layout`
- `no_workflow_state`
- `ambiguous_or_risky`

Diagnose these conditions:

- Missing, empty, malformed, absolute, or path-traversing `active_run`.
- `active_run` or a candidate run directory resolves outside
  `agents_workspace/` after canonical path resolution.
- `active_run` points to a missing directory.
- Multiple viable runs exist when a single repair target is needed.
- `run_state.json` is missing or invalid JSON.
- `run_state.json.run_id` disagrees with the run directory name.
- `workspace_dir` or `run_dir` is missing or stale.
- `project_status = "completed"` but `current_step` is not
  `"project_complete"`.
- `current_state.md` disagrees with `run_state.json`.
- `blocked = true` but `blockers.md` is missing or has no open blocker.
- Required active-run files are missing.
- Old root-layout files exist.
- Old and new layouts both exist.

Output a concise report:

```text
ThisIsEnough doctor

Mode: diagnose
Classification: <classification>
Active run: <none | runs/<run-id> | invalid: reason>
Viable runs: <count and names>
Old layout: <absent | present | partial>

Findings:
- <finding>

Safe automatic action:
- <none | repair | migrate>

Stopped because:
- <only when action is unsafe>
```

## Default mode

Default mode always starts with `diagnose`.

After diagnosis:

- `healthy_current_layout` -> report healthy and stop.
- `repairable_current_layout` -> run the safe repairs and report what changed.
- `migratable_old_layout` -> migrate and report what changed.
- `no_workflow_state` -> say no ThisIsEnough workflow state exists and stop.
- `ambiguous_or_risky` -> stop and ask the user to choose. Do not edit files.

## Repair mode

Repair mode fixes inconsistencies only inside the current active-run schema.
Before changing anything, re-run diagnosis and confirm the workspace is
`repairable_current_layout`. If not, stop with the reason.

Safe repairs:

- If `active_run` is missing and `agents_workspace/runs/` contains exactly one
  viable run directory with parseable `run_state.json`, recreate `active_run`
  with `runs/<run-id>`.
- If `active_run` points to a missing run and exactly one viable run exists,
  replace it with `runs/<run-id>`.
- If `run_state.json` is missing but `requirement.md` exists, no roadmap or
  phase work has started, and no existing state file indicates later progress,
  create the initial `run_state.json` from the standard template using the run
  directory path. Otherwise stop.
- If `run_state.json` is missing `run_id`, `workspace_dir`, or `run_dir`, fill
  those fields from the run directory path.
- If `run_state.json.run_id`, `workspace_dir`, or `run_dir` is stale but the
  correct value is obvious from the resolved active run, update the JSON.
- If `project_status = "completed"` but `current_step` is not
  `"project_complete"`, set `current_step` to `"project_complete"`.
- If `current_state.md` is missing or conflicts with `run_state.json`, rewrite
  it from `run_state.json` while preserving any clearly reusable "Important
  context" bullets from the old file. Before rewriting an existing
  `current_state.md`, copy the original to a timestamped repair backup inside
  the active run directory and mention the backup path in `changelog.md`.
- If `decisions.md` or `changelog.md` is missing, create the standard heading
  template. Append a doctor entry to `changelog.md` after the repair.
- If `phases/` is missing and `run_state.json.current_phase` is null or
  `"none"`, create an empty `phases/` directory.
- If `blocked = true` and `blockers.md` is missing, create a minimal blocker
  only when the missing details can be inferred from `current_state.md`,
  `current_step`, or `next_action`. Otherwise stop and ask the user for the
  missing blocker details.
- If `blocked = true` and `blockers.md` exists but has no open blocker, stop and
  ask the user for the missing blocker details unless a single open blocker can
  be reconstructed from `current_state.md`, `current_step`, and `next_action`.

Unsafe repairs that must stop:

- More than one viable run could be the active run.
- `active_run` points outside `agents_workspace/`, uses `..`, is absolute, is a
  symlink escape, or fails canonical path containment checks.
- `run_state.json` is missing after roadmap or phase work has started.
- `run_state.json` exists but is invalid JSON.
- `requirement.md` is missing.
- `roadmap.md` is missing after roadmap creation has started.
- `phases/` is missing while `run_state.json.current_phase` points to a phase.
- Old and new layouts both exist.
- Any repair would replace non-empty content without an explicit safe-repair
  rule and a preservation path.

When repairing `current_state.md`, use this shape:

```md
# Current State

Project status: <project_status>
Current phase: <current_phase or none>
Current phase status: <current_phase_status or not_started>
Current owner: <current_owner or orchestrator>
Current loop: <loop_count or 0>

## Last completed step

- Repaired by tie:doctor from run_state.json.

## Next action

- <next_action or current_step>

## Blocked

<Yes | No>

## Important context

- <preserved context if available, otherwise "None yet.">
```

Record every repair in the active run's `changelog.md` with an ISO timestamp.

## Migrate mode

Migrate mode upgrades the old root layout to the active-run layout.

Automatic migration is safe only when all of these are true:

- `agents_workspace/run_state.json` exists and is parseable JSON.
- `agents_workspace/requirements.md` exists.
- `agents_workspace/roadmap.md`, `current_state.md`, `decisions.md`, and
  `changelog.md` exist.
- `agents_workspace/active_run` does not exist.
- `agents_workspace/runs/` is absent or contains no run directories.
- The target `agents_workspace/runs/<run-id>/` does not already exist.
- No file would be overwritten.
- The chosen `<run-id>` passes the safe-basename rule and the target run
  directory resolves under the canonical `agents_workspace/runs/` directory.

Stop and ask the user when:

- Old and new layouts both exist.
- `active_run` exists.
- `runs/` already contains one or more run directories.
- Root `run_state.json` cannot be parsed.
- Required root old-layout files are missing.
- A target run ID cannot be chosen without collision.
- Backup creation would collide with existing content.

Migration steps:

1. Choose `<run-id>` from `run_state.json.run_id` when present and it passes the
   safe-basename rule and does not collide with an existing run or backup.
   Otherwise generate `YYYY-MM-DD-HHMMSS-migrated-run`.
2. Resolve the target path canonically and create
   `agents_workspace/runs/<run-id>/` only if it remains under
   `agents_workspace/runs/`.
3. Copy old root files into the run directory:
   - `requirements.md` -> `requirement.md`
   - `run_state.json` -> `run_state.json`
   - `roadmap.md` -> `roadmap.md`
   - `current_state.md` -> `current_state.md`
   - `decisions.md` -> `decisions.md`
   - `changelog.md` -> `changelog.md`
   - `blockers.md` -> `blockers.md` if present
   - `phases/` -> `phases/` if present
4. Write the run copy of `run_state.json`, adding or correcting:
   - `"run_id": "<run-id>"`
   - `"workspace_dir": "agents_workspace"`
   - `"run_dir": "agents_workspace/runs/<run-id>"`
5. Verify the run copy exists, every required file is present, `requirement.md`
   contains the migrated requirement text, `run_state.json` parses, and
   `run_state.json.run_dir` matches the target path. If verification fails, do
   not write `active_run`; leave the original root layout untouched and report
   the partial run directory for manual cleanup.
6. Create a backup directory named
   `agents_workspace/legacy-pre-run-layout-<timestamp>/`.
7. Move the original old root workflow files into that backup directory after
   the run copy is complete and verified. Preserve names exactly in the backup.
   If any move fails, do not write `active_run`; report the root/backup split
   and stop for manual recovery.
8. Verify no old root workflow files remain directly under `agents_workspace/`.
9. Write `agents_workspace/active_run` as `runs/<run-id>`.
10. Append a migration summary to the run's `changelog.md`, including the backup
   path and the old-to-new filename mapping.

Do not migrate partial old layouts automatically. If any required root old-layout
file is missing, report the partial files and ask the user how to proceed.

## Final response

End with:

- Classification.
- Files changed, if any.
- Repairs or migration steps performed.
- Any remaining blockers or manual choices.
- Suggested next command: `/tie:status`, `/tie:resume`, or `/tie:start`, only
  when appropriate.
