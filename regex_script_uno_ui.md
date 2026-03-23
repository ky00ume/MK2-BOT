# UNO Game UI — 기술 구조 문서

## ⚠️ 변경 이력 (중요)

### v1.0 — AI 의존 방식 (폐기)
- AI가 `[UNO_STATE]` 블록을 출력 → regex JS로 파싱
- 문제: AI가 상태 블록을 신뢰성 있게 출력 못함, `<script>` 차단됨

### v2.0 — LUA editDisplay 방식 (폐기)
- `listenEdit("editDisplay", ...)` 콜백으로 HTML 반환
- `setState`/`getState`로 상태 저장
- 문제: **editDisplay 콜백이 화면에 HTML을 렌더링하지 않음** (8 PR 내내 미해결)

### v3.0 — CBS 변수 치환 방식 (안정화)
- `setChatVar`/`getChatVar`로 모든 상태 관리
- `customScripts` (editdisplay/editrequest 타입)로 플레이스홀더 → CBS 변수 치환
- `addChat` + `reloadDisplay`로 UI 갱신
- `backgroundHTML`에 CSS 정의

### v4.0 — 모듈 분리 + 자가 진단 로그 + 로어북 이벤트 (이전)
- **3-모듈 구조**: `CardEngine` / `HouseRule` / `CurseEvent` 계층 분리 (단일 파일 내 섹션 구분)
- **자가 진단 로그**: `DEBUG_MODE` + `log()` / `flushLog()` 시스템 추가
- **1% 이벤트 로어북 방식**: `CURSE_USE_LOREBOOK` 플래그로 로어북 방식 / 스크립트 방식 토글
- **CBS 변수 그룹 분류**: A(덱) / B(손패) / C(게임 진행) / D(1% 이벤트) 4그룹

### v5.0 — 완전 재구성: 이중 필터 + 상시 판정 로그 + tostring 강제 (현재) ✅
- **BasicRule/HouseRule 완전 분리**: `BasicRule_canPlay` (순수 기본 규칙) + `HouseRule_apply` (하우스 룰) 이중 필터
- **JudgeLog 상시 출력**: `JudgeLog_evaluate()` — `DEBUG_MODE` 무관, 카드 제출 시마다 UI 메시지 영역에 판정 로그 1줄 출력
- **tostring() 강제**: `BasicRule_canPlay` 내 모든 비교 직전 `tostring()` 적용 → 숫자/문자열 혼동 원천 차단
- **playCard 중복 제거**: wild/일반 분기에서 각각 수행하던 UNO 체크·승리 체크를 공통 후처리 블록 1개로 통합

---

## 현재 아키텍처 (v5.0)

