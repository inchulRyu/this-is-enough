# Validation Intent

<!-- Optional preflight guidance only. Create this file only when general risk
conditions justify it. Do not assign an exhaustive EV-ID matrix here; save
concrete EV-IDs for validation_plan.md after implementation exists. -->

## Phase

<phase name>

## Recommended validation level

L0_static_review | L1_static_plus_build | L2_unit_or_integration | L3_runtime_scenario | L4_e2e_or_system | L5_reference_or_benchmark

## Recommended validation profile

standard | high | system

<!-- If the appropriate profile is compact, do not create validation_intent.md. -->

## Intent trigger

- <general risk condition that makes preflight useful: blast radius, data risk,
  security/privacy, external system, ambiguous oracle, benchmark/parity, etc.>

## Why this profile and level are appropriate

- ...

## Representative validation checks

- <risk area>: <method and expected confidence>

## Areas Generator should be careful about

- ...

## Test oracle / success source

- Existing test suite: ...
- Reference behavior: ...
- Product acceptance criteria: ...
- Manual scenario: ...
- Quantitative threshold: ...
