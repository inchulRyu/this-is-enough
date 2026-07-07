# ThisIsEnough (`tie`)

> 설계부터 가볍게. 이름이 곧 철학입니다: 필요한 것만, 그 이상은 없이.

**English**: [README.md](./README.md)

ThisIsEnough는 **Claude Code**와 **Codex CLI**에서 동작하는 코딩 에이전트용
**파일 우선(file-first) 워크플로우 플러그인**입니다. 사용자의 멘탈 모델,
에이전트의 이해, 코드의 실제 동작 — 이 셋을 계속 일치시킵니다.

## 왜 필요한가

워크플로우 없이 에이전트와 일하면 세 가지 문제가 반복됩니다:

1. **합의가 증발한다** — 대화에서 정한 결정이 컨텍스트가 길어질수록 희석되고
   사라진다.
2. **매 세션 코드베이스를 다시 훑는다** — 느리고, 그마저 종종 잘못 읽는다.
3. **작업 방식이 일정하지 않다** — 결과를 신뢰하기 어렵다.

유행하는 하네스들도 이 문제를 공략하지만 무겁습니다 — 토큰, 시간, 격식.
TIE는 세 문제를 푸는 조각만 남깁니다: 문서화된 합의, 지속되는 지도, 정해진
순서의 고정 역할. 그 외에는 아무것도 없습니다.

## 동작 방식

1. **대화 동기화** (`tie:requirements`) — 지도를 바탕으로 에이전트가 현재
   시스템 흐름과 변경 후 예상 흐름을 보여주고, 합의는 이루어지는 순간
   문서로 기록됩니다.
2. **승인 게이트** — 관찰 가능한 "~하면 ~한다" 흐름으로 이루어진 핵심
   체크리스트를 구현 전에 딱 한 번 확인받습니다. 승인은 대화에서 답하는
   것으로 끝 — 에이전트가 요구사항의 `## 승인`과 `state.json`에 대신
   기록하며, 워크플로우 파일을 직접 편집할 일은 없습니다.
3. **런(run)** — 계획(방향만; 큰 작업은 단계로 나누고 뒷 단계는 시작 직전에
   상세화) → 구현(Implementer가 코드 앞에서 세부를 스스로 판단) → 검증(체크리스트의
   흐름을 실제로 실행 + 지도의 인접 흐름 확인) → 지도 갱신(자동·증분) →
   체크포인트 커밋, 단계마다 반복. 검증 통과 없이는 완료도 없습니다.
4. **완료** — 실패한 접근과 새로 발견한 불변식을 헌법으로 승격하고 최종 보고.

## ARCHITECTURE.md — 헌법 + 지도

재탐색 문제의 답은 레포 루트의 커밋되는 파일 하나입니다. **헌법**에는 코드만
봐서는 알 수 없는 것 — 불변식, 설계 이유와 기각한 대안, 실패한 접근 — 이
들어갑니다. **지도**에는 무엇이 어디서 일어나는지 — 시스템의 흐름들, 각 단계는
한두 문장과 백틱 `심볼` 포인터 — 가 들어갑니다. 값(리터럴)은 절대 지도에 넣지
않고 코드에 남깁니다. 그래서 리터럴 변경은 문서 갱신이 필요 없고, 낡은
포인터는 grep 한 번으로 잡힙니다. 런 중의 갱신은 자동·증분이며, `tie:map`은
최초 생성 · TIE 밖에서 작업한 뒤 재동기화 · 재구성을 위한 수동 진입점입니다.

## 설치

### Claude Code — 영구 설치 (권장)

이 레포는 자기 자신의 플러그인 마켓플레이스를 겸합니다
(`.claude-plugin/marketplace.json`). 한 번 추가하면 모든 세션·프로젝트에서
기억됩니다 — `--plugin-dir` 플래그도, 세션마다의 설정도 필요 없습니다.

**방법 A: GitHub에서 바로** (클론 불필요 — 권장):

```text
/plugin marketplace add inchulRyu/this-is-enough
/plugin install tie@thisisenough
/reload-plugins
```

**방법 B: 로컬 클론에서** (레포가 이미 디스크에 있다면):

```bash
git clone https://github.com/inchulRyu/this-is-enough.git
```

그다음 Claude Code 안에서:

```text
/plugin marketplace add /absolute/path/to/this-is-enough
/plugin install tie@thisisenough
/reload-plugins
```

