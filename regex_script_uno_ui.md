# RISUAI Regex Script 설정 가이드 — UNO 게임 UI

## 개요

이 문서는 `MikuNiceTry_CharCard.json` 캐릭터 카드와 함께 사용할 RISUAI **Regex Script (Modify Display)** 설정을 설명합니다.  
AI가 `[UNO_STATE]...[/UNO_STATE]` 블록을 출력하면, 이 Regex Script가 해당 블록을 HTML/CSS 기반의 UNO 게임 UI로 실시간 변환·렌더링합니다.

---

## ⚠️ 주의: 카드 JSON에 Regex가 내장되어 있습니다

`MikuNiceTry_CharCard.json`의 `data.extensions.risuai.regex` 필드에 이미 Regex Script 설정이 포함되어 있습니다.  
RISUAI에서 카드를 정상적으로 임포트하면 자동으로 적용됩니다.

아래 내용은 수동으로 등록하거나, 문제가 발생했을 때 참조하기 위한 **백업 가이드**입니다.

---

## RISUAI Regex Script 수동 설정 방법

### 1. RISUAI 설정 진입

1. RISUAI 좌측 메뉴 → **"Settings"** (⚙️)
2. **"Regex Scripts"** 탭 선택
3. **"Add Regex Script"** 클릭

### 2. 설정값 입력

| 항목 | 값 |
|------|-----|
| **Script Name** | `UNO Game UI` |
| **Type** | `Modify Display` (화면 표시 변환) |
| **Scope** | `Both` (AI 출력과 사용자 입력 모두) 또는 `AI Output` 권장 |
| **Enabled** | ✅ ON |

---

### 3. IN (입력 패턴 — 정규식)

아래 패턴을 **"Find" / "Pattern"** 입력란에 붙여넣기:

```
\[UNO_STATE\][\s\S]*?\[\/UNO_STATE\]
```

**설명**: `[UNO_STATE]`로 시작하고 `[/UNO_STATE]`로 끝나는 블록 전체를 매칭합니다.  
`[\s\S]*?` 는 줄바꿈을 포함한 모든 문자를 최소 매칭합니다.

---

### 4. OUT (출력 — HTML/CSS 템플릿)

**"Replace" / "Output"** 입력란에 아래 HTML을 붙여넣기:

> **참고**: 아래 HTML은 `[UNO_STATE]` 블록의 각 필드를 파싱하여 UI로 렌더링합니다.  
> RISUAI가 JavaScript 실행을 지원하는 경우 동적 파싱이 작동합니다.  
> JavaScript가 비활성화된 환경에서는 정적 카드 레이아웃만 표시됩니다.

