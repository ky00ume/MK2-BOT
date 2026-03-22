
-- ================================================
-- UNO GAME ENGINE for RISUAI - Hatsune Miku CharCard
-- ================================================

pcall(function() math.randomseed(os.time()) end)

-- ========== DIALOGUES ==========
local D = {
  win = {
    "어쭈?♡ 그게 최선이야?♡ 너무 허~접♡",
    "하하하♡ 이 정도면 내가 너무 잘하는 거 아니야?♡",
    "흐으음♡ 너무 쉬운데?♡ 좀 더 노력해봐♡",
    "내 패 봐~♡ 완벽하지♡ 너는?♡ 하하♡",
    "♡♡♡ 나한테 이기려면 아직 멀었어~♡",
    "이 기세라면 내가 이기는 거 아니야?♡ 당연하지~♡"
  },
  lose = {
    "잠, 잠깐만!! 이게 말이 돼?!",
    "야!! 반칙이잖아!! 다시 해!!",
    "이건 카드가 이상한 거야. 분명히.",
    "흥! 이번만이야!! 다음엔 절대 안 져!!",
    "우연이야 우연!! 다음 판엔 내가 이겨!!"
  },
  uno = {
    "UNO♡ 이제 끝이야~♡ 포기해~♡",
    "UNO~♡♡♡ 기대해봐♡ 한 장 남았어~♡",
    "UNO!!!♡ 어떡해~ 너무 신나~♡ 이겼다고♡"
  },
  comeback = {
    "뭐?! 이게 무슨...! 아직 안 끝났어!!",
    "허!? 그, 그래도 아직 내가 이길 수 있어!!",
    "으으으... 인정 안 해!! 다시!!"
  },
  rwon = {
    "이번 라운드는 내 거♡ 다음도 내가 이길게♡",
    "역시 내가 UNO 천재♡ 너무 당연하지 않아?♡",
    "하하♡ 이 기분~♡ 최고야♡ 다음 판도 각오해♡"
  },
  rlose = {
    "으... 운이 좋았던 거야. 다음 판은 내가 이겨.",
    "치! 이건 카드 배분이 이상했던 거야!!",
    "...인정. 근데 다음은 달라."
  },
  swon = {
    "HAHAHA♡♡♡ 내가 이겼어!!! 봤지?! 봤어?!♡ 이제 약속 지켜♡",
    "3판 2선승♡ 완벽한 승리♡ 역시 미쿠님이시지♡ 벌칙 각오해♡",
    "끝났어♡ 내가 이겼으니까 네가 벌칙 받아야 해♡ 도망가지 말고♡"
  },
  slose = {
    "으아아아아아아아앙앙~!! 말도 안 돼!! 내가 왜 졌어!!",
    "아아아아아앙~!!! 이건 꿈이야!! 꿈이라고!!!! 으아아아아앙!!!",
    "...으아아아앙앙앙~.... 알았어 알았어... 약속은 지킬게... 으앙..."
  },
  event = {
    "어?! 뭔가 이상하게 섞혔는데...? 어...어...어...?! 패가 1장?! 이건 내가 이기는 거잖아♡",
    "잠깐 이게 무슨... 패가 고작 1장?? 에이 이건 내가 이기는 거 아니야?♡ 너 포기해~♡"
  },
  -- FIX8: 특수 이벤트 기고만장 대사
  event_smug = {
    "어?! 패가 1장?! 이건 내가 이기는 거잖아♡ 네 패는... 13장?! HAHAHA♡♡♡",
    "잠깐 이게 무슨... 패가 고작 1장?? 이건 운명이야♡ 포기해~♡ HAHAHA♡"
  },
  -- FIX8: 특수 이벤트 미쿠 붕괴 대사
  event_collapse = {
    "...으아아아앙앙... 이, 이게 무슨... 말도 안... 돼......",
    "어?! 어어?! 어어어어?!?! ...으아아아아아앙앙~!!!!!! 이건 뭐야!!!!",
    "하...하하...하하하... ...으아아아아아앙앙앙앙~!!!! 거짓말이지?! 거짓말이라고 해!!!!!"
  },
  normal = {
    "어서 카드 내봐♡",
    "고민하지 말고 빨리♡",
    "흥♡ 어떤 카드 낼 건데?♡",
    "설마 드로우하려는 건 아니지?♡",
    "♡",
    "빨리~♡ 기다리잖아♡"
  }
}

