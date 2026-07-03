---
description: Resume the active ThisIsEnough run from its recorded state. Continues from state.json's step; never starts a new run or a draft.
---

Invoke the `tie:resume` skill now and follow it exactly.

Resolve the run through `.tie/active_run` (a workspace-relative pointer
`runs/<run-id>`, resolved as `.tie/<pointer>`), read `state.json` for the
current `step` and `owner`, read the last `log.md` entry for context, then
continue from that step. If `state.json` and the artifacts disagree,
`state.json` is the machine-state baseline; log the mismatch as `[복구]` and
correct it.

If the user provided text after the command (`$ARGUMENTS`):

- If the run is blocked, treat it as the answer to the open blocker recorded
  in `log.md`; resolve it and continue from the interrupted step.
- Otherwise — when the run is not `completed` and the text is not a draft
  path — treat it as an added agreement or context: append it to the run's
  `requirement.md` under `## 갱신 기록` with an ISO timestamp before
  continuing. A `completed` run never gets appends (new text is a new
  requirement — point at `/tie:start`), and draft paths are never promoted
  from resume.

If `.tie/active_run` is missing or points at a run without `state.json`, this
is not a resume. Say there is nothing to resume here and suggest
`/tie:start <requirement>`. Never start a new run or a draft from this command.
