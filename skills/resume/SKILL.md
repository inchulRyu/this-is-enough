---
name: resume
description: Use when the user wants to continue a previously-interrupted ThisIsEnough workflow run. Resolves .tie/active_run, reads the run's state, then hands control to the orchestrator at the correct step.
---

# tie:resume — pick up where the workflow left off

The user is continuing a previous run. There should already be a
`.tie/active_run` pointer from a prior session.

## What you do

1. **Resolve the active run.** Read `.tie/active_run`. It stores a
   workspace-relative pointer, normally `runs/<run-id>`; resolve it as
   `.tie/<pointer>`. Reject absolute paths, `..` segments, or anything that
   resolves outside `.tie/`, and never prepend an extra `runs/` segment.
   If there is no `.tie/` workflow state at all, this is not a resume: say
   so and suggest the platform start command (`/tie:start <requirement>` in
   Claude Code, `$tie:orchestrator <requirement>` in Codex CLI). If
   `active_run` exists but is unreadable, invalid, or points at a run
   without `state.json`, that is recoverable state — report it and suggest
   `/tie:doctor` or `$tie:doctor` instead of starting a new run.

2. **Read state in this exact order:**
   - `<run-dir>/state.json` — machine truth: `status`, `step`, `owner`,
     `current_item`, `approved_at`, `blocked`, `next_action`
   - last few entries of `<run-dir>/log.md` — what just happened
   - the artifact for the current step: `plan.md` (plan/implement),
     `verification.md` (verify/fix), plus `requirement.md` (always, for
     approval state)

   If `state.json` and an artifact disagree, `state.json` is the machine
   baseline: log the mismatch as a `[복구]` entry and correct the artifact.

3. **Approval gate.** If `state.json.approved_at` is null or the requirement's
   `## 승인` section says `대기`, the run is not approved. Do not advance past
   approval: show the `## 핵심 체크리스트` and ask for the one confirmation
   before anything else runs.

4. **Process text passed with the command.**
   - If `blocked = true` and the text answers the open `[블로커]` log entry:
     append a `[복구]` entry recording the answer, set
     `state.json.blocked = false` (and `status` back to `in_progress`), then
     resume at `state.json.step`.
   - If the text references a draft path (`.tie/drafts/<draft-id>.md`):
     `tie:resume` never starts a draft run. Do not promote or delete the
     draft. If the active run is not completed, say it must be completed or
     resolved first and stop. Otherwise point the user at the platform start
     command and stop.
   - Any other text: append it to the run's `requirement.md` under
     `## 갱신 기록` with an ISO timestamp. If it changes any C-n items,
     re-confirm only the changed ones with the user before continuing. If the
     run is already `completed`, do not append — new text is a new
     requirement; point at the platform start command instead.

5. **Branch on status:**
   - `completed` → say the run is already complete, point at `log.md`, stop.
   - `blocked` with no answer given → restate the open `[블로커]` concisely
     (options, recommendation, resume condition) and stop.
   - Otherwise → hand off to `tie:orchestrator`, which continues from
     `state.json.step` / `next_action` without re-running finished steps.

6. **Report briefly before handing off:**

```
Resuming ThisIsEnough run.

Run:    <run_id>  (<status>)
Step:   <step> — owner: <owner>
Last:   <one line from the last log.md entry>
Next:   <next_action>
```

## Anti-patterns

- ❌ Re-running steps that already completed. Trust the files.
- ❌ Discarding `.tie/active_run` or the run directory and starting fresh
  because something "looks off." Investigate first; if state is genuinely
  corrupted, log what you found as `[복구]` and ask the user before any reset.
- ❌ Inventing state that is not in `state.json` or `log.md`.
