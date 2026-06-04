# ThisIsEnough (`tie`)

> Run one skill. The orchestrator drives **plan → implement → evaluate → fix**
> loops until the project is done or hits a real blocker.

ThisIsEnough is a **file-first autonomous workflow runtime** for coding agents.
It implements the spec in
[`docs/runtime-spec-v0.3.md`](./docs/runtime-spec-v0.3.md)
as a cross-platform plugin that works in both **Claude Code** and **Codex CLI**.

## What it does

You can draft a requirement first, or state a requirement directly. Once a run
starts, ThisIsEnough then:

1. **Clarifies only essential ambiguities** (no busywork questions).
2. **Builds a Roadmap**, defaulting to one phase unless dependency or risk
   boundaries justify a split.
3. For each phase, autonomously:
   - **Planner** expands the raw requirement into a rich product-level Plan
     (prevents under-scoping).
   - **Generator** decomposes into tasks, implements them in your repo's
     existing conventions, and leaves a short implementation handoff.
   - **Evaluator** picks `standard` or `high` validation plus the lowest L0-L5
     validation level that gives confidence, actually runs the checks, maps
     requirements to artifacts and evidence, and returns pass / fail / blocked.
   - Complex or risky phases may get optional pre-validation guidance in
     `validation_intent.md`; simpler phases skip it.
   - On pass, **Orchestrator** records phase completion and creates a git
     checkpoint commit when git is available and safe.
   - On fail, fix loop runs until pass or blocker.
4. **Stops only on**: project complete, user decision needed, environment
   broken, repeated unrecoverable failure, or risky operation requiring
   confirmation.

Before implementation starts, draft requirements can live under
`.tie/drafts/`. Once a run starts, state for that request lives under
an isolated run directory in `.tie/runs/<run-id>/`, with
`.tie/active_run` pointing to the current/latest run. Any session can
resume cleanly with `$tie:resume` or `/tie:resume`.
Each run also keeps `telemetry.jsonl`, an append-only machine log for timing and
execution events. It lets you analyze long runs by phase, role, step, command,
validation, and fix loop without parsing or bloating markdown artifacts.

Volatile workflow state is ignored by git by default. Durable lessons that
future work should know are promoted to `.tie/project_memory.md`,
which is intended to be committed.

Workflow artifacts stay concise by default: `current_state.md` stays a short
handoff pointer, Generator logs stay phase-level, and validation reports keep
routine pass evidence concise. Detailed timing stays in `telemetry.jsonl`, with
only short derived summaries appearing in human-facing artifacts when useful.
`standard` is the default validation profile. `high` is
reserved for phases where risk, blast radius, or runtime/system evidence needs
more ceremony. Lean artifacts do not loosen the phase gate: no phase is
complete until the Evaluator returns `pass`.

Role prompts are kept outcome-first: they define ownership, success criteria,
stop conditions, and handoff shape, while the full runtime spec and templates
remain the detailed reference for state schemas and edge-case procedure.

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

After install you can verify with `/plugin` → **Installed** tab. The slash
commands (`/tie:requirements`, `/tie:start`, `/tie:resume`, `/tie:status`,
`/tie:next`, `/tie:doctor`) appear in the command picker.

To pull updates later:

```text
/plugin marketplace update thisisenough
/plugin update tie
/reload-plugins
```

### Claude Code — dev / one-off testing

For iterating on the plugin itself without registering it:

```bash
claude --plugin-dir /path/to/this-is-enough
```

This loads the plugin only for the current session.

### Codex CLI

Codex currently discovers skills most reliably from `~/.agents/skills/`. Install
with the one-liner:

```bash
curl -fsSL https://github.com/inchulRyu/this-is-enough/raw/refs/heads/main/install-codex.sh | bash
```

The script clones to `~/.codex/thisisenough` and creates
`~/.agents/skills/tie -> ~/.codex/thisisenough/skills`. It is idempotent: re-run
the same command any time to update the managed clone and refresh the symlink.
If the managed clone has local edits or diverged commits, the installer refuses
to overwrite them.

Restart Codex, then type:

```text
$tie:
```

You should see `tie:requirements`, `tie:orchestrator`, `tie:planner`,
`tie:generator`, `tie:evaluator`, `tie:resume`, `tie:status`, and
`tie:doctor`.

To uninstall:

```bash
rm ~/.agents/skills/tie
rm -rf ~/.codex/thisisenough
```

Full reference in [`.codex/INSTALL.md`](./.codex/INSTALL.md).

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

Draft a requirement before implementation:

```text
# Claude Code
/tie:requirements Help me shape a dashboard requirement before we start.

# Codex CLI
$tie:requirements Help me shape a dashboard requirement before we start.
```

Start a workflow:

```text
# Claude Code
/tie:start I want to add a dashboard with empty/error states and …

# Codex CLI
$tie:orchestrator I want to add a dashboard with empty/error states and …
```

Start from an approved draft:

```text
# Claude Code
/tie:start from draft .tie/drafts/<draft-id>/requirement.md

# Codex CLI
$tie:orchestrator Start from draft .tie/drafts/<draft-id>/requirement.md
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

Diagnose or safely repair workflow state:

```text
# Claude Code
/tie:doctor           # auto-diagnose, then repair/migrate only when safe
/tie:doctor diagnose  # read-only
/tie:doctor repair