```
유저 입력 "/start"
    │
    ▼
onInput(triggerId)          ← Lua Trigger Script
    │
    └── stopChat() → startGame()
            │
            ├── CurseEvent_reset()    — 이벤트 상태 초기화
            ├── startNewGame()        — 덱, 패 초기화, 상태 setChatVar
            │       ├── CardEngine_createDeck() / CardEngine_shuffle()
            │       └── log() / flushLog()
            ├── saveUI()    — cv_game_html에 게임 UI HTML 저장
            ├── savePanel() — cv_panel_html/label/sub 저장
            ├── saveStatus() — cv_status_html 저장 + saveBottomUI()
            ├── flushLog()  — 디버그 로그를 채팅에 출력 (DEBUG_MODE=true 시)
            ├── addChat(triggerId,"char","{STATUS_BAR}\n{UNO_GAME}\n{SIDE_PANEL}")
            ├── setChatVar("cv_game_msg_idx", len)
            └── reloadDisplay()

버튼 클릭 (risu-btn 속성)
    │
    ▼
onButtonClick(triggerId, btnValue) ← Lua 함수
    │
    ├── "play-N"      → playCard(triggerId, N)
    │       ├── CurseEvent_checkLorebookPending()  — 로어북 방식 대기 체크
    │       ├── ① JudgeLog_evaluate → BasicRule_canPlay (기본 규칙 판정)
    │       │       └── tostring() 강제 후 비교 → logHTML + logText 반환
    │       ├── ③ CurseEvent_onGreen8Played() (완전 독립; HouseRule 전에 실행 → curse_green8 플래그 선행 설정)
    │       ├── ② HouseRule_apply (기본 규칙 통과 시만 호출; CurseEvent 결과 반영)
    │       │       └── skip/reverse/draw2/wild4 효과 + houseLogHTML 반환
    │       ├── cv_message ← 기본메시지 + judgeHTML + houseLogHTML (항상 기록)
    │       ├── ④ HouseRule_checkUnoRequired() UNO 체크 (공통)
    │       ├── ⑤ checkWin() 승리 체크 (공통)
    │       └── → 색상선택(wild) / 턴유지(skip) / processAI() 중 택일
    │
    ├── "uno-draw"    → drawCard(triggerId)
    │       ├── CurseEvent_checkLorebookPending()
    │       ├── CardEngine_drawCards()
    │       └── → processAI()
    │
    ├── "uno-call"    → callUno(triggerId)
    ├── "penalty-call" → penaltyCall(triggerId)
    ├── "color-*"     → chooseColor(triggerId, color)
    └── "game-start"  → startGame(triggerId)

processAI(triggerId) — AI 턴 처리
    ├── aiPick() → CardEngine_canPlay() 기반 카드 선택
    ├── HouseRule 체크: isSkipEffect / getDrawPenalty
    ├── CurseEvent_onAiUno() — UNO 도달 시 호출 (CURSE_USE_LOREBOOK에 따라 분기)
    │       ├── LOREBOOK=true: upsertLocalLoreBook(curse_trigger_check) 활성화
    │       └── LOREBOOK=false: math.random(1,100)==1 주사위
    ├── log() 각 단계 기록 → flushLog() 출력
    └── checkWin() or savePanel()+saveStatus()

채팅 렌더링 (customScripts - editdisplay 타입)
    ├── {STATUS_BAR} → {{getvar::cv_status_html}}
    ├── {UNO_GAME}   → [게임 메시지에서만] {{getvar::cv_game_html}}
    ├── {SIDE_PANEL} → [cv_panel_html=="show"일 때] 버튼 HTML
    ├── {START_UNO}  → "" (숨김)
    ├── {MONO:...}   → "" (숨김)
    ├── {CURSE_ACTIVATE} → "" (숨김) + cv_curse_activate_pending="1" 설정
    │       ※ 로어북 방식에서 AI가 이 토큰을 출력 시 처리
    ├── __USER__     → {{user}}
    ├── __CHAR__     → {{char}}
    └── (마지막 메시지 하단) → {{getvar::cv_bottom_ui}}

AI 요청 전처리 (customScripts - editrequest 타입)
    └── (<char>) 태그 뒤에 게임 상태 CBS 매크로 주입
```

---

## RISUAI 배치 경로

| 구성 요소 | 리스 메뉴 위치 | 설명 |
|-----------|--------------|------|
| `uno_engine.lua` (전체 코드) | **캐릭터 카드 편집 → 고급 설정 → 트리거 스크립트** (`customScripts` 필드) | Lua 엔진 본체. `onButtonClick`, `onStart`, `onInput` 함수가 여기 등록됨 |
| CBS 정규식 | **캐릭터 카드 편집 → 고급 설정 → 정규식 스크립트** | `{UNO_GAME}` → `cv_game_html`, `{STATUS_BAR}` → `cv_status_html` 등 |
| 로어북 (CurseEvent용) | **캐릭터 카드 편집 → 로어북** | `curse_active`, `curse_trigger` 키로 자동 관리됨 |
| CSS (카드/오버레이 스타일) | **캐릭터 카드 편집 → 고급 설정 → backgroundHTML** | `.uno-status`, `.uno-result-overlay` 등 스타일 정의 |
| 기본 변수 초기값 | **캐릭터 카드 편집 → 고급 설정 → defaultVariables** | `cv_phase`, `cv_top_card` 등 CBS 변수 초기값 |

---

## CBS 변수 그룹 분류 (v4.0)

### 그룹 A — 카드 덱 (CardEngine 전용)
| 변수명 | 초기값 | 설명 |
|--------|--------|------|
| cv_draw_pile | | 뽑기 덱 (쉼표 구분) |
| cv_discard_pile | | 버린 카드 더미 (쉼표 구분) |
| cv_top_card | | 현재 최상단 카드 |
| cv_current_color | | 현재 활성 색상 |

