# Evaluation Report

<!-- Latest verdict. Keep passed evidence concise; write detail for failures,
blockers, surprising results, and high-risk checks only. In standard profile,
this report contains the grouped checks and completion audit. In high profile,
link validation_plan.md when a separate plan was useful. Detailed timing and
command/check durations belong in telemetry.jsonl. -->

Verdict: pass | fail | blocked
Validation profile used: standard | high
Validation level used: L0 | L1 | L2 | L3 | L4 | L5
Validation intent used: yes | no
Validation plan: inline | validation_plan.md
Fix loop count: <N>
Failed EV-IDs seen: none | EV-001, EV-002

## Summary

<short summary>

## Completion audit

| Requirement / acceptance item | Artifact or behavior inspected | Evidence | Result |
| ----------------------------- | ------------------------------ | -------- | ------ |
| RQ-001 | <file/path or behavior> | <command/output/review/runtime evidence> | pass |
| RQ-002 | <file/path or behavior> | <evidence> | fail |

## Validation checks

<!-- Group related assertions by risk area. -->

| EV-ID | Method | Covers | Expected | Result | Evidence |
| ----- | ------ | ------ | -------- | ------ | -------- |
| EV-001 | static review | RQ-001 | <expected behavior> | pass | <one-line evidence> |
| EV-002 | command/runtime/manual | <plan section> | <expected behavior> | fail | <one-line evidence> |

## Passed checks

- EV-001: <one-line evidence>
- EV-002: ...

## Notable evidence

- <only high-risk or non-obvious pass evidence; omit routine command output>

## Failed checks

### EV-003: <title>
Severity: critical | major | minor
Related requirements:
- RQ-002
Related tasks:
- G-004

Expected:
- ...

Actual:
- ...

Why it matters:
- ...

Concrete next action for Generator:
- ...

## Blockers

- None

## Recheck required

- EV-003
- EV-004