```html
<style>
.uno-ui{font-family:'Segoe UI',sans-serif;background:linear-gradient(160deg,#0f0c29,#1a1a4e,#16213e);border-radius:16px;padding:16px;color:#fff;max-width:520px;margin:10px auto;box-shadow:0 8px 32px rgba(0,0,0,.6);border:1px solid rgba(255,255,255,.08)}
.uno-bubble{background:rgba(255,255,255,.08);border:1px solid rgba(255,255,255,.15);border-radius:12px;padding:10px 14px;margin-bottom:10px;font-size:.92em;line-height:1.5;backdrop-filter:blur(4px)}
.uno-section{display:flex;align-items:center;gap:8px;margin:6px 0;flex-wrap:wrap}
.uno-label{font-size:.75em;color:#a0a8cc;text-transform:uppercase;letter-spacing:.05em;min-width:70px}
.uno-card{display:inline-flex;align-items:center;justify-content:center;width:38px;height:54px;border-radius:6px;font-weight:900;font-size:1em;box-shadow:2px 3px 8px rgba(0,0,0,.5);border:2px solid rgba(255,255,255,.25);position:relative;cursor:default;transition:transform .15s;user-select:none}
.uno-card:hover{transform:translateY(-3px) scale(1.05)}
.uno-card.red{background:#d32f2f;color:#fff}
.uno-card.blue{background:#1565c0;color:#fff}
.uno-card.green{background:#2e7d32;color:#fff}
.uno-card.yellow{background:#f9a825;color:#1a1a1a}
.uno-card.wild{background:linear-gradient(135deg,#d32f2f 0%,#f9a825 33%,#2e7d32 66%,#1565c0 100%);color:#fff;text-shadow:0 1px 3px rgba(0,0,0,.7)}
.uno-card.back{background:linear-gradient(135deg,#1a1a4e,#2d2d7e);color:#fff;font-size:.7em;letter-spacing:.05em;text-align:center;padding:4px}
.uno-discard-area{display:flex;align-items:center;gap:12px;margin:8px 0;padding:10px;background:rgba(255,255,255,.04);border-radius:10px;border:1px solid rgba(255,255,255,.08)}
.uno-deck-btn{background:linear-gradient(135deg,#1a1a4e,#2d2d7e);border:2px solid rgba(255,255,255,.3);border-radius:10px;padding:8px 14px;color:#fff;font-size:.85em;cursor:pointer;display:flex;flex-direction:column;align-items:center;gap:2px;min-width:70px}
.uno-deck-btn span{font-size:1.5em}
.uno-deck-count{font-size:.75em;color:#a0a8cc}
.uno-score{text-align:center;padding:6px 10px;background:rgba(255,255,255,.06);border-radius:8px;font-size:.8em;color:#c0c8e8;margin-bottom:6px;border:1px solid rgba(255,255,255,.08)}
.uno-turn-badge{display:inline-block;padding:2px 10px;border-radius:20px;font-size:.72em;font-weight:bold;letter-spacing:.05em}
.uno-turn-badge.miku{background:#e91e8c;color:#fff}
.uno-turn-badge.user{background:#00bcd4;color:#fff}
.uno-hand-row{display:flex;flex-wrap:wrap;gap:5px;padding:6px;background:rgba(0,0,0,.2);border-radius:10px;min-height:64px;align-items:center}
.uno-section-title{font-size:.78em;color:#7880a0;margin:8px 0 3px;text-transform:uppercase;letter-spacing:.08em}
.uno-notice{text-align:center;font-size:.72em;color:#7880a0;margin-top:8px;padding-top:8px;border-top:1px solid rgba(255,255,255,.06);font-style:italic}
</style>
<div class="uno-ui" id="uno-render"></div>
<script>
(function(){
var block=document.body.innerText||document.body.textContent;
var m=block.match(/\[UNO_STATE\]([\s\S]*?)\[\/UNO_STATE\]/);
if(!m)return;
var lines=m[1].trim().split('\n');
var state={};
lines.forEach(function(l){
var kv=l.match(/^([^:]+):\s*(.*)$/);
if(kv)state[kv[1].trim()]=kv[2].trim();
});
function cardEl(txt,back){
if(back){var d=document.createElement('div');d.className='uno-card back';d.textContent='UNO';return d;}
txt=txt.trim();
var cl='wild',label=txt;
if(/^Red/i.test(txt))cl='red',label=txt.replace(/Red\s*/i,'');
else if(/^Blue/i.test(txt))cl='blue',label=txt.replace(/Blue\s*/i,'');
else if(/^Green/i.test(txt))cl='green',label=txt.replace(/Green\s*/i,'');
else if(/^Yellow/i.test(txt))cl='yellow',label=txt.replace(/Yellow\s*/i,'');
label=label.replace(/Draw\s*Two/gi,'D2').replace(/Draw\s*2/gi,'D2').replace(/Draw\s*Four/gi,'D4').replace(/Draw\s*4/gi,'D4').replace(/Skip/gi,'⊘').replace(/Reverse/gi,'↺').replace(/Wild/gi,'W').trim();
var d=document.createElement('div');d.className='uno-card '+cl;d.textContent=label;return d;
}
var el=document.getElementById('uno-render');
if(!el)return;
var mikuHand=parseInt(state['miku_hand'])||0;
var userCards=(state['user_hand']||'').split(',').map(function(s){return s.trim();}).filter(Boolean);
var discardTop=state['discard_top']||'?';
var deckRem=state['deck_remaining']||'?';
var currentTurn=state['current_turn']||'user';
var score=state['series_score']||'미쿠 0 : 0 {{user}}';
var round=state['current_round']||'1';
var mikuSaid=(state['miku_said']||'♡').replace(/^"|"$/g,'');
var isMikuTurn=(currentTurn==='miku');
// Score bar
var scoreDiv=document.createElement('div');
scoreDiv.className='uno-score';
scoreDiv.innerHTML='🃏 '+score+' &nbsp;|&nbsp; Round '+round+' &nbsp;|&nbsp; <span class="uno-turn-badge '+(isMikuTurn?'miku':'user')+'">'+(isMikuTurn?'미쿠 턴':'내 턴')+'</span>';
el.appendChild(scoreDiv);
// Miku bubble
var bubble=document.createElement('div');
bubble.className='uno-bubble';
bubble.innerHTML='😆 <b>미쿠:</b> '+mikuSaid;
el.appendChild(bubble);
// Miku hand
var st=document.createElement('div');
st.className='uno-section-title';
st.textContent='미쿠의 패';
el.appendChild(st);
var mikuRow=document.createElement('div');
mikuRow.className='uno-hand-row';
for(var i=0;i<mikuHand;i++)mikuRow.appendChild(cardEl('',true));
var mikuCountSpan=document.createElement('span');
mikuCountSpan.style.cssText='font-size:.75em;color:#a0a8cc;margin-left:4px';
mikuCountSpan.textContent=mikuHand+'장';
mikuRow.appendChild(mikuCountSpan);
el.appendChild(mikuRow);
// Discard + deck
var discardSec=document.createElement('div');
discardSec.className='uno-discard-area';
var dlabel=document.createElement('div');dlabel.className='uno-label';dlabel.textContent='버린 카드';
discardSec.appendChild(dlabel);
discardSec.appendChild(cardEl(discardTop,false));
var spacer=document.createElement('div');spacer.style.flex='1';discardSec.appendChild(spacer);
var deckBtn=document.createElement('div');
deckBtn.className='uno-deck-btn';
deckBtn.innerHTML='<span>🂠</span><div class="uno-deck-count">'+deckRem+'장</div><div style="font-size:.7em;margin-top:2px">카드 뽑기</div>';
discardSec.appendChild(deckBtn);
el.appendChild(discardSec);
// User hand
var st2=document.createElement('div');
st2.className='uno-section-title';
st2.textContent='내 패 ('+userCards.length+'장)';
el.appendChild(st2);
var userRow=document.createElement('div');
userRow.className='uno-hand-row';
userCards.forEach(function(c){if(c)userRow.appendChild(cardEl(c,false));});
el.appendChild(userRow);
// Notice
var notice=document.createElement('div');
notice.className='uno-notice';
notice.textContent='UN○를 할 때는 카드를 잘 섞어서 이런 일이 발생하지 않도록 합시다';
el.appendChild(notice);
})();
</script>
```

