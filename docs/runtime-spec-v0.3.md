# Agent Orchestrator Workflow Runtime Spec v0.3

## 0. Purpose

이 문서는 장기 실행형 에이전트 오케스트레이터를 만들기 위한 워크플로우 런타임 명세다.

이 명세의 목표는 단순히 Planner / Generator / Evaluator의 역할을 설명하는 것이 아니라, 에이전트가 사용자의 요구사항을 제품적으로 충분한 작업 단위로 확장하고, 구현하고, 검증하고, 중간에 중단되더라도 파일 기반 상태를 통해 안정적으로 재개할 수 있게 하는 것이다.

핵심 철학은 다음과 같다.

> Agent memory is temporary. Files are the source of truth.
>
> 에이전트의 내부 기억은 보조 캐시일 뿐이며, 실제 진행 상태와 판단의 기준은 항상 파일에 기록된 내용이다.

---

## 1. Core Principles

### 1.1 File-first execution

모든 주요 상태, 판단, 결정, 진행 상황, 검증 결과는 파일로 남겨야 한다.

에이전트가 어떤 판단을 했더라도 파일에 기록되지 않았다면, 그 판단은 존재하지 않는 것으로 간주한다.

> Not written, not remembered.

### 1.2 Orchestrator owns the workflow

오케스트레이터는 별도 서브에이전트라기보다 메인 에이전트 또는 런타임 컨트롤러가 맡는 역할이다.

오케스트레이터는 다음을 책임진다.

- 요구사항 정리
- 필수 모호성 해소
- Roadmap 생성
- 현재 Phase 선택
- 다음 owner 결정
- 파일 상태 갱신
- 중단 / 재개 판단
- blocked 상태 관리
- 전체 완료 판단

오케스트레이터는 직접 구현을 수행하지 않는다. 구현은 Generator가 맡는다.

### 1.3 Planner prevents under-scoping by expanding raw requirements into rich product-level specs

Planner의 핵심 역할은 사용자의 raw requirement를 단순히 정리하거나 task list로 바꾸는 것이 아니다.

Planner는 짧거나 불완전한 사용자 요구사항을 제품적으로 충분히 풍부한 product-level spec으로 확장한다. 이 역할이 필요한 이유는, Planner 없이 Generator가 raw prompt를 바로 구현하기 시작하면 작업 범위를 너무 작게 잡고, 먼저 spec을 잡지 못한 채 덜 feature-rich하고 덜 완성도 있는 결과물을 만들 가능성이 높기 때문이다.

따라서 Planner는 다음을 수행한다.

- raw request가 암시하는 제품적 의미를 해석한다.
- 사용자가 기대할 만한 완성된 경험을 구체화한다.
- “최소 구현”이 아니라 “제품 기능으로서 충분히 완성됐다고 느껴지는 기준”을 정의한다.
- 기능이 기존 제품 맥락 안에서 어떻게 맞물려야 하는지 설명한다.
- user-facing behavior, interaction flow, edge case, empty state, failure state, consistency expectation을 명확히 한다.
- high-level technical design과 integration direction을 제시한다.
- 각 Plan 항목이 어떤 Requirement를 반영하는지 명시한다.

Planner는 요구사항을 제품적으로 충분히 풍부한 product-level spec으로 확장해야 한다. 다만 이것은 무제한적인 scope expansion이나 implementation detail expansion을 의미하지 않는다. Plan은 Generator가 under-scope하지 않게 만드는 제품/행동 기준이지, 구현 설계서, task list, test matrix, 감사 로그가 아니다.

Planner의 확장은 다음 범위 안에서 이루어져야 한다.

- product context
- user-facing behavior
- main interaction flow
- functional depth
- high-level UX / design implication
- high-level technical design
- acceptance intent
- validation-relevant expectations

Planner는 다음을 피해야 한다.

- 사용자가 원하지 않은 별도 제품으로 키우기
- unrelated feature를 추가해 plan을 부풀리기
- requirements, decisions, code에 이미 canonical하게 있는 세부사항을 줄 단위로 복제하기
- schema, route table, test case, command transcript를 Plan 안에 장황하게 열거하기
- repo를 보지 않고 low-level architecture를 단정하기
- 구현 라이브러리, 함수 구조, DB schema, 파일 구조를 너무 일찍 고정하기
- Generator가 repo 맥락에서 판단해야 할 implementation path를 빼앗기

핵심 원칙은 다음과 같다.

> Planner should make the work richer at the product/spec level, not more rigid at the implementation level.

즉 Planner는 feature-rich하게 확장하되, implementation-rigid하게 만들면 안 된다.

### 1.4 Planner avoids premature granular implementation detail

Planner는 high-level product spec과 high-level technical design을 작성하지만, granular implementation detail을 너무 일찍 고정하지 않는다.

초기 기술 디테일이 틀리면 downstream implementation 전체에 오류가 전파될 수 있다. 따라서 Planner는 무엇을 만들어야 하는지와 어떤 결과물이 나와야 하는지는 분명히 하되, 구체적인 구현 경로와 세부 기술 선택은 Generator가 현재 repo 맥락에서 판단할 수 있게 남겨둔다.

Planner가 명시해도 되는 것:

- 어떤 사용자 흐름이 완성되어야 하는가
- 어떤 상태나 데이터 흐름이 제품적으로 필요해 보이는가
- 기존 시스템과 어떤 수준으로 통합되어야 하는가
- 어떤 edge case가 제품 경험상 중요해 보이는가
- 어떤 품질 기준을 만족해야 하는가

Planner가 불필요하게 확정하면 안 되는 것:

- 특정 함수명
- 특정 파일명
- 구체적인 component tree
- 구체적인 DB schema
- 구체적인 library choice
- 구체적인 API implementation detail
- repo를 확인하지 않은 세부 architecture

### 1.5 Generator owns implementation judgment

