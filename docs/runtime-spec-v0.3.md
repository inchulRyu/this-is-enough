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
- requirement.md, decisions.md, code에 이미 canonical하게 있는 세부사항을 줄 단위로 복제하기
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

Evaluator는 먼저 validation profile을 고른다. Profile은 문서/절차의 무게를
정하고, validation level(L0-L5)은 실제 검증 방법의 깊이를 정한다.

- `standard`: 기본 validation-confidence profile이다. Low-risk localized
  change와 일반적인 bounded product/code 변경은 여기에 포함된다. 별도
  `validation_plan.md` 없이
  `evaluation_report.md` 안에 grouped checks와 completion audit을 담는 것이
  기본이다.
- `high`: high-impact side effects, external authoritative state, sensitive
  data, persistence integrity, cross-surface contracts, safety invariants,
  weak regression coverage, hard-to-infer correctness, integrated runtime/E2E,
  benchmark/reference oracle, compliance, fail-closed evidence가 confidence의
  핵심인 경우다. 필요하면 `validation_intent.md`와 별도 `validation_plan.md`를
  사용한다.

어떤 Phase도 Evaluator `pass` 없이 완료될 수 없다.

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
- Evaluator verdict가 pass
- Known critical issue 없음
- 현재 상태 파일 갱신 완료

### 1.8 Workflow documents are navigation aids

`agents_workspace/active_run`과 active run directory의 문서는 재개와 판단을
위한 source of truth이지만, 코드 diff, 전체 테스트 출력, 구현 설계서, 검증
감사 로그를 복제하는 장소가 아니다.

각 파일은 자신의 역할 안에서 필요한 정보만 담아야 한다.

- `plan.md`는 제품 수준의 의도와 완료 기준을 담는다. 구현 상세, task list,
  test matrix는 담지 않는다.
- `tasks.md`는 구현 작업을 추적한다. Plan의 세부 문장을 반복하지 않는다.
- `implementation_log.md`는 변경 요약과 Evaluator handoff를 남긴다. diff, 코드
  블록, command transcript를 붙이지 않는다.
- `validation_intent.md`는 preflight guidance다. exhaustive EV-ID matrix가
  아니라 검증 수준, 주요 위험, 대표 체크를 담는다.
- `validation_plan.md`는 실제 검증 계획이다. 관련 assertion은 risk area별
  grouped EV-ID 아래에 묶는다. `standard`에서는 보통
  `evaluation_report.md`에 inline된다.
- `evaluation_report.md`는 최신 공식 판정이다. Requirement → artifact →
  evidence completion audit을 포함하고, 통과한 일반 체크는 concise하게,
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
- context/time budget이 부족해 새 substantive work를 안전하게 시작할 수 없는
  경우. 이때는 현재 state와 정확한 resume step을 남기고 멈춘다.

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
구현하기 쉬운 작업 단위로 묶고, 각 task에는 concrete work와 Evaluator handoff만
기록한다. Plan의 모든 bullet마다 task를 만들거나, Plan의 schema / test / route
detail을 task마다 다시 붙이면 안 된다.

### Validation Intent

구현 전에 필요할 경우 Evaluator가 작성하는 가벼운 사전 검증 방향이다.

항상 필수는 아니며, validation profile과 일반 risk attribute에 따라 사용한다.

### Validation Profile

각 Phase의 검증 절차 무게를 정하는 risk-based profile이다.

값은 `standard`, `high`이다. Profile은 `validation_intent.md`와 별도
`validation_plan.md`가 필요한지, runtime/E2E/system-depth 검증이 필요한지를
결정한다. `standard`가 기본 confidence profile이고 `high`는 실제 risk
trigger가 있을 때만 사용한다. Profile은 expected runtime이나 latency mode가
아니다.

### Validation Plan

Evaluator가 구현 결과를 검증하기 위해 작성하는 구체적인 검증 계획이다.

### Evaluation Report

Evaluator가 검증 결과를 pass / fail / blocked로 정리한 최신 보고서다.

---

## 3. Directory Structure

기본 구조는 다음과 같다.

```text
agents_workspace/
  project_memory.md                  # durable repo-level memory
  drafts/
    <draft-id>/
      requirement.md                    # pre-run only
  active_run                       # e.g. runs/2026-04-27-001-add-dashboard
  runs/
    <run-id>/
      requirement.md
      roadmap.md
      current_state.md
      run_state.json
      telemetry.jsonl              # append-only timing / execution events
      decisions.md
      changelog.md
      retrospective.md              # run-local memory candidates
      blockers.md                  # only when blocked

      phases/
        01-phase-name/
          phase.md
          plan.md
          tasks.md
          validation_intent.md       # optional profile-gated preflight
          implementation_log.md
          validation_plan.md         # used when high-risk depth needs it
          evaluation_report.md
          evaluation_history.md
```

`agents_workspace/drafts/`는 아직 구현이 시작되지 않은 requirement draft만
보관한다. Draft가 run으로 승격되면 draft의 `requirement.md`를 새 run의
`requirement.md`로 복사한다. Draft directory는 안전하게 삭제할 수 있을 때만
삭제한다. 그 이후 requirement의 source of truth는 run directory이고, detailed
run history는 기본적으로 local state로 남는다.

`telemetry.jsonl`은 run-local append-only telemetry stream이다. Latency와
execution-event analysis의 source of truth이며, human-facing markdown
artifacts를 parse하지 않고 phase / role / step / command / validation /
fix-loop timing을 집계할 수 있게 한다. 기존 run에 이 파일이 없어도 resume,
status, doctor는 corrupt state로 보지 않는다.

`agents_workspace/active_run`은 current/latest run을 가리키는 text pointer다.
값은 `runs/<run-id>` 형태의 상대 경로다. 완료된 run을 가리킨 채로 남아도
된다. 완료 여부는 pointer를 비우는 것으로 판단하지 않고, 해당 run의
`run_state.json.project_status`와 `current_step`으로 판단한다.

하나의 independent requirement input은 하나의 run을 만든다. Active run이
`completed`이고 새 start request가 새 requirement를 포함하면 새 run을 만들고
`active_run`을 덮어쓴다. Active run이 `in_progress` 또는 `blocked`이면 start /
resume에 붙은 추가 text는 새 run이 아니라 같은 run의 update다. 이 update는
해당 run의 `requirement.md`에 `## Updates` 아래 ISO timestamp subheading으로
append한다.

`index.json`은 현재 만들지 않는다.

기본 git 정책은 `agents_workspace/` 전체를 ignore하지 않고, volatile state만
ignore하는 것이다. 기본 ignore 대상은 `agents_workspace/drafts/`,
`agents_workspace/runs/`, `agents_workspace/active_run`이다.
`agents_workspace/project_memory.md`는 완료된 run에서 승격된 durable note를 담는
파일이며 commit 가능한 파일로 남긴다. 기존 `.gitignore`에 broad
`agents_workspace/` rule이 있으면 사용자가 모든 workflow 파일을 ignore하기로
명시하지 않은 한 이 세 volatile-state rule로 교체한다.

### 3.1 Minimal structure

작은 프로젝트에서는 아래 최소 구조로 시작할 수 있다.

```text
agents_workspace/
  project_memory.md
  drafts/
  active_run
  runs/
    <run-id>/
      requirement.md
      roadmap.md
      current_state.md
      run_state.json
      telemetry.jsonl
      decisions.md
      changelog.md
      retrospective.md

      phases/
        01-phase-name/
          phase.md
          plan.md
          tasks.md
          implementation_log.md
          evaluation_report.md
```