설치 후 `/plugin` → **Installed** 탭에서 확인할 수 있습니다. 슬래시 커맨드
(`/tie:requirements`, `/tie:start`, `/tie:map`, `/tie:resume`, `/tie:status`,
`/tie:doctor`)가 커맨드 피커에 나타납니다.

업데이트는:

```text
/plugin marketplace update thisisenough
/plugin update tie
/reload-plugins
```

### Claude Code — 개발 / 일회성 테스트

플러그인 자체를 고치면서 등록 없이 띄우려면:

```bash
claude --plugin-dir /path/to/this-is-enough
```

현재 세션에만 로드됩니다.

### Codex CLI

Codex는 현재 `~/.agents/skills/`에서 스킬을 가장 안정적으로 발견합니다.
한 줄로 설치:

```bash
curl -fsSL https://github.com/inchulRyu/this-is-enough/raw/refs/heads/main/install-codex.sh | bash
```

스크립트는 `~/.codex/thisisenough`에 클론하고
`~/.agents/skills/tie -> ~/.codex/thisisenough/skills` 심링크를 만듭니다.
관리 클론에 로컬 수정이나 갈라진 커밋이 있으면 덮어쓰지 않고 거부합니다.

Codex를 재시작한 뒤 입력:

```text
$tie:
```

`tie:requirements`, `tie:start`, `tie:planner`, `tie:implementer`,
`tie:verifier`, `tie:map`, `tie:resume`, `tie:status`, `tie:doctor`가
보여야 합니다.

업데이트는 같은 한 줄을 다시 실행하면 됩니다 — 멱등하며 관리 클론을 최신
커밋으로 갱신합니다:

```bash
curl -fsSL https://github.com/inchulRyu/this-is-enough/raw/refs/heads/main/install-codex.sh | bash
```

