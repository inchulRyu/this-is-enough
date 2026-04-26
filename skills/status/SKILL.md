---
name: status
description: Use when the user asks for a quick read on where a ThisIsEnough workflow run currently stands without taking any action. Read-only summary of run_state.json, current_state.md, roadmap progress, and any open blocker.
---

# tie:status — read-only snapshot

The user wants to know where things stand. Do not take any action. Do not
modify any file. Do not dispatch any subagent.

## What you do

1. **Verify workspace exists.** If `agents_workspace/run_state.json` is
   missing, say so plainly: "No ThisIsEnough workflow has been started in
   this directory. Use `$tie:orchestrator <your requirement>` to begin."

2. **Read (do not modify):**
   - `agents_workspace/run_state.json`
   - `agents_workspace/current_state.md`
   - `agents_workspace/roadmap.md`
   - latest `evaluation_report.md` of the current phase (if any)
   - `blockers.md` (if blocked)

3. **Output a single status block:**

```
ThisIsEnough — workflow status

Project:   <project_status>
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
   To answer and continue: $tie:resume <your answer>
```

5. **Do not** suggest improvements, do not start work, do not edit files.
   Status is read-only.

## Anti-patterns

- ❌ Modifying any file (including `current_state.md` repairs — leave that to
  `tie:resume` or `tie:orchestrator`).
- ❌ Dispatching subagents.
- ❌ Long narratives. The status block is the answer.