---

## UI 레이아웃 설명

| 영역 | 내용 |
|------|------|
| **스코어바** (최상단) | `미쿠 X : Y {{user}} \| Round N \| 현재 턴 뱃지` |
| **미쿠 말풍선** | 😆 + 미쿠의 도발/반응 대사 (네이비 반투명 배경) |
| **미쿠 패** | UNO 뒷면 카드 ×N장 (개수만 표시) |
| **버린 카드 + 덱** | 현재 discard top 카드 (색상 표시) + 덱 잔여 장수 + 카드 뽑기 버튼 |
| **내 패** | 각 카드 앞면 (색상별 구분, 숫자/기호 표시) |
| **하단 안내** | *"UN○를 할 때는 카드를 잘 섞어서 이런 일이 발생하지 않도록 합시다"* |

---

## 카드 색상 코드

| 색상 | 배경색 |
|------|--------|
| 빨강 (Red) | `#d32f2f` |
| 파랑 (Blue) | `#1565c0` |
| 초록 (Green) | `#2e7d32` |
| 노랑 (Yellow) | `#f9a825` |
| Wild | 4색 그라디언트 |
| 뒷면 | `#1a1a4e → #2d2d7e` 그라디언트 |

---

## AI 출력 형식 (시스템 프롬프트가 생성하는 블록)

AI가 매 턴 출력하는 `[UNO_STATE]` 블록 예시:

```
[UNO_STATE]
miku_hand: 3
user_hand: Red5, Blue Skip, GreenDraw2, Wild, Yellow3, Red9, Blue7
discard_top: Red7
deck_remaining: 52
current_turn: user
series_score: 미쿠 0 : 0 {{user}}
current_round: 1
miku_said: "어쭈? 그게 최선이야?♡ 허~접♡"
[/UNO_STATE]
```

Regex Script는 이 블록을 매칭하여 위의 HTML UI로 교체 렌더링합니다.

---

## 트러블슈팅

| 문제 | 해결 방법 |
|------|-----------|
| UI가 렌더링되지 않음 | RISUAI 설정에서 HTML 렌더링이 활성화되어 있는지 확인 |
| JavaScript 오류 | RISUAI 버전에 따라 JS 실행이 제한될 수 있음. JS 없는 정적 HTML 버전으로 교체 필요 |
| `[UNO_STATE]` 블록이 그대로 표시됨 | Regex Script가 올바르게 등록되었는지, "Modify Display" 타입인지 확인 |
| AI가 게임 상태를 출력하지 않음 | 시스템 프롬프트가 올바르게 적용되었는지, `/start` 명령 후인지 확인 |
