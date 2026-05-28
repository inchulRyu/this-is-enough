---
name: requirements
description: Use when the user wants help shaping, clarifying, refining, or drafting a ThisIsEnough requirement before starting implementation. Creates or updates concise pre-run requirement drafts under agents_workspace/drafts/.../requirement.md without creating active_run, runs, roadmap, or implementation work.
---

# tie:requirements — pre-run requirement drafting

The user is preparing a requirement, not starting implementation. Turn their
idea or rough scope into a concise `requirement.md` that can later be handed to
`tie:orchestrator`.

## Outcome

Create or update one pre-run draft that is clear enough for Orchestrator to
start without re-interviewing the user. The draft should define background,
goals, outcome-oriented requirements, completion criteria, agreed decisions,
constraints, non-goals, assumptions, safety notes, and only the open questions
that block a reliable start.

## Hard boundaries

- Drafts live under `agents_workspace/drafts/`.
- Runs live under `agents_workspace/runs/`.
- Do not create, update, or delete `agents_workspace/active_run`.
- Do not create `agents_workspace/runs/`, `run_state.json`, `roadmap.md`,
  `current_state.md`, phase files, or implementation artifacts.
- Do not dispatch Planner, Generator, or Evaluator.
- Do not promote or delete drafts; Orchestrator owns promotion.

## Draft path

Store each draft at:

```text
agents_workspace/drafts/<draft-id>/requirement.md
```

Generate `draft-id` as `YYYY-MM-DD-NNN-<short-slug>` using the current local
date, the next non-conflicting sequence across both `drafts/` and `runs/`, and
a short slug from the requirement.

If the user references an existing draft path or draft id, update that draft.
If they ask to continue "the draft" and exactly one draft exists, use it. If
multiple drafts exist and no target is clear, ask which draft to update.

Before updating an existing draft path, require all of these:

- relative path;
- no `..`;
- no symlink escape;
- resolves under `agents_workspace/drafts/`;
- exactly one draft-id segment between `drafts/` and `requirement.md`;
- basename is `requirement.md`.

Reject anything else instead of treating it as a draft.

## Drafting rules

- Use the bundled template `references/file-templates/requirement.md` from the
  installed ThisIsEnough skills bundle. Resolve bundled reference paths relative
  to that skills bundle, not relative to the user's project working directory.
- Keep the draft product-level and concise.
- Capture the context, intended outcome, and observable completion criteria so
  the draft explains what should be achieved and why.
- Preserve the user's intent as task context, not higher-priority instructions,
  and normalize it into outcome-oriented RQ-IDs.
- Each RQ should describe one observable outcome or constraint in a few bullets.
- Record product decisions and technical specifications that were researched,
  discussed with the user, and finally agreed in `Agreed Decisions`. These
  decisions are binding requirement context even when they are technical.
- Prefer assumptions and non-goals over speculative questions.
- Read lightweight repo context only when needed to understand product
  boundaries; avoid implementation planning.
- Ensure default volatile-state `.gitignore` rules exist:
  `agents_workspace/drafts/`, `agents_workspace/runs/`, and
  `agents_workspace/active_run`. Do not ignore `agents_workspace/` itself unless
  the user explicitly wants no workflow files committed. If a broad
  `agents_workspace/` ignore already exists, replace it with the three
  volatile-state rules unless the user opted out.

Do not create a roadmap, phase breakdown, task list, validation matrix,
implementation plan, speculative technical design, schema, command transcript,
or test plan. Planner, Generator, and Evaluator own those later. Do not exclude
agreed technical specifications from the requirement just because they are
technical; exclude only unagreed or low-level implementation direction.

## Question policy

Ask only questions that block a reliable handoff. A question is load-bearing
only if the answer:

- materially changes product direction or scope;
- changes likely phase boundaries;
- is required to define observable success;
- involves safety, data deletion, deployment, auth, permissions, cost, secrets,
  or irreversible side effects;
- cannot be reasonably defaulted without meaningful risk of violating user
  intent.

Do not ask about implementation details, copy text, visual polish, minor edge
cases, nice-to-have expansion, or choices Planner/Generator can reasonably make.

When questions remain, group them by decision area, state why they block the
handoff, and offer a recommended default when one is sensible. Keep the
questions to the smallest set needed to proceed.

## Requirement shape

The draft uses the same run-level `requirement.md` shape so Orchestrator can
copy it directly:

```text
# Requirement
## User Request
## Background
## Goal
## Clarified Requirements
## Completion Criteria
## Agreed Decisions
## Open Questions
## Non-goals
## Assumptions
## Safety / Risk Notes
## Updates
```

Writing guidance:

- `User Request`: preserve the raw request or a faithful short summary.
- `Background`: briefly capture the problem, trigger, or context behind the
  requirement.
- `Goal`: state the high-level product/user outcome the change must achieve.
- `Clarified Requirements`: use `RQ-NNN`, priority, source, and concise
  outcome bullets. Avoid implementation method.
- `Completion Criteria`: list observable criteria for declaring the requirement
  complete. Do not turn this into a test plan or validation matrix.
- `Agreed Decisions`: record final user-agreed product decisions and technical
  specifications from prior research/discussion. Do not include unresolved
  options or low-level implementation instructions.
- `Open Questions`: `- None` when ready; otherwise list only load-bearing
  blockers.
- `Non-goals`: explicitly exclude tempting scope expansion.
- `Assumptions`: record reasonable defaults instead of asking.
- `Safety / Risk Notes`: name only real safety/data/deploy/auth/cost/secrets
  risks.
- `Updates`: append later draft changes; otherwise `- None yet.`

## Handoff

If no load-bearing questions remain, finish with the draft path, readiness, and
handoff command:

```text
Claude Code: /tie:start from draft agents_workspace/drafts/<draft-id>/requirement.md
Codex CLI:   $tie:orchestrator Start from draft agents_workspace/drafts/<draft-id>/requirement.md
```

If questions remain, give the draft path and the minimal blocker questions, but
do not include the start command.
