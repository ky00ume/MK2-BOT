# UNO Game UI — 기술 구조 문서

## ⚠️ 변경 이력 (중요)

### v1.0 — AI 의존 방식 (폐기)
- AI가 `[UNO_STATE]` 블록을 출력 → regex JS로 파싱
- 문제: AI가 상태 블록을 신뢰성 있게 출력 못함, `<script>` 차단됨

### v2.0 — LUA editDisplay 방식 (폐기)
- `listenEdit("editDisplay", ...)` 콜백으로 HTML 반환
- `setState`/`getState`로 상태 저장
- 문제: **editDisplay 콜백이 화면에 HTML을 렌더링하지 않음** (8 PR 내내 미해결)

### v3.0 — CBS 변수 치환 방식 (현재) ✅
- `setChatVar`/`getChatVar`로 모든 상태 관리
- `customScripts` (editdisplay/editrequest 타입)로 플레이스홀더 → CBS 변수 치환
- `addChat` + `reloadDisplay`로 UI 갱신
- `backgroundHTML`에 CSS 정의

---

## 현재 아키텍처 (v3.0)

```
유저 입력 "/start"
    │
    ▼
onInput(triggerId)          ← Lua Trigger Script
    │
    └── stopChat() → startGame()
            │
            ├── startNewGame() — 덱, 패 초기화, 상태 setChatVar
            ├── saveUI() — cv_game_html에 게임 UI HTML 저장
            ├── savePanel() — cv_panel_html/label/sub 저장
            ├── saveStatus() — cv_status_html 저장 + saveBottomUI()
            ├── addChat(triggerId,"char","{STATUS_BAR}\n{UNO_GAME}\n{SIDE_PANEL}")
            ├── setChatVar("cv_game_msg_idx", len-1)
            └── reloadDisplay()

버튼 클릭 (risu-btn 속성)
    │
    ▼
onButtonClick(triggerId, btnValue) ← Lua 함수
    │
    ├── "play-N"     → playCard(triggerId, N)
    ├── "uno-draw"   → drawCard(triggerId)
    ├── "uno-call"   → callUno(triggerId)
    ├── "penalty-call" → penaltyCall(triggerId)
    ├── "color-*"    → chooseColor(triggerId, color)
    └── "game-start" → startGame(triggerId)
            │
            └── → saveUI() / savePanel() / saveStatus() → reloadDisplay()

채팅 렌더링 (customScripts - editdisplay 타입)
    │
    ├── {STATUS_BAR} → {{getvar::cv_status_html}}
    ├── {UNO_GAME}   → [게임 메시지에서만] {{getvar::cv_game_html}}
    ├── {SIDE_PANEL} → [cv_panel_html=="show"일 때] 버튼 HTML
    ├── {START_UNO}  → "" (숨김)
    ├── {MONO:...}   → "" (숨김)
    ├── __USER__     → {{user}}
    ├── __CHAR__     → {{char}}
    └── (마지막 메시지 하단) → {{getvar::cv_bottom_ui}}

AI 요청 전처리 (customScripts - editrequest 타입)
    └── (<char>) 태그 뒤에 게임 상태 CBS 매크로 주입
```

---

## CBS 변수 목록 (defaultVariables에 초기화됨)

| 변수명 | 초기값 | 설명 |
|--------|--------|------|
| cv_phase | idle | 게임 단계: idle/playing/between_games/match_end |
| cv_turn | player | 현재 턴: player/ai |
| cv_top_card | | 버린 패 더미 최상단 카드 |
| cv_current_color | | 현재 활성 색상 |
| cv_player_hand | | 플레이어 손패 (쉼표 구분) |
| cv_ai_hand | | 미쿠 손패 (쉼표 구분) |
| cv_ai_count | 0 | 미쿠 손패 수 |
| cv_draw_pile | | 뽑기 덱 |
| cv_message | | 게임 메시지 텍스트 |
| cv_uno_call | 0 | UNO 선언 여부 |
| cv_choose_color | 0 | 와일드 카드 색상 선택 모드 |
| cv_winner | | 매치 최종 승자 |
| cv_round_winner | | 이번 판 승자 |
| cv_wins_player | 0 | 플레이어 승수 |
| cv_wins_ai | 0 | 미쿠 승수 |
| cv_game_num | 1 | 현재 게임 번호 (1~3) |
| cv_last_action | | 직전 액션 코드 |
| cv_game_html | | 게임 UI HTML (buildUI 결과) |
| cv_game_msg_idx | -1 | 게임 UI가 있는 채팅 인덱스 |
| cv_panel_html | | 패널 표시 여부 ("show" or "") |
| cv_status_html | | 상태창 HTML |
| cv_panel_label | 게임 시작 | 패널 버튼 레이블 |
| cv_panel_sub | 카드를 눌러서 시작 | 패널 버튼 서브텍스트 |
| cv_status_mono | ... | 상태창 내면독백 (hover 표시) |
| cv_draw_curse | | 1% 이벤트 상태: ""/ready/end |
| cv_rng_counter | 0 | RNG 시드용 영속 카운터 |
| cv_curse_attempts | 0 | 미쿠 UNO 도달 횟수 (커스 트리거) |
| cv_uno_pending | 0 | 미선언 UNO 패널티 대기 |
| cv_bottom_ui | | 마지막 메시지 하단 주입 HTML |

---

## 카드 표기법

```
색상_값 형식:
  red_5, blue_skip, green_reverse, yellow_draw2
  any_wild, any_wild4
```

---

## 1% 특수 이벤트

미쿠가 3번 이상 UNO에 도달하면 1% 확률로 발동:
1. `cv_draw_curse = "ready"` — 플레이어 패를 드로우 카드 더미로 교체, 버린 패를 green_N으로 교체
2. 플레이어가 green_8을 내면 발동: `cv_draw_curse = "end"`, 로어북 이벤트 주입
3. 미쿠가 24장 카드를 받는 연출 + AI가 극적 붕괴 RP 수행

---

## 파일 구성

| 파일 | 역할 |
|------|------|
| `MikuNiceTry_CharCard.json` | CharCard (customScripts, backgroundHTML, defaultVariables, triggerscript 포함) |
| `uno_engine.lua` | triggerscript code와 동일한 코드의 가독성용 독립 파일 |
| `regex_script_uno_ui.md` | 이 문서 |
| `README.md` | 사용 방법 |
