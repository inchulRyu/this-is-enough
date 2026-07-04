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

The orchestrator dispatches the Planner, Implementer, and Verifier per run so
each role gets its own context window. Dispatching is the default whenever the
platform supports it — the user invoking the workflow is itself the delegation
request; do not wait for a separate explicit ask. There are no phase
directories; every dispatch
targets the single active run directory with a role mode: `plan` | `detail-stage`
(Planner), `implement` | `fix` (Implementer), `verify` | `recheck` (Verifier).
Use the platform's native mechanism:

- **Claude Code**: Call the `Task` (or `Agent`) tool with `subagent_type` matching
  one of the named agents bundled in `agents/` (`tie-planner`,
  `tie-implementer`, `tie-verifier`). The subagent prompt names the `tie:<role>`
  skill to invoke, the mode, and the dispatch paths.
- **Codex CLI**: Call `spawn_agent` with a worker role, then `wait_agent` for the
  result. The subagent prompt likewise directs it to invoke the corresponding
  skill (e.g., `$tie:planner`) with the mode and paths.
- **Fallback (no subagent support only)**: Inline the role by directly invoking
  the skill in the current context. This fallback is for missing tooling (e.g.
  Codex without `multi_agent = true`), never a judgment call. The orchestrator
  should warn the user that context window pressure is higher in this mode.

`tie:doctor` and `tie:map` are not dispatched roles. They run inline as
maintenance entry points on workflow state and `ARCHITECTURE.md`.

## Persistence is platform-agnostic

Workspace state lives in plain files, identical on every platform. Run state is
exactly five files under `.tie/runs/<run-id>/` — `requirement.md`, `plan.md`,
`verification.md`, `log.md`, `state.json` — and `.tie/active_run` points to the
current run. The entire `.tie/` directory is gitignored; nothing in it is
committed. Durable knowledge lives instead in the committed `ARCHITECTURE.md`
(constitution + map) at the project root, updated incrementally during runs.

Dispatch payloads carry explicit absolute paths: the run directory, the run
files the role needs, and the `ARCHITECTURE.md` path (or `none`). Subagents use
only those paths and never infer state from root `.tie/`. If a subagent has
restricted file access, it must at minimum read the active run directory and
`ARCHITECTURE.md`, and write the files its role owns.