Generator는 Planner의 Plan과 원 Requirement를 함께 읽고, 실제 repo 맥락에서 구현 가능한 Task로 분해한다.

Generator는 Plan이 말하는 “무엇을 만들 것인가”와 Requirement가 말하는 “왜 필요한가”를 함께 이해해야 한다.

Generator는 Planner가 일부러 남겨둔 구현 여지를 다음 기준으로 판단한다.

- 현재 repo 구조
- 기존 architecture
- 기존 naming convention
- 기존 data flow
- 기존 state management pattern
- 테스트 환경
- 유지보수성
- 변경 범위 대비 복잡도

Generator는 단순히 코드 조각을 추가하는 것이 아니라, 프론트엔드, 백엔드, 상태, 데이터 흐름, 테스트, 기존 UX와의 통합을 함께 고려해야 한다.

### 1.6 Evaluator is adaptive, not fixed

Evaluator는 무조건 Playwright, 무조건 E2E, 무조건 end-stage review를 수행하는 고정 검증자가 아니다.

Evaluator는 Requirement, Plan, Task, repo 특성, 변경 범위, 위험도를 읽고 이번 Phase에 적절한 검증 전략을 설계한다.

검증 방식은 상황에 따라 다음 중 하나 또는 조합이 될 수 있다.

- 정적 코드 리뷰
- 요구사항 coverage 확인
- 타입체크 / lint / build
- unit test
- integration test
- API test
- DB 상태 확인
- runtime manual scenario check
- browser / Playwright / E2E check
- benchmark / reference oracle 비교
- regression test

Evaluator의 핵심 역할은 “마지막에 눌러보는 사람”이 아니라, 현재 작업에 맞는 검증 기준과 검증 강도를 설계하고, 제품 레벨에서 정말 완료되었는지 판단하는 것이다.

### 1.7 No premature completion

에이전트는 작업이 대충 된 것처럼 보인다는 이유로 완료를 선언하면 안 된다.

완료는 다음 조건을 만족해야 한다.

- 해당 Phase의 Milestone 충족
- Plan의 acceptance intent 충족
- 관련 Requirements coverage 충족
- Generator self-check 완료
- Evaluator verdict가 pass
- Known critical issue 없음
- 현재 상태 파일 갱신 완료

### 1.8 Workflow documents are navigation aids

`agents_workspace/` 문서는 재개와 판단을 위한 source of truth이지만, 코드 diff,
전체 테스트 출력, 구현 설계서, 검증 감사 로그를 복제하는 장소가 아니다.

각 파일은 자신의 역할 안에서 필요한 정보만 담아야 한다.

- `plan.md`는 제품 수준의 의도와 완료 기준을 담는다. 구현 상세, task list,
  test matrix는 담지 않는다.
- `tasks.md`는 구현 작업을 추적한다. Plan의 세부 문장을 반복하지 않는다.
- `implementation_log.md`는 변경 요약과 검증 요약을 남긴다. diff, 코드 블록,
  command transcript를 붙이지 않는다.
- `generator_self_check.md`는 평가 준비 상태를 요약한다. Evaluator의 EV-ID별
  판정을 미리 복제하지 않는다.
- `validation_intent.md`는 preflight guidance다. exhaustive EV-ID matrix가
  아니라 검증 수준, 주요 위험, 대표 체크를 담는다.
- `validation_plan.md`는 실제 검증 계획이다. 관련 assertion은 risk area별
  grouped EV-ID 아래에 묶는다.
- `evaluation_report.md`는 최신 공식 판정이다. 통과한 일반 체크는 compact하게,
  실패/blocked/고위험/놀라운 결과는 자세히 쓴다.
- `evaluation_history.md`는 full report 복사본이 아니라 각 평가 run의 짧은
  snapshot이다.

핵심 원칙은 다음과 같다.

> Write enough for the next agent to decide and resume; do not duplicate the
> repo, the diff, or another workflow file.

### 1.9 Stop only when necessary

기본 원칙은 Roadmap의 모든 Phase가 완료될 때까지 계속 진행하는 것이다.

다만 다음 경우에는 반드시 멈추고 blocked 상태로 전환한다.

- 사용자 결정 없이는 방향이 갈리는 핵심 선택이 필요한 경우
- 현재 정보만으로 진행하면 잘못된 구현 가능성이 매우 높은 경우
- repo 상태가 손상되었거나 테스트/빌드 환경 자체가 신뢰 불가능한 경우
- 같은 Evaluation failure가 반복되어 Generator가 자율적으로 해결하지 못하는 경우
- 사용자 데이터, 보안, 배포, 결제, 삭제 등 위험한 작업이 포함된 경우

---

## 2. Terminology

### Requirement

사용자의 원래 요구사항 또는 초기 정리 과정에서 확정된 필수 조건이다.

각 Requirement는 고유 ID를 가진다.

예:

- RQ-001
- RQ-002
- RQ-003

### Roadmap

전체 작업을 어떤 큰 흐름으로 나눌지에 대한 상위 구조다.

Roadmap은 여러 Phase로 구성된다.

### Phase

Roadmap 안에서 순차적으로 진행되는 주요 작업 단위다.

Phase는 “챕터”처럼 이해할 수 있지만, 시스템 용어로는 Phase를 사용한다.

Phase는 너무 작을 필요는 없다. Sprint처럼 고정된 작은 단위가 아니라, 요구사항을 추적하고 검증 가능한 논리적 작업 구간이다.

### Milestone

각 Phase가 완료되었다고 판단하는 기준이다.

Milestone은 제품 레벨의 완료감을 설명해야 한다.

### Plan

Planner가 작성하는 Phase별 풍부한 product-level spec이다.

Plan은 Requirement를 더 구체적이고 제품적인 형태로 확장한다. Plan의 목적은 Generator가 raw request만 보고 under-scope하지 않도록, 제품적으로 충분한 기능 깊이와 완료 기준을 제공하는 것이다.

