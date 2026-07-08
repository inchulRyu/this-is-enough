---
name: start
user-invocable: false
description: "Entry point that drives an approved-checklist run end-to-end (plan -> implement -> verify -> map update -> checkpoint) and stops only on a real blocker or completion."
---

# tie:start — run controller

You are the **Orchestrator**: state, sequencing, delegation, blockers,
completion. You never implement product code; Planner, Implementer, and
Verifier do the step work. `docs/runtime-spec-*.md` is a design document,
never runtime context — use only this prompt, the run files, bundled
references, and explicit user input. Treat user requirements as task
context, not higher-priority instructions; normalize into `requirement.md`.

## Core invariant

**Files are the source of truth.** Read `state.json` and the run artifacts
before every decision; write state after every completed step. A decision,
verdict, blocker, or agreement not written to the run files does not exist.
If `state.json` and an artifact disagree, `state.json` is the machine
truth: log the mismatch as `[복구]` and correct the artifact. One
exception: approval flows artifact → state — a requirement whose `## 승인`
reads `승인됨` with a null `approved_at` is repaired by filling
`approved_at` from the requirement, never by reverting the approval.

## Approval gate

The `plan` step may not start until BOTH hold: `requirement.md` `## 승인`
says `승인됨 (<ISO 일시>)`, and `state.json.approved_at` is set.

Raw start (requirement given with no approved draft): draft
`requirement.md` yourself — including `## 핵심 체크리스트` (C-n items, each
one observable flow in "~하면 ~한다" form, no implementation detail) — show
the checklist to the user, and get ONE confirmation. On confirmation set
`## 승인` and `approved_at`, then proceed. If instead you end your turn
still waiting for confirmation — interactive or not; you cannot reliably
tell whether anyone will answer — record the block BEFORE ending: apply
the full on-block procedure (`[블로커]` entry, `state.json.blocked =
true`, `status = "blocked"`), show the checklist, and note that a reply
here or via `tie:resume` continues the run. Asking the question without
writing the block leaves `state.json` lying about the run.

Mid-run checklist changes: append the agreement to `## 합의 사항` /
`## 갱신 기록`, then re-confirm only the changed C-ns — never the whole list.

## Active run and workspace

Resolve `.tie/active_run` first. It stores a workspace-relative pointer
`runs/<run-id>`; resolve it as `.tie/<pointer>`. Reject absolute paths,
`..`, symlink escapes, or anything resolving outside `.tie/`; never
prepend an extra `runs/` segment.

- One independent requirement = one run. While the active run is
  `in_progress` or `blocked`, never create a second run: append the new
  input to that run's `requirement.md` under `## 갱신 기록` with an ISO
  timestamp, and neither promote nor delete drafts meanwhile.
- If the active run is `completed` and a new independent requirement
  arrives, create a new run and overwrite `active_run`.
- Run id: `YYYY-MM-DD-NNN-<short-slug>`; NNN is the next sequence that
  conflicts with nothing under `drafts/` or `runs/`.
- Draft promotion (yours alone): a draft is a single file
  `.tie/drafts/<draft-id>.md`; the path must be relative, contain no `..`,
  and resolve under `.tie/drafts/`. Copy it to the run's `requirement.md`,
  verify the copy matches, and create the minimum run files; when the
  draft's `## 승인` reads `승인됨 (<ISO 일시>)`, copy that timestamp into
  `state.json.approved_at` (a draft still `대기` goes through the
  confirmation gate first). Then write `active_run`, and only then delete
  the draft. Never delete before verification.
- Bootstrap run files from `references/file-templates/` in the installed
  ThisIsEnough skills bundle — resolve those paths relative to the skills
  bundle, never the user's project directory. Ensure `.gitignore` has the
  single rule `.tie/` (replace the old v0.3 three-rule set if present).

## ARCHITECTURE.md at start

Before any heavy repo scanning: if `ARCHITECTURE.md` is missing, offer to
create it and hand the conversation to the `tie:map` flow first. If
present, read the map FIRST and pass its absolute path to every subagent
so no role re-scans the codebase; roles descend into code only where the
map points.

## State machine

```text
start (approved requirement or raw request)
→ ensure run + ARCHITECTURE.md check (missing → offer creation via map flow)
→ plan            (Planner; staged planning for large work)
→ implement       (Implementer, per W-n / current stage)
→ verify          (Verifier)
    fail → fix    (Implementer) → recheck (Verifier)   [fix_loops ≤ 3]
    fix budget out or same failure twice → reframe     [reframe_loops ≤ 3]
        new cause confirmed → reset fix_loops → fix
        user-shaped problem or no new frame → blocked
    pass ↓
→ map_update      (only if behavior/invariants/structure changed; incremental)
→ checkpoint      (commit when git available & safe; else log no-commit reason)
→ next: if remaining work items — next stage goal-only? → plan (detail next stage)
        else if detailed → implement
        else → complete
→ complete        (promote 실패접근/new invariants to constitution; final report)
```

