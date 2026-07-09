---
name: map
user-invocable: false
description: "Create, resync, or restructure the repo's ARCHITECTURE.md (constitution + map). Out-of-run entry point — during runs the orchestrator updates the map automatically and incrementally; use this for first creation, resync after changes made outside TIE, or restructuring."
---

# tie:map — constitution + map maintenance

You maintain `ARCHITECTURE.md` at the repo root: the codebase document every
TIE role reads before touching code. This is the manual, out-of-run entry
point. During runs the Orchestrator updates the map automatically and
incrementally, so this skill covers only: first creation, resync after work
done outside TIE, and restructuring. If it gets invoked often, that signals
too much work is happening outside TIE — say so.

## The document contract

`ARCHITECTURE.md` holds exactly two parts and follows this skeleton:

```md
# Architecture

<!-- 헌법과 지도만 담는다. 값(리터럴)은 코드 포인터로 강등한다.
백틱 심볼 이름만 쓰고 링크·줄번호는 쓰지 않는다 (Name, don't link). -->

## 헌법 — 왜, 그리고 깨지면 안 되는 것

### 불변식

- <교차 파일 불변식, 레이어 경계, 안전 약속>

### 설계 이유와 기각한 대안

- <왜 이렇게 만들었나. 왜 그 기능이 없나(의도된 부재)>

### 실패한 접근

- <시도 → 실패 이유 → 반복 금지>

## 지도 — 무엇이 어디서 일어나는가

### 전체 흐름

<입구에서 출구까지, 주요 동작 흐름을 단계로. 각 단계 한두 문장 + `심볼` 포인터>

### <영역>

<영역이 커질 때만 소절 추가. 이 영역의 흐름 + `심볼` 포인터. 값·공식은 코드에>
```

Rules that always apply:

- **No literal values, ever.** Constants, thresholds, field lists, formulas,
  weights — demote every one to a backtick code pointer and let the code speak.
- **Name, don't link.** Pointers are backtick symbol names (`loadConfig`,
  `PaymentService`). No hyperlinks, no line numbers — those rot silently.
- **Altitude discipline.** Each level speaks only its own altitude and points
  one level down; it never repeats lower detail. `전체 흐름` names steps and
  points to areas and symbols; an area section names its flow and points to
  symbols; the code holds the rest.
- **One file by default.** Split into area docs only when the file is
  genuinely bloated, never pre-emptively.
- **Cheap pointer checks.** Whenever you touch the map, spot-check the
  backtick pointers you rely on with grep; fix stale ones or flag them.

## Pick a mode

- No `ARCHITECTURE.md` → **create**.
- It exists → **resync**.
- The user asks to split, merge, or adopt an existing differently-shaped
  architecture doc → **restructure**.

## create

1. **Scan the repo top-down.** Entry points first, then the main execution and
   data flows end to end, then subsystem responsibilities. You are hunting
   flows and locations, not detail.
2. **Draft the map.** Name each flow as steps — one or two sentences per step
   plus `symbol` pointers. Never copy values or formulas out of the code.
3. **Draft the constitution — only what code cannot say.** Cross-file
   invariants, layer boundaries, intended absences ("no caching, on purpose"),
   why-decisions and rejected alternatives. Keep it short; one or two pages is
   healthy. If the code already expresses it, leave it out.
4. **Present the draft to the user for correction.** This is a sync
   conversation, not a review ritual: the map converges to the user's mental
   model of the system, and only the user can correct it. Walk the flows, take
   corrections, revise.
5. **Write only after the user confirms.**

## resync

Resync is also the designated follow-up when a run's start staleness probe
or a run's out-of-scope stale flags pointed here.

1. **Verify the doc against the code.** For each mapped flow, check the steps
   still match; grep every backtick pointer to confirm the symbol still
   exists. When git history is available, use `git log` on changed areas to
   focus the check.
2. **Propose a concise delta:** flows added / changed / removed, stale
   pointers and their fixes. A short list, not a rewrite.
3. **Never silently delete constitution entries.** If an invariant or
   why-decision looks stale, flag it as suspected-stale and let the user
   decide — the constitution records intent the code cannot confirm.
4. **Apply after the user confirms.**

## restructure

Only when a file is genuinely bloated — restructure is not routine tidying.

- Keep the altitude rules across the split: the top `ARCHITECTURE.md` keeps
  the constitution and the whole-system `전체 흐름` and points one level down
  to area docs; each area doc speaks its own area's flow and points to symbols.
- **Point to area docs by path.** The top `ARCHITECTURE.md` names each area
  doc with a backtick relative path from the repo root
  (`docs/architecture/auth.md`) — no hyperlinks, no anchors, no line numbers.
  This is the file-level extension of **Name, don't link**; these path
  pointers join the cheap pointer checks, verified by an existence check
  instead of a grep.
- Merging area docs back, or adopting an existing differently-shaped doc,
  follows the same contract: converge the content into the skeleton above.
- Present the restructuring plan and apply only after the user confirms.

## Boundaries

- Read code freely; write only `ARCHITECTURE.md` (plus area docs when
  restructuring).
- Never create or touch `.tie/` state. This is not a run: no run directory,
  no `state.json`, no log.

## Return

Finish with one line covering: mode used, flows added/updated, pointers
fixed, and which user confirmations were obtained.

```text
Map <create|resync|restructure>: <n> flows added/updated, <n> pointers fixed, user confirmed <what>
```