# Codex CLI
$tie:doctor
$tie:doctor diagnose
$tie:doctor repair
```

## Skills

| Skill              | What it does                                                                |
| ------------------ | --------------------------------------------------------------------------- |
| `tie:requirements` | Drafts concise pre-run requirements under `.tie/drafts/`.       |
| `tie:orchestrator` | Entry point. Drives the entire state machine end-to-end.                    |
| `tie:planner`      | Expands raw requirement into a rich product-level Plan (subagent role).     |
| `tie:generator`    | Decomposes / implements / fixes while keeping handoffs short.               |
| `tie:evaluator`    | Owns validation, evidence, and pass/fail/blocked verdicts.                  |
| `tie:resume`       | Resumes the run pointed to by `.tie/active_run`.                |
| `tie:status`       | Read-only snapshot of where the run currently stands.                       |
| `tie:doctor`       | Diagnoses, safely repairs, or migrates workflow state.                      |

## What the workspace looks like

```text
.tie/
  project_memory.md                  # durable notes intended for git
  drafts/
    <draft-id>/
      requirement.md                    # pre-run only
  active_run                       # e.g. runs/2026-04-27-001-add-dashboard
  runs/
    <run-id>/
      requirement.md
      roadmap.md
      current_state.md              # concise human-readable handoff
      run_state.json
      telemetry.jsonl               # append-only timing / execution events
      decisions.md
      changelog.md
      retrospective.md              # run-local memory candidates
      blockers.md                  (only when blocked)
      phases/
        01-<phase-slug>/
          phase.md
          plan.md
          tasks.md
          validation_intent.md       (optional risk preflight)
          implementation_log.md
          validation_plan.md         (used when high-risk depth needs it)
          evaluation_report.md
          evaluation_history.md      # concise snapshots
```

`drafts/` contains only requirements whose implementation has not started. When
you start from a draft, ThisIsEnough copies its `requirement.md` into the new
run, verifies the copy, then removes the draft directory only if it contains no
files besides `requirement.md`. From that point on, the run's `requirement.md`
is the source of truth for the requirement, and detailed run history stays in
the local run directory.

Validation uses profiles, not a one-size-fits-all checklist: `standard` or
`high`. Separately, the Evaluator chooses the lowest validation level that gives
confidence: `L0_static_review`, `L1_static_plus_build`,
`L2_unit_or_integration`, `L3_runtime_scenario`, `L4_e2e_or_system`, or
`L5_reference_or_benchmark`. The Evaluator raises the profile and level only
when risk requires it.
`validation_intent.md` is truly optional preflight guidance for complex or risky
phases; when present, it names representative risks and success oracles, not an
exhaustive EV-ID matrix.

Telemetry is separate from validation profiles. `standard` and `high` describe
confidence and evidence depth, not expected runtime or speed. Generator and
Evaluator command/check durations are recorded separately from Orchestrator
wall-time events so slow agent work, tests, validation, fix loops, and
checkpoint overhead can be attributed independently. Older runs without
`telemetry.jsonl` remain resumable and diagnosable.

One independent requirement creates one run. `active_run` may continue pointing
at a completed run; completion is read from that run's
`run_state.json.project_status` and `current_step`, not by clearing the pointer.
If the active run is completed and a new start request includes a new
requirement, ThisIsEnough creates a new run and overwrites `active_run`. If the
active run is still `in_progress` or `blocked`, extra start/resume text is
appended to that run's `requirement.md` under `## Updates` with an ISO timestamp
instead of creating a second run. Draft paths are the exception: they are not
appended, promoted, or deleted while another run is incomplete. There is no
`index.json`; older runs are kept as directories under `.tie/runs/`.

Run directories, drafts, and `active_run` are volatile state and are gitignored
by default:

```gitignore
.tie/drafts/
.tie/runs/
.tie/active_run
```

Do not ignore `.tie/` itself unless you also do not want to commit
`.tie/project_memory.md`. If an old setup already ignores
`.tie/`, replace that broad rule with the three rules above. If a
team wants shared resumability across machines, it can opt into committing the
volatile state by removing those ignore rules.

If a workspace was created before active-run isolation, `/tie:doctor` in Claude
Code or `$tie:doctor` in Codex can diagnose it and migrate the old root layout
into `runs/<run-id>/` when there is no conflicting new layout.

At project completion, the orchestrator reviews the run-local logs and
`retrospective.md`, then promotes only durable lessons to
`.tie/project_memory.md`: resolved failed approaches, unusual
project structure, constraints future changes must respect, and useful follow-up
cautions. Routine workflow logs stay local. A concise completion timing summary
may be derived from `telemetry.jsonl`; the detailed event stream stays in the
ignored run directory.

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
- silently skips a phase-pass checkpoint commit,
- marks a phase complete without an Evaluator `pass`,
- continues past a destructive/risky step without an explicit user OK.

If any of those come up, it stops with a clear blocker.

## Spec

The full design rationale and template details live in
[`docs/runtime-spec-v0.3.md`](./docs/runtime-spec-v0.3.md).
The skills in this plugin implement that spec faithfully.

## License

MIT.