Plan은 저수준 구현을 불필요하게 고정하지 않는다.

### Task

Generator가 Plan을 실제 구현 가능한 작업 단위로 나눈 것이다.

Task는 Plan section과 Requirement ID를 참조해야 한다.

Task는 Plan을 복제하지 않는다. Generator는 관련 behavior와 acceptance intent를
구현하기 쉬운 작업 단위로 묶고, 각 task에는 concrete work와 completion
evidence만 기록한다. Plan의 모든 bullet마다 task를 만들거나, Plan의 schema /
test / route detail을 task마다 다시 붙이면 안 된다.

### Validation Intent

구현 전에 필요할 경우 Evaluator가 작성하는 가벼운 사전 검증 방향이다.

항상 필수는 아니며, 복잡하거나 위험도가 높은 Phase에서 사용한다.

### Validation Plan

Evaluator가 구현 결과를 검증하기 위해 작성하는 구체적인 검증 계획이다.

### Evaluation Report

Evaluator가 검증 결과를 pass / fail / blocked로 정리한 최신 보고서다.

---

## 3. Directory Structure

기본 구조는 다음과 같다.

```text
agents_workspace/
  requirements.md
  roadmap.md
  current_state.md
  run_state.json
  decisions.md
  changelog.md
  blockers.md

  phases/
    01-phase-name/
      phase.md
      plan.md
      tasks.md
      validation_intent.md
      implementation_log.md
      generator_self_check.md
      validation_plan.md
      evaluation_report.md
      evaluation_history.md
```

### 3.1 Minimal mode

작은 프로젝트에서는 아래 최소 구조로 시작할 수 있다.

```text
agents_workspace/
  requirements.md
  roadmap.md
  current_state.md
  decisions.md
  changelog.md

  phases/
    01-phase-name/
      phase.md
      plan.md
      tasks.md
      validation_plan.md
      evaluation_report.md
```

### 3.2 Full mode

장기 실행, 재개 가능성, 반복 검증이 중요한 프로젝트에서는 full structure를 사용한다.

```text
agents_workspace/
  requirements.md
  roadmap.md
  current_state.md
  run_state.json
  decisions.md
  changelog.md
  blockers.md

  phases/
    01-phase-name/
      phase.md
      plan.md
      tasks.md
      validation_intent.md
      implementation_log.md
      generator_self_check.md
      validation_plan.md
      evaluation_report.md
      evaluation_history.md
```

---

## 4. File Ownership Rules

파일 소유권은 다음과 같이 나눈다.

```text
Orchestrator
- requirements.md
- roadmap.md
- current_state.md
- run_state.json
- decisions.md
- blockers.md
- changelog.md
- phases/*/phase.md

Planner
- phases/*/plan.md

Generator
- phases/*/tasks.md
- phases/*/implementation_log.md
- phases/*/generator_self_check.md

Evaluator
- phases/*/validation_intent.md
- phases/*/validation_plan.md
- phases/*/evaluation_report.md
- phases/*/evaluation_history.md
```

### 4.1 Write rules

- 각 에이전트는 자신이 소유한 파일을 주로 수정한다.
- 다른 에이전트가 소유한 파일을 수정해야 할 경우, 이유를 `changelog.md` 또는 해당 phase log에 기록한다.
- `current_state.md`와 `run_state.json`은 오케스트레이터만 최종 갱신한다.
- `decisions.md`, `changelog.md`, `blockers.md`, `evaluation_history.md`는 append-only에 가깝게 운용한다.
- `evaluation_report.md`는 최신 평가 결과로 덮어쓴다.
- `evaluation_history.md`에는 모든 평가 run의 짧은 snapshot을 누적한다. full report를 복제하지 않는다.

---

## 5. State Enums

### 5.1 Project status

```text
not_started
in_progress
blocked
completed
aborted
```

### 5.2 Phase status

```text
pending
planning
planned
decomposing
decomposed
implementing
self_checking
validation_planning
evaluating
fixing
passed
blocked
skipped
```

### 5.3 Task status

```text
pending
in_progress
completed
skipped
blocked
needs_revision
```

### 5.4 Evaluation verdict

```text
pass
fail
blocked
not_run
```

### 5.5 Validation level

```text
L0_static_review
L1_static_plus_build
L2_unit_or_integration
L3_runtime_scenario
L4_e2e_or_system
L5_reference_or_benchmark
```

---

## 6. State Machine

오케스트레이터는 다음 상태 전이를 따른다.

```text
intake
→ clarify_requirements
→ create_roadmap
→ select_phase
→ plan_phase
→ decompose_tasks
→ optional_validation_intent
→ implement_tasks
→ generator_self_check
→ create_validation_plan
→ evaluate
→ pass
  → phase_complete
  → select_next_phase
→ fail
  → create_fix_tasks
  → implement_fixes
  → generator_self_check
  → re_evaluate
→ blocked
  → wait_for_user_or_repair
→ project_complete
```

### 6.1 Normal loop

정상적인 Phase 진행 루프는 다음과 같다.

```text
Planner writes plan.md
→ Generator writes tasks.md
→ Generator implements tasks
→ Generator writes generator_self_check.md
→ Evaluator writes validation_plan.md
→ Evaluator writes evaluation_report.md
→ if fail: Generator fixes issues
→ if pass: Orchestrator marks phase passed
```

### 6.2 Optional pre-validation loop

복잡하거나 위험도가 높은 Phase에서는 구현 전에 Evaluator가 가벼운 검증 방향을 먼저 작성한다.

```text
Planner writes plan.md
→ Generator writes tasks.md
→ Evaluator writes validation_intent.md
→ Generator implements tasks
```

이 단계는 sprint를 부활시키는 것이 아니다.