### 그룹 B — 플레이어 손패
| 변수명 | 초기값 | 설명 |
|--------|--------|------|
| cv_player_hand | | 플레이어 손패 (쉼표 구분) |
| cv_ai_hand | | 미쿠 손패 (쉼표 구분) |
| cv_ai_count | 0 | 미쿠 손패 수 (UI 표시용) |

### 그룹 C — 게임 진행 상태 (HouseRule 관련)
| 변수명 | 초기값 | 설명 |
|--------|--------|------|
| cv_phase | idle | 게임 단계: idle/playing/between_games/match_end |
| cv_turn | player | 현재 턴: player/ai |
| cv_game_num | 1 | 현재 게임 번호 (1~3) |
| cv_wins_player | 0 | 플레이어 승수 |
| cv_wins_ai | 0 | 미쿠 승수 |
| cv_uno_call | 0 | UNO 선언 여부 (0/1) |
| cv_uno_pending | 0 | UNO 미선언 패널티 대기 (0/1) |
| cv_choose_color | 0 | 와일드 카드 색상 선택 모드 (0/1) |
| cv_last_action | | 직전 액션 코드 |
| cv_round_winner | | 이번 판 승자 |
| cv_winner | | 매치 최종 승자 |
| cv_message | | 게임 메시지 텍스트 |
| cv_game_html | | 게임 UI HTML (buildUI 결과) |
| cv_game_msg_idx | -1 | 게임 UI가 있는 채팅 인덱스 |
| cv_panel_html | | 패널 표시 여부 ("show" or "") |
| cv_status_html | | 상태창 HTML |
| cv_panel_label | 게임 시작 | 패널 버튼 레이블 |
| cv_panel_sub | 카드를 눌러서 시작 | 패널 버튼 서브텍스트 |
| cv_status_mono | ... | 상태창 내면독백 (hover 표시) |
| cv_bottom_ui | | 마지막 메시지 하단 주입 HTML |
| cv_rng_counter | 0 | RNG 시드용 영속 카운터 |

### 그룹 D — 1% 이벤트 전용 (CurseEvent 전용)
> ★ **그룹 A/B/C 로직은 이 변수들을 직접 읽거나 쓰지 않는다. 오직 CurseEvent_* 함수만 접근.**

| 변수명 | 초기값 | 설명 |
|--------|--------|------|
| cv_draw_curse | | 이벤트 상태: "" → "ready" → "end" |
| cv_curse_attempts | 0 | 미쿠 UNO 도달 횟수 (3 이상이면 발동 자격) |
| cv_curse_activate_pending | 0 | 로어북 방식: AI가 {CURSE_ACTIVATE} 출력 시 1로 설정됨 |

---

## 카드 표기법

```
색상_값 형식:
  red_5, blue_skip, green_reverse, yellow_draw2
  any_wild, any_wild4
```

---

## 1% 특수 이벤트 (v4.0 — 로어북 방식 우선)

### 방식 선택 (`uno_engine.lua` 상단에서 토글)
```lua
local CURSE_USE_LOREBOOK = true  -- true: 로어북 방식 (기본), false: 스크립트 방식
```

### 로어북 방식 (CURSE_USE_LOREBOOK = true) — 기본값
```
[발동 조건] 미쿠 UNO 도달 3회 이상 + cv_draw_curse == ""
    │
    ├── CurseEvent_onAiUno():
    │     └── upsertLocalLoreBook("curse_trigger_check", CURSE_TRIGGER_LORE, {alwaysActive=true})
    │           로어북 내용: "1% 확률, 발동 시 {CURSE_ACTIVATE} 출력" 지시
    │
    ├── AI 응답 생성 시 로어북 활성화 → AI가 {CURSE_ACTIVATE} 포함 가능
    │
    ├── editdisplay CBS: {CURSE_ACTIVATE} 감지 →
    │     ① 화면에서 제거
    │     ② cv_curse_activate_pending = "1" 설정
    │
    └── 다음 버튼 클릭 시 CurseEvent_checkLorebookPending():
          └── cv_top_card = green_N, cv_current_color = "green"
              cv_player_hand = CURSE_HAND, cv_draw_curse = "ready"
              curse_trigger_check 비활성화
```

