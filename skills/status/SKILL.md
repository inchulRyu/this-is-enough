---
name: status
description: Use when the user asks where the active ThisIsEnough workflow run currently stands, without taking any action. Resolves .tie/active_run and summarizes the run's state and any open blocker. Read-only.
---

# tie:status — read-only snapshot

The user wants to know where things stand. Take no action: no file writes, no
repairs, no subagent dispatches.

## What you do

1. **Resolve the active run.** Read `.tie/active_run`. It stores a
   workspace-relative pointer, normally `runs/<run-id>`; resolve it as
   `.tie/<pointer>`. Reject absolute paths, `..` segments, or anything that
   resolves outside `.tie/`, and never prepend an extra `runs/` segment.
   - No `.tie/` workflow state at all → say plainly: "No ThisIsEnough
     workflow has been started in this directory. Start one with
     `/tie:start <requirement>` in Claude Code or
     `$tie:orchestrator <requirement>` in Codex CLI."
   - `active_run` exists but is unreadable, invalid, or points at a run
     without `state.json` → that is recoverable state, not a fresh start:
     report the invalid pointer and suggest `/tie:doctor` (Claude Code) or
     `$tie:doctor` (Codex CLI), not a start command.

2. **Read (never modify):**
   - `<run-dir>/state.json` — `run_id`, `status`, `step`, `owner`,
     `current_item`, `approved_at`, `blocked`, `next_action`
   - `<run-dir>/requirement.md` — `## 승인` state and C-n checkbox progress
   - `<run-dir>/plan.md` (if present) — W-n checkbox progress and stage state
     (which stage is detailed vs goal-only)
   - `<run-dir>/verification.md` (if present) — latest `Verdict`
   - last entry of `<run-dir>/log.md`

3. **Output one status block:**

```
ThisIsEnough — status

Run:          <run_id>  (<status>)
Step:         <step> — owner: <owner>   current: <current_item or ->
Approval:     대기 | 승인됨 (<approved_at>)
Checklist:    <n> of <m> C-n passed
Work items:   <n> of <m> W-n done  <current stage, if staged>
Last verdict: <pass | fail | blocked | none yet>
Last log:     <one line from the last log.md entry>

Next: <next_action>
```

4. **If blocked**, append:

```
Open blocker: <one-line summary of the last [블로커] log entry>
To answer and continue: `/tie:resume <your answer>` in Claude Code or
`$tie:resume <your answer>` in Codex CLI
```

## Anti-patterns

- ❌ Editing or repairing any file, even when state looks inconsistent — leave
  that to `tie:resume` or `tie:doctor`.
- ❌ Dispatching subagents.
- ❌ Long narratives. The status block is the answer.
