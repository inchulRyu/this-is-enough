# ThisIsEnough (`tie`)

> Light by design. The name is the philosophy: only what is needed, nothing more.

**한국어**: [README.ko.md](./README.ko.md)

ThisIsEnough is a **file-first workflow plugin** for coding agents on
**Claude Code** and **Codex CLI**. It keeps your mental model, the agent's
understanding, and the code's actual behavior in sync.

## Why

Agent work without a workflow has three recurring problems:

1. **Agreements evaporate** — decisions made in conversation dilute and
   disappear as the context grows.
2. **Every session re-scans the codebase** — slow, and often misread anyway.
3. **Inconsistent work style** — results are hard to trust.

Popular harnesses attack these but are heavy: tokens, time, ceremony. TIE
keeps exactly the pieces that solve the three problems — written agreements, a
persistent map, fixed roles in a fixed order — and nothing else.

## How it works

1. **Sync conversation** (`tie:requirements`) — grounded in the map, the agent
   presents the current system flow and the expected flow after your change;
   agreements are written down the moment they happen.
2. **Approval gate** — the core checklist (핵심 체크리스트) of observable
   "when X, Y happens" flows is confirmed with you once before any
   implementation. Approving is just replying in the conversation — the
   agent records it in the requirement's `## 승인` section and
   `state.json`; you never edit workflow files by hand.
3. **The run** — plan (direction only; large work is staged, later stages
   detailed just before they start) → implement (the Implementer judges the
   details at the code) → verify (each checklist flow actually exercised,
   plus adjacent flows from the map) → map update (automatic, incremental)
   → checkpoint commit, per stage. No verify pass, no completion.
4. **Complete** — failed approaches and new invariants are promoted to the
   constitution, then a final report.

## ARCHITECTURE.md — constitution + map

The answer to re-scanning: one committed file at the repo root. The
**constitution** holds what code alone cannot tell you — invariants, design
rationale and rejected alternatives, failed approaches. The **map** holds what
happens where — the system's flows, each step a sentence or two plus a backtick
`symbol` pointer. Values never go in the map; they stay in code, so literal
changes need no doc update and stale pointers are caught with a grep. In-run
updates are automatic and incremental; `tie:map` is the manual entry point for
initial creation, resync after work done outside TIE, and restructuring.

## Install

### Claude Code — persistent install (recommended)

The repo doubles as its own plugin marketplace (`.claude-plugin/marketplace.json`).
You add it once and Claude Code remembers it across all sessions and projects —
no `--plugin-dir` flag, no per-session setup.

**Option A: directly from GitHub** (no clone needed — recommended):

```text
/plugin marketplace add inchulRyu/this-is-enough
/plugin install tie@thisisenough
/reload-plugins
```

**Option B: from a local clone** (if you already have the repo on disk):

```bash
git clone https://github.com/inchulRyu/this-is-enough.git
```

Then inside Claude Code:

```text
/plugin marketplace add /absolute/path/to/this-is-enough
/plugin install tie@thisisenough
/reload-plugins
```

After install you can verify with `/plugin` → **Installed** tab. The slash
commands (`/tie:requirements`, `/tie:start`, `/tie:map`, `/tie:resume`,
`/tie:status`, `/tie:doctor`) appear in the command picker.

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
`~/.agents/skills/tie -> ~/.codex/thisisenough/skills`. If the managed clone
has local edits or diverged commits, the installer refuses to overwrite them.

Restart Codex, then type:

```text
$tie:
```

You should see `tie:requirements`, `tie:start`, `tie:planner`,
`tie:implementer`, `tie:verifier`, `tie:map`, `tie:resume`, `tie:status`, and
`tie:doctor`.

To update, re-run the same one-liner — it is idempotent and refreshes the
managed clone to the latest commit:

```bash
curl -fsSL https://github.com/inchulRyu/this-is-enough/raw/refs/heads/main/install-codex.sh | bash
```

