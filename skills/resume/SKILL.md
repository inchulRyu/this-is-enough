---
name: resume
description: Use when the user wants to continue a previously-interrupted ThisIsEnough workflow run. Resolves agents_workspace/active_run, reads that run's state files, then hands control to the orchestrator at the correct step.
---

# tie:resume — pick up where the workflow left off

The user is continuing a previous workflow run. There should already be an
`agents_workspace/active_run` pointer from a prior session.

## What you do

1. **Resolve the active run.** Read `agents_workspace/active_run`, resolve its
   text relative to `agents_workspace/`, and treat that directory as the run
   directory. If `active_run` is missing, unreadable, or points at a run without
   `run_state.json`, this is not a resume. Tell the user no workflow is
   resumable in this directory and suggest the platform start command:
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
   - Append the text to the active run's `requirement.md` under `## Updates`,
     prefixed with an ISO timestamp subheading.
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
   - Otherwise → invoke `tie:orchestrator`. The orchestrator's resume logic
     (Section 7 of its skill) will pick up at the right state-machine step.

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
- ❌ Discarding `agents_workspace/active_run` or the active run directory and
  starting fresh because something
  "looks off." Investigate first; if state is genuinely corrupted, write
  what you found to `changelog.md` and ask the user before reset.