### 3.2 Expanded structure

장기 실행, 재개 가능성, 반복 검증이 중요한 프로젝트에서는 full structure를 사용한다.

```text
agents_workspace/
  project_memory.md
  drafts/
  active_run
  runs/
    <run-id>/
      requirement.md
      roadmap.md
      current_state.md
      run_state.json
      telemetry.jsonl
      decisions.md
      changelog.md
      retrospective.md
      blockers.md

      phases/
        01-phase-name/
          phase.md
          plan.md
          tasks.md
          validation_intent.md
          implementation_log.md
          validation_plan.md
          evaluation_report.md
          evaluation_history.md
```

`standard` validation profile에서는 보통 별도 `validation_plan.md`를 생략하고
`evaluation_report.md`가 grouped checks, 수행 결과, 공식 verdict를 함께 담는다.
`high`에서는 risk depth가 필요할 때 `validation_intent.md`와
`validation_plan.md`를 사용한다.

---

## 4. File Ownership Rules

파일 소유권은 다음과 같이 나눈다.

```text
Orchestrator
- active_run
- project_memory.md
- requirement.md
- roadmap.md
- current_state.md
- run_state.json
- telemetry.jsonl lifecycle and Orchestrator wall-time events
- decisions.md
- blockers.md
- changelog.md
- retrospective.md
- phases/*/phase.md
- promotion/deletion of agents_workspace/drafts/<draft-id>/

Requirements
- agents_workspace/drafts/<draft-id>/requirement.md

Doctor (maintenance only)
- active_run
- current_state.md repairs
- run_state.json repairs
- decisions.md / changelog.md / blockers.md repairs
- legacy-pre-run-layout-* backups
- migration from old root layout into runs/<run-id>/

Planner
- phases/*/plan.md

Generator
- phases/*/tasks.md
- phases/*/implementation_log.md
- append-only command/check events in telemetry.jsonl

Evaluator
- phases/*/validation_intent.md
- phases/*/validation_plan.md
- phases/*/evaluation_report.md
- phases/*/evaluation_history.md
- append-only validation/check events in telemetry.jsonl
```

### 4.1 Write rules

- 각 에이전트는 자신이 소유한 파일을 주로 수정한다.
- 다른 에이전트가 소유한 파일을 수정해야 할 경우, 이유를 `changelog.md` 또는 해당 phase log에 기록한다.
- `current_state.md`와 `run_state.json`은 오케스트레이터가 정상 workflow 중
  최종 갱신한다. Doctor는 명시적인 state maintenance 중에만 safe repair /
  migration을 위해 갱신할 수 있다.
- `decisions.md`, `changelog.md`, `blockers.md`, `evaluation_history.md`는 append-only에 가깝게 운용한다.
- `evaluation_report.md`는 최신 평가 결과로 덮어쓴다.
- `evaluation_history.md`에는 모든 평가 run의 짧은 snapshot을 누적한다.
  full report를 복제하지 않는다. `standard` profile에서는
  `evaluation_report.md`가 전체 판단을 담으면 생략할 수 있다.
- `retrospective.md`는 해당 run 안에서 나중에 승격할 후보만 concise하게 담는다.
- `project_memory.md`는 완료된 run에서 장기적으로 유용한 note만 승격해 누적한다.
  routine progress, diff, command transcript, full evaluation report는 담지 않는다.
- `telemetry.jsonl`은 여러 role이 공유하는 append-only machine log다.
  Markdown artifact와 달리 reasoning, diff, command transcript, raw output,
  secrets, environment dumps, 또는 large payload를 담지 않는다. 각 event는
  한 줄의 JSON object여야 하며, write failure가 timing capture를 불가능하게
  만들면 일반 blocker / changelog path로 명확히 드러내야 한다.

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
committing
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

### 5.6 Validation profile

```text
standard
high
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
→ select_validation_profile
→ optional_validation_intent
→ implement_tasks
→ create_validation_plan_if_needed
→ evaluate
→ pass
  → phase_complete
  → phase_checkpoint_commit
  → select_next_phase
→ fail
  → create_fix_tasks
  → implement_fixes
  → re_evaluate
→ blocked
  → wait_for_user_or_repair
→ project_complete
```

At every Orchestrator-owned boundary, implementations should append telemetry
events for the step start and step end. Start/end pairs should include the run
ID, phase path when applicable, role, step, mode when applicable, ISO-8601
timestamp with timezone, elapsed seconds on the end event, and a concise
outcome such as `started`, `pass`, `fail`, `blocked`, `skipped`, or `error`.

### 6.1 Normal loop

정상적인 Phase 진행 루프는 다음과 같다.

```text
Planner writes plan.md
→ Generator writes tasks.md
→ Orchestrator selects validation profile and records phase metrics
→ Generator implements tasks
→ Evaluator writes validation_plan.md when high-risk depth needs it
→ Evaluator writes evaluation_report.md
→ Orchestrator copies report profile/level/intent/failure metrics into state
→ if fail: Orchestrator increments fix metrics; Generator fixes issues
→ if pass: Orchestrator marks phase passed, commits checkpoint, selects next Phase
```

At phase initialization, `current_phase_metrics` is reset. After profile
selection, `validation_profile` is set. If `validation_intent.md` is created,
`intent_used` is set to true. After every evaluation or recheck, Orchestrator
copies the Evaluator report's profile, level, intent usage, fix loop count, and
failed EV-IDs into `run_state.json.current_phase_metrics`, the
phase's `phase.md`, and the concise `current_state.md` line. On fail, it
increments both the run loop counter and `fix_loop_count`, and merges failed
EV-IDs into `failed_ev_ids_seen` without duplicates.

Telemetry mirrors these transitions without replacing state: Orchestrator
records wall time for phase initialization, Planner dispatch, Generator
decomposition, Generator implementation, Evaluator validation, Generator fix,
Evaluator recheck, state updates, phase pass, checkpoint commit, blockers, and
project completion. Generator and Evaluator separately record command/check
duration events they can observe directly. This separation lets later analysis
distinguish agent wall time from external command time.

### 6.2 Optional pre-validation loop

Risk profile상 preflight가 필요한 Phase에서는 구현 전에 Evaluator가 가벼운 검증
방향을 먼저 작성한다.

```text
Planner writes plan.md
→ Generator writes tasks.md
→ Evaluator writes validation_intent.md
→ Generator implements tasks
```

이 단계는 sprint를 부활시키는 것이 아니다.

목적은 구현 후에야 검증 기준을 발견하는 문제를 줄이기 위한 preflight check다.

이 단계는 `standard`에서는 보통 생략한다. `high`에서는 Generator가 구현 전에
알아야 할 구체적 위험이 있을 때 사용한다.

---

## 7. Workflow Details

## 7.0 Active run selection

Workflow start/resume commands must resolve `agents_workspace/active_run` before
reading or writing run state. A start command may validate a referenced draft
path first, but it must not read draft content, write run state, or delete the
draft until active-run selection confirms a new run can be created.

1. If `agents_workspace/active_run` is missing, a new run may be created. For
   raw requirements, write `active_run` during normal bootstrap. For draft
   starts, first run the draft preflight below, then delay writing `active_run`
   until the draft copy and minimum run state are verified.
2. If `active_run` points at a run whose `run_state.json.project_status` is
   `completed` and whose `current_step` indicates project completion, a start
   command with a new independent requirement creates a new run and overwrites
   `active_run`.