#### editdisplay CBS 설정 (로어북 방식 활성화 필수)
CharCard의 customScripts에 다음 editdisplay 항목을 추가:
- **정규식**: `\{CURSE_ACTIVATE\}` (with `g` flag)
- **치환값**: `` (빈 문자열, 화면에서 제거)
- **사이드 이펙트**: `risuAPI.setChatVar(triggerName, "cv_curse_activate_pending", "1")` 또는 동등한 CBS 설정

### 스크립트 방식 (CURSE_USE_LOREBOOK = false) — fallback
```
[발동 조건] 미쿠 UNO 도달 3회 이상 + cv_draw_curse == ""
    │
    └── CurseEvent_onAiUno():
          math.random(1, 100) == 1 (1% 주사위)
          당첨 시: cv_top_card = green_N, cv_current_color = "green"
                   cv_player_hand = CURSE_HAND, cv_draw_curse = "ready"
```

### 공통 발동 이후 흐름
```
cv_draw_curse == "ready" 상태에서
플레이어가 green_8 카드를 내면
    │
    └── CurseEvent_onGreen8Played():
          cv_draw_curse = "end"
          upsertLocalLoreBook("curse_event_active", CURSE_LORE, {alwaysActive=true})
          → AI가 극적 붕괴 RP 수행 (24장 카드 수령 연출)
```

---

## 디버그 모드 사용법 (v5.0)

### 활성화/비활성화
```lua
-- uno_engine.lua 상단에서 설정
local DEBUG_MODE        = true  -- false로 바꾸면 DEBUG 로그 전체 OFF
local CURSE_USE_LOREBOOK = true -- 1% 이벤트 방식 선택
```

> ⚠️ **v5.0 변경사항**: `JudgeLog_evaluate()` 판정 로그는 `DEBUG_MODE`에 **무관하게 항상** 게임 UI 메시지 영역(`cv_message`)에 출력됩니다.

### 로그 출력 형식
`DEBUG_MODE = true`로 설정 시, 각 게임 액션 완료 후 채팅창에 다음 형태의 로그 블록이 추가됨:

```
🔧 [HH:MM:SS] [1/5] playCard 시작: idx=3
🔧 [HH:MM:SS] [2/5] [판정] 바닥:(빨강 7) vs 내 패:(파랑 7) | 숫자 일치:True | 색상 일치:False | 최종:낼 수 있음
🔧 [HH:MM:SS] [3/5] CurseEvent 체크: card=red_5
🔧 [HH:MM:SS] [4/5] HouseRule_apply 호출
🔧 [HH:MM:SS] [5/5] UNO 체크: #ph=2, unoCall=0
🔧 [HH:MM:SS] [processAI] 시작: AI 패=7장, top=red_5, cur=red
🔧 [HH:MM:SS] [HouseRule] AI card=blue_skip, skip=true, draw=0
🔧 [HH:MM:SS] [processAI] picked=blue_skip, 남은 패=6장
```

### 판정 로그 UI 출력 예시 (항상 표시)
게임 UI의 메시지 영역에 판정 로그가 1줄씩 표시됩니다:
```
나: 파랑 7 사용!
[판정] 바닥:(빨강 7) vs 내 패:(파랑 7) | 숫자 일치:True | 색상 일치:False | 최종:낼 수 있음
└─[하우스] Skip 효과 → 상대 턴 스킵
```

### 1% 이벤트 디버그 예시
```
🔧 [CurseEvent] onAiUno: attempts=3, mode=lorebook
🔧 [CurseEvent] 로어북 curse_trigger_check 활성화 (AI 응답 대기)
-- (다음 AI 응답 후)
🔧 [CurseEvent] 🎯 로어북 방식 발동! top=green_7, curse=ready
-- (플레이어가 green_8 사용 시)
🔧 [CurseEvent] onGreen8Played: curse=ready
🔧 [CurseEvent] 🎉 green_8 발동! curse=end, 로어북 활성화
```

---

## 파일 구성

| 파일 | 역할 |
|------|------|
| `MikuNiceTry_CharCard.json` | CharCard (customScripts, backgroundHTML, defaultVariables, triggerscript 포함) |
| `uno_engine.lua` | triggerscript code와 동일한 코드의 가독성용 독립 파일 (v5.0) |
| `regex_script_uno_ui.md` | 이 문서 |
| `README.md` | 사용 방법 |
| `HOUSE_RULES.md` | 하우스 룰 가이드 |
