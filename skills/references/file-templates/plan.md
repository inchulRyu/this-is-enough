# Plan

<!-- Keep this product-level and proportionate. Do not paste schemas, route
tables, test matrices, or task lists when they can be referenced from
requirement.md, decisions.md, or code. -->

## Requirement coverage

- RQ-001: <briefly describe how this plan reflects it>
- RQ-002: <how this plan reflects it>

## Feature summary

<product-level summary>

## Product context

<why this feature/change belongs in the current product>

## Why this should not be under-scoped

<the most important things that would likely be missed if Generator implemented
only the raw request>

## Expanded product spec

### User-facing behavior

- ...

### Main interaction flow

1. ...
2. ...
3. ...

### Functional depth

- <behavioral depth and user-visible/system guarantees; avoid enumerating every
  field/function/test>

### Edge cases / empty states / failure states

- ...

### Consistency expectations

- ...

## High-level technical design

- <direction and integration points only; leave exact file/function boundaries
  to Generator unless fixed by requirement.md or decisions>

## Implementation freedom left for Generator

The Generator should decide:
- exact file structure
- exact component/function boundaries
- exact data fetching mechanism
- exact test implementation
- repo-specific integration details

## Validation sizing

Recommended validation profile: compact | standard | high | system

Why this profile is proportionate:
- <phase risk/blast radius and why this does not need a heavier or lighter profile>

Validation notes:
- <success oracle or risk area for Evaluator; do not write EV-IDs or test matrix>

## Constraints and edge considerations

- ...

## Out of scope

- ...

## Acceptance intent

This phase should feel complete when:
- ...
