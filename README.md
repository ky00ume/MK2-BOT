# MK2-BOT — みむかｩわナイストライ UNO CharCard

RisuAI용 하츠네 미쿠 UNO 인터랙티브 RP 캐릭터 카드 (v3.0)

## 사용 방법

1. `MikuNiceTry_CharCard.json` 을 RisuAI에서 캐릭터로 임포트
2. 새 채팅 시작
3. `/start` 입력 또는 하단 버튼 클릭 → UNO 게임 시작

## 기능

- **3판 2승제 UNO** — 미쿠 vs 플레이어
- **인터랙티브 카드 UI** — 클릭 가능한 카드 버튼, 드로우 버튼, UNO 선언 버튼
- **미쿠 RP 연동** — 게임 상황에 따른 대사 자동 생성 (AI 응답)
- **1% 특수 이벤트** — 미쿠 UNO 순간 역전 이벤트 재현
- **상태창** — 스코어, 현재 판, 게임 상태 표시
- **내면독백** — AI 응답 하단에 숨겨진 미쿠의 속마음 (AI 생성)

## 기술 구조 (v3.0)

### CBS 변수 치환 방식
- Lua `setChatVar`/`getChatVar`로 모든 게임 상태 관리
- `customScripts` (editdisplay 타입)로 플레이스홀더 → CBS 변수 치환
- `addChat` + `reloadDisplay`로 UI 렌더링
- `backgroundHTML`에 전체 CSS 정의
- `defaultVariables`로 CBS 변수 초기화

### 파일 구성
| 파일 | 역할 |
|------|------|
| `MikuNiceTry_CharCard.json` | 메인 CharCard (게임 엔진 포함) |
| `uno_engine.lua` | CharCard 내 코드와 동일 (가독성용) |
| `regex_script_uno_ui.md` | 기술 구조 상세 문서 |

## 버전 이력

- **v3.0** — CBS 변수 치환 방식으로 전면 재설계 (`setChatVar`/`getChatVar` + `customScripts`)
- **v2.x** — Lua editDisplay 방식 (UI 렌더링 불가 문제로 폐기)
- **v1.x** — AI 의존 방식 (신뢰성 문제로 폐기)
