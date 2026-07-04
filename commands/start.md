---
description: Start a ThisIsEnough run from an approved draft or a raw requirement. Hands off to the orchestrator, which owns run creation and draft promotion.
---

The user is starting a ThisIsEnough workflow run.

Their input is: $ARGUMENTS

Invoke the `tie:orchestrator` skill now and follow it exactly.

Classify `$ARGUMENTS` first:

- A path of the form `.tie/drafts/<draft-id>.md` is a draft start. This command
  layer must not read, copy, or delete the draft; pass the path to the
  orchestrator, which owns the entire promotion sequence (copy → verify →
  active_run → delete draft).
- Anything else is a raw requirement — or, if the active run is `in_progress`
  or `blocked`, an update to that run: the orchestrator appends it to the run's
  `requirement.md` under `## 갱신 기록` instead of creating a second run.

Resolve the active run through `.tie/active_run`; its content is a
workspace-relative pointer `runs/<run-id>`, resolved as `.tie/<pointer>`.

Two gates are never skipped, even for raw requirements: no implementation
before the requirement's `## 승인` says `승인됨` (the core checklist confirmed
once with the user), and no completion without a Verifier `pass`.
