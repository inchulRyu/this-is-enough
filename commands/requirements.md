---
description: Draft or refine a ThisIsEnough requirement 명세 before starting a run. Writes a single draft file under .tie/drafts/; never creates runs or active_run.
---

The user wants help drafting a ThisIsEnough requirement 명세 before
implementation.

Their input is: $ARGUMENTS

Invoke the `tie:requirements` skill now and follow it exactly. This command is
drafting only: converse, sync the user's mental model with the current system
flow (reading ARCHITECTURE.md if present), and keep the draft updated live —
every agreement (A-n) and checklist item (C-n) is written into the draft the
moment it is made, never left only in conversation.

The only files this flow may write are a single draft file
`.tie/drafts/<draft-id>.md` and, when needed, the `.gitignore` rule `.tie/`.
Do not create or modify `.tie/active_run`, do not create anything under
`.tie/runs/`, and do not start or resume a run.

When the skill uses bundled templates, resolve bundled reference paths relative
to the installed ThisIsEnough skills bundle, not the user's project working
directory.