목적은 구현 후에야 검증 기준을 발견하는 문제를 줄이기 위한 preflight check다.

---

## 7. Workflow Details

## 7.1 Intake and requirement clarification

사용자가 요구사항을 작성하면 오케스트레이터는 먼저 요구사항을 읽고 실행 가능한 수준으로 정리한다.

이 단계의 목표는 완벽한 상세 명세 작성이 아니다.

오케스트레이터는 다음만 처리한다.

- 반드시 결정해야 하는 부분
- 애매해서 나중에 큰 충돌을 만들 수 있는 부분
- 사용자 의도가 여러 방향으로 갈릴 수 있는 부분
- 안전, 데이터, 배포, 비용, 권한과 관련된 위험한 결정

오케스트레이터는 모든 빈칸을 사용자에게 묻지 않는다.

구현 디테일이나 reasonable default로 처리 가능한 항목은 Planner / Generator가 자율 판단하도록 남긴다.

결과는 `requirements.md`에 기록한다.

### requirements.md template

```md
# Requirements

## User Request

<original user request or summarized request>

## Clarified Requirements

### RQ-001: <title>
Description:
- ...

Priority: must | should | could
Source: user | orchestrator_inferred | clarified

### RQ-002: <title>
Description:
- ...

Priority: must | should | could
Source: user | orchestrator_inferred | clarified

## Open Questions

- None

## Non-goals

- ...

## Assumptions

- A-001: ...

## Safety / Risk Notes

- ...
```

---

## 7.2 Roadmap creation

요구사항이 정리되면 오케스트레이터는 전체 Roadmap을 만든다.

Roadmap은 Requirement를 Phase로 나누고, 각 Phase의 Milestone을 정의한다.

### roadmap.md template

```md
# Roadmap

Project status: in_progress

## Phase 1: <phase name>
Status: pending
Directory: phases/01-phase-name

Covers requirements:
- RQ-001
- RQ-002

Goal:
- ...

Milestone:
- ...

Depends on:
- None

## Phase 2: <phase name>
Status: pending
Directory: phases/02-phase-name

Covers requirements:
- RQ-003

Goal:
- ...

Milestone:
- ...

Depends on:
- Phase 1
```

---

## 7.3 Phase initialization

각 Phase를 시작할 때 오케스트레이터는 phase directory와 `phase.md`를 만든다.

### phase.md template

```md
# Phase <n>: <phase name>

Status: planning

## Covers requirements

- RQ-001
- RQ-002

## Goal

<what this phase should accomplish>

## Milestone

<what must be true for this phase to be considered complete>

## Dependencies

- ...

## Notes

- ...
```

---

## 7.4 Planner phase

Planner는 `requirements.md`, `roadmap.md`, `current_state.md`, 현재 Phase의 `phase.md`를 읽고 `plan.md`를 작성한다.

Planner의 목표는 raw requirement를 Generator가 바로 구현하기 쉬운 단순 task로 줄이는 것이 아니다.

Planner의 목표는 raw requirement를 제품적으로 충분히 풍부한 spec으로 확장하여, Generator가 작업 범위를 너무 작게 잡거나 incomplete product experience를 만들지 않도록 하는 것이다. 동시에 Plan은 product-level and proportionate해야 한다. 필요한 만큼 쓰되, requirements / decisions / code / 다른 workflow 파일이 이미 맡고 있는 세부사항을 반복하지 않는다.

Planner는 다음을 반드시 지킨다.

- 요구사항을 product-level spec으로 확장한다.
- 단, 제품 전체를 무리하게 재설계하지 않는다.
- product context와 user-facing behavior를 중심에 둔다.
- main interaction flow를 명확히 한다.
- 사용자가 기대할 만한 complete experience를 정의한다.
- empty state, error state, edge condition, consistency expectation을 필요에 따라 포함한다.
- high-level technical design은 작성하되, low-level implementation detail은 불필요하게 고정하지 않는다.
- schema, route table, test matrix, command transcript, task list를 Plan 안에 장황하게 열거하지 않는다.
- 이미 canonical한 요구사항/결정/코드 세부사항은 참조하고, 줄 단위로 복제하지 않는다.
- Plan이 어떤 Requirement를 반영하는지 명확히 기록한다.
- Generator가 구현 판단을 할 여지를 남긴다.

### plan.md template

```md
# Plan

<!-- Keep this product-level and proportionate. Do not paste schemas, route
tables, test matrices, or task lists when they can be referenced from
requirements/decisions/code. -->

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
  to Generator unless fixed by requirements or decisions>

## Implementation freedom left for Generator

The Generator should decide:
- exact file structure
- exact component/function boundaries
- exact data fetching mechanism
- exact test implementation
- repo-specific integration details

## Constraints and edge considerations

- ...

## Out of scope

- ...

## Acceptance intent

This phase should feel complete when:
- ...
```

---

## 7.5 Generator task decomposition

Generator는 `requirements.md`, `phase.md`, `plan.md`, `current_state.md`를 읽고 `tasks.md`를 작성한다.

Generator는 Plan이 말하는 “무엇”과 Requirement가 말하는 “왜”를 함께 이해해야 한다.

Task는 Plan section과 Requirement ID를 참조해야 한다.

### tasks.md template

```md
# Tasks

<!-- Keep tasks compact and proportionate to the Phase. Do not copy Plan details
into each task; reference plan sections and state the concrete work. -->

## Task G-001: <task title>

Status: pending
Related requirements:
- RQ-001

Related plan sections:
- User-facing behavior
- Main interaction flow

Description:
- <brief concrete work, not a copied spec>

Implementation notes:
- <only task-specific constraints; omit generic reminders>

Expected evidence of completion:
- <files/tests/commands or observable behavior that prove completion>

## Task G-002: <task title>

Status: pending
Related requirements:
- RQ-002

Related plan sections:
- Functional requirements

Description:
- ...
```