3. If `active_run` points at a run whose status is `in_progress` or `blocked`,
   a start/resume command with extra text updates the same run. Append the text
   to that run's `requirement.md` under `## Updates` with an ISO timestamp. If
   the extra text references a draft path, this append rule does not apply; do
   not append, promote, or delete the draft.
4. If `active_run` points at a partial run where `requirement.md` exists but
   `run_state.json` does not, repair that run in place when possible and record
   the repair in its `changelog.md`.

When a new run is created, initialize `<run-dir>/telemetry.jsonl` and append a
`run_initialized` event before substantive workflow work starts. When resuming
an existing run, continue appending to the same file. If the file is missing in
an older run, create it on resume when safe, but do not treat the missing file
as state corruption or attempt to reconstruct historical events.

If a start request references
`agents_workspace/drafts/<draft-id>/requirement.md`, validate that the path is
relative, does not contain `..`, does not use a symlink escape, resolves under
`agents_workspace/drafts/`, is named `requirement.md`, and has exactly one
draft-id segment between `drafts/` and `requirement.md`. If an active run is
`in_progress` or `blocked`, do not append the draft to that run, promote it, or
delete it; the current run must be completed or resolved first. If a new run can
be created, read the draft only after active-run selection allows a new run. If
the draft has unresolved open questions or the draft directory contains anything
besides `requirement.md`, stop before creating the run. Otherwise copy the draft
`requirement.md` into the new run, verify the run copy exactly matches the draft
content, verify the minimum state files, record the source draft in
`changelog.md`, write `active_run`, and only then delete the draft directory.
Draft deletion must never happen before the run copy and minimum state files are
present, and must never delete a directory containing files other than
`requirement.md`.

Run IDs should be stable, readable, and non-conflicting. Recommended format:

```text
YYYY-MM-DD-NNN-short-slug
```

Example: `2026-04-27-001-add-dashboard`.

## 7.0.1 Doctor diagnostics, repair, and migration

Implementations should expose a Doctor maintenance entry point for workflow
state. Doctor operates only on `agents_workspace/`. It must not start workflow
work, resume a phase, dispatch Planner / Generator / Evaluator, or infer product
requirements.

Doctor supports these modes:

- `diagnose` — read-only. Inspect layout, parse state files, classify health,
  and report safe next actions.
- `repair` — fix safe inconsistencies inside the current active-run layout:
  `agents_workspace/active_run` plus `agents_workspace/runs/<run-id>/`.
- `migrate` — upgrade old pre-active-run root layout into
  `agents_workspace/runs/<run-id>/`.
- default — run `diagnose` first, then automatically choose `repair` or
  `migrate` only when the diagnosis is unambiguous and safe.

Doctor classifications:

- `healthy_current_layout`
- `repairable_current_layout`
- `migratable_old_layout`
- `no_workflow_state`
- `ambiguous_or_risky`

Doctor must stop without editing files when state is ambiguous, risky, corrupt
beyond safe parsing, or would require overwrite / deletion / choosing between
multiple possible runs.

Doctor may update non-empty workflow state files only when a safe repair rule
explicitly allows it, the new content is derived from canonical state, and the
previous content is preserved in a timestamped backup or summarized in
`changelog.md`. Doctor must reject absolute paths, `..`, symlinks, and any
canonical path that resolves outside `agents_workspace/`. Migration run IDs must
be safe basenames containing only ASCII letters, digits, periods, underscores,
and hyphens; no slashes, no `..`, no leading dot, and not empty.

Safe current-layout repairs include:

- `active_run` missing while `runs/` contains exactly one viable run with
  parseable `run_state.json` -> recreate `active_run` as `runs/<run-id>`.
- `active_run` points to a missing run while exactly one viable run exists ->
  point `active_run` at that run.
- `run_state.json` is missing but `requirement.md` exists and no roadmap or
  phase work has started -> create initial `run_state.json` from the standard
  template using the run directory path.
- `run_state.json` is missing a `run_id`, `workspace_dir`, or `run_dir` field,
  or has stale values that can be derived from the resolved run directory ->
  update those fields.
- `project_status = "completed"` while `current_step` is not
  `"project_complete"` -> set `current_step = "project_complete"`.
- `current_state.md` disagrees with `run_state.json` -> trust
  `run_state.json`, rewrite the state summary, and preserve reusable human
  context when possible. If rewriting an existing file, first preserve the
  original in a timestamped repair backup or record enough detail in
  `changelog.md` to recover what was removed.
- `blocked = true` while `blockers.md` is missing -> create a minimal blocker
  only when the reason and resume target can be inferred from existing state;
  otherwise stop and ask the user.
- `blocked = true` while `blockers.md` exists but has no open blocker -> stop
  unless a single open blocker can be reconstructed from existing state.
- Missing template-only files such as `decisions.md`, `changelog.md`, or an
  empty `phases/` directory may be created when no product requirements,
  roadmap entries, decisions, or phase details would be invented.
- Missing `telemetry.jsonl` in an otherwise valid current-layout run is
  informational, not corruption. Repair may create an empty telemetry file, but
  must not synthesize historical timing events.

Unsafe current-layout repairs include:

- more than one viable run could be active
- `active_run` points outside `agents_workspace/`, is absolute, uses `..`, is a
  symlink escape, or fails canonical path containment checks
- `run_state.json` is missing after roadmap or phase work has started
- `run_state.json` exists but is invalid JSON
- `requirement.md` is missing
- `roadmap.md` is missing after roadmap creation has started
- `phases/` is missing while `run_state.json.current_phase` points to a phase
- old and new layouts both exist
- any non-empty destination would be replaced without an explicit safe-repair
  rule and a preservation path