전체 레퍼런스: [`.codex/INSTALL.md`](./.codex/INSTALL.md). 두 플랫폼의 제거
방법은 아래 [제거](#제거) 섹션에 있습니다.

> Codex 팁: 서브에이전트 디스패치에는 `~/.codex/config.toml`의
> `multi_agent = true`가 필요합니다. 없으면 Planner/Implementer/Verifier가
> 오케스트레이터의 컨텍스트 안에서 인라인으로 실행됩니다(동작은 하지만
> 토큰을 더 씁니다).

### 제거

**Claude Code:**
```text
/plugin uninstall tie@thisisenough
/plugin marketplace remove thisisenough
```

**Codex CLI:**
```bash
rm ~/.agents/skills/tie
rm -rf ~/.codex/thisisenough   # 선택, 클론까지 제거
```

## 사용법

```text
# 양 플랫폼에서 이름이 같습니다: Claude Code는 /tie:..., Codex CLI는 $tie:...

# 대화 동기화 → 요구사항 초안 → 체크리스트 승인
/tie:requirements 대시보드 요구사항을 정리하고 싶어.

# 런 시작 — 승인된 초안으로, 또는 날 것의 요구사항으로(체크리스트 먼저 확인)
/tie:start from draft .tie/drafts/<draft-id>.md

# ARCHITECTURE.md 생성/재동기화 · 재개 · 상태 · 진단/복구
/tie:map    /tie:resume    /tie:status    /tie:doctor
```

## 런 하나의 흐름 — 시나리오

작은 CLI 계산기에 `subtract` 명령을 추가한다고 해봅시다.
(예시는 Claude Code 문법입니다. Codex에서는 위 표대로 `/tie:`를 `$tie:`로
바꾸면 됩니다.)

**1. 요구사항을 다듬는다.**

```text
/tie:requirements add와 같은 인터페이스로 subtract 명령을 추가하고 싶어.
```

에이전트는 레포를 훑는 대신 `ARCHITECTURE.md`를 읽고, 현재 흐름과 변경 후
예상 흐름을 보여주며, 합의가 이루어지는 순간마다
`.tie/drafts/<draft-id>.md`에 기록합니다. 초안은 관찰 가능한 흐름들로 된
핵심 체크리스트로 수렴합니다:

```md
## 핵심 체크리스트
- [ ] C-1: `calc.py subtract 5 3`을 실행하면 2.0을 출력하고 종료 코드 0으로 끝난다
- [ ] C-2: 기존 add 명령은 이전과 완전히 동일하게 동작한다
- [ ] C-3: 알 수 없는 명령을 주면 subtract를 포함한 usage를 보여주고 종료 코드 1로 끝난다
```

**2. 승인하고 시작한다.**

```text
/tie:start from draft .tie/drafts/2026-07-03-001-calc-subtract.md
```

승인은 대화에서 답하는 것입니다 — "승인합니다", 또는 "C-2는 이것도 다뤄야
해: …"로 먼저 재협상해도 됩니다. 에이전트가 `requirement.md`의 `## 승인`과
`state.json.approved_at`에 기록합니다. 요구사항 대화에서 이미 승인된 초안은
곧바로 시작됩니다. 초안 없이 날 것의 요구사항을 `/tie:start`에 바로 넘겨도
됩니다 — 그러면 에이전트가 요구사항을 직접 작성하고, 다른 무엇보다 먼저
체크리스트를 보여주고 한 번의 확인을 받습니다.

**3. 나머지는 런이 알아서 한다.**

- **Planner**가 `plan.md`를 씁니다: 기술 방향과 굵은 작업 항목(W-n), 각
  항목이 커버하는 C-n 표기. 큰 작업은 단계로 나누되 첫 단계만 상세화하고,
  뒷 단계는 그때까지 얻은 지식으로 시작 직전에 상세화합니다.
- **Implementer**가 W-n 단위로 구현합니다. 세부는 코드 앞에서 스스로 판단하고,
  결정과 실패한 접근을 `log.md`에 남깁니다.
- **Verifier**가 체크리스트의 모든 흐름을 실제로 실행합니다(읽기만 하는 것은
  검증이 아닙니다). 지도의 인접 흐름을 회귀 목록으로 함께 확인하고, 판정을
  `verification.md`에 씁니다. `fail`이면 Implementer가 구체적 다음 행동과 함께
  수정 라운드를 받습니다 — 추측으로 고치지 않고 원인을 증거로 확정한 뒤,
  수정이 건드릴 파급을 먼저 선언하고 고치며, recheck는 그 파급부터 다시
  봅니다. 수정 예산이 바닥나도 바로 당신을 부르지 않습니다: 물러서서
  **reframe**합니다 — 막힌 컨텍스트의 가정을 하나도 물려받지 않은 신선한
  렌즈 에이전트들(문제 재정의·환경 의심·딥서치)이 사실만으로 문제를 다시
  도출합니다. 새 원인이 증거로 확정되면 수정 예산이 갱신되고, 진짜 사용자급
  결정만 블로커로 도달합니다. 횟수 제한이 있어 무한 루프는 없습니다.
- `pass`가 나오면 오케스트레이터가 C-n 체크박스를 채우고, 동작이나 구조가
  바뀌었다면 지도를 증분 갱신하고, 체크포인트 커밋을 만듭니다
  (`tie: <run-id> …`, `.tie/`는 절대 스테이징하지 않음).

**4. 중단은 문제가 되지 않는다.**

모든 결정은 컨텍스트가 아니라 파일에 있습니다. 런 도중 터미널을 닫고 내일
돌아와서:

```text
/tie:resume
```

런이 멈춘 정확히 그 지점에서 이어집니다. 승인 대기도 마찬가지입니다:
헤드리스·무인 시작은 체크리스트를 보여주며 blocked로 멈추고, `/tie:resume`에
승인을 담아 답하면 기록하고 계속합니다.

**5. 완료.** 실패한 접근과 새로 발견한 불변식이 `ARCHITECTURE.md` 헌법으로
승격되고, 변경을 머릿속에 다시 동기화해주는 짧은 explainer를 받습니다:
당신 언어로 쓴 변경 전후 흐름, 대신 내린 결정들, 커밋, 그리고 직접
확인해볼 수 있는 명령 한두 개 — 원하면 무엇이 바뀌었는지 2~3문항 퀴즈까지.

## 스킬

| 스킬               | 역할                                                                       |
| ------------------ | -------------------------------------------------------------------------- |
| `tie:requirements` | 대화 동기화; 합의가 이루어질 때마다 `.tie/drafts/` 아래 초안에 기록.        |
| `tie:start`        | 진입점. 런 상태 머신을 끝까지 운전.                                         |
| `tie:planner`      | 기술 방향과 W-n 작업 항목; 큰 작업은 단계별 지연 상세화.                    |
| `tie:implementer`  | 구현; 세부는 현장에서 판단; 결정과 실패 접근을 기록.                        |
| `tie:verifier`     | 체크리스트 흐름 + 지도의 인접 흐름을 실행; pass/fail/blocked 판정.          |
| `tie:map`          | `ARCHITECTURE.md` 생성·재동기화·재구성(사용자 확인 하에).                   |
| `tie:resume`       | `.tie/active_run`이 가리키는 런을 재개.                                     |
| `tie:status`       | 활성 런의 읽기 전용 스냅샷.                                                 |
| `tie:doctor`       | 진단, 안전한 복구, v0.3 워크스페이스 마이그레이션.                          |

역할 스킬(`tie:planner`, `tie:implementer`, `tie:verifier`)은 디스패치되는
역할의 계약을 담는 것으로, 직접 호출할 일은 없습니다. Claude Code에서는
피커에서 숨겨지고(`user-invocable: false`), Codex에서는 `$tie:` 아래 보이지만
디스패치된 서브에이전트용입니다.

## 모델과 effort

TIE는 모델도 reasoning effort도 지정하지 않습니다. 모델 선택은 TIE가
존재하는 이유인 세 문제 중 어느 것도 풀지 않고, 모델명은 호스트마다 다르고
금방 낡으며, 플러그인이 사용자의 비용을 몰래 결정해서는 안 되기 때문입니다.
모든 역할은 세션 설정을 상속합니다 — Claude Code에서는 `/model`과 `/effort`,
Codex에서는 `~/.codex/config.toml`의 `model` / `model_reasoning_effort`.
Claude Code에서 역할별로 고정하고 싶다면 `agents/`의 에이전트 frontmatter에
`model:` 한 줄을 추가하면 됩니다 — 딥 리서치를 하는 Planner가 고추론 모델의
이득을 가장 크게 봅니다. Codex는 설정이 전역으로 적용됩니다.

## 워크스페이스 구조

```text
ARCHITECTURE.md            # 헌법 + 지도 — 커밋됨
.tie/                      # 휘발성 워크플로우 상태 — 전체 gitignore
  active_run               # 포인터: runs/<run-id>
  drafts/
    <draft-id>.md          # 승인 전 요구사항 초안
  runs/
    <run-id>/
      requirement.md       # 요구사항 명세: 합의(A-n), 체크리스트(C-n), 승인
      plan.md              # 기술 방향 + 작업 항목(W-n)
      verification.md      # 최신 검증 보고 (덮어씀)
      log.md               # 태그된 이벤트의 append-only 저널
      state.json           # 기계용 재개 상태
```

런당 파일 다섯 개, gitignore 규칙은 `.tie/` 단 하나 — 커밋할 가치가 있는
것은 처음부터 `ARCHITECTURE.md`에 살기 때문입니다.

## 쓰지 않아야 할 때

한 줄짜리 버그 수정(그냥 고치세요), 동작 변화가 없는 순수 리팩터링(체크리스트에
넣을 것이 없음), 일회용 스크립트(워크스페이스가 아깝습니다). 그런 경우에도
지도의 권위는 유지됩니다: 런 없이 동작이나 구조가 바뀌었다면 직접 또는
`tie:map`으로 갱신하세요.

## v0.3에서 마이그레이션

`/tie:doctor`(또는 `$tie:doctor`)를 실행하세요. v0.3 레이아웃(phase 디렉토리,
`project_memory.md`, 세 줄짜리 gitignore)을 감지하고, 진행 중인 v0.3 런은
v0.3 규칙으로 끝내라고 안내하며, 확인을 받아 `project_memory.md`를
`ARCHITECTURE.md` 헌법으로 승격해줍니다.

## 안전

어떤 역할도 프로젝트 밖 파일을 수정하거나, 시스템/네트워크 설정을 바꾸거나,
확인 없이 파괴적 git을 실행하거나, 시크릿을 건드리거나, Verifier의 pass 없이
완료를 선언하거나, 위험하고 되돌릴 수 없는 단계를 사용자 OK 없이 지나가지
않습니다. 그런 상황에서는 명확한 블로커와 함께 멈춥니다.

## 스펙

설계 근거와 계약: [`docs/runtime-spec-v0.4.md`](./docs/runtime-spec-v0.4.md).
스킬들은 이 스펙에서 파생되며, 런타임에는 절대 스펙을 읽지 않습니다.

## 라이선스

MIT.