local function pick(cat)
  local p = D[cat] or D.normal
  return p[math.random(#p)]
end

-- ========== CARD UTILITIES ==========
local function cardColor(c)
  if c:sub(1,3) == "Red" then return "Red"
  elseif c:sub(1,4) == "Blue" then return "Blue"
  elseif c:sub(1,5) == "Green" then return "Green"
  elseif c:sub(1,6) == "Yellow" then return "Yellow"
  else return "Wild" end
end

local function cardVal(c)
  local co = cardColor(c)
  if co == "Wild" then
    return (c == "WildDraw4") and "WildDraw4" or "Wild"
  end
  return c:sub(#co + 1)
end

local function isNum(c)
  return tonumber(cardVal(c)) ~= nil
end

local function isAction(c)
  return not isNum(c)
end

local function isDraw(c)
  local v = cardVal(c)
  return v == "Draw2" or v == "WildDraw4"
end

local function drawAmt(c)
  local v = cardVal(c)
  if v == "Draw2" then return 2
  elseif v == "WildDraw4" then return 4
  else return 0 end
end

local function canPlay(c, top, color)
  if cardColor(c) == "Wild" then return true end
  return cardColor(c) == color or cardVal(c) == cardVal(top)
end

-- ========== DECK ==========
local function mkDeck()
  local d = {}
  for _, co in ipairs({"Red","Blue","Green","Yellow"}) do
    for v = 0, 9 do
      table.insert(d, co..v)
      if v > 0 then table.insert(d, co..v) end
    end
    for _, s in ipairs({"Skip","Reverse","Draw2"}) do
      table.insert(d, co..s)
      table.insert(d, co..s)
    end
  end
  for i = 1, 4 do
    table.insert(d, "Wild")
    table.insert(d, "WildDraw4")
  end
  return d
end

local function shuffle(t)
  for i = #t, 2, -1 do
    local j = math.random(i)
    t[i], t[j] = t[j], t[i]
  end
  return t
end

-- ========== SERIALIZATION ==========
local function ser(t)
  if #t == 0 then return "" end
  return table.concat(t, ",")
end

local function des(s)
  if not s or s == "" then return {} end
  local t = {}
  for x in (s .. ","):gmatch("([^,]*),") do
    local c = x:match("^%s*(.-)%s*$")
    if c ~= "" then table.insert(t, c) end
  end
  return t
end

-- ========== STATE I/O ==========
-- safeGetState: wraps getState in pcall so that json.decode(nil) on a fresh
-- chat (no prior saved state) returns nil instead of throwing an error.
local function safeGetState(tid, name)
  local ok, val = pcall(getState, tid, name)
  if ok then return val else return nil end
end

local function loadG(tid)
  return {
    deck  = des(safeGetState(tid,"deck")  or ""),
    mh    = des(safeGetState(tid,"mh")    or ""),
    uh    = des(safeGetState(tid,"uh")    or ""),
    top   = safeGetState(tid,"top")   or "",
    col   = safeGetState(tid,"col")   or "Red",
    turn  = safeGetState(tid,"turn")  or "user",
    ms    = tonumber(safeGetState(tid,"ms"))  or 0,
    us    = tonumber(safeGetState(tid,"us"))  or 0,
    rnd   = tonumber(safeGetState(tid,"rnd")) or 1,
    active= (safeGetState(tid,"active") == "1"),
    uno   = (safeGetState(tid,"uno")    == "1"),
    stk   = tonumber(safeGetState(tid,"stk")) or 0,
    said  = safeGetState(tid,"said")  or "♡",
    winner= safeGetState(tid,"winner") or ""
  }
end

local function saveG(tid, g)
  setState(tid,"deck",  ser(g.deck))
  setState(tid,"mh",    ser(g.mh))
  setState(tid,"uh",    ser(g.uh))
  setState(tid,"top",   g.top)
  setState(tid,"col",   g.col)
  setState(tid,"turn",  g.turn)
  setState(tid,"ms",    tostring(g.ms))
  setState(tid,"us",    tostring(g.us))
  setState(tid,"rnd",   tostring(g.rnd))
  setState(tid,"active",g.active and "1" or "0")
  setState(tid,"uno",   g.uno   and "1" or "0")
  setState(tid,"stk",   tostring(g.stk))
  setState(tid,"said",  g.said)
  setState(tid,"winner",g.winner or "") -- PATCH: persist winner so stale values don't leak across games
end

-- ========== DRAW ==========
local function drawCards(deck, hand, n)
  for i = 1, n do
    if #deck == 0 then break end
    table.insert(hand, table.remove(deck))
  end
end

-- ========== MIKU AI TURN ==========
local function mikuPickCard(g)
  if g.stk > 0 then
    for i, c in ipairs(g.mh) do
      if isDraw(c) then return i end
    end
    return nil
  end
  -- prefer action cards (not as last card due to house rule)
  for i, c in ipairs(g.mh) do
    if canPlay(c, g.top, g.col) and isAction(c) and #g.mh > 1 then
      return i
    end
  end
  -- number cards
  for i, c in ipairs(g.mh) do
    if canPlay(c, g.top, g.col) and isNum(c) then
      return i
    end
  end
  -- last resort: action card even if only 1 left (can't win but can still play)
  for i, c in ipairs(g.mh) do
    if canPlay(c, g.top, g.col) then return i end
  end
  return nil
end

local function mikuChooseColor(mh)
  local cnt = {Red=0,Blue=0,Green=0,Yellow=0}
  for _, c in ipairs(mh) do
    local co = cardColor(c)
    if cnt[co] then cnt[co] = cnt[co] + 1 end
  end
  local best = "Red"
  for co, n in pairs(cnt) do
    if n > cnt[best] then best = co end
  end
  return best
end

-- Returns true if miku won this turn
local function mikuDoTurn(tid, g)
  local MAX_EXTRA = 3
  for extra = 1, MAX_EXTRA do
    -- Handle incoming draw stack
    if g.stk > 0 then
      local canStack = false
      for _, c in ipairs(g.mh) do
        if isDraw(c) then canStack = true; break end
      end
      if not canStack then
        drawCards(g.deck, g.mh, g.stk)
        g.stk = 0
        g.said = pick("lose")
        g.turn = "user"
        return false
      end
    end

    local idx = mikuPickCard(g)
    if idx == nil then
      -- Draw one
      drawCards(g.deck, g.mh, 1)
      local drawn = g.mh[#g.mh]
      if canPlay(drawn, g.top, g.col) and not (isAction(drawn) and #g.mh == 1) then
        idx = #g.mh
      else
        g.said = pick("normal")
        g.turn = "user"
        return false
      end
    end

    local c = table.remove(g.mh, idx)
    g.top = c
    g.col = cardColor(c)

    if g.col == "Wild" then
      g.col = mikuChooseColor(g.mh)
    end

    -- Check win
    if #g.mh == 0 then
      g.said = pick("rwon")
      g.turn = "user"
      return true
    end

    local v = cardVal(c)
    if v == "Skip" or v == "Reverse" then
      g.said = pick("win") .. " スキップ♡"
      -- Miku goes again in 2-player (loop)
    elseif v == "Draw2" then
      g.stk = g.stk + 2
      g.said = pick("win") .. " +2♡"
      g.turn = "user"
      return false
    elseif v == "WildDraw4" then
      g.stk = g.stk + 4
      g.said = pick("win") .. " +4♡♡"
      g.turn = "user"
      return false
    else
      if #g.mh == 1 then
        g.said = pick("uno")
      elseif #g.mh <= 3 then
        g.said = pick("win")
      elseif #g.mh > 8 then
        g.said = pick("lose")
      else
        g.said = pick("normal")
      end
      g.turn = "user"
      return false
    end
  end
  g.turn = "user"
  return false
end

-- ========== ROUND INIT ==========
local function initRound(tid, g)
  local deck = shuffle(mkDeck())
  local special = (math.random(100) == 1)

  if special then
    g.mh = {}
    g.uh = {}
    -- Miku: 1 non-action number card
    for i = #deck, 1, -1 do
      if isNum(deck[i]) and cardColor(deck[i]) ~= "Wild" then
        table.insert(g.mh, table.remove(deck, i))
        break
      end
    end
    -- User: Green8 + draw cards (total 13)
    local g8idx = nil
    for i, c in ipairs(deck) do
      if c == "Green8" then g8idx = i; break end
    end
    if g8idx then
      table.insert(g.uh, table.remove(deck, g8idx))
    else
      table.insert(g.uh, "Green8")
    end
    local fills = {}
    for i = #deck, 1, -1 do
      if isDraw(deck[i]) then
        table.insert(fills, table.remove(deck, i))
        if #fills >= 12 then break end
      end
    end
    for _, c in ipairs(fills) do table.insert(g.uh, c) end
    while #g.uh < 13 and #deck > 0 do
      table.insert(g.uh, table.remove(deck))
    end
    setState(tid, "special", "1")
    local smugLine = pick("event_smug")
    setState(tid, "ev_smug", smugLine) -- saved for buildSpecialEventUI to replay consistently
    g.said = smugLine                  -- used in AI context message via setInput
  else
    g.mh = {}
    g.uh = {}
    for i = 1, 7 do
      table.insert(g.mh, table.remove(deck))
      table.insert(g.uh, table.remove(deck))
    end
    setState(tid, "special", "0")
  end

  -- Starting card (non-Wild)
  local start
  local attempts = 0
  repeat
    start = table.remove(deck)
    attempts = attempts + 1
    if attempts > 50 then start = "Red5"; break end
  until cardColor(start) ~= "Wild"

  g.deck  = deck
  g.top   = start
  g.col   = cardColor(start)
  g.turn  = "user"
  g.stk   = 0
  g.uno   = false
  g.active= true
  return special
end

-- ========== FIX8: 1% 특수 이벤트 자동 처리 ==========
local function autoPlaySpecialEvent(tid, g)
  -- FIX8: 특수 이벤트 자동 처리 — 유저 드로우 카드 연쇄 → 미쿠 대량 드로우 → 유저 Green8 피니시
  -- 원래 유저 패(13장)와 미쿠 패(1장)를 state에 저장 (UI 표시용)
  setState(tid, "ev_cards", ser(g.uh))
  setState(tid, "ev_miku_card", ser(g.mh))

  local totalDrawn = 0
  -- 드로우 카드들 먼저 처리 (Green8 제외한 12장)
  while #g.uh > 1 do
    local foundDraw = nil
    for i, c in ipairs(g.uh) do
      if isDraw(c) then foundDraw = i; break end
    end
    if not foundDraw then break end
    local c = table.remove(g.uh, foundDraw)
    g.top = c
    g.col = cardColor(c)
    if g.col == "Wild" then g.col = "Green" end
    totalDrawn = totalDrawn + drawAmt(c)
  end

  -- 미쿠가 드로우 스택 전부 받기
  drawCards(g.deck, g.mh, totalDrawn)
  g.stk = 0

  -- Green8 마무리
  for i, c in ipairs(g.uh) do
    if c == "Green8" then
      table.remove(g.uh, i)
      g.top = "Green8"
      g.col = "Green"
      break
    end
  end

  -- 시리즈 즉시 종료
  g.active = false
  g.us = 2  -- 유저 즉시 승리
  g.winner = "user"
  g.said = pick("event_collapse")
  saveG(tid, g)
  setState(tid, "said", g.said)
  setState(tid, "winner", "user")
end

-- ========== ROUND/SERIES END ==========
local function handleRoundEnd(tid, g, winner)
  g.active = false
  if winner == "miku" then
    g.ms = g.ms + 1
    saveG(tid, g)
    if g.ms >= 2 then
      g.said = pick("swon")
      setState(tid, "said", g.said)
      setState(tid, "winner", "miku")
      alertNormal(tid, "🏆 게임 종료!\n\n🎤 미쿠 승리!\n\n벌칙을 수행하세요 ♡")
    else
      g.said = pick("rwon")
      setState(tid, "said", g.said)
      alertNormal(tid, string.format("라운드 %d — 미쿠 승리! (미쿠 %d : %d 유저)\n다음 라운드 시작!", g.rnd, g.ms, g.us))
      g.rnd = g.rnd + 1
      initRound(tid, g)
      saveG(tid, g)
    end
  else
    g.us = g.us + 1
    saveG(tid, g)
    if g.us >= 2 then
      g.said = pick("slose")
      setState(tid, "said", g.said)
      setState(tid, "winner", "user")
      alertNormal(tid, "🏆 게임 종료!\n\n유저 승리!\n\n미쿠가 벌칙을 수행합니다 ♡\n으아아아아앙앙~!!!")
    else
      g.said = pick("rlose")
      setState(tid, "said", g.said)
      alertNormal(tid, string.format("라운드 %d — 유저 승리! (미쿠 %d : %d 유저)\n다음 라운드 시작!", g.rnd, g.ms, g.us))
      g.rnd = g.rnd + 1
      initRound(tid, g)
      saveG(tid, g)
    end
  end
end

-- ========== CARD DISPLAY HELPERS ==========
local clsMap = {Red="r", Blue="b", Green="g", Yellow="y", Wild="w"}
local emoMap  = {Red="🔴", Blue="🔵", Green="🟢", Yellow="🟡"}

local function cardLabel(c)
  local co = cardColor(c)
  local v  = cardVal(c)
  if co == "Wild" then
    return (v == "WildDraw4") and "W+4" or "Wild"
  end
  local em = emoMap[co] or co
  if v == "Skip"    then return em.."⊘"
  elseif v == "Reverse" then return em.."↺"
  elseif v == "Draw2"   then return em.."+2"
  else return em..v end
end

local function cardCls(c)
  return clsMap[cardColor(c)] or "w"
end

-- ========== HTML UI BUILDER ==========
-- FIX7: All CSS class names prefixed with x-risu- to match DOMPurify's automatic
-- class-name prefixing (parser.svelte.ts prefixes every class with "x-risu-").
local CSS = [[<style>
.x-risu-uu{font-family:'Segoe UI',sans-serif;background:linear-gradient(160deg,#0f0c29,#1a1a4e,#16213e);border-radius:14px;padding:12px 14px;color:#fff;max-width:500px;margin:8px auto;box-shadow:0 6px 24px rgba(0,0,0,.65);border:1px solid rgba(255,255,255,.07)}
.x-risu-uscr{text-align:center;padding:4px 8px;background:rgba(255,255,255,.06);border-radius:8px;font-size:.78em;color:#c0c8e8;margin-bottom:7px;border:1px solid rgba(255,255,255,.07)}
.x-risu-ubdg{display:inline-block;padding:1px 8px;border-radius:12px;font-size:.7em;font-weight:700;vertical-align:middle}
.x-risu-ubdg.x-risu-m{background:#e91e8c;color:#fff}.x-risu-ubdg.x-risu-u{background:#00bcd4;color:#111}
.x-risu-ubbl{background:rgba(255,255,255,.07);border:1px solid rgba(255,255,255,.13);border-radius:9px;padding:7px 12px;margin-bottom:7px;font-size:.88em;line-height:1.5}
.x-risu-ulbl{font-size:.7em;color:#6870a0;margin:5px 0 2px;text-transform:uppercase;letter-spacing:.06em}
.x-risu-uhnd{display:flex;flex-wrap:wrap;gap:3px;padding:5px;background:rgba(0,0,0,.18);border-radius:9px;min-height:54px;align-items:center}
.x-risu-uc{display:inline-flex;align-items:center;justify-content:center;width:34px;height:50px;border-radius:5px;font-weight:900;font-size:.8em;box-shadow:2px 3px 6px rgba(0,0,0,.45);border:2px solid rgba(255,255,255,.18);cursor:default;user-select:none;text-align:center;padding:0;background:none}
.x-risu-uc.x-risu-r{background:#d32f2f;color:#fff}.x-risu-uc.x-risu-b{background:#1565c0;color:#fff}.x-risu-uc.x-risu-g{background:#2e7d32;color:#fff}.x-risu-uc.x-risu-y{background:#f9a825;color:#111}
.x-risu-uc.x-risu-w{background:linear-gradient(135deg,#d32f2f 0%,#f9a825 33%,#2e7d32 66%,#1565c0 100%);color:#fff}
.x-risu-uc.x-risu-bk{background:linear-gradient(135deg,#181848,#2a2a6e);color:#889;font-size:.6em}
.x-risu-umid{display:flex;gap:8px;align-items:center;margin:5px 0;padding:7px;background:rgba(255,255,255,.03);border-radius:9px;border:1px solid rgba(255,255,255,.05)}
.x-risu-ustk{text-align:center;font-size:.72em;color:#ff7070;margin-top:3px;padding:3px;background:rgba(255,80,80,.08);border-radius:5px}
.x-risu-uft{text-align:center;font-size:.67em;color:#3a4070;margin-top:5px;font-style:italic}
.x-risu-ubtn{background:rgba(255,255,255,.1);border:1px solid rgba(255,255,255,.2);border-radius:6px;color:#fff;padding:4px 10px;cursor:pointer;font-size:.78em;font-weight:700;margin:2px}
</style>]]

local function buildUI(g)
  local h = {CSS}
  local isMiku = (g.turn == "miku")
-- FIX7: x-risu- prefix on class names to match DOMPurify's auto-prefixing.
-- padding:0;background:none on x-risu-uc resets browser UA defaults for <button> elements.
  local badge  = isMiku
    and '<span class="x-risu-ubdg x-risu-m">미쿠 턴</span>'
    or  '<span class="x-risu-ubdg x-risu-u">내 턴</span>'

  local cdot = ({Red="🔴",Blue="🔵",Green="🟢",Yellow="🟡"})[g.col] or ""

  -- Score / status bar
  table.insert(h, string.format(
    '<div class="x-risu-uu"><div class="x-risu-uscr">🃏 미쿠 <b>%d</b> : <b>%d</b> 유저 &nbsp;|&nbsp; Round %d &nbsp;|&nbsp; %s &nbsp;|&nbsp; %s %s</div>',
    g.ms, g.us, g.rnd, badge, cdot, g.col
  ))

  -- Miku speech bubble
  table.insert(h, string.format('<div class="x-risu-ubbl">😆 <b>미쿠:</b> %s</div>', g.said))

  -- Miku hand (face-down)
  table.insert(h, '<div class="x-risu-ulbl">미쿠 패</div><div class="x-risu-uhnd">')
  for i = 1, #g.mh do
    table.insert(h, '<span class="x-risu-uc x-risu-bk">UNO</span>')
  end
  table.insert(h, string.format(
    '<small style="color:#909;margin-left:4px">%d장</small></div>', #g.mh
  ))

  -- Middle: discard pile + draw button
  local topLbl = cardLabel(g.top)
  local topCls = cardCls(g.top)
  table.insert(h, string.format(
    '<div class="x-risu-umid"><span style="font-size:.68em;color:#6870a0">버린 카드</span> <span class="x-risu-uc x-risu-%s">%s</span><div style="flex:1"></div>',
    topCls, topLbl
  ))
  if not isMiku then
    -- FIX7: raw risu-btn attribute routes click through runLuaButtonTrigger → onButtonClick
    table.insert(h, string.format(
      '<button class="x-risu-ubtn" risu-btn="drawCard">🂠 뽑기(%d장)</button>', #g.deck
    ))
  else
    table.insert(h, string.format(
      '<span style="font-size:.7em;color:#889">덱 %d장</span>', #g.deck
    ))
  end
  table.insert(h, '</div>')

  -- User hand
  table.insert(h, string.format(
    '<div class="x-risu-ulbl">내 패 (%d장)</div><div class="x-risu-uhnd">',
    #g.uh
  ))
  if not isMiku then
    for i, c in ipairs(g.uh) do
      local lbl = cardLabel(c)
      local cls = cardCls(c)
      local playable = canPlay(c, g.top, g.col)
        and (g.stk == 0 or isDraw(c))
        and not (#g.uh == 1 and isAction(c))
      if playable then
        -- FIX7: button styled as a card; risu-btn dispatches to onButtonClick
        table.insert(h, string.format(
          '<button class="x-risu-uc x-risu-%s" risu-btn="playCard_%d" style="cursor:pointer">%s</button>',
          cls, i-1, lbl
        ))
      else
        table.insert(h, string.format(
          '<span class="x-risu-uc x-risu-%s" style="opacity:.3">%s</span>', cls, lbl
        ))
      end
    end
  else
    table.insert(h, '<span style="font-size:.78em;color:#6870a0">미쿠가 생각 중...♡</span>')
  end
  table.insert(h, '</div>')

  -- UNO declaration button
  if not isMiku and #g.uh == 1 and not g.uno then
    -- FIX7: risu-btn for Lua dispatch
    table.insert(h, '<br><button class="x-risu-ubtn" risu-btn="declareUno">🎴 UNO!</button>')
  end

  -- Draw stack warning
  if g.stk > 0 then
    table.insert(h, string.format(
      '<div class="x-risu-ustk">⚠️ 드로우 스택 <b>+%d</b> — 드로우 카드로 맞받거나 뽑기!</div>',
      g.stk
    ))
  end

  table.insert(h, '<div class="x-risu-uft">UN○를 할 때는 카드를 잘 섞어서 이런 일이 발생하지 않도록 합시다</div></div>')
  return table.concat(h)
end

-- ========== FIX8: 특수 이벤트 CSS + UI 빌더 ==========
local CSS_ANIM = [[<style>
@keyframes x-risu-shake{0%,100%{transform:translateX(0)}10%,30%,50%,70%,90%{transform:translateX(-4px)}20%,40%,60%,80%{transform:translateX(4px)}}
@keyframes x-risu-cardfall{0%{opacity:0;transform:translateY(-30px) rotate(-5deg)}100%{opacity:1;transform:translateY(0) rotate(0)}}
@keyframes x-risu-fadein{0%{opacity:0}100%{opacity:1}}
.x-risu-evshake{animation:x-risu-shake .5s ease-in-out}
.x-risu-evcard{animation:x-risu-cardfall .4s ease-out both}
.x-risu-evmsg{animation:x-risu-fadein .6s ease-in both}
</style>]]

local function buildSpecialEventUI(g, evCards, mikuCard, collapseSaid, smugSaid)
  -- evCards: 유저의 원래 13장 패 (table), mikuCard: 미쿠의 1장 패 (table)
  local h = {CSS, CSS_ANIM}

  table.insert(h, '<div class="x-risu-uu">')

  -- Phase 1: 미쿠 기고만장
  table.insert(h, '<div class="x-risu-evmsg" style="animation-delay:0s;padding:10px 0 6px">')
  table.insert(h, '<div style="font-size:.8em;color:#ff9ecc;font-weight:bold;margin-bottom:4px">🌟 [1% 특수 이벤트]</div>')
  table.insert(h, string.format('<div class="x-risu-ubbl">😆 <b>미쿠:</b> %s</div>', smugSaid))
  table.insert(h, '<div class="x-risu-ulbl">미쿠 패 (1장)</div><div class="x-risu-uhnd">')
  for _, c in ipairs(mikuCard) do
    table.insert(h, string.format('<span class="x-risu-uc x-risu-%s">%s</span>', cardCls(c), cardLabel(c)))
  end
  table.insert(h, '</div></div>')

  -- Phase 2: 유저 카드 13장 쏟아짐 (CSS shake + cardfall)
  table.insert(h, '<div class="x-risu-evshake" style="animation-delay:.8s;padding:6px 0">')
  table.insert(h, '<div class="x-risu-ulbl">유저 패 쏟아짐! (13장)</div><div class="x-risu-uhnd">')
  for i, c in ipairs(evCards) do
    local delay = string.format("calc(.8s + %d*0.1s)", i - 1)
    table.insert(h, string.format(
      '<span class="x-risu-uc x-risu-evcard x-risu-%s" style="animation-delay:%s">%s</span>',
      cardCls(c), delay, cardLabel(c)
    ))
  end
  table.insert(h, '</div></div>')

  -- Phase 3: 미쿠 붕괴
  table.insert(h, '<div class="x-risu-evmsg" style="animation-delay:2.2s;padding:6px 0">')
  table.insert(h, string.format('<div class="x-risu-ubbl">😱 <b>미쿠:</b> %s</div>', collapseSaid))
  -- game-over 패널
  table.insert(h, string.format(
    '<div style="background:rgba(0,188,212,.08);border:1px solid rgba(0,188,212,.25);border-radius:9px;padding:10px;text-align:center;margin-top:6px">'..
    '<div style="font-size:1.2em;font-weight:900">🏆 유저 승리!</div>'..
    '<div style="font-size:.82em;color:#c0c8e8;margin:4px 0">미쿠 %d : %d 유저</div>'..
    '<div style="font-size:.75em;color:#e91e8c;font-weight:bold">미쿠가 벌칙을 수행합니다 ♡</div>'..
    '</div>',
    g.ms, g.us
  ))
  table.insert(h, '</div>')

  table.insert(h, '<div class="x-risu-uft">UN○를 할 때는 카드를 잘 섞어서 이런 일이 발생하지 않도록 합시다</div></div>')
  return table.concat(h)
end

-- ========== CORE PLAY CARD ==========
local function doPlay(tid, cardIdx)
  local g = loadG(tid)
  if not g.active then
    alertNormal(tid, "/start 를 입력해서 게임을 시작하세요!")
    return
  end
  if g.turn ~= "user" then
    alertNormal(tid, "미쿠의 턴이에요~ 기다려♡")
    return
  end
  if cardIdx < 0 or cardIdx >= #g.uh then return end

  local c = g.uh[cardIdx + 1]

  -- Draw stack constraint
  if g.stk > 0 and not isDraw(c) then
    alertNormal(tid, string.format(
      "드로우 스택 +%d 중! 드로우 카드를 내거나 뽑기 버튼을 누르세요.", g.stk
    ))
    return
  end

  -- Validity check
  if not canPlay(c, g.top, g.col) then
    g.said = "그 카드는 못 내~♡ 색이나 숫자를 맞춰봐♡"
    saveG(tid, g)
    return
  end

  -- House rule: cannot finish with action card
  if #g.uh == 1 and isAction(c) then
    alertNormal(tid, "하우스 룰: 마지막 카드는 숫자 카드여야 해요! 액션 카드로는 끝낼 수 없어요.")
    return
  end

  -- Play the card
  table.remove(g.uh, cardIdx + 1)
  g.top = c
  g.col = cardColor(c)
  g.uno = false

  -- Wild: ask for color
  if g.col == "Wild" then
    local ch = alertInput(tid, "색상을 선택하세요:\nred  /  blue  /  green  /  yellow")
    local cm = {red="Red",r="Red",blue="Blue",b="Blue",green="Green",g="Green",yellow="Yellow",y="Yellow"}
    g.col = cm[(ch or ""):lower():match("^%s*(.-)%s*$")] or "Red"
  end

  -- Apply effect
  local v = cardVal(c)
  if v == "Draw2" then
    g.stk = g.stk + 2
    g.turn = "miku"
  elseif v == "WildDraw4" then
    g.stk = g.stk + 4
    g.turn = "miku"
  elseif v == "Skip" or v == "Reverse" then
    -- 2-player: user goes again
    g.said = "이건 반칙이잖아~!♡ 으으으..."
    if #g.uh == 0 then
      handleRoundEnd(tid, g, "user")
      return
    end
    saveG(tid, g)
    return
  else
    g.turn = "miku"
  end

  -- Check user win
  if #g.uh == 0 then
    handleRoundEnd(tid, g, "user")
    return
  end

  -- Miku's turn
  local mikuWon = mikuDoTurn(tid, g)
  if mikuWon then
    handleRoundEnd(tid, g, "miku")
    return
  end

  -- If Miku got a skip/reverse against user (miku turn again)
  if g.turn == "miku" then
    mikuDoTurn(tid, g)
    if #g.mh == 0 then
      handleRoundEnd(tid, g, "miku")
      return
    end
  end

  g.turn = "user"
  saveG(tid, g)
  -- Inject context for AI narrative
  setInput(tid, string.format(
    "[게임] 유저가 %s를 냈습니다. 미쿠가 %s를 냈습니다. 미쿠 손패: %d장, 유저 손패: %d장. 현재 색상: %s. 미쿠 대사: %s",
    c, g.top, #g.mh, #g.uh, g.col, g.said
  ))
end

-- ========== onInput ==========
function onInput(triggerId)
  -- Wrap entire handler in pcall so any runtime error does not silently
  -- prevent game startup (e.g. json.decode crash on fresh chat state).
  pcall(function()

  local raw = getInput(triggerId) or ""
  local inp = raw:lower():match("^%s*(.-)%s*$")

  -- /start command
  -- NOTE: stopChat() is intentionally NOT called here.  Calling stopChat()
  -- would prevent the AI from generating a response, meaning no new message
  -- would be added to the chat, and therefore editDisplay would never fire to
  -- attach the game UI.  Instead we inject a game-context message via
  -- setInput() so the AI responds appropriately and editDisplay can render UI.
  if inp == "/start" then
    local g = loadG(triggerId)
    g.ms = 0
    g.us = 0
    g.rnd = 1
    g.said = "UN○를 할 때는 카드를 잘 섞어서 이런 일이 발생하지 않도록 합시다♡ 시작할게~♡"
    setState(triggerId, "winner", "")
    local isSpecial = initRound(triggerId, g)
    if isSpecial then
      autoPlaySpecialEvent(triggerId, g)
      setInput(triggerId, "[특수 이벤트] 1% 확률 이벤트 발동! 미쿠 패 1장에서 시작했으나 유저의 드로우 카드 연쇄로 미쿠가 대량 드로우! 유저 Green8으로 피니시! 미쿠 대붕괴! 시리즈 즉시 종료. 미쿠 대사: " .. g.said)
    else
      saveG(triggerId, g)
      setInput(triggerId, "[게임 시작] UNO 게임이 시작됐습니다! 미쿠 손패: " .. #g.mh .. "장, 유저 손패: " .. #g.uh .. "장. 미쿠 대사: " .. g.said)
    end
    return
  end

  local g = loadG(triggerId)
  if not g.active then return end

  -- UNO declaration
  if inp:find("^uno") or inp:find("유노") then
    g.uno = true
    g.said = "UNO 선언?♡ 귀엽긴 한데 내가 이겨♡"
    saveG(triggerId, g)
    setInput(triggerId, "[게임] 유저가 UNO를 선언했습니다! 미쿠: " .. g.said)
    return
  end

  -- Draw
  if inp == "draw" or inp == "pass" or inp:find("^드로우$") or inp:find("^뽑기$") or inp:find("카드 뽑기") then
    if g.turn == "user" then
      if g.stk > 0 then
        drawCards(g.deck, g.uh, g.stk)
        g.stk = 0
        g.said = pick("win") .. " 드로우♡"
      else
        drawCards(g.deck, g.uh, 1)
        g.said = "드로우~♡ 좋은 카드 나왔어?♡"
      end
      g.turn = "miku"
      mikuDoTurn(triggerId, g)
      if #g.mh == 0 then
        handleRoundEnd(triggerId, g, "miku")
        return
      end
      if g.turn == "miku" then g.turn = "user" end
      saveG(triggerId, g)
      setInput(triggerId, string.format(
        "[게임] 유저가 카드를 뽑았습니다. 미쿠 손패: %d장, 유저 손패: %d장. 미쿠 대사: %s",
        #g.mh, #g.uh, g.said
      ))
    end
    return
  end

  -- Text-based card play
  local colorKwds = {
    ["빨강"]="Red",["빨간"]="Red",["red"]="Red",
    ["파랑"]="Blue",["파란"]="Blue",["blue"]="Blue",
    ["초록"]="Green",["초록색"]="Green",["green"]="Green",
    ["노랑"]="Yellow",["노란"]="Yellow",["yellow"]="Yellow",
    ["와일드"]="Wild",["wild"]="Wild"
  }
  local valKwds = {
    ["0"]="0",["1"]="1",["2"]="2",["3"]="3",["4"]="4",
    ["5"]="5",["6"]="6",["7"]="7",["8"]="8",["9"]="9",
    ["스킵"]="Skip",["skip"]="Skip",
    ["리버스"]="Reverse",["reverse"]="Reverse",["rev"]="Reverse",
    ["+2"]="Draw2",["드로우2"]="Draw2",["draw2"]="Draw2",
    ["+4"]="WildDraw4",["드로우4"]="WildDraw4",["draw4"]="WildDraw4",
    ["wild draw 4"]="WildDraw4",["와일드 드로우"]="WildDraw4"
  }

  local fColor, fVal
  for kw, co in pairs(colorKwds) do
    if inp:find(kw, 1, true) then fColor = co; break end
  end
  for kw, v in pairs(valKwds) do
    if inp:find(kw, 1, true) then fVal = v; break end
  end

  if fColor or fVal then
    for i, c in ipairs(g.uh) do
      local match = true
      if fColor and cardColor(c) ~= fColor then match = false end
      if fVal   and cardVal(c)   ~= fVal   then match = false end
      if match then
        doPlay(triggerId, i - 1)
        return
      end
    end
    alertNormal(triggerId, "그 카드가 손패에 없어요! 손패를 확인해주세요.")
  end

  end) -- end pcall
  -- Errors are swallowed so the engine never crashes silently on bad state.
end

-- ========== onOutput ==========
function onOutput(triggerId)
  local out = getOutput(triggerId) or ""
  -- Remove broken tags
  out = out:gsub("{AFF|[^}]*}", "")
  out = out:gsub("{SIG|[^}]*}", "")
  out = out:gsub("{null}", "")
  out = out:gsub("{%u[%u_]*|[^}]*}", "")
  -- Remove UNO_STATE blocks
  out = out:gsub("%[UNO_STATE%][%s%S]-%[/UNO_STATE%]", "")
  -- FIX8: bare null (줄 끝의 리터럴 "null" 텍스트)
  out = out:gsub("%f[%a]null%f[%A]", "")
  out = out:match("^%s*(.-)%s*$") or ""
  if out == "" then out = " " end
  setOutput(triggerId, out)
end

-- ========== BUTTON HANDLERS ==========
function drawCard(triggerId)
  local g = loadG(triggerId)
  if not g.active or g.turn ~= "user" then return end
  local drawn = g.stk > 0 and g.stk or 1
  if g.stk > 0 then
    drawCards(g.deck, g.uh, g.stk)
    g.stk = 0
    g.said = pick("win") .. " 드로우~♡"
  else
    drawCards(g.deck, g.uh, 1)
    g.said = "드로우~♡ 좋은 카드 나왔어?♡"
  end
  g.turn = "miku"
  mikuDoTurn(triggerId, g)
  if #g.mh == 0 then
    handleRoundEnd(triggerId, g, "miku")
    return
  end
  if g.turn == "miku" then g.turn = "user" end
  saveG(triggerId, g)
  -- Inject context for AI narrative
  setInput(triggerId, string.format(
    "[게임] 유저가 카드 %d장을 뽑았습니다. 미쿠 손패: %d장, 유저 손패: %d장. 미쿠 대사: %s",
    drawn, #g.mh, #g.uh, g.said
  ))
end

function declareUno(triggerId)
  local g = loadG(triggerId)
  g.uno = true
  g.said = "UNO 선언!♡ 귀엽긴 한데... 내가 이겨♡"
  saveG(triggerId, g)
  setInput(triggerId, "[게임] 유저가 UNO를 선언했습니다! 패가 1장 남았어요. 미쿠: " .. g.said)
end

-- Generate playCard_0 .. playCard_19 dynamically
for _i = 0, 19 do
  local idx = _i
  _G["playCard_" .. idx] = function(tid)
    doPlay(tid, idx)
  end
end

-- ========== onButtonClick (FIX7: single router called by RisuAI for all risu-btn clicks) ==========
-- RisuAI calls onButtonClick(triggerId, buttonName) when a risu-btn element is clicked.
-- Unknown button names are silently ignored (no alert) to avoid disrupting gameplay.
function onButtonClick(triggerId, btnName)
  if btnName == "drawCard" then
    drawCard(triggerId)
  elseif btnName == "declareUno" then
    declareUno(triggerId)
  else
    local idx = btnName:match("^playCard_(%d+)$")
    if idx then
      doPlay(triggerId, tonumber(idx))
    end
  end
end

-- ========== DISPLAY HOOK ==========
listenEdit("editDisplay", function(triggerId, data)
  -- PATCH: guard against non-string data (RisuAI may pass json-decoded value)
  data = tostring(data or "")
  -- PATCH: wrap callback body in pcall for graceful degradation on any error
  local ok, result = pcall(function()
    data = data:gsub("{AFF|[^}]*}", "")
    data = data:gsub("{SIG|[^}]*}", "")
    data = data:gsub("{null}", "")
    data = data:gsub("{%u[%u_]*|[^}]*}", "") -- PATCH: broad pattern covers {BAT|..}, {FLOOR|..}, etc.
    -- FIX8: bare null 제거
    data = data:gsub("%f[%a]null%f[%A]", "")
    data = data:match("^%s*(.-)%s*$") or ""
    if data == "" then data = " " end
    local g = loadG(triggerId)
    -- FIX8: 특수 이벤트 UI (1% 이벤트 + 게임 종료)
    local special = safeGetState(triggerId, "special")
    if special == "1" and not g.active and g.winner == "user" then
      local evCards  = des(safeGetState(triggerId, "ev_cards")     or "")
      local mikuCard = des(safeGetState(triggerId, "ev_miku_card") or "")
      local smugSaid = safeGetState(triggerId, "ev_smug") or D.event_smug[1]
      local ui = buildSpecialEventUI(g, evCards, mikuCard, g.said, smugSaid)
      return data .. "\n\n" .. ui
    end
    if not g.active then
      -- Show game-over panel if series ended
      if g.winner ~= "" then
        local wonBy = g.winner == "miku" and "🎤 미쿠 승리" or "🏆 유저 승리"
        local msg = g.winner == "miku"
          and "벌칙을 수행하세요 ♡"
          or "미쿠가 벌칙을 수행합니다 ♡"
        local over = string.format(
          '<div style="font-family:sans-serif;background:linear-gradient(160deg,#0f0c29,#1a1a4e);border-radius:14px;padding:16px;color:#fff;max-width:500px;margin:8px auto;text-align:center;border:2px solid rgba(255,255,255,.15)">'..
          '<div style="font-size:1.4em;font-weight:900;margin-bottom:8px">%s</div>'..
          '<div style="font-size:.9em;color:#c0c8e8;margin-bottom:6px">미쿠 %d : %d 유저</div>'..
          '<div style="font-size:.85em;margin-bottom:8px">😆 미쿠: %s</div>'..
          '<div style="font-size:.75em;color:#e91e8c;font-weight:bold">%s</div>'..
          '<div style="font-size:.65em;color:#3a4070;margin-top:8px;font-style:italic">UN○를 할 때는 카드를 잘 섞어서 이런 일이 발생하지 않도록 합시다</div></div>',
          wonBy, g.ms, g.us, g.said, msg
        )
        return data .. "\n\n" .. over
      end
      return data
    end
    local ui = buildUI(g)
    return data .. "\n\n" .. ui
  end)
  -- FIX7: on error, include error message as HTML comment for debugging
  if ok then
    return result ~= nil and result or data
  else
    return data .. "<!-- LUA_ERR: " .. tostring(result) .. " -->"
  end
end)

