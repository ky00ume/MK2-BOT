# UNO Game UI — 기술 구조 문서

## ⚠️ 변경 이력 (중요)

### v2.0 — LUA Trigger Script 기반 (현재)

**이전 v1.0 방식의 문제점:**
- `data.extensions.risuai.triggerscript` 배열이 비어 있었음 → 게임 엔진 없음
- Regex Script의 `out` 필드에 `<script>` 태그 포함 → RISUAI 보안 제한으로 JS 실행 불가
- AI가 `[UNO_STATE]` 블록을 출력해야 했으나 신뢰성 없이 출력 → `{AFF|...}`, `{SIG|...}`, `{null}` 등의 깨진 태그가 화면에 그대로 노출

**현재 v2.0 해결책:**
- 모든 게임 로직을 **LUA Trigger Script** (`triggerscript` 배열)로 이전
- AI는 RP 서사만 담당 → `[UNO_STATE]` 블록 출력 완전 금지
- Regex Script는 CSS 스타일시트와 JS 파싱 코드를 제거하고, AI 출력 정리 regex만 남김
- `listenEdit("editDisplay", ...)` 를 사용해 매 메시지 렌더링 시 HTML UI를 동적 삽입

---

## 현재 아키텍처

```
유저 입력
    │
    ▼
onInput(triggerId)          ← LUA Trigger Script
    │
    ├── /start → 게임 초기화 (108장 덱, 7장 딜링, 라운드 시작)
    ├── 텍스트 카드 명령 → doPlay()
    └── stopChat() → AI 응답 차단 (게임 처리 중)

버튼 클릭 ({{button::...}})
    │
    ▼
playCard_N(triggerId)       ← LUA 함수 (N = 손패 인덱스)
drawCard(triggerId)         ← 카드 뽑기
declareUno(triggerId)       ← UNO 선언
    │
    └── doPlay() → 게임 상태 업데이트 → saveG()

AI 응답 생성 후
    │
    ▼
onOutput(triggerId)         ← LUA Trigger Script
    └── 깨진 태그 제거, [UNO_STATE] 블록 제거

메시지 렌더링 시
    │
    ▼
listenEdit("editDisplay")   ← LUA Trigger Script
    └── buildUI() → HTML/CSS 게임 UI를 메시지에 첨부
```

---

## LUA 게임 엔진 구조

| 모듈 | 설명 |
|------|------|
| **Dialogues (D)** | 상황별 미쿠 대사 풀 (9개 카테고리, 3~6개 바리에이션) |
| **Card Utilities** | cardColor, cardVal, isNum, isAction, isDraw, canPlay 함수 |
| **Deck** | mkDeck() 108장 생성, shuffle() Fisher-Yates |
| **Serialization** | ser()/des() — 핸드를 쉼표 구분 문자열로 직렬화 |
| **State I/O** | loadG(tid)/saveG(tid) — setState/getState 래퍼 |
| **Miku AI** | mikuPickCard(), mikuChooseColor(), mikuDoTurn() |
| **Round Logic** | initRound() — 딜링, 1% 이벤트, 시작 카드 세팅 |
| **Series Logic** | handleRoundEnd() — 라운드/시리즈 종료 처리 |
| **UI Builder** | buildUI() — HTML/CSS 렌더링 (CSS 인라인) |
| **Handlers** | onInput, onOutput, drawCard, declareUno, playCard_0~19 |

---

## 게임 상태 키 (setState/getState)

| 키 | 타입 | 설명 |
|----|------|------|
| `deck` | string | 쉼표 구분 덱 카드 목록 |
| `mh` | string | 미쿠 손패 |
| `uh` | string | 유저 손패 |
| `top` | string | 버린 카드 더미 맨 위 카드 |
| `col` | string | 현재 활성 색상 (Red/Blue/Green/Yellow) |
| `turn` | string | "miku" 또는 "user" |
| `ms` | string | 미쿠 승수 |
| `us` | string | 유저 승수 |
| `rnd` | string | 현재 라운드 번호 |
| `active` | string | "1" = 게임 진행 중 |
| `uno` | string | "1" = UNO 선언됨 |
| `stk` | string | 드로우 스택 누적치 |
| `said` | string | 미쿠 현재 대사 |
| `special` | string | "1" = 1% 이벤트 발동 |

---

## 카드 표기 규칙

| 카드 | 표기 |
|------|------|
| 빨강 5 | `Red5` |
| 파랑 Skip | `BlueSkip` |
| 초록 Reverse | `GreenReverse` |
| 노랑 Draw Two | `YellowDraw2` |
| Wild | `Wild` |
| Wild Draw Four | `WildDraw4` |

---

## UI 레이아웃

```
┌────────────────────────────────────────┐
│  🃏 미쿠 0 : 0 유저 | Round 1 | 내 턴  │  ← 스코어바
├────────────────────────────────────────┤
│  😆 미쿠: 어쭈? 그게 최선이야?♡        │  ← 말풍선
├────────────────────────────────────────┤
│  미쿠 패                               │
│  [UNO][UNO][UNO][UNO][UNO][UNO][UNO] 7장│  ← 뒷면 카드
├────────────────────────────────────────┤
│  버린 카드  [🔴5]     🂠 뽑기(93장)    │  ← 중앙 영역
├────────────────────────────────────────┤
│  내 패 (7장)                           │
│  [🔴3][🔵7][🟢⊘][🔴+2]...            │  ← 클릭 가능 카드
│  (흐릿한 카드 = 낼 수 없음)            │
├────────────────────────────────────────┤
│  ⚠️ 드로우 스택 +4 (해당 시)           │
├────────────────────────────────────────┤
│  UN○를 할 때는 카드를 잘 섞어서...    │  ← 하단 안내
└────────────────────────────────────────┘
```

---

## Regex Script (현재)

| 항목 | 값 |
|------|-----|
| **역할** | AI 출력의 깨진 태그 제거 |
| **패턴** | `\{(?:AFF\|SIG\|null)[^}]*\}` |
| **교체** | 빈 문자열 |
| **타입** | both (유저 입력 + AI 출력 양쪽) |

> JS `<script>` 기반의 HTML 파싱 코드는 RISUAI에서 실행되지 않아 제거되었습니다.  
> UI 렌더링은 전적으로 LUA `listenEdit("editDisplay", ...)` 콜백이 담당합니다.

---

*v1.0 — JS+Regex 기반 (구버전, 동작 불가)*  
*v2.0 — LUA Trigger Script 기반 (현재)*