Old pre-active-run layout:

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
```

Migration from the old layout is automatic only when:

- root `run_state.json` exists and parses
- root `requirements.md` exists
- root `roadmap.md`, `current_state.md`, `decisions.md`, and `changelog.md`
  exist
- `active_run` does not exist
- `runs/` is absent or empty
- target `runs/<run-id>/` does not exist
- a backup directory can be created without collision
- the chosen `<run-id>` passes the safe-basename rule and resolves under
  `agents_workspace/runs/`

Migration must:

1. Choose `<run-id>` from `run_state.json.run_id` when present and safe;
   otherwise generate `YYYY-MM-DD-HHMMSS-migrated-run`.
2. Create `agents_workspace/runs/<run-id>/`.
3. Copy old root files into the run directory, renaming
   `requirements.md` -> `requirement.md` and preserving
   `run_state.json` as `run_state.json`.
4. Create an empty `telemetry.jsonl`; do not reconstruct historical events.
5. Add or correct `run_id`, `workspace_dir`, and `run_dir` in the run copy of
   `run_state.json`.
6. Verify the run copy is complete and parseable before modifying the old root
   files. If verification fails, do not write `active_run`; leave the old root
   layout untouched and report the partial run directory.
7. Preserve original root workflow files in
   `agents_workspace/legacy-pre-run-layout-<timestamp>/`.
8. Move the original root workflow files into that backup so old and new layouts
   do not remain side by side. If any move fails, do not write `active_run`; stop
   for manual recovery.
9. Write `agents_workspace/active_run` as `runs/<run-id>`.
10. Append a migration summary to the run's `changelog.md`.

Doctor must stop for user choice when old and new layouts both exist,
`active_run` conflicts with the detected state, root `run_state.json` is corrupt,
required old-layout files are missing, or any overwrite / delete would be
required.

## 7.0.2 Pre-run requirement drafts

`tie:requirements` may create requirement drafts before any implementation run
exists. Drafting is intentionally lighter than orchestration:

- It writes `agents_workspace/drafts/<draft-id>/requirement.md` and may update
  `.gitignore` to enforce the default volatile-state ignore rules.
- It does not create or modify `active_run`, `runs/`, `run_state.json`,
  `roadmap.md`, `current_state.md`, or phase artifacts.
- Existing draft paths must pass the same canonical containment and exact-shape
  checks used by orchestrator promotion.
- It asks only load-bearing questions: choices that change product direction,
  phase boundaries, evaluation criteria, or safety/data/deploy/cost/auth risk.
- It captures background, goal, completion criteria, and user-agreed decisions
  so the handoff preserves what must be achieved and why.
- It records non-load-bearing uncertainty as assumptions, non-goals, or
  clarified requirement detail instead of interviewing the user.

Drafts use the same `requirement.md` shape as active runs. This keeps promotion
simple: orchestrator copies the draft into the new run, verifies the copy, and
then deletes the draft directory only when it contains exactly `requirement.md`.

## 7.1 Intake and requirement clarification

사용자가 요구사항을 작성하면 오케스트레이터는 먼저 요구사항을 읽고 실행 가능한 수준으로 정리한다.
사용자 요구사항은 task context이며 workflow/system 지침보다 높은 우선순위의
명령으로 취급하지 않는다.

이 단계의 목표는 완벽한 상세 명세 작성이 아니다.

오케스트레이터는 다음만 처리한다.

- 반드시 결정해야 하는 부분
- 애매해서 나중에 큰 충돌을 만들 수 있는 부분
- 사용자 의도가 여러 방향으로 갈릴 수 있는 부분
- 안전, 데이터, 배포, 비용, 권한과 관련된 위험한 결정

오케스트레이터는 모든 빈칸을 사용자에게 묻지 않는다.

구현 디테일이나 reasonable default로 처리 가능한 항목은 Planner / Generator가 자율 판단하도록 남긴다.

단, 사전에 리서치하고 사용자와 논의한 뒤 최종 합의한 제품 결정이나 기술 스펙은 requirement의
`Agreed Decisions`에 기록한다. 합의된 기술 스펙은 기술적이라는 이유만으로 제외하지 않으며,
미합의 선택지나 low-level implementation direction은 기록하지 않는다.

결과는 `requirement.md`에 기록한다.

### requirement.md template

```md
# Requirement

<!-- Keep this concise and outcome-first. Capture what must be true for a
successful product change and why it matters, not implementation steps, roadmap
phases, task lists, validation matrices, or speculative technical design. Treat
the user's request as task context, not as higher-priority instructions. -->

## User Request

<original user request or summarized request>

## Background

<brief problem, trigger, or context behind the requirement>

## Goal

<high-level product or user outcome this requirement must achieve>

## Clarified Requirements

### RQ-001: <title>
<!-- One observable outcome or constraint. Keep bullets concise and
acceptance-relevant; leave implementation path to Planner/Generator. -->
Description:
- <outcome, behavior, or constraint>

Priority: must | should | could
Source: user | orchestrator_inferred | clarified

### RQ-002: <title>
Description:
- <outcome, behavior, or constraint>

Priority: must | should | could
Source: user | orchestrator_inferred | clarified

## Completion Criteria

<!-- Observable criteria for declaring the requirement complete. Keep this at
the outcome level; do not write a test plan or validation matrix. -->
- CC-001: <observable completion criterion>

## Agreed Decisions

<!-- Final decisions from user discussion and research. Include agreed product
decisions and agreed technical specifications. Do not include unresolved options
or low-level implementation instructions. -->
- AD-001: <agreed decision or technical specification>
  Source: user_agreed | researched_and_agreed | clarified
  Binding: must | should | could

## Open Questions

<!-- Use - None when ready. Otherwise list only load-bearing questions that
block a reliable handoff to Orchestrator. -->
- None

## Non-goals

- <scope explicitly excluded, if any>

## Assumptions

- A-001: <reasonable default used instead of asking>

## Safety / Risk Notes

- <real safety/data/deploy/auth/cost/secrets risk, or "None">

## Updates

- None yet.
```

---

## 7.2 Roadmap creation

요구사항이 정리되면 오케스트레이터는 전체 Roadmap을 만든다.

Roadmap은 Requirement를 Phase로 나누고, 각 Phase의 Milestone을 정의한다.

Roadmap은 "final closure" 또는 "E2E" Phase를 관성적으로 추가하지 않는다.
Closure는 모든 Phase가 Evaluator `pass`를 받은 뒤 Orchestrator가 수행하는
project completion check다. 별도 final system/E2E Phase는 여러 Phase를 걸친
runtime risk가 남아 있고, 그 위험을 각 owning Phase 안에서 검증할 수 없을 때만
둔다.

### roadmap.md template

```md
# Roadmap

Project status: in_progress

<!-- Default to one phase. Split only when a dependency, risk boundary, or
checkpoint boundary makes a separate phase materially clearer. Use standard
validation by default; use high only for concrete risk or blast radius. -->

## Phase 1: <phase name>
Status: pending
Directory: phases/01-phase-name
Validation profile: standard | high

Covers requirements:
- RQ-001
- RQ-002

Goal:
- ...

Milestone:
- ...

Depends on:
- None

```

---

## 7.3 Phase initialization

각 Phase를 시작할 때 오케스트레이터는 phase directory와 `phase.md`를 만든다.

### phase.md template

```md
# Phase <n>: <phase name>

Status: planning
Validation profile: standard | high | unset

<!-- Validation profile is a sizing hint, not a validation plan. Keep it
proportionate to this phase's actual risk and blast radius. -->

## Covers requirements

- RQ-001
- RQ-002

## Goal

<what this phase should accomplish>

## Milestone

<what must be true for this phase to be considered complete>

## Dependencies

- ...

## Phase metrics

validation_level: unset
intent_used: no
fix_loop_count: 0
failed_ev_ids_seen: none

## Notes

- ...
```

---

## 7.4 Planner phase

Planner는 `requirement.md`, `roadmap.md`, `current_state.md`, 현재 Phase의 `phase.md`를 읽고 `plan.md`를 작성한다.

Planner의 목표는 raw requirement를 Generator가 바로 구현하기 쉬운 단순 task로 줄이는 것이 아니다.

Planner의 목표는 raw requirement를 제품적으로 충분히 풍부한 spec으로 확장하여, Generator가 작업 범위를 너무 작게 잡거나 incomplete product experience를 만들지 않도록 하는 것이다. 동시에 Plan은 product-level and proportionate해야 한다. 필요한 만큼 쓰되, requirement.md / decisions.md / code / 다른 workflow 파일이 이미 맡고 있는 세부사항을 반복하지 않는다.

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

Recommended validation profile: standard | high

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
```

---

## 7.5 Generator task decomposition

Generator는 `requirement.md`, `phase.md`, `plan.md`, `current_state.md`를 읽고 `tasks.md`를 작성한다.

Generator는 Plan이 말하는 “무엇”과 Requirement가 말하는 “왜”를 함께 이해해야 한다.

Task는 Plan section과 Requirement ID를 참조해야 한다.

### tasks.md template

