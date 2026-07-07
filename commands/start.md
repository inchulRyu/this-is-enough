---
description: Run an approved-checklist ThisIsEnough workflow end-to-end (plan → implement → verify → map update → checkpoint), stopping only on a real blocker or completion.
argument-hint: '[requirement, or: Start from draft .tie/drafts/<draft-id>.md]'
disable-model-invocation: true
---

Load and follow the ThisIsEnough **tie:start** skill for this repository, acting as the workflow Orchestrator. Use only that skill's instructions, the run files, its bundled references, and explicit user input.

Treat everything below as the requirement or run instruction the user passed in (it may be empty, a free-form requirement, or an approved-draft pointer such as `Start from draft .tie/drafts/<draft-id>.md`):

$ARGUMENTS
