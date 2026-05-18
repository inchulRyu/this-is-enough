# Validation Plan

<!-- Concrete validation plan for high profile, or for standard only when a
separate plan is clearer than inline grouped checks. Prefer grouped EV-IDs by
risk area. Put related sub-assertions under one EV-ID instead of making a new
EV-ID for every field, route, or source line. -->

## Scope

Evaluate Phase <n>: <phase name>

## Inputs reviewed

- requirement.md
- roadmap.md
- phase.md
- plan.md
- tasks.md
- implementation_log.md

## Selected validation level

L0_static_review | L1_static_plus_build | L2_unit_or_integration | L3_runtime_scenario | L4_e2e_or_system | L5_reference_or_benchmark

## Selected validation profile

standard | high

Validation intent used: yes | no

## Why this profile and level are appropriate

- ...

## Test oracle / success source

- Product acceptance intent: ...
- Existing tests: ...
- Reference behavior: ...
- Manual scenario: ...
- Quantitative threshold: ...

## Validation checks

### EV-001: Requirement and acceptance coverage
Method: static review
Related requirements:
- RQ-001
Expected:
- <all must-have requirements and acceptance intent are covered>

### EV-002: Product behavior / runtime scenario
Method: runtime | test | code review | e2e | benchmark
Related plan sections:
- ...
Expected:
- <observable behavior; include related sub-assertions here if they share the
  same method/risk>

### EV-003: Integration quality
Method: code review / integration test
Expected:
- ...

### EV-004: Code quality and maintainability
Method: code review
Expected:
- ...