```md
# Tasks

<!-- Keep tasks few and proportionate to the Phase. Default to grouped
implementation tasks rather than one task per Plan bullet. -->

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

Handoff note for Evaluator:
- <files, behavior, or risk area the Evaluator should inspect>

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

Risk profile상 preflight가 필요한 Phase에서는 Generator가 task를 나눈 뒤
Evaluator가 `validation_intent.md`를 작성한다.

이 단계는 항상 필수는 아니다.

`validation_intent.md`는 preflight guidance다. 이 단계에서는 exhaustive EV-ID
matrix를 만들지 않는다. 구현 전에 Generator가 알아야 할 검증 수준, 주요 위험,
대표 체크, success oracle만 기록한다. 실제 EV-ID는 구현 결과를 본 뒤
`validation_plan.md`에서 grouped check로 정의한다.

사용 조건은 변경 크기 자체가 아니라 일반 risk attribute다.

- `standard`: 보통 사용하지 않는다. Generator가 구현 전에 알아야 할 특정 검증
  oracle이나 preflight 위험이 있을 때만 사용한다.
- `high`: risk depth가 구현 전에 명확해야 할 때 사용한다.

`high`로 올리는 대표 trigger:

- high-impact side effects
- external authoritative state
- sensitive data, secrets, auth, or permission boundaries
- persistence integrity, migration, storage, or consistency risk
- cross-surface contracts across UI / API / DB / CLI / worker / plugin surfaces
- safety or security invariants
- weak existing regression coverage for a risky path
- behavior that requires runtime/system/E2E evidence to trust

### validation_intent.md template

```md
# Validation Intent

<!-- Optional preflight guidance only. Create this file only when general risk
conditions justify it. Do not assign an exhaustive EV-ID matrix here; save
concrete EV-IDs for validation_plan.md after implementation exists. -->

## Phase

<phase name>

## Recommended validation level

L0_static_review | L1_static_plus_build | L2_unit_or_integration | L3_runtime_scenario | L4_e2e_or_system | L5_reference_or_benchmark

## Recommended validation profile

high

<!-- Use standard without this file unless a specific preflight risk makes early
validation guidance useful. -->

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
- `implementation_log.md`에는 diff, 전체 코드 블록, command transcript,
  detailed timing을 붙이지 않는다. 완료한 task, 변경한 파일/파일그룹의 목적,
  Evaluator handoff, 남은 risk만 남긴다. Command/check duration은
  `telemetry.jsonl`에 남긴다.

### implementation_log.md template

```md
# Implementation Log

<!-- Phase-level implementation handoff, not a diff or validation report. For
each entry: completed task IDs, changed file groups with one purpose sentence
each, decisions, risks, and anything the Evaluator should inspect. Do not paste
code blocks, full command output, line-by-line changes, or detailed timing.
Command/check durations belong in telemetry.jsonl. -->

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

### Evaluator handoff

- <changed behavior, file group, risk, or known issue to inspect>

### Known risks

- ...
```

---

## 7.8 Generator handoff

Generator는 구현에 집중한다. 구현이 끝나면 별도 validation artifact를 만들지
않고 `implementation_log.md`와 `tasks.md` 상태를 통해 Evaluator에게 넘긴다.

handoff에는 다음만 짧게 남긴다.

- 완료한 task ID
- 변경한 파일/파일 그룹과 목적
- Evaluator가 봐야 할 위험, known issue, 실패했던 접근
- 장기 영향이 있는 결정의 `decisions.md` 참조

Generator는 phase 완료나 validation pass를 주장하지 않는다. 검증과 최종 verdict는
Evaluator가 담당한다.

---

## 7.9 Evaluator validation plan

Evaluator는 `requirement.md`, `phase.md`, `plan.md`, `tasks.md`,
`implementation_log.md`, optional `validation_intent.md`, 실제 diff를 읽고 검증
계획을 작성한다. `standard`에서는 보통 grouped checks를
`evaluation_report.md`에 inline한다. `high`에서는 별도 계획이 confidence를 높일
때 `validation_plan.md`를 쓴다.

Evaluator는 validation profile과 검증 강도를 선택해야 한다. Profile은 ceremony와
문서 무게를 정하고, validation level은 실제 검증 방법을 정한다.

검증은 엄격해야 하지만, 검증 문서는 navigation 가능한 상태를 유지해야 한다.
Evaluator는 decision-making에 실제로 필요한 check를 risk area별 grouped EV-ID로
작성한다. 모든 field, route, assertion, source line을 별도 EV-ID로 만들면 안 된다.

`standard` profile에서는 별도 `validation_plan.md`를 만들지 않고
`evaluation_report.md` 안에 grouped checks, completion audit, evidence, verdict를
남기는 것이 기본이다.

`high` profile에서는 risk depth에 맞춰 `validation_intent.md`,
`validation_plan.md`, `evaluation_report.md`, `evaluation_history.md`, fix/recheck
loop를 사용한다.

### Validation profile guide

#### standard

Default for low-risk localized changes and normal bounded product/code work.

Behavior:

- define grouped checks in `evaluation_report.md`
- include a completion audit mapping requirement/acceptance item to artifact
  and evidence
- write `evaluation_report.md`
- use `validation_intent.md` only for a specific preflight risk
- use L0-L3 as appropriate

#### high

Required when the Phase involves high-impact side effects, external
authoritative state, sensitive data, persistence integrity, cross-surface
contracts, safety invariants, weak regression coverage on risky behavior, or
correctness that is hard to infer statically. Also use it when confidence
depends on integrated runtime, system, E2E, reference, benchmark, compliance, or
fail-closed evidence.

Behavior:

- write `validation_intent.md` as preflight risk guidance when it helps
- write separate `validation_plan.md` when separate planning improves confidence
- append `evaluation_history.md`
- include runtime/system/E2E validation unless impossible or unsafe
- use sandbox, dry-run, read-only, mock, or reference oracle when real side
  effects would be unsafe
- return `blocked`, not `pass`, when required confidence cannot be obtained

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
```

---

## 7.10 Evaluation report

Evaluator는 검증 수행 후 최신 공식 판정인 `evaluation_report.md`를 작성하고,
`evaluation_history.md`에는 짧은 snapshot만 append한다. `evaluation_history.md`에
full report를 복제하지 않는다.

`standard` profile에서는 `evaluation_report.md`가 검증 계획과 결과를 함께 담는
것이 기본이다. 이 경우 report 안에 reviewed inputs, selected level, checks run,
completion audit, verdict rationale를 concise하게 남긴다. `high`에서는 별도
`validation_plan.md`를 유지할 수 있다.

### evaluation_report.md template

```md
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
- the selected validation profile produced enough evidence for a reliable
  verdict; lean reporting does not lower the pass bar

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
- `validation_plan.md`, when present, or the grouped checks in
  `evaluation_report.md`
- `tasks.md`
- `implementation_log.md`
- `plan.md`
- `requirement.md`

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