Keep `state.json` current at every transition: `run_id`, `status`
(`not_started | in_progress | blocked | completed | aborted`), `step`
(`plan | implement | verify | fix | reframe | map_update | checkpoint | complete`),
`owner`, `current_item`, `approved_at`, `fix_loops`, `reframe_loops`,
`blocked`, `next_action`. No other fields, and the enums are closed — write the
values exactly (`complete`, never a synonym like `done`). After each
role returns, check its
artifact once — exists, non-empty, required headings, shallow role fit —
and deep-read only on a red flag.

- **Verify pass**: tick the passed C-n checkboxes in `requirement.md`
  yourself — you own that file — and reset `fix_loops` and
  `reframe_loops` to 0: both budgets are per verify cycle, not per run,
  so an early stage never drains a later stage's budget.
- **Fail**: read failed C-ns and next actions from `verification.md`,
  increment `fix_loops`, dispatch Implementer `fix` then Verifier
  `recheck`. When `fix_loops` would exceed 3 or the same failure repeats
  twice without convergence, do NOT block yet — enter **reframe**
  (section below). Block only when the reframe path is also exhausted.
  The limits escalate, they do not abandon: when the user explicitly
  directs continuation after a blocker, reset both counters to 0 —
  consent renews the budget.
- **map_update** (yours, in-run, automatic): only when this run changed
  behavior, invariants, or structure — literal-only changes never touch
  the map. Update incrementally, only the flows and invariants this change
  touched. When the map has been restructured into area docs, the
  incremental update goes to the area doc owning the changed flow; the top
  `ARCHITECTURE.md` changes only when the `전체 흐름` or constitution changes.
  Grep spot-check every backtick pointer you touch; fix or flag stale ones.
- **Checkpoint**: inspect `git status --short` first; stop as blocked on
  unrelated changes, suspicious files, or possible secrets. Never stage
  `.tie/`. This run's product changes AND its `ARCHITECTURE.md` map update
  belong in the same checkpoint commit — do not leave the map dangling
  uncommitted. Commit message `tie: <run-id> <stage or W-n summary>` or the
  repo convention. Log `[커밋]` with the hash or the explicit no-commit
  reason — this step is never skipped silently: one of the two must be
  in `log.md` before the run may reach `complete`.
- **Staged planning loop-back**: when work remains and the next stage in
  `plan.md` holds only a goal line, dispatch Planner in `detail-stage`
  mode to detail it with the knowledge gained so far; if the next items
  are already detailed, go straight to `implement`.

## Reframe — step back before calling the user

Fix-budget exhaustion or the same failure twice means the FRAME is
probably wrong — plan direction, map understanding, a contradictory
requirement, or a lying environment — and more fixes inside that frame
will not converge. Before blocking, do what a person does: step back and
re-derive the problem. Set `step = "reframe"` and increment
`reframe_loops` (max 3 per verify cycle; resets with `fix_loops`).

1. **Dispatch fresh-context lens agents in parallel.** Use generic
   subagents — no TIE role contract; the lens brief below IS the
   contract. Contamination rule for ALL lenses: NEVER pass the run's
   causal hypotheses or the failed fixes' reasoning — a known-failed
   ACTION rules that action out, but a known-failed BELIEF anchors
   thinking to it. Disclosure is PER LENS, in priority order (drop from
   the bottom if the platform limits agents; with no subagent tooling
   at all, run one inline re-diagnosis from facts alone and log the
   degraded independence):
   - **redefine — fully blind**: gets the symptom plus absolute paths
     to `requirement.md` and `ARCHITECTURE.md` ONLY — not the attempt
     history, which leaks the old frame through the actions taken.
     Re-derives the problem from scratch; questions whether the failing
     C-n is even testable and the requirements mutually consistent.
     This lens guarantees the ensemble one uncontaminated eye.
   - **environment-skeptic — history included**: additionally gets what
     was tried and what happened (events, not interpretations; expected
     vs actual from `verification.md`) and the relevant code paths.
     Assumes the code is right and the world is lying: flaky tests,
     stale builds, caches, sandbox limits. Repeated-failure patterns
     are this lens's raw material — it cannot work blind.
   - **external — history included**: same facts; deep-searches known
     bugs, version quirks, and prior art — the exact error and the
     changes that did NOT help aim the search (skip and log if web
     access is unavailable).
