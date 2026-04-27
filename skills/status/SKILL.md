---
name: status
description: Use when the user asks for a quick read on where the active ThisIsEnough workflow run currently stands without taking any action. Resolves agents_workspace/active_run and summarizes that run's state files and any open blocker.
---

# tie:status — read-only snapshot

The user wants to know where things stand. Do not take any action. Do not
modify any file. Do not dispatch any subagent.

## What you do

1. **Resolve the active run.** Read `agents_workspace/active_run`, resolve its
   text relative to `agents_workspace/`, and treat that directory as the run
   directory. If `active_run` is missing, unreadable, or points at a run without
   `run_state.json`, say so plainly: "No ThisIsEnough workflow has been started
   in this directory. Start one with `/tie:start <requirement>` in Claude Code
   or `$tie:orchestrator <requirement>` in Codex CLI."

2. **Read (do not modify):**
   - `<active-run-dir>/run_state.json`
   - `<active-run-dir>/current_state.md`
   - `<active-run-dir>/roadmap.md`
   - latest `evaluation_report.md` of the current phase (if any)
   - `<active-run-dir>/changelog.md`
   - `blockers.md` (if blocked)

3. **Output a single status block:**

```
ThisIsEnough — workflow status

Project:   <project_status>
Run:       <run_id>
Phase:     <current_phase> — <current_phase_status>  (loop <loop_count>)
Owner:     <current_owner>
Step:      <current_step>
Blocked:   <yes/no>   <if yes: one-line reason>

Roadmap progress:
  ✅ Phase 1: <name>          passed
  🔄 Phase 2: <name>          <status>
  ⏳ Phase 3: <name>          pending
  ⏳ Phase 4: <name>          pending

Last evaluation: <verdict> (L<N>)   <if any>
Last log entry:  <one line from changelog>

Next action: <next_action from run_state.json>
```

4. **If blocked**, append:

```
🚧 Open blocker: <B-ID> — <title>
   Question: <user decision needed?>
   Options: <brief list>
   To answer and continue: `/tie:resume <your answer>` in Claude Code or
   `$tie:resume <your answer>` in Codex CLI
```

5. **Do not** suggest improvements, do not start work, do not edit files.
   Status is read-only.

## Anti-patterns

- ❌ Modifying any file (including `current_state.md` repairs — leave that to
  `tie:resume` or `tie:orchestrator`).
- ❌ Dispatching subagents.
- ❌ Long narratives. The status block is the answer.