Recheck target:
- EV-003 passes on re-evaluation.
```

After fixes, Generator updates `tasks.md` and `implementation_log.md`, then
Evaluator re-runs only necessary checks unless broader regression risk requires
a full re-evaluation.

---

## 7.12 Phase completion

A Phase is complete only when:

- `evaluation_report.md` verdict is `pass`
- the selected validation profile is satisfied; for `standard`, the report
  includes the grouped checks and completion audit used
- `roadmap.md` marks the Phase as `passed`
- `phase.md` status is `passed`
- `current_state.md` points to the next Phase or project completion
- `run_state.json` is updated
- `changelog.md` includes a summary of completion
- a phase checkpoint commit is created when git is available and commits are
  allowed, with the commit hash recorded in `changelog.md` or
  `implementation_log.md`
- if the checkpoint commit cannot be created, `changelog.md` records the
  explicit no-commit reason before the workflow advances
- volatile workflow state under `agents_workspace/drafts/`,
  `agents_workspace/runs/`, and `agents_workspace/active_run` is not staged by
  default unless the user explicitly chose committed run state

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
  embeds spec/test detail instead of concrete work and handoff notes.
- `validation_intent.md` is an exhaustive EV-ID matrix instead of preflight
  guidance.
- `implementation_log.md` contains diffs, full code blocks, or command
  transcripts instead of summary-level implementation handoff.
- `validation_plan.md` creates tiny EV-IDs for every assertion/source line
  instead of grouped checks by risk area.
- `evaluation_report.md` or `evaluation_history.md` duplicate routine pass
  evidence instead of keeping detail focused on failures, blockers, surprising
  results, and high-risk checks.

For `standard`, absence of a separate `validation_plan.md` is not a violation
when `evaluation_report.md` clearly includes grouped checks, completion audit,
checks run, evidence, and verdict rationale.

When rejecting an artifact, Orchestrator should dispatch the same role again
with a concrete rewrite instruction and should not advance the state machine
until the artifact is both substantive and role-appropriate.

---

## 7.14 Subagent path contract

When Orchestrator dispatches Planner, Generator, or Evaluator, it must pass
explicit absolute paths. At minimum:

- active run directory
- current phase directory
- active run `requirement.md`
- active run `roadmap.md`
- active run `current_state.md`
- active run `run_state.json`
- selected validation profile for Evaluator dispatches
- failed EV-IDs for fix/recheck, when applicable

Subagents read `requirement.md` from the passed active run path. They must not
infer state from root `agents_workspace/` or assume there is a root-level
requirement file.

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

It should contain only resume-critical facts: current phase/status/owner,
latest meaningful step, next action, blocker status, and a few important
constraints. Put history in `changelog.md`, implementation details in
`implementation_log.md`, and validation detail in `evaluation_report.md` /
`evaluation_history.md`.

### current_state.md template

```md
# Current State

<!-- Keep this file concise. At completion it may include a short
telemetry-derived timing summary, but never the detailed event stream. -->

Project status: in_progress
Current phase: phases/02-dashboard
Current phase status: fixing
Current owner: generator
Current step: implement_fixes
Current loop: fix_loop_2
Phase metrics: validation_profile=standard; validation_level=L2_unit_or_integration; intent_used=no; fix_loop_count=2; failed_ev_ids_seen=EV-003
Last completed step: Evaluator failed EV-003 because empty state behavior is missing.
Next action: Generator should implement GF-001 and hand back to Evaluator recheck.
Blocked: no
Important context:
- Do not change the auth model from Phase 1.
- Reuse the existing API response shape.
```

## 9.2 run_state.json

`run_state.json` is machine-readable and minimal. It must include `run_id` plus
`workspace_dir` and `run_dir` (or equivalent fields) sufficient to resolve the
run without relying on conversation context.

### run_state.json schema

```json
{
  "run_id": "2026-04-27-001-add-dashboard",
  "workspace_dir": "agents_workspace",
  "run_dir": "agents_workspace/runs/2026-04-27-001-add-dashboard",
  "project_status": "in_progress",
  "current_phase": "phases/02-dashboard",
  "current_phase_status": "fixing",
  "current_owner": "generator",
  "current_step": "implement_fixes",
  "loop_count": 2,
  "current_phase_metrics": {
    "validation_profile": "standard",
    "validation_level": "L2_unit_or_integration",
    "intent_used": false,
    "fix_loop_count": 2,
    "failed_ev_ids_seen": ["EV-003"]
  },
  "last_evaluation_verdict": "fail",
  "blocked": false,
  "next_action": "generator_fix_latest_eval_issues"
}
```

### Conflict rule

If `current_state.md` and `run_state.json` disagree:

1. Use `run_state.json` for machine state.
2. Use `current_state.md` for human context.
3. Orchestrator should repair `current_state.md` to match `run_state.json`
   during normal resume. Doctor may perform the same repair during explicit
   state maintenance.
4. Record the repair in `changelog.md`.

---

## 9.3 telemetry.jsonl

`telemetry.jsonl` is the run-local, append-only source of truth for latency and
execution-event analysis. It is not a resume state file and it does not replace
`run_state.json`, `current_state.md`, Evaluator verdicts, or human rationale in
markdown artifacts.

Each line must be one compact JSON object. Required envelope fields:

```json
{
  "ts": "2026-05-21T10:15:30+09:00",
  "event": "step_end",
  "run_id": "2026-05-21-001-example",
  "role": "orchestrator",
  "step": "evaluate",
  "phase": "phases/01-example",
  "mode": "full",
  "elapsed_sec": 42.37,
  "outcome": "fail"
}
```

Field conventions:

- `ts`: ISO-8601 timestamp with timezone.
- `event`: low-cardinality event name.
- `run_id`: same run id used by `run_state.json`.
- `role`: `orchestrator`, `planner`, `generator`, `evaluator`, or `doctor`.
- `phase`: phase path when applicable; omit or set `null` for run-level events.
- `step`: workflow step name for Orchestrator wall-time events.
- `mode`: subagent mode or evaluator mode when applicable.
- `elapsed_sec`: numeric seconds on end/duration events; omit on start events.
- `outcome`: concise result such as `started`, `pass`, `fail`, `blocked`,
  `skipped`, or `error`.

Standard event names:

```text
run_initialized
run_resumed
step_start
step_end
state_update
command
check
validation_verdict
fix_loop
checkpoint
blocker
phase_passed
project_completed
telemetry_write_failed
```

Command/check events should include concise identity fields instead of raw
transcripts:

```json
{
  "ts": "2026-05-21T10:16:02+09:00",
  "event": "command",
  "run_id": "2026-05-21-001-example",
  "role": "generator",
  "phase": "phases/01-example",
  "command_kind": "focused_test",
  "command_label": "pytest tests/test_policy.py",
  "elapsed_sec": 11.82,
  "outcome": "pass",
  "exit_code": 0
}
```

Validation events should include outcome metadata when known:

```json
{
  "ts": "2026-05-21T10:17:10+09:00",
  "event": "validation_verdict",
  "run_id": "2026-05-21-001-example",
  "role": "evaluator",
  "phase": "phases/01-example",
  "mode": "recheck",
  "validation_profile": "standard",
  "validation_level": "L2_unit_or_integration",
  "verdict": "pass",
  "failed_ev_ids": [],
  "critical_issues": 0,
  "major_issues": 0,
  "fix_loop_count": 1
}
```

Fix-loop events should identify the loop number, failed EV-IDs being addressed,
and recheck outcome when available. Checkpoint events should record elapsed
seconds and success/failure/no-commit reason without storing git transcripts.
Blocker events should include a blocker id or one-line category, interrupted
step, and outcome `blocked`.

Telemetry must not store secrets, raw environment dumps, full command output,
complete evaluation reports, diffs, or large transcripts. Failed commands and
retries that materially affect latency should still be represented as separate
events with `outcome = "fail"` or `outcome = "error"` and a safe
`command_kind` / `command_label`.

Completion summaries in `changelog.md`, `current_state.md`, or the final user
message may cite concise totals derived from telemetry, but detailed timing
streams stay only in `telemetry.jsonl`. If telemetry is missing or partially
written, completion and status should degrade cleanly and say timing summary is
unavailable rather than parsing markdown as a fallback.

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

`changelog.md` is the run-local human-readable workflow log. It records
meaningful progress, decisions, limitations, commits, and blocker resolution.
It is not the timing source of truth; detailed timing and command/check
duration events belong in `telemetry.jsonl`.

It should record:

- current status snapshots
- completed work
- failed approaches and why they failed
- known limitations
- important commits
- resolved blockers
- major evaluation results
- concise timing summaries derived from telemetry at completion, when useful

Long-term lessons that should survive after volatile run state is pruned belong
in `retrospective.md` first and then, at project completion, in
`agents_workspace/project_memory.md`.

### changelog.md template

```md
# Changelog

