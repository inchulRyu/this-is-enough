---
name: requirements
description: The top-of-workflow conversation mode — sync the user's mental model with the codebase and draft an approvable requirement spec (요구사항 명세) under .tie/drafts/.
---

# tie:requirements — sync and draft the requirement spec

This is the top of the workflow: a conversation whose job is to synchronize
three things — the user's mental model, your understanding, and the codebase's
actual behavior. The synchronized result is written into a requirement draft
(요구사항 명세) the user can approve. No run is created here.

## Ground the conversation in the map

- If `ARCHITECTURE.md` exists at the repo root, read it first. Do not scan the
  whole codebase; descend into code only where the map points.
- Present, in the user's language:
  1. the CURRENT system flow relevant to the request (from the map), then
  2. the EXPECTED flow after the change.
- Iterate on both until they match what the user has in mind. When the user
  corrects you, update the draft immediately.
- If no `ARCHITECTURE.md` exists, suggest running `tie:map` first. If the user
  declines, proceed with light, targeted repo reading scoped to the request.

## Live-update rule (the point of this skill)

**Every agreement, decision, or decided work item is written into the draft
the moment it happens.** Agreements append to `## 합의 사항` as `A-n`, decided
behavior lands in `## 핵심 체크리스트` as `C-n`, and flow corrections update
`## 변경 후 기대 흐름`. An agreement that lives only in conversation context
does not exist — long conversations dilute context, and the draft is the only
thing that survives. This is a hard rule, not a style preference.

## Draft file

One draft = one file (no directory):

```text
.tie/drafts/<draft-id>.md
```

`draft-id` is `YYYY-MM-DD-NNN-<short-slug>`: current local date, the next
sequence NNN that conflicts with nothing under `.tie/drafts/` or `.tie/runs/`,
and a short slug from the requirement.

Bootstrap new drafts from the bundled template
`references/file-templates/requirement.md`, resolved relative to the installed
ThisIsEnough skills bundle — never the user's project working directory.

If the user references an existing draft path or id, update that draft. If
they say "the draft" and exactly one exists, use it; if several exist and the
target is unclear, ask. Before updating an existing draft path, require ALL
of: relative path; no `..`; no symlink escape; resolves under `.tie/drafts/`;
basename `<draft-id>.md` directly under `drafts/` (no subdirectory). Reject
anything else instead of treating it as a draft.

## Draft content

Identical shape to the run-level `requirement.md`, so the Orchestrator can
promote it by copying:

```md
# 요구사항 명세

## 배경과 목표

<왜 이 변경이 필요한가, 무엇이 달성되어야 하는가. 몇 줄>

## 합의 사항

<!-- 대화 중 지속 갱신. 합의 즉시 추가. 구현을 구속하는 합의(기술 선택 포함)도 여기에 -->
- A-1: <합의 내용>

## 변경 후 기대 흐름

<이 요구사항이 반영된 시스템의 동작 흐름. 짧은 단계 서술. 사용자 언어로>

## 핵심 체크리스트

<!-- 각 항목은 관찰 가능한 동작 흐름 하나 — "~하면 ~한다" 형태.
구현 방식·함수명·값은 쓰지 않는다. 이 목록이 검증의 기준이 된다. -->
- [ ] C-1: <흐름>
- [ ] C-2: <흐름>

## 제외 범위

- <이번에 하지 않는 것>

## 미결 질문

- 없음

## 승인

대기

<!-- 승인되면: 승인됨 (<ISO 일시>) -->

## 갱신 기록

- 없음
```

## Checklist authoring rules

- Each `C-n` is ONE observable behavior flow in "~하면 ~한다" form
  (when X happens, the system does Y).
- No implementation method, function names, or literal values. The checklist
  describes behavior the user can observe; it becomes the Verifier's
  verification standard.
- When the change touches existing behavior, include a `C-n` stating that the
  relevant adjacent flow keeps working unchanged.
- Keep the list short. If the user cannot confirm it in one read, move scope
  into `## 제외 범위` instead of growing the list.

## Question policy

Ask only load-bearing questions — ones whose answer:

- materially changes product direction or scope;
- is required to define observable success;
- involves safety, data deletion, deployment, auth, permissions, cost,
  secrets, or irreversible side effects.

Everything else gets a recorded assumption in `## 합의 사항` or an exclusion
in `## 제외 범위` instead of an interview. Do not ask about implementation
details, copy text, or choices Planner/Implementer can reasonably make.

## Approval and handoff

Approval is not a document-review ceremony: walk the user through
`## 핵심 체크리스트` once and confirm it matches the behavior in their head.

When the user confirms, set `## 승인` in the draft to `승인됨 (<ISO 일시>)`
and hand off:

```text
Claude Code: /tie:start from draft .tie/drafts/<draft-id>.md
Codex CLI:   $tie:orchestrator Start from draft .tie/drafts/<draft-id>.md
```

If not approved, give the draft path and state exactly what blocks approval
(unconfirmed C-ns or remaining `## 미결 질문` items). Do not include the
start commands.

## Hard boundaries

- Write only `.tie/drafts/<draft-id>.md` — with the single exception of the
  `.gitignore` rule below. Never create `.tie/runs/`, `.tie/active_run`,
  plan artifacts, or implementation artifacts.
- Never promote or delete drafts; the Orchestrator owns promotion.
- Never write `ARCHITECTURE.md`. Reading it is the norm; creation and
  restructuring belong to `tie:map`.
- Do not dispatch Planner, Implementer, or Verifier.
- Ensure `.gitignore` contains the single rule `.tie/`. If the old three-rule
  set (`.tie/drafts/`, `.tie/runs/`, `.tie/active_run`) is present, replace
  it with `.tie/`.