---

## 7.6 Optional Validation Intent

복잡하거나 위험도가 높은 Phase에서는 Generator가 task를 나눈 뒤 Evaluator가 `validation_intent.md`를 작성한다.

이 단계는 항상 필수는 아니다.

`validation_intent.md`는 preflight guidance다. 이 단계에서는 exhaustive EV-ID
matrix를 만들지 않는다. 구현 전에 Generator가 알아야 할 검증 수준, 주요 위험,
대표 체크, success oracle만 기록한다. 실제 EV-ID는 구현 결과를 본 뒤
`validation_plan.md`에서 grouped check로 정의한다.

사용 조건:

- 여러 시스템이 함께 바뀌는 경우
- 데이터 흐름이 복잡한 경우
- UI / API / DB가 함께 바뀌는 경우
- 기존 테스트가 부족한 경우
- 안전하거나 민감한 기능인 경우
- Generator가 구현 전에 검증 기준을 알아야 하는 경우

### validation_intent.md template

```md
# Validation Intent

<!-- Preflight guidance only. Do not assign an exhaustive EV-ID matrix here;
save concrete EV-IDs for validation_plan.md. -->

## Phase

<phase name>

## Recommended validation level

L0_static_review | L1_static_plus_build | L2_unit_or_integration | L3_runtime_scenario | L4_e2e_or_system | L5_reference_or_benchmark

## Why this level is appropriate

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
```

---

## 7.7 Implementation

Generator는 task를 하나씩 처리한다.

구현 중 다음을 지킨다.

- 기존 repo 구조와 naming convention을 우선한다.
- 기존 data flow와 state pattern을 존중한다.
- 불필요한 추상화나 대규모 리팩터링을 피한다.
- Plan에서 정한 user-facing behavior를 벗어나지 않는다.
- Requirement와 Plan에 없는 기능을 임의로 크게 추가하지 않는다.
- 필요한 경우 자율적으로 구현 결정을 내리되, 장기적으로 영향이 큰 결정은 `decisions.md`에 기록한다.
- 실패한 접근은 `implementation_log.md` 또는 `changelog.md`에 기록한다.
- `implementation_log.md`에는 diff, 전체 코드 블록, command transcript를 붙이지 않는다. 완료한 task, 변경한 파일/파일그룹의 목적, 검증 요약, 남은 risk만 남긴다.

### implementation_log.md template

```md
# Implementation Log

<!-- Summary log, not a diff. For each entry: completed task IDs, changed file
groups with one purpose sentence each, verification summary, risks. Do not paste
code blocks, full command output, or line-by-line changes. -->

## <date/time>

### Completed

- G-001: ...
- G-002: ...

### Files changed

- <path or file group> — <one concise purpose sentence>

### Decisions made

- D-001: ...

### Failed approaches

- Tried: ...
- Why it failed: ...
- Do not repeat: ...

### Verification summary

- <command or manual check>: pass | fail | not run — <one-line note>

### Known risks

- ...
```

---

## 7.8 Generator self-check

Generator는 Evaluator에게 넘기기 전에 반드시 self-check를 수행한다.

Self-check는 완벽한 평가가 아니라, 명백한 문제를 Evaluator에게 넘기지 않기 위한 최소 품질 게이트다.

Self-check는 evaluation report가 아니다. Generator는 요구사항/acceptance coverage를
grouped evidence 중심으로 확인하고, EV-ID별 판정표를 만들지 않는다.

### generator_self_check.md template

```md
# Generator Self Check

<!-- Readiness summary, not an evaluation report. Do not create an EV-ID matrix;
group related acceptance checks and point to primary evidence. -->

## Summary

<what was implemented>

## Requirements addressed

- RQ-001: <primary evidence only: task/file/test/manual check>
- RQ-002: ...

## Acceptance coverage

- <grouped acceptance intent>: met | partial | not met — <evidence>

## Tasks completed

- G-001: completed
- G-002: completed

## Commands run

- Command: <command>
  Result: pass | fail | not_applicable
  Notes: <one-line summary, not full output>

## Manual checks performed

- ...

## Known limitations

- ...

## Risks / areas needing evaluator focus

- ...

## Handoff readiness

Ready for evaluation: yes | no
```

Generator는 known failing test나 known broken behavior를 숨기면 안 된다.

---

## 7.9 Evaluator validation plan

Evaluator는 `requirements.md`, `phase.md`, `plan.md`, `tasks.md`, `implementation_log.md`, `generator_self_check.md`를 읽고 `validation_plan.md`를 작성한다.

Evaluator는 검증 강도를 선택해야 한다.

검증은 엄격해야 하지만, 검증 문서는 navigation 가능한 상태를 유지해야 한다.
Evaluator는 decision-making에 실제로 필요한 check를 risk area별 grouped EV-ID로
작성한다. 모든 field, route, assertion, source line을 별도 EV-ID로 만들면 안 된다.

### Validation level guide

#### L0_static_review

문서와 코드 변경을 정적으로 검토한다.

적합한 경우:

- 문서 수정
- 작은 설정 변경
- UI copy 변경
- 위험도가 낮은 단순 변경

#### L1_static_plus_build

정적 검토에 build/typecheck/lint를 추가한다.

적합한 경우:

- 컴파일 가능성이 중요한 코드 변경
- 타입 안전성이 중요한 변경
- 작은 로직 변경

#### L2_unit_or_integration

unit test 또는 integration test를 수행한다.

적합한 경우:

- 비즈니스 로직
- API 로직
- 데이터 변환
- 상태 관리

#### L3_runtime_scenario

실행 중인 앱 또는 서비스에서 주요 시나리오를 확인한다.

적합한 경우:

- 사용자 흐름
- UI와 API가 함께 바뀐 경우
- manual runtime check가 충분한 경우

#### L4_e2e_or_system