Full reference in [`.codex/INSTALL.md`](./.codex/INSTALL.md). Uninstall
instructions for both platforms are in [Uninstalling](#uninstalling) below.

> Codex tip: subagent dispatch requires `multi_agent = true` in
> `~/.codex/config.toml`. Without it, Planner/Implementer/Verifier run inline
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

```text
# Same names on both platforms: /tie:... in Claude Code, $tie:... in Codex CLI

# Sync conversation → requirement draft → checklist approval
/tie:requirements Help me shape a dashboard requirement.

# Start a run — from an approved draft, or raw requirements (checklist confirmed first)
/tie:start from draft .tie/drafts/<draft-id>.md

# Bootstrap/resync ARCHITECTURE.md · resume · status · diagnose & repair
/tie:map    /tie:resume    /tie:status    /tie:doctor
```

## A typical run

Say you want to add a `subtract` command to a small CLI calculator.
(Examples use Claude Code syntax; on Codex, replace `/tie:` with `$tie:`
per the table above.)

**1. Shape the requirement.**

```text
/tie:requirements I want a subtract command, same interface as add.
```

The agent reads `ARCHITECTURE.md` instead of scanning the repo, shows the
current flow and the expected flow after your change, and writes each
agreement into `.tie/drafts/<draft-id>.md` the moment it happens. The draft
converges on a core checklist of observable flows:

```md
## 핵심 체크리스트
- [ ] C-1: `calc.py subtract 5 3`을 실행하면 2.0을 출력하고 종료 코드 0으로 끝난다
- [ ] C-2: 기존 add 명령은 이전과 완전히 동일하게 동작한다
- [ ] C-3: 알 수 없는 명령을 주면 subtract를 포함한 usage를 보여주고 종료 코드 1로 끝난다
```

**2. Approve and start.**

```text
/tie:start from draft .tie/drafts/2026-07-03-001-calc-subtract.md
```

Approval is a conversational reply — "approve", or "C-2 should also cover
…" to renegotiate first. The agent records it in `requirement.md`'s
`## 승인` and `state.json.approved_at`. A draft approved during the
requirements conversation starts immediately. You can also skip drafting
and pass raw requirements straight to `/tie:start`; the agent writes the
requirement itself and shows you the checklist for one confirmation before
anything else happens.

**3. The run does the rest.**

- **Planner** writes `plan.md`: technical direction and coarse work items
  (W-n), each naming the C-ns it covers. Large work is split into stages;
  only the first is detailed, later stages get detailed just before they
  start, with the knowledge gained so far.
- **Implementer** implements W-n by W-n, judging details at the code, logging
  decisions and failed approaches to `log.md`.
- **Verifier** actually exercises every checklist flow (reading is not
  verification), plus adjacent flows from the map as a regression list,
  and writes the verdict to `verification.md`. On `fail`, the Implementer gets
  a fix round with concrete next actions — it confirms the cause with evidence
  before touching code, declares the fix's blast radius up front, and the
  recheck starts from that radius. When the fix budget runs dry, the run
  doesn't call you yet: it steps back and **reframes** — fresh-context lens
  agents (redefine the problem, suspect the environment, deep-search prior
  art) re-derive the problem from facts only, with none of the stuck run's
  assumptions. A confirmed new cause renews the fix budget; only genuinely
  user-shaped decisions become blockers. Bounded, never endless.
- On `pass` the orchestrator ticks the C-n boxes, updates the map
  incrementally if behavior or structure changed, and makes a checkpoint
  commit (`tie: <run-id> …`, never staging `.tie/`).

**4. Interruptions don't matter.**

Every decision lives in files, not context. Close the terminal mid-run,
come back tomorrow, and:

```text
/tie:resume
```

picks up exactly where the run stopped. This includes a pending approval:
a headless or unattended start stops as blocked with the checklist shown,
and replying through `/tie:resume` with your approval records it and
continues.

**5. Complete.** Failed approaches and newly discovered invariants are
promoted into the `ARCHITECTURE.md` constitution, and you get a short
explainer that syncs the change back into your head: the before → after
flow in your own language, the decisions made on your behalf, the commit,
and a command or two to verify with your own hands — plus an optional
2–3 question quiz on what changed, if you want it.

## Skills

| Skill              | What it does                                                              |
| ------------------ | ------------------------------------------------------------------------- |
| `tie:requirements` | Sync conversation; writes the draft under `.tie/drafts/` as agreements happen. |
| `tie:start`        | Entry point. Drives the run state machine end-to-end.                     |
| `tie:planner`      | Technical direction and W-n work items; staged detailing for large work.  |
| `tie:implementer`  | Implements; judges details on the ground; logs decisions and failed approaches. |
| `tie:verifier`     | Exercises checklist flows + adjacent mapped flows; pass/fail/blocked.     |
| `tie:map`          | Creates, resyncs, or restructures `ARCHITECTURE.md` (with your confirmation). |
| `tie:resume`       | Resumes the run pointed to by `.tie/active_run`.                          |
| `tie:status`       | Read-only snapshot of the active run.                                     |
| `tie:doctor`       | Diagnoses, safely repairs, and migrates v0.3 workspaces.                  |

The role skills (`tie:planner`, `tie:implementer`, `tie:verifier`) carry the
dispatched roles' contracts; you never invoke them directly. In Claude Code
they are hidden from the command picker (`user-invocable: false`); in Codex
they are visible under `$tie:` but are meant for dispatched subagents.

## Models and effort

TIE never pins a model or reasoning effort. Model choice solves none of the
three problems TIE exists for, model names differ per host and go stale,
and a plugin should not silently decide your costs. Every role inherits
your session settings — `/model` and `/effort` in Claude Code, `model` /
`model_reasoning_effort` in Codex's `~/.codex/config.toml`. To pin a
per-role override in Claude Code, add a `model:` line to the agent
frontmatter in `agents/` — the Planner, which does deep research, benefits
most from a high-reasoning model. Codex applies its config globally.

## What the workspace looks like

```text
ARCHITECTURE.md            # constitution + map — committed
.tie/                      # volatile workflow state — gitignored entirely
  active_run               # pointer: runs/<run-id>
  drafts/
    <draft-id>.md          # requirement draft, pre-approval
  runs/
    <run-id>/
      requirement.md       # 요구사항 명세: agreements (A-n), checklist (C-n), approval
      plan.md              # technical direction + work items (W-n)
      verification.md      # latest verification report (overwritten)
      log.md               # append-only journal of tagged events
      state.json           # machine resume state
```

Five files per run, and the gitignore is a single rule — `.tie/` — because
everything worth committing lives in `ARCHITECTURE.md` from the start.

## When NOT to use

One-line bug fixes (just fix them), pure refactors with no behavior change
(nothing to checklist), throwaway scripts (the workspace is not worth it).
Even then the map stays authoritative: if behavior or structure changed
without a run, update it by hand or via `tie:map`.

## Migrating from v0.3

Run `/tie:doctor` (or `$tie:doctor`). It detects v0.3 layouts (phase
directories, `project_memory.md`, the three-rule gitignore), advises finishing
in-progress v0.3 runs under v0.3 rules, and offers — with your confirmation —
to promote `project_memory.md` into the `ARCHITECTURE.md` constitution.

## Safety

No role modifies files outside the project, changes system or network config,
runs destructive git without confirmation, touches secrets, declares
completion without a Verifier pass, or proceeds past risky/irreversible
steps without your OK. In those situations it stops with a clear blocker.

## Spec

Design rationale and contracts: [`docs/runtime-spec-v0.4.md`](./docs/runtime-spec-v0.4.md).
The skills derive from that spec and never read it at runtime.

## License

MIT.