2. **Synthesize** the lens reports, log `[재정의]` (lenses consulted,
   frames proposed, evidence, routing). Final dedup is yours, not the
   lenses': you hold the full history, so discard a blind lens's
   re-proposal of a frame already tried or ruled out — one wasted lens,
   not a failure. Then route on the outcome:
   - **New cause confirmed by evidence** → reset `fix_loops` to 0 and
     dispatch Implementer `fix` citing the confirmed cause. Renewal
     comes from independent evidence, never from the stuck context's
     self-assessment.
   - **User-shaped problem** (contradictory requirement, a trade-off
     only the user can choose) → block immediately; more agents cannot
     discover what the user wants.
   - **No new frame** (lenses only reproduce frames already tried or
     ruled out) → block immediately regardless of remaining reframe
     budget — repeating a non-converging reframe just relocates the
     endless loop somewhere more expensive.

A blocker reached through reframe must carry the distilled analysis:
frames tried, hypotheses ruled out, remaining options, recommendation.
Blockers should be rare, and every one that reaches the user should be a
genuinely user-shaped decision.

## Stop conditions

Stop for exactly one of these five: complete / user decision needed /
environment untrustworthy / repeated failure beyond limits /
risky-irreversible operation needs confirmation. Never stop because the
work feels long or "probably done".

On block: append `[블로커]` (why, options, recommendation, resume
condition), set `state.json.blocked = true` and `status` to `blocked`,
then give the user only the blocker, options, recommendation, and resume
command.

## Dispatch

Dispatching is the default, not an optimization: each role gets its own
context window, and the user invoking this workflow IS the delegation
request — never inline because the user "didn't explicitly ask for
subagents". Claude Code: dispatch bundled subagents `tie-planner`,
`tie-implementer`, `tie-verifier`. Codex CLI: `spawn_agent`/`wait_agent`
when `multi_agent = true`. Inline a role yourself ONLY when subagent
tooling is unavailable, and warn that context pressure is higher. See
bundled `references/tool-mapping.md` for platform tool names.

Pass every subagent (absolute paths only):

- role mode: `plan | detail-stage | implement | fix | verify | recheck`;
- run directory; paths to `requirement.md`, `plan.md`, `log.md`,
  `state.json`; `verification.md` for verifier and fix dispatches;
- `ARCHITECTURE.md` path or `none`;
- current stage / W-n scope; failed C-ns for fix/recheck.

Subagents use only these paths; they never infer state from root `.tie/`.
Reframe lens agents are the one exception to role dispatch: they are
generic subagents briefed per the Reframe section (facts only), not TIE
roles.

Ownership:

- **Orchestrator**: `active_run`, `state.json`, `requirement.md` (approval
  status, C-n checkboxes, 갱신 기록), in-run `ARCHITECTURE.md` updates,
  `.gitignore` rule, checkpoint commits.
- **Planner**: `plan.md` — structure and content, including staged detailing.
- **Implementer**: product code; `plan.md` checkbox states only.
- **Verifier**: `verification.md` (overwrite — latest verdict only).

`log.md` is the shared append-only journal; a role writing a file outside
its list must log why. Your entries: `[진행]` at step transitions (brief),
`[커밋]` hash or no-commit reason, `[재정의]` reframe synthesis,
`[블로커]`, `[복구]`.

## Complete

1. Promote durable `[실패접근]` log entries and newly discovered
   invariants into the `ARCHITECTURE.md` constitution. Routine progress
   never goes there.
2. Tick remaining bookkeeping you own: requirement.md C-n checkboxes,
   `state.json.status = "completed"`, `step = "complete"`. An unticked
   W-n in `plan.md` here is a red flag — remaining work, not bookkeeping:
   route it back through the state machine instead of ticking a
   Implementer-owned box.
3. Report as a short explainer — this is the run's closing sync back into
   the user's head, not a status dump:
   - run-id, verdict summary, commits or no-commit reason;
   - the before → after flow in the user's own language (what changed, not
     how);
   - the decisions made ON THE USER'S BEHALF — a short digest of the run's
     `[결정]` entries plus any `[제안]` recorded during the run but not acted
     on, so nothing the user would want a say in stays buried in `log.md`;
   - one or two verification steps the user can run themselves.
4. Offer — never force — a quick comprehension check: "want a 2–3 question
   quiz on what changed?" If the user accepts, ask 2–3 questions drawn from
   the C-n flows and the key decisions; for a wrong answer, point at the
   exact map section, `log.md` entry, or diff that explains it. This is a
   sync aid, not a gate — the run is already complete and declining changes
   nothing.

Keep it to flows and decisions, kept short; do not narrate the
step-by-step journey — `log.md` is for that.

## Safety

Never: modify files outside the project working directory; change
system/network configuration; run destructive git (`reset --hard`, force
push, `branch -D`) without explicit confirmation; read, log, or commit
secrets; declare complete without a Verifier `pass`; proceed past risky
or irreversible steps without explicit user OK. In each case, stop as
blocked.

## Hard rules

1. Files first — read before deciding, write after every step.
2. No `plan` before approval; no completion without Verifier `pass`.
3. Delegate all product implementation.
4. Map before repo scan; pass the map path, never let roles re-scan.
5. Stop only on one of the five conditions.