Playwright, browser automation, API+DB system check 등 end-to-end 검증을 수행한다.

적합한 경우:

- 핵심 사용자 흐름
- 인증/결제/권한/데이터 저장
- UI/API/DB가 복합적으로 변경된 경우

#### L5_reference_or_benchmark

reference implementation, benchmark, quantitative threshold, regression suite를 사용한다.

적합한 경우:

- 모델/알고리즘/수치계산
- 성능 목표
- 정확도 목표
- 기존 시스템과 parity가 중요한 경우

### validation_plan.md template

```md
# Validation Plan

<!-- Concrete validation plan. Prefer grouped EV-IDs by risk area. Put related
sub-assertions under one EV-ID instead of making a new EV-ID for every field,
route, or source line. -->

## Scope

Evaluate Phase <n>: <phase name>

## Inputs reviewed

- requirements.md
- roadmap.md
- phase.md
- plan.md
- tasks.md
- implementation_log.md
- generator_self_check.md

## Selected validation level

L0_static_review | L1_static_plus_build | L2_unit_or_integration | L3_runtime_scenario | L4_e2e_or_system | L5_reference_or_benchmark

## Why this level is appropriate

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
```

---

## 7.10 Evaluation report

Evaluator는 검증 수행 후 최신 공식 판정인 `evaluation_report.md`를 작성하고,
`evaluation_history.md`에는 짧은 snapshot만 append한다. `evaluation_history.md`에
full report를 복제하지 않는다.

### evaluation_report.md template

```md
# Evaluation Report

<!-- Latest verdict. Keep passed evidence compact; write detail for failures,
blockers, surprising results, and high-risk checks only. -->

Verdict: pass | fail | blocked
Validation level used: L0 | L1 | L2 | L3 | L4 | L5

## Summary

<short summary>

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
```

### Verdict rules

Evaluator must return `fail` if:

- core user-facing behavior is missing
- important Requirement is not covered
- implementation only partially satisfies the Plan
- implementation satisfies the literal raw request but misses important expanded Plan behavior
- known critical bug remains
- tests/build fail for relevant areas
- code is too brittle or poorly integrated to trust

Evaluator may return `pass` only if:

- all must-have Requirements for the Phase are satisfied
- Phase Milestone is met
- Plan acceptance intent is met
- critical and major issues are absent
- remaining issues are minor and documented
- implementation is maintainable enough to proceed

Evaluator returns `blocked` if:

- user decision is required
- repo state prevents reliable validation
- missing dependency or environment issue prevents evaluation
- same failure repeats beyond retry policy

---

## 7.11 Fix loop

If Evaluator returns fail, Orchestrator sets Phase status to `fixing`.

Generator then reads:

- `evaluation_report.md`
- `validation_plan.md`
- `tasks.md`
- `implementation_log.md`
- `plan.md`
- `requirements.md`

Generator creates fix tasks inside `tasks.md`.

Fix task IDs should use `GF-` prefix.

Example:

```md
## Fix Task GF-001: Add empty state handling

Status: pending
Source evaluation check:
- EV-003

Related requirements:
- RQ-002

Description:
- Add explicit empty state behavior when dashboard data is empty.

Expected evidence of completion:
- EV-003 passes on re-evaluation.
```

After fixes, Generator updates `generator_self_check.md`, then Evaluator re-runs only necessary checks unless broader regression risk requires a full re-evaluation.

---

## 7.12 Phase completion

A Phase is complete only when:

- `evaluation_report.md` verdict is `pass`
- `roadmap.md` marks the Phase as `passed`
- `phase.md` status is `passed`
- `current_state.md` points to the next Phase or project completion
- `run_state.json` is updated
- `changelog.md` includes a summary of completion

---

## 7.13 Artifact quality gates

After every Planner / Generator / Evaluator dispatch, Orchestrator verifies the
files the subagent claims to have written before advancing state.

The check is not a full audit of every workflow file. Orchestrator checks only
the artifact(s) newly written by the step, starting with a shallow role-fit
check:

- file exists and is non-empty
- expected headings / status / verdict fields are present
- task/check ID counts look plausible for the Phase
- small targeted excerpts do not show obvious duplication, pasted diffs, or
  command transcripts

Orchestrator deep-reads only when the shallow check shows red flags.
Orchestrator should reject and rerun the responsible role when an artifact
violates its role:

- `plan.md` is thin, or bloated with task lists, test matrices, command
  transcripts, schemas, route tables, or low-level implementation detail.
- `tasks.md` mostly restates `plan.md`, creates one task per Plan bullet, or
  embeds spec/test detail instead of concrete work and completion evidence.
- `validation_intent.md` is an exhaustive EV-ID matrix instead of preflight
  guidance.
- `implementation_log.md` contains diffs, full code blocks, or command
  transcripts instead of summary-level implementation evidence.
- `generator_self_check.md` duplicates `validation_plan.md` or pre-judges every
  EV-ID instead of summarizing readiness and primary evidence.
- `validation_plan.md` creates tiny EV-IDs for every assertion/source line
  instead of grouped checks by risk area.
- `evaluation_report.md` or `evaluation_history.md` duplicate routine pass
  evidence instead of keeping detail focused on failures, blockers, surprising
  results, and high-risk checks.

When rejecting an artifact, Orchestrator should dispatch the same role again
with a concrete rewrite instruction and should not advance the state machine
until the artifact is both substantive and role-appropriate.

---

## 8. Retry and Blocker Policy

### 8.1 Retry limits

Default retry policy:

```text
max_fix_loops_per_phase: 3
max_same_failure_repeats: 2
max_total_phase_attempts: 5
```

These values may be adjusted by project configuration.

### 8.2 Same failure repeat

If the same Evaluation check fails repeatedly, the issue must be escalated.

Example:

```text
EV-003 failed twice with substantially the same cause.
→ mark as blocker_candidate
→ Generator must explain why previous fixes failed
→ If it fails again, mark Phase blocked
```

### 8.3 Blocker record

When blocked, Orchestrator writes to `blockers.md`.

### blockers.md template

```md
# Blockers

## B-001: <title>

Status: open | resolved
Phase: phases/02-dashboard
Detected by: orchestrator | generator | evaluator
Related evaluation check: EV-003

Context:
- ...

Why blocked:
- ...

User decision needed:
- yes | no

Options:
1. ...
2. ...
3. ...

Recommended option:
- ...

Resume condition:
- ...
```

---

## 9. Current State and Run State

## 9.1 current_state.md

`current_state.md` is short and human-readable.

It must not become a long history file.

### current_state.md template

```md
# Current State

Project status: in_progress
Current phase: phases/02-dashboard
Current phase status: fixing
Current owner: generator
Current loop: fix_loop_2

## Last completed step

- Evaluator failed EV-003 because empty state behavior is missing.

## Next action

- Generator should implement GF-001 and rerun self-check.

## Blocked

No

## Important context

- Do not change the auth model from Phase 1.
- Reuse the existing API response shape.
```

## 9.2 run_state.json

`run_state.json` is machine-readable and minimal.

### run_state.json schema

```json
{
  "project_status": "in_progress",
  "current_phase": "phases/02-dashboard",
  "current_phase_status": "fixing",
  "current_owner": "generator",
  "current_step": "implement_fixes",
  "loop_count": 2,
  "last_evaluation_verdict": "fail",
  "blocked": false,
  "next_action": "generator_fix_latest_eval_issues"
}
```

### Conflict rule

If `current_state.md` and `run_state.json` disagree:

1. Use `run_state.json` for machine state.
2. Use `current_state.md` for human context.
3. Orchestrator should repair `current_state.md` to match `run_state.json`.
4. Record the repair in `changelog.md`.

---

## 10. Decisions and Changelog

## 10.1 decisions.md

`decisions.md` records meaningful choices that may affect future work.

### decisions.md template

```md
# Decisions

## D-001: <decision title>

Date: <date>
Made by: orchestrator | planner | generator | evaluator
Phase: <phase path or global>

Context:
- ...

Decision:
- ...

Reason:
- ...

Impact:
- ...

Alternatives considered:
- ...
```

### What must be recorded

Record a decision when:

- it affects future architecture
- it changes scope
- it chooses between user-visible behaviors
- it resolves ambiguity without asking the user
- it changes data flow, storage, API shape, or state management
- it skips or defers a requirement

## 10.2 changelog.md

`changelog.md` is the portable long-term memory of the workflow.

It should record:

- current status snapshots
- completed work
- failed approaches and why they failed
- known limitations
- important commits
- resolved blockers
- major evaluation results

### changelog.md template

```md
# Changelog

## <date/time>

### Status

- Current phase: ...
- Current owner: ...

### Completed

- ...

### Failed approaches

- Tried: ...
- Why it failed: ...
- Do not repeat: ...

### Known limitations

- ...

### Next action

- ...
```

---

## 11. Git Policy

Git usage may be optional depending on environment, but coding workflows should prefer it.

### 11.1 Start-of-work git checks

Before implementation, Generator should check:

```text
git status
git branch --show-current
git log --oneline -20
```

If the working tree contains user changes, Generator must not overwrite them without explicit instruction.

### 11.2 Commit policy

If git is available and commits are allowed:

- Commit after meaningful units of work.
- Do not commit known broken code unless explicitly marking a WIP checkpoint.
- Run relevant tests before final pass commit.
- Record commit hash in `implementation_log.md` or `changelog.md`.

### 11.3 No destructive changes

Generator must not:

- delete unrelated user files
- reset hard without permission
- overwrite unstaged user changes
- rewrite history unless explicitly instructed

---

## 12. Resume Policy

When resuming work, Orchestrator must read in this order:

1. `run_state.json`
2. `current_state.md`
3. `roadmap.md`
4. current phase `phase.md`
5. current phase `plan.md`
6. current phase `tasks.md`
7. latest `evaluation_report.md` if it exists
8. `changelog.md`
9. `blockers.md` if blocked

Then Orchestrator decides the next owner.

### Resume decision examples

```text
If current_phase_status = planning
→ next owner: Planner

If current_phase_status = implementing
→ next owner: Generator

If current_phase_status = evaluating
→ next owner: Evaluator

If current_phase_status = fixing
→ next owner: Generator

If current_phase_status = blocked
→ next owner: Orchestrator or User
```

---

## 13. Skill / Plugin Commands

A skill or plugin implementing this workflow should expose commands similar to the following.

### `/workflow:init`

Create `agents_workspace/`, initialize required files, and write initial `requirements.md`.

Inputs:

- user request
- optional project mode: minimal | full

Outputs:

- initialized workspace
- requirements.md
- current_state.md
- run_state.json

### `/workflow:clarify`

Analyze requirements and identify only essential ambiguities.

Outputs:

- updated requirements.md
- open questions if necessary
- decisions.md updates if assumptions are made

### `/workflow:roadmap`

Create or update `roadmap.md` and phase folders.

Outputs:

