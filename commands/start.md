---
description: Start a new ThisIsEnough autonomous workflow run for the requirement that follows. Bootstraps agents_workspace/ and hands off to the orchestrator.
---

The user is starting a new ThisIsEnough workflow.

Their requirement is: $ARGUMENTS

Invoke the `tie:orchestrator` skill now and follow it exactly. Treat the
requirement above as the initial user request for intake. Do not start
implementing anything before the orchestrator's intake → clarify → roadmap
flow has produced `agents_workspace/requirements.md` and `roadmap.md`.

If `agents_workspace/run_state.json` already exists in the current working
directory, do NOT re-bootstrap — instead invoke `tie:resume` and treat
"$ARGUMENTS" as the user's update for the resumed conversation.
