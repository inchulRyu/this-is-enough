# Evaluation Report

<!-- Latest verdict. Keep passed evidence compact; write detail for failures,
blockers, surprising results, and high-risk checks only.

For compact profile, this report is both validation plan and result: include
the grouped checks, method, expected behavior, result, and evidence below.
For standard/high/system, keep detailed check definitions in validation_plan.md
and summarize results here. -->

Verdict: pass | fail | blocked
Validation profile used: compact | standard | high | system
Validation level used: L0 | L1 | L2 | L3 | L4 | L5
Compact mode: yes | no
Validation intent used: yes | no
Validation plan: inline | validation_plan.md
Fix loop count: <N>
Failed EV-IDs seen: none | EV-001, EV-002

## Summary

<short summary>

## Validation checks

<!-- Required for compact mode; optional summary for other profiles. -->

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