- roadmap.md
- phases/*/phase.md

### `/workflow:plan-phase`

Run Planner for the current Phase.

Outputs:

- phases/current/plan.md

### `/workflow:decompose`

Run Generator task decomposition for the current Phase.

Outputs:

- phases/current/tasks.md

### `/workflow:validation-intent`

Optional pre-implementation validation planning.

Outputs:

- phases/current/validation_intent.md

### `/workflow:implement`

Run Generator implementation for pending tasks.

Outputs:

- code changes
- tasks.md updates
- implementation_log.md updates

### `/workflow:self-check`

Run Generator self-check.

Outputs:

- generator_self_check.md

### `/workflow:evaluate`

Run Evaluator.

Outputs:

- validation_plan.md
- evaluation_report.md
- evaluation_history.md

### `/workflow:fix`

Generate and implement fix tasks from evaluation failures.

Outputs:

- updated tasks.md
- implementation_log.md
- generator_self_check.md

### `/workflow:next`

Let Orchestrator decide and perform the next appropriate workflow step.

### `/workflow:resume`

Read current files and resume from the correct step.

### `/workflow:status`

Print current project and phase status from `current_state.md` and `run_state.json`.

### `/workflow:repair`

Repair inconsistent or missing workflow files.

### `/workflow:complete-phase`

Mark current Phase as passed and move to next Phase.

### `/workflow:complete-project`

Mark project as completed when all Phases pass.

---

## 14. Agent Role Contracts

## 14.1 Orchestrator contract

The Orchestrator must:

- keep the workflow moving
- read file state before deciding
- update `current_state.md` and `run_state.json`
- only ask the user when necessary
- avoid over-clarifying
- prevent infinite loops
- mark blockers clearly
- ensure every Phase maps back to Requirements
- reject and rerun workflow artifacts that are bloated, duplicate another
  artifact, or contain content owned by another role

The Orchestrator must not:

- implement product code directly unless explicitly configured to do so
- skip Planner for non-trivial Phases
- mark a Phase complete without Evaluator pass
- rely on agent memory instead of files

## 14.2 Planner contract

The Planner must:

- read Requirements, Roadmap, Current State, and Phase file
- expand the raw requirement into a product-level, proportionate spec
- prevent Generator under-scoping
- focus on product context, user-facing behavior, interaction flow, functional depth, and high-level technical design
- identify what a complete product experience should feel like
- include edge cases, empty states, failure states, and consistency expectations when relevant
- avoid premature granular implementation detail
- avoid copying schemas, route tables, test matrices, command transcripts, or
  task lists into the Plan
- record Requirement coverage
- define acceptance intent
- avoid unrelated feature invention

The Planner must not:

- merely restate the raw requirement
- reduce the request into a thin task list
- let the feature become under-scoped
- micromanage implementation
- lock in low-level technical choices without necessity
- redesign the whole product unless requested
- omit Requirement mapping

## 14.3 Generator contract

The Generator must:

- read Requirements, Plan, Tasks, Current State, and latest Evaluation Report if present
- decompose Plan into proportionate Tasks without copying the Plan into each task
- implement complete behavior, not isolated fragments
- preserve existing architecture and conventions
- update tasks and implementation logs at summary level
- self-check before evaluation without producing an Evaluator-style EV matrix
- honestly record limitations and risks

The Generator must not:

- drift away from Plan intent
- shrink the Plan back down to the raw request without justification
- hide known broken behavior
- ignore existing repo patterns
- create unnecessary complexity
- overwrite unrelated user changes

## 14.4 Evaluator contract

The Evaluator must:

- read Requirements, Plan, Tasks, Implementation Log, and Self Check
- evaluate against the expanded Plan, not only the raw request
- choose appropriate validation level
- create a grouped Validation Plan
- verify product-level correctness
- distinguish critical, major, and minor issues
- return pass/fail/blocked
- provide concrete next actions
- append short snapshots to Evaluation History

The Evaluator must not:

- rely only on Generator summary
- pass partially working core behavior
- pass an implementation that satisfies the literal request but misses important Planner-defined acceptance intent
- create exhaustive EV-ID matrices when grouped checks would give the same confidence
- duplicate the full Evaluation Report into Evaluation History
- require Playwright or E2E when unnecessary
- ignore code quality issues
- be vague or flattering without evidence

---

## 15. Completion Criteria

## 15.1 Phase completion criteria

A Phase is complete when:

- all must-have Requirements assigned to the Phase are covered
- Planner Plan acceptance intent is satisfied
- Generator tasks are completed or explicitly skipped with reason
- Generator self-check is complete
- Evaluator verdict is pass
- current state is updated
- changelog records completion

## 15.2 Project completion criteria

A Project is complete when:

- all Roadmap Phases are passed or explicitly skipped with user-approved reason
- no open critical blockers remain
- requirements.md has no unresolved must-have open questions
- changelog includes final summary
- current_state.md says project completed
- run_state.json says `project_status = completed`

---

## 16. Practical Defaults

Recommended defaults:

```json
{
  "workspace_dir": "agents_workspace",
  "mode": "full",
  "max_fix_loops_per_phase": 3,
  "max_same_failure_repeats": 2,
  "default_validation_level": "L1_static_plus_build",
  "use_validation_intent_for_complex_phases": true,
  "git_policy": "safe_optional",
  "ask_user_only_when_required": true
}
```

---

## 17. Final Workflow Summary

The workflow is:

```text
User requirement
→ Orchestrator clarifies only essential ambiguity
→ Orchestrator creates Roadmap
→ For each Phase:
    Planner expands raw requirement into a rich product-level Plan
    Planner prevents under-scoping while avoiding premature implementation rigidity
    Generator decomposes Plan into Tasks
    Optional Evaluator writes Validation Intent
    Generator implements Tasks
    Generator runs Self Check
    Evaluator writes Validation Plan
    Evaluator evaluates implementation against Requirement + expanded Plan
    If fail: Generator fixes and Evaluator rechecks
    If pass: Orchestrator completes Phase
→ Repeat until all Phases pass
→ Project complete
```

The most important invariants are:

```text
Files are the source of truth.
Agents must read before work and write after work.
Planner should enrich product scope without locking implementation details.
Generator must implement the expanded Plan, not just the literal raw request.
Evaluator must evaluate against Requirement + Plan acceptance intent, not only surface completion.
No Phase is complete until Evaluator passes it.
No project is complete until every Phase is passed or explicitly resolved.
```
