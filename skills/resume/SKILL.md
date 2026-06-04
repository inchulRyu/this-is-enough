---
name: resume
description: Use when the user wants to continue a previously-interrupted ThisIsEnough workflow run. Resolves .tie/active_run, reads that run's state files, then hands control to the orchestrator at the correct step.
---

# tie:resume — pick up where the workflow left off

The user is continuing a previous workflow run. There should already be an
`.tie/active_run` pointer from a prior session.

## What you do

1. **Resolve the active run.** Read `.tie/active_run`, which stores
   a workspace-relative pointer, normally `runs/<run-id>`. Resolve it as
   `.tie/<pointer>` and treat that directory as the run directory.
   Do not treat the pointer as relative to the project root by itself, and do
   not prepend another `runs/` segment. If `active_run` is missing, unreadable,
   or points at a run without `run_state.json`, this is not a resume. Tell the
   user no workflow is resumable in this directory and suggest the platform
   start command:
   - Claude Code: `/tie:start <requirement>`
   - Codex CLI: `$tie:orchestrator <requirement>`

2. **Read state in this exact order:**
   - `<active-run-dir>/run_state.json`
   - `<active-run-dir>/current_state.md`
   - `<active-run-dir>/roadmap.md`
   - current phase's `phase.md`, `plan.md`, `tasks.md`, `validation_intent.md` (if present)
   - latest `evaluation_report.md` (if present)
   - last 3 entries of `changelog.md`
   - `<active-run-dir>/telemetry.jsonl` metadata if present (existence and
     recent timing summary only; do not parse markdown as a timing fallback)
   - `blockers.md` (if `run_state.json.blocked = true`)

3. **Reconcile any disagreement.** If `current_state.md` and `run_state.json`
   conflict, trust `run_state.json` and repair `current_state.md`. Note the
   repair in `changelog.md`.

   If `telemetry.jsonl` is missing, do not treat the run as corrupt. This is
   expected for older runs. Create the file when safe and let Orchestrator
   append a `run_resumed` event before continuing.

4. **Process user input passed alongside `/tie:resume` or `$tie:resume`.** If
   the user provided text after the command:
   - If the text references a draft path shaped exactly like
     `.tie/drafts/<draft-id>/requirement.md`, treat it as a
     draft-start request, not as an update to this run. Do not append the draft
     path to `requirement.md`, do not promote the draft, and do not delete it.
     If this active run is not completed, tell the user the current active run
     must be completed or resolved before starting from that draft and stop. If
     this active run is already completed, tell the user to start from the draft
     with the platform start command and stop; `tie:resume` never starts a new
     draft run.
   - Otherwise append the text to the active run's `requirement.md` under
     `## Updates`, prefixed with an ISO timestamp subheading.
   - If `blocked = true` and the text answers the open blocker, also treat it
     as the answer (handled in step 5 below — mark the blocker resolved before
     resuming).
   - Generator/Evaluator/Planner re-read `requirement.md` on every dispatch, so
     they will pick it up automatically. Note the append in `changelog.md`.

5. **Branch on state:**

   - `project_status = completed` → tell the user the project is already
     complete, point them at `changelog.md`, and stop. Do NOT re-run anything.
   - `blocked = true` → read `blockers.md`. If the user's current prompt
     answers the open blocker, mark it `Status: resolved`, clear
     `run_state.json.blocked`, set `current_step` to the blocker's
     `Resume target step`, and resume. If not, re-state the blocker (concise)
     and stop.
   - Otherwise → invoke `tie:orchestrator`. It must read the active run state
     files and continue from `current_step` / `next_action` without re-running
     completed steps.

6. **Report briefly to the user before handing off:**

```
Resuming ThisIsEnough workflow.

Project: <project_status>
Phase: <current_phase> (<current_phase_status>)
Last step: <one-line from current_state.md>
Next: <what's about to happen>
```

Then hand off to the orchestrator (or stop if blocked).

## Anti-patterns

- ❌ Re-running steps that already completed. Trust the files.
- ❌ Re-asking clarification questions that are already answered in the active
  run's `requirement.md`.
- ❌ Discarding `.tie/active_run` or the active run directory and
  starting fresh because something
  "looks off." Investigate first; if state is genuinely corrupted, write
  what you found to `changelog.md` and ask the user before reset.