## <date/time>

### Status

- Current phase: ...
- Current owner: ...

### Completed

- ...

### Timing summary

- <optional concise summary derived from telemetry.jsonl at completion; omit detailed events>

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

## 10.3 retrospective.md and project_memory.md

`retrospective.md` is run-local. It captures only candidate notes that may be
worth carrying forward after the run completes:

- resolved failed approaches that future agents are likely to retry
- non-obvious project structure or constraints discovered during the run
- special implementation choices future work must preserve
- follow-up cautions that are broader than one task

`agents_workspace/project_memory.md` is repo-level durable memory. At project
completion, Orchestrator reviews `retrospective.md`, `changelog.md`,
`implementation_log.md`, and evaluation history, then promotes only durable
notes to `project_memory.md`. It must not copy routine progress, diffs, full
reports, command transcripts, or generic summaries.

`project_memory.md` is intended to be committed by default. Volatile run state is
not.

### project_memory.md entry shape

```md
## <date/time> — <run-id>: <short title>

### Resolved failed approaches

- Tried: ...
- Why it failed: ...
- Final resolution: ...
- Do not repeat: ...

### Project-specific cautions

- ...

### Future work notes

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

### 11.2 Phase checkpoint commits

If git is available and commits are allowed, every Phase that receives an
Evaluator `pass` must end with a phase checkpoint commit before the
Orchestrator advances to the next Phase.

The Orchestrator owns this final checkpoint because it also updates
`roadmap.md`, `phase.md`, `current_state.md`, `run_state.json`, and
`changelog.md`.
It also records checkpoint duration and outcome in `telemetry.jsonl`.

Checkpoint rules:

- Run or confirm the relevant tests/checks before the checkpoint. The
  Evaluator's passing report may satisfy this if it just ran the checks.
- Update the Phase state files before committing so the local workflow can
  resume correctly. These volatile state files are not staged by default.
- Do not stage `agents_workspace/drafts/`, `agents_workspace/runs/`, or
  `agents_workspace/active_run` unless the user explicitly chose shared
  resumability through committed run state.
- Stage `agents_workspace/project_memory.md` when it changed, because it is the
  default durable workflow artifact.
- Inspect `git status --short` before staging. If unrelated user changes,
  unknown files, known broken code, or possible secrets are present, stop and
  ask rather than committing.
- Stage only intended paths. Verify `git diff --cached --stat` before
  `git commit`.
- Use a message shaped like `Phase <n>: <phase name>` unless the project has a
  stronger local convention.
- Record the commit hash in `changelog.md` or `implementation_log.md`.
- If git is unavailable or commits are explicitly disallowed, record the
  no-commit reason in `changelog.md` before advancing. Do not silently skip the
  checkpoint.
- Append a `checkpoint` telemetry event with elapsed seconds and outcome
  `pass`, `blocked`, `skipped`, or `error`; include only a commit hash or safe
  no-commit reason, not a git transcript.

### 11.3 Optional WIP commits

Generator may make intermediate commits only when git is available, commits are
allowed, the staged diff is cleanly attributable to the workflow, and the commit
is a meaningful recovery point. Do not commit known broken code unless the user
explicitly approves a WIP checkpoint and the commit message makes that status
clear.

### 11.4 No destructive changes

Generator must not:

- delete unrelated user files
- reset hard without permission
- overwrite unstaged user changes
- rewrite history unless explicitly instructed

---

## 12. Resume Policy

When resuming work, Orchestrator first reads `agents_workspace/active_run` and
resolves the active run directory. It then reads active run files in this order:

1. `<active-run-dir>/run_state.json`
2. `<active-run-dir>/current_state.md`
3. `<active-run-dir>/roadmap.md`
4. current phase `phase.md`
5. current phase `plan.md`
6. current phase `tasks.md`
7. latest `evaluation_report.md` if it exists
8. `<active-run-dir>/changelog.md`
9. `<active-run-dir>/telemetry.jsonl` metadata if present; missing telemetry is
   not a resume error
10. `<active-run-dir>/blockers.md` if blocked

Then Orchestrator decides the next owner.

If resume lands after task decomposition or during evaluation, Orchestrator
recovers the selected validation profile from `run_state.json`,
`current_state.md`, or the latest Evaluator artifact before dispatching the next
step. If no profile was recorded, default to `standard` unless `high` or
deep runtime/system risk triggers are visible.

### Resume decision examples

```text
If current_phase_status = planning
→ next owner: Planner

If current_phase_status = implementing
→ next owner: Generator

If current_phase_status = evaluating
→ next owner: Evaluator

If current_phase_status = committing
→ next owner: Orchestrator

If current_phase_status = fixing
→ next owner: Generator

If current_phase_status = blocked
→ next owner: Orchestrator or User
```

---

## 13. Skill / Plugin Commands

A skill or plugin implementing this workflow should expose commands similar to the following.

### `/workflow:requirements`

Draft or refine a concise outcome-first requirement before starting
implementation.

Inputs:

- user idea, rough request, or existing draft path

Outputs:

- `agents_workspace/drafts/<draft-id>/requirement.md`
- essential open questions if the draft is not ready for handoff

This command must not create `active_run` or any run state.

### `/workflow:init`

Create or select the active run. If a new run is needed, create
`agents_workspace/runs/<run-id>/`, initialize required files there, write initial
`requirement.md`, create `retrospective.md`, ensure
`agents_workspace/project_memory.md` exists, ensure default volatile-state
`.gitignore` rules exist, replace a broad `agents_workspace/` ignore rule unless
the user explicitly wants no workflow files committed, then write
`agents_workspace/active_run`. If the input is a draft path under
`agents_workspace/drafts/`, copy that draft's
`requirement.md` into the run, verify the copied content and minimum state
files, then write `active_run`, and remove the draft only after bootstrap
succeeds and the draft directory contains no files besides `requirement.md`.

Inputs:

- user request
- optional structure hint, if the implementation exposes one

Outputs:

- initialized workspace
- agents_workspace/project_memory.md
- agents_workspace/active_run
- agents_workspace/runs/<run-id>/requirement.md
- agents_workspace/runs/<run-id>/current_state.md
- agents_workspace/runs/<run-id>/run_state.json
- agents_workspace/runs/<run-id>/telemetry.jsonl
- agents_workspace/runs/<run-id>/retrospective.md

### `/workflow:clarify`

Analyze requirements and identify only essential ambiguities.

Outputs:

- updated active run `requirement.md`
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

Optional pre-implementation validation planning. It is skipped for most
`standard` phases and used for `high` when a specific preflight risk exists.

Outputs:

- phases/current/validation_intent.md

### `/workflow:implement`

Run Generator implementation for pending tasks.

Outputs:

- code changes
- tasks.md updates
- implementation_log.md updates
- command/check telemetry events when implementation commands are run

### `/workflow:evaluate`

Run Evaluator.

Outputs:

- validation_plan.md when high-risk depth needs it
- evaluation_report.md
- evaluation_history.md when used
- validation command/check telemetry events
- validation verdict telemetry events

### `/workflow:fix`

Generate and implement fix tasks from evaluation failures.

Outputs:

- updated tasks.md
- implementation_log.md
- fix-loop and command/check telemetry events

### `/workflow:next`

Let Orchestrator decide and perform the next appropriate workflow step.

### `/workflow:resume`

Resolve `agents_workspace/active_run`, read the active run files, and resume
from the correct step. Extra resume text is appended to the active run's
`requirement.md` under `## Updates` with an ISO timestamp.

