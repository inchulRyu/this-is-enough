# ThisIsEnough (`tie`)

> Run one skill. The orchestrator drives **plan → implement → evaluate → fix**
> loops until the project is done or hits a real blocker.

ThisIsEnough is a **file-first autonomous workflow runtime** for coding agents.
It implements the spec in
[`agent_orchestrator_workflow_runtime_spec_v_0_3.md`](./agent_orchestrator_workflow_runtime_spec_v_0_3.md)
as a cross-platform plugin that works in both **Claude Code** and **Codex CLI**.

## What it does

You state a requirement once. ThisIsEnough then:

1. **Clarifies only essential ambiguities** (no busywork questions).
2. **Builds a Roadmap** of phases.
3. For each phase, autonomously:
   - **Planner** expands the raw requirement into a rich product-level Plan
     (prevents under-scoping).
   - **Generator** decomposes into tasks, implements them in your repo's
     existing conventions, and self-checks.
   - **Evaluator** picks an appropriate validation level (L0–L5), actually
     runs the checks, and returns pass / fail / blocked.
   - On fail, fix loop runs until pass or blocker.
4. **Stops only on**: project complete, user decision needed, environment
   broken, repeated unrecoverable failure, or risky operation requiring
   confirmation.

All state lives under `agents_workspace/` as plain files. Any session can
resume cleanly with `$tie:resume` or `/tie:resume`.

## Install

### Claude Code — persistent install (recommended)

The repo doubles as its own plugin marketplace (`.claude-plugin/marketplace.json`).
You add it once and Claude Code remembers it across all sessions and projects —
no `--plugin-dir` flag, no per-session setup.

**Option A: from a local clone** (fastest if you already have the repo on disk):

```bash
git clone https://github.com/inchulRyu/this-is-enough.git
```

Then inside Claude Code:

```text
/plugin marketplace add /absolute/path/to/this-is-enough
/plugin install tie@thisisenough
/reload-plugins
```

**Option B: directly from GitHub** (no clone needed):

```text
/plugin marketplace add inchulRyu/this-is-enough
/plugin install tie@thisisenough
/reload-plugins
```

After install you can verify with `/plugin` → **Installed** tab. The skills
(`/tie:start`, `/tie:resume`, `/tie:status`, `/tie:next`) appear in the slash
command picker.

To pull updates later:

```text
/plugin marketplace update thisisenough
/reload-plugins
```

### Claude Code — dev / one-off testing

For iterating on the plugin itself without registering it:

```bash
claude --plugin-dir /path/to/this-is-enough
```

This loads the plugin only for the current session.

### Codex CLI

Codex discovers skills natively from `~/.agents/skills/`. Install once with a
clone + symlink and it persists across all Codex sessions:

```bash
git clone https://github.com/inchulRyu/this-is-enough.git ~/.codex/thisisenough
mkdir -p ~/.agents/skills
ln -s ~/.codex/thisisenough/skills ~/.agents/skills/tie
```

Restart Codex. Full instructions in [`.codex/INSTALL.md`](./.codex/INSTALL.md).

> Codex tip: subagent dispatch requires `multi_agent = true` in
> `~/.codex/config.toml`. Without it, Planner/Generator/Evaluator run inline
> in the orchestrator's context (works, but uses more tokens).

### Uninstalling

**Claude Code:**
```text
/plugin uninstall tie@thisisenough
/plugin marketplace remove thisisenough
```

**Codex CLI:**
```bash
rm ~/.agents/skills/tie
rm -rf ~/.codex/thisisenough   # optional, removes the clone
```

## Use

Start a workflow:

```text
# Claude Code
/tie:start I want to add a dashboard with empty/error states and …

# Codex CLI
$tie:orchestrator I want to add a dashboard with empty/error states and …
```

Resume after a stopped session:

```text
/tie:resume          # Claude Code
$tie:resume          # Codex CLI
```

Read-only status snapshot:

```text
/tie:status
$tie:status
```

## Skills

| Skill              | What it does                                                                |
| ------------------ | --------------------------------------------------------------------------- |
| `tie:orchestrator` | Entry point. Drives the entire state machine end-to-end.                    |
| `tie:planner`      | Expands raw requirement into a rich product-level Plan (subagent role).     |
| `tie:generator`    | Decomposes / implements / self-checks / fixes (subagent role, modes).       |
| `tie:evaluator`    | Adaptive L0–L5 validation, returns pass/fail/blocked (subagent role).       |
| `tie:resume`       | Resumes an interrupted run from `agents_workspace/`.                        |
| `tie:status`       | Read-only snapshot of where the run currently stands.                       |

## What the workspace looks like

```text
agents_workspace/
  requirements.md
  roadmap.md
  current_state.md
  run_state.json
  decisions.md
  changelog.md
  blockers.md           (only when blocked)
  phases/
    01-<phase-slug>/
      phase.md
      plan.md
      tasks.md
      validation_intent.md       (optional)
      implementation_log.md
      generator_self_check.md
      validation_plan.md
      evaluation_report.md
      evaluation_history.md
```

By default the workspace IS committed — it's the resume substrate. Add it to
`.gitignore` only if you don't want shared resumability.

## When NOT to use

- One-line bug fixes. Just fix it.
- Pure refactors with no product-level change. The Planner has nothing to
  expand.
- Throwaway scripts. The workspace overhead isn't worth it.

## Safety

The orchestrator never:

- modifies system or network configuration,
- touches files outside the project working directory,
- runs destructive git operations without confirmation,
- commits secrets,
- continues past a destructive/risky step without an explicit user OK.

If any of those come up, it stops with a clear blocker.

## Spec

The full design rationale and template details live in
[`agent_orchestrator_workflow_runtime_spec_v_0_3.md`](./agent_orchestrator_workflow_runtime_spec_v_0_3.md).
The skills in this plugin implement that spec faithfully.

## License

MIT.
