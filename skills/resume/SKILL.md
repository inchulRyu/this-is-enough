---
name: resume
description: Use when the user wants to continue a previously-interrupted ThisIsEnough workflow run. Reads run_state.json, current_state.md, and the relevant phase files, then hands control to the orchestrator at the correct step.
---

# tie:resume — pick up where the workflow left off

The user is continuing a previous workflow run. There is already an
`agents_workspace/` from a prior session.

## What you do

1. **Verify workspace exists.** If `agents_workspace/run_state.json` does not
   exist, this is not a resume — invoke `tie:orchestrator` instead and treat
   the user's prompt as a new requirement.

2. **Read state in this exact order:**
   - `agents_workspace/run_state.json`
   - `agents_workspace/current_state.md`
   - `agents_workspace/roadmap.md`
   - current phase's `phase.md`, `plan.md`, `tasks.md`
   - latest `evaluation_report.md` (if present)
   - last 3 entries of `changelog.md`
   - `blockers.md` (if `run_state.json.blocked = true`)

3. **Reconcile any disagreement.** If `current_state.md` and `run_state.json`
   conflict, trust `run_state.json` and repair `current_state.md`. Note the
   repair in `changelog.md`.

4. **Process user input passed alongside `/tie:resume` or `$tie:resume`.** If
   the user provided text after the command:
   - If `blocked = true` and the text answers the open blocker, treat it as
     the answer (handled in step 5 below — mark the blocker resolved before
     resuming).
   - Otherwise, treat it as additional context that supplements the existing
     requirements. Append it to `agents_workspace/requirements.md` under a
     new `## User updates (resume)` section, prefixed with an ISO timestamp
     subheading. Generator/Evaluator/Planner re-read `requirements.md` on
     every dispatch, so they will pick it up automatically. Note the append
     in `changelog.md`.

5. **Branch on state:**

   - `project_status = completed` → tell the user the project is already
     complete, point them at `changelog.md`, and stop. Do NOT re-run anything.
   - `blocked = true` → read `blockers.md`. If the user's current prompt
     answers the open blocker, mark it `Status: resolved` and resume from the
     step that was interrupted. If not, re-state the blocker (concise) and
     stop.
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
- ❌ Re-asking clarification questions that are already answered in
  `requirements.md`.
- ❌ Discarding `agents_workspace/` and starting fresh because something
  "looks off." Investigate first; if state is genuinely corrupted, write
  what you found to `changelog.md` and ask the user before reset.
