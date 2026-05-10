# Tool name mapping across platforms

Skills in this plugin are written using **Claude Code tool names**. When running
inside Codex CLI (or another agent host), translate as follows.

| Concept                        | Claude Code        | Codex CLI                       | OpenCode      |
| ------------------------------ | ------------------ | ------------------------------- | ------------- |
| Read a file                    | `Read`             | `read`                          | `read`        |
| Write a file                   | `Write`            | `write` (or `apply_patch`)      | `write`       |
| Edit a file                    | `Edit`             | `apply_patch`                   | `edit`        |
| List directory / search        | `Glob` / `Grep`    | `find` / `rg` via `bash`        | same          |
| Run a shell command            | `Bash`             | `bash`                          | `bash`        |
| Spawn a subagent for one task  | `Task` / `Agent`   | `spawn_agent` (requires `multi_agent = true` in `~/.codex/config.toml`) | `spawn` |
| Wait for a spawned subagent    | (return value)     | `wait_agent`                    | (return)      |
| Track multi-step todos         | `TodoWrite`        | `update_plan`                   | `update_plan` |
| Web fetch / search             | `WebFetch` / `WebSearch` | `bash` + `curl` / `web.search` (if enabled) | varies |

## Subagent dispatch

The orchestrator skill needs to dispatch the Planner, Generator, and Evaluator as
subagents so each runs in its own context window. Use the platform's native
mechanism:

- **Claude Code**: Call the `Task` (or `Agent`) tool with `subagent_type` matching
  one of the named agents bundled in `agents/` (`tie-planner`, `tie-generator`,
  `tie-evaluator`). The subagent prompt should tell it which `tie:<role>` skill
  to invoke and which phase directory to operate on.
- **Codex CLI**: Call `spawn_agent` with a worker role, then `wait_agent` for the
  result. The subagent prompt should likewise direct it to invoke the
  corresponding skill (e.g., `$tie:planner`) with the phase path.
- **Fallback (no subagent support)**: Inline the role by directly invoking the
  skill in the current context. The orchestrator should warn the user that
  context window pressure is higher in this mode.

`tie:doctor` is not a phase subagent role. It runs inline as a maintenance skill
because it diagnoses, repairs, or migrates workflow state instead of planning,
implementing, or evaluating a phase.

## Persistence is platform-agnostic

Workspace state lives in plain files. `agents_workspace/active_run` points to
the current/latest run, and the run's state is closed under
`agents_workspace/runs/<run-id>/`. Reading, writing, and editing those files
works identically on every platform — that is the whole point of the file-first
design. Those volatile state paths are gitignored by default; durable lessons
are promoted separately to `agents_workspace/project_memory.md`. If the spawned
subagent only has read access to part of the tree, ensure
it at minimum can read the active run directory and current phase directory, and
write to the files its role owns (see Section 4 of the spec). Pass explicit
absolute paths; subagents should not infer state from root `agents_workspace/`.