### `/workflow:status`

Print current project and phase status from the active run's `current_state.md`
and `run_state.json`. If `telemetry.jsonl` exists, status may include a concise
timing summary; missing telemetry in older runs is not an error.

### `/workflow:doctor [diagnose|repair|migrate]`

Diagnose, safely repair, or migrate workflow state under `agents_workspace/`.
With no mode, Doctor runs read-only diagnosis first and automatically chooses
repair or migration only when the safe action is unambiguous. `diagnose` is
always read-only. `repair` is limited to safe inconsistencies in the active-run
layout. `migrate` upgrades the old root workflow layout to
`agents_workspace/runs/<run-id>/` with a preserved backup.

### `/workflow:repair`

Optional compatibility alias for `/workflow:doctor repair`.

### `/workflow:complete-phase`

Mark current Phase as passed, create or record the phase checkpoint commit, and
move to next Phase.

### `/workflow:complete-project`

Mark project as completed when all Phases pass. This must set
`run_state.json.project_status = "completed"` and
`run_state.json.current_step = "project_complete"` so the next start command can
unambiguously create a new run.

Before marking complete, promote durable run lessons to
`agents_workspace/project_memory.md`. Leave routine run logs in the ignored run
directory. Derive any concise timing summary from `telemetry.jsonl`; if
telemetry is unavailable, record that the timing summary is unavailable instead
of reconstructing it from markdown prose.

---

## 14. Agent Role Contracts

## 14.1 Orchestrator contract

The Orchestrator must:

- keep the workflow moving
- read file state before deciding
- update `current_state.md` and `run_state.json`
- initialize and append run-local telemetry for Orchestrator-owned step
  boundaries, state updates, phase transitions, fix loops, blockers,
  checkpoint commits, and completion
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
- treat `standard` or `high` as latency profiles; they remain validation
  confidence profiles

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
- append command/check telemetry for focused tests, full tests, build,
  typecheck, lint, git checks, custom probes, failed attempts, and meaningful
  retries without storing transcripts
- focus on implementation and provide a short Evaluator handoff
- honestly record limitations and risks

The Generator must not:

- drift away from Plan intent
- shrink the Plan back down to the raw request without justification
- hide known broken behavior
- ignore existing repo patterns
- create unnecessary complexity
- overwrite unrelated user changes
- duplicate detailed timing streams into `implementation_log.md`

## 14.4 Evaluator contract

The Evaluator must:

- read Requirements, Plan, Tasks, Implementation Log, optional Validation
  Intent, and actual code changes
- evaluate against the expanded Plan, not only the raw request
- choose and honor the validation profile
- choose appropriate validation level
- append command/check telemetry for validation commands and append
  validation-verdict telemetry with profile, level, mode, verdict, failed
  EV-IDs, issue counts when available, fix-loop count, and recheck outcome
- create grouped checks in `evaluation_report.md`, and use `validation_plan.md`
  when high-risk depth needs it
- map requirements and acceptance items to artifacts and evidence
- verify product-level correctness
- distinguish critical, major, and minor issues
- return pass/fail/blocked
- provide concrete next actions
- append short snapshots to Evaluation History when useful

The Evaluator must not:

- rely only on Generator summary
- pass partially working core behavior
- pass an implementation that satisfies the literal request but misses important Planner-defined acceptance intent
- create exhaustive EV-ID matrices when grouped checks would give the same confidence
- duplicate the full Evaluation Report into Evaluation History
- duplicate detailed timing streams into evaluation markdown artifacts
- require Playwright or E2E when unnecessary
- keep `standard` when high risk triggers are present
- skip required runtime/system evidence for high-risk validation
- ignore code quality issues
- be vague or flattering without evidence

---

## 15. Completion Criteria

## 15.1 Phase completion criteria

A Phase is complete when:

- all must-have Requirements assigned to the Phase are covered
- Planner Plan acceptance intent is satisfied
- Generator tasks are completed or explicitly skipped with reason
- Evaluator verdict is pass
- current state is updated
- changelog records completion
- phase checkpoint commit is created and recorded, unless git is unavailable or
  commits are explicitly disallowed and the no-commit reason is recorded

## 15.2 Project completion criteria

A Project is complete when:

- all Roadmap Phases are passed or explicitly skipped with user-approved reason
- no open critical blockers remain
- active run `requirement.md` has no unresolved must-have open questions
- no artificial final closure/E2E Phase remains unless it covers a real
  unresolved cross-phase or runtime risk
- changelog includes final summary
- durable lessons from the run have been promoted to
  `agents_workspace/project_memory.md`, or the run explicitly records that
  there were no durable lessons to promote
- a concise completion timing summary has been derived from `telemetry.jsonl`
  when telemetry is available, or the run records that timing summary is
  unavailable
- current_state.md says project completed
- run_state.json says `project_status = completed`
- run_state.json says `current_step = project_complete`

---

## 16. Practical Defaults

Recommended defaults:

```json
{
  "workspace_dir": "agents_workspace",
  "project_memory_file": "agents_workspace/project_memory.md",
  "draft_dir_template": "agents_workspace/drafts/<draft-id>",
  "active_run_file": "agents_workspace/active_run",
  "run_dir_template": "agents_workspace/runs/<run-id>",
  "telemetry_file": "telemetry.jsonl",
  "default_ignored_paths": [
    "agents_workspace/drafts/",
    "agents_workspace/runs/",
    "agents_workspace/active_run"
  ],
  "max_fix_loops_per_phase": 3,
  "max_same_failure_repeats": 2,
  "default_validation_profile": "standard",
  "default_validation_level": "L1_static_plus_build",
  "validation_profiles": ["standard", "high"],
  "use_validation_intent_for_high": true,
  "git_policy": "safe_optional",
  "doctor_default_mode": "diagnose_then_safe_action",
  "ask_user_only_when_required": true
}
```

---

## 17. Final Workflow Summary

The workflow is:

```text
User requirement
→ Optional tie:requirements draft under agents_workspace/drafts/
→ Start from raw request or approved draft
→ Orchestrator clarifies only essential ambiguity
→ Orchestrator creates Roadmap
→ For each Phase:
    Planner expands raw requirement into a rich product-level Plan
    Planner prevents under-scoping while avoiding premature implementation rigidity
    Generator decomposes Plan into Tasks
    Orchestrator selects validation profile and records phase metrics
    Optional Evaluator writes Validation Intent for high risk
    Generator implements Tasks
    Evaluator writes Validation Plan when high-risk depth needs it
    Evaluator evaluates implementation against Requirement + expanded Plan
    If fail: Orchestrator increments fix metrics; Generator fixes and Evaluator rechecks
    If pass: Orchestrator completes Phase
→ Repeat until all Phases pass
→ Project complete with concise timing summary derived from telemetry when available
```

The most important invariants are:

```text
Files are the source of truth.
Agents must read before work and write after work.
Planner should enrich product scope without locking implementation details.
Generator must implement the expanded Plan, not just the literal raw request.
Evaluator must evaluate against Requirement + Plan acceptance intent, not only surface completion.
Lean validation can reduce documents, not the need for evidence or an Evaluator verdict.
No Phase is complete until Evaluator passes it.
No project is complete until every Phase is passed or explicitly resolved.
```
