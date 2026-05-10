---
name: requirements
description: Use when the user wants help shaping, clarifying, refining, or drafting a ThisIsEnough requirement before starting implementation. Creates or updates pre-run requirement drafts under agents_workspace/drafts/.../requirement.md without creating active_run, runs, roadmap, or implementation work.
---

# tie:requirements — pre-run requirement drafting

The user is preparing a requirement, not starting an implementation run. Turn
their idea, conversation, or rough scope into a `requirement.md` that can later
be handed to `tie:orchestrator`.

## Core Rule

`agents_workspace/drafts/` contains only requirements whose implementation has
not started. `agents_workspace/runs/` contains requirements whose implementation
has started or completed.

Do not create, update, or delete `agents_workspace/active_run`. Do not create
`agents_workspace/runs/`, `run_state.json`, `roadmap.md`, `current_state.md`,
phase files, or implementation artifacts. Do not dispatch Planner, Generator, or
Evaluator.

## Draft Location

Store each draft here:

```text
agents_workspace/
  drafts/
    <draft-id>/
      requirement.md
```

Generate `draft-id` as `YYYY-MM-DD-NNN-<short-slug>` using the current local
date, the next non-conflicting sequence for that date across both
`agents_workspace/drafts/` and `agents_workspace/runs/`, and a short slug from
the requirement. Promoted drafts are deleted, so checking `runs/` prevents
reusing a draft id that may already be referenced by a run changelog.

If the user references an existing draft path or draft id, update that draft. If
the user asks to continue "the draft" and exactly one draft exists, use it. If
multiple drafts exist and no target is clear, ask which draft to update.

Before updating any existing draft path, apply the same safety checks used for
promotion: the path must be relative, must not contain `..`, must not use a
symlink escape, must resolve under `agents_workspace/drafts/`, must have exactly
one draft-id directory between `drafts/` and `requirement.md`, and must be named
`requirement.md`. Reject anything else instead of treating it as a draft.

## Workflow

1. Understand the user's goal and any relevant conversation context.
2. Read lightweight repo context only when needed to understand product
   boundaries. Avoid deep implementation planning.
3. Ensure the default volatile-state `.gitignore` rules exist:
   `agents_workspace/drafts/`, `agents_workspace/runs/`, and
   `agents_workspace/active_run`. Do not ignore `agents_workspace/` itself; if
   a broad `agents_workspace/` ignore rule already exists, replace it with the
   three volatile-state rules unless the user explicitly wants no workflow files
   committed.
4. Create or update `agents_workspace/drafts/<draft-id>/requirement.md`.
5. Ask only load-bearing questions. Do not interview the user for details that a
   reasonable default, Planner, or Generator can handle later.
6. Finish with the draft path and readiness. Include unresolved questions if the
   draft is not ready. Include the handoff command only when no unresolved
   load-bearing questions remain.

## Question Policy

Do not cap the number of questions. Instead, require every question to pass the
load-bearing test.

Ask when the answer:

- Changes the product direction or scope materially.
- Changes roadmap phase boundaries.
- Is required to define observable success or evaluation criteria.
- Involves safety, data deletion, deployment, auth, permissions, cost, secrets,
  or irreversible side effects.
- Cannot be reasonably defaulted without a meaningful risk of violating user
  intent.

Do not ask about:

- Function names, file layout, minor library choices, copy text, spacing, colors,
  or ordinary implementation details.
- Edge cases that can be captured as assumptions or deferred to Planner.
- Nice-to-have scope expansion.

When asking, group questions by decision area and briefly state why the decision
is needed now. Offer a recommended default when there is a sensible one.

## Draft Format

Use the same format as the runtime's run-level `requirement.md` so handoff is a
simple copy:

```md
# Requirement

## User Request

<original user request or summarized request>

## Clarified Requirements

### RQ-001: <title>
Description:
- ...

Priority: must | should | could
Source: user | orchestrator_inferred | clarified

## Open Questions

- None

## Non-goals

- ...

## Assumptions

- A-001: ...

## Safety / Risk Notes

- ...

## Updates

- None yet.
```

Keep the draft product-level. Do not create a roadmap, task list, validation
matrix, implementation plan, or command transcript. If an uncertainty is not
load-bearing, record it under `Assumptions`, `Non-goals`, or the relevant RQ
description instead of asking.

## Handoff

When the draft has no unresolved load-bearing questions, tell the user how to
start from it:

```text
Claude Code: /tie:start from draft agents_workspace/drafts/<draft-id>/requirement.md
Codex CLI:   $tie:orchestrator Start from draft agents_workspace/drafts/<draft-id>/requirement.md
```

The orchestrator owns promotion. During promotion it copies the draft
`requirement.md` into a new run, verifies the run copy, then removes the draft
directory only when that directory contains exactly `requirement.md`. After
that, the run's `requirement.md` is the source of truth.

Do not promote or delete drafts from this skill.
