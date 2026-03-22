-- ================================================
-- UNO GAME ENGINE v3.0 for RISUAI - Hatsune Miku CharCard
-- Architecture: setChatVar/getChatVar + customScripts CBS
-- Card notation: color_value (e.g. red_5, blue_skip, any_wild4)
-- ================================================

pcall(function() math.randomseed(os.time()) end)

-- ========== CONSTANTS ==========
local COLORS   = {"red","yellow","green","blue"}
local SPECIALS = {"skip","reverse","draw2"}

-- 1% special event: hand given to player so that playing green_8 triggers the cascade
local CURSE_HAND =
    "green_8,green_draw2,green_draw2,yellow_draw2,yellow_draw2,"
    .. "blue_draw2,blue_draw2,red_draw2,red_draw2,"
    .. "any_wild4,any_wild4,any_wild4,any_wild4"

-- Lorebookentry content injected when the 1% event fires
local CURSE_LORE =
    "⚠️ 특수 이벤트 발동: 미쿠와나 나이스 트라이 원작 재현 이벤트\n\n"
    .. "플레이어의 패가 전부 드로우 카드(+2×8, +4×4)였고 그린 8 하나로 미쿠에게 24장이 쏟아졌다.\n\n"
    .. "반드시 아래 방식으로 반응:\n"
    .. "1. 미쿠가 패닉 상태로 카드 더미를 보며 현실 부정\n"
    .. "2. 테이블을 뒤집거나 카드를 날리며 도망치려 함\n"
    .. "3. 울면서 방에서 도망치는 장면으로 마무리\n"
    .. "4. 마지막 줄: \"...UNO를 할 때는 카드를 잘 섞어서 이런 일이 발생하지 않도록 합시다.\"\n\n"
    .. "이 이벤트 중에는 평소의 메스가키 태도를 완전히 잃고 진짜로 무너져야 한다."

-- ========== UTILS ==========
local function nvl(v, default)
    if not v or v == "" or v == "null" then return default end
    return v
end
local function s(t) return table.concat(t, ",") end
local function d(str)
    if not str or str == "" then return {} end
    local t = {}
    for c in str:gmatch("[^,]+") do t[#t+1] = c end
    return t
end

local function parseCard(card)
    local c, v = card:match("^([^_]+)_(.+)$")
    return c or "any", v or card
end

local function colorKr(c)
    return ({red="빨강",yellow="노랑",green="초록",blue="파랑"})[c] or c
end

local function cardName(card)
    local c, v = parseCard(card)
    local vm = {skip="스킵",reverse="리버스",draw2="+2",wild="와일드",wild4="+4 와일드"}
    if c == "any" then return vm[v] or v end
    return colorKr(c) .. " " .. (vm[v] or v)
end

local function canPlay(card, top, cur)
    local cc, cv = parseCard(card)
    local tc, tv = parseCard(top)
    local ac = cur ~= "" and cur or tc
    if cc == "any" then return true end
    if cc == ac then return true end
    if cv == tv then return true end
    return false
end

local function getPhase(triggerId)
    local p = getChatVar(triggerId, "cv_phase") or "idle"
    if p == "null" or p == "" then p = "idle" end
    return p
end

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
    event_smug = {
        "어?! 패가 1장?! 이건 내가 이기는 거잖아♡ 네 패는... 13장?! HAHAHA♡♡♡",
        "잠깐 이게 무슨... 패가 고작 1장?? 이건 운명이야♡ 포기해~♡ HAHAHA♡"
    },
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

-- ========== DECK ==========
local function createDeck()
    local deck = {}
    for _, color in ipairs(COLORS) do
        deck[#deck+1] = color .. "_0"
        for _, n in ipairs({"1","2","3","4","5","6","7","8","9"}) do
            deck[#deck+1] = color .. "_" .. n
            deck[#deck+1] = color .. "_" .. n
        end
        for _, sp in ipairs(SPECIALS) do
            deck[#deck+1] = color .. "_" .. sp
            deck[#deck+1] = color .. "_" .. sp
        end
    end
    for i = 1, 4 do deck[#deck+1] = "any_wild" end
    for i = 1, 4 do deck[#deck+1] = "any_wild4" end
    return deck
end

local function shuffle(deck)
    for i = #deck, 2, -1 do
        local j = math.random(1, i)
        deck[i], deck[j] = deck[j], deck[i]
    end
    return deck
end

-- Draw `count` cards into `hand`. Updates pile in CV. If isAI, also updates cv_ai_hand/cv_ai_count.
local function drawCards(triggerId, hand, count, isAI)
    local pile = d(getChatVar(triggerId, "cv_draw_pile") or "")
    if #pile == 0 then
        local newDeck = shuffle(createDeck())
        for i = 1, #newDeck do pile[#pile+1] = newDeck[i] end
        setChatVar(triggerId, "cv_draw_pile", s(pile))
    end
    for i = 1, count do
        if #pile == 0 then break end
        hand[#hand+1] = table.remove(pile, 1)
    end
    setChatVar(triggerId, "cv_draw_pile", s(pile))
    if isAI then
        setChatVar(triggerId, "cv_ai_hand", s(hand))
        setChatVar(triggerId, "cv_ai_count", tostring(#hand))
    end
end

-- AI picks the best card: prefers action cards, then numbers
local function aiPick(hand, top, cur)
    local playable = {}
    for i, card in ipairs(hand) do
        if canPlay(card, top, cur) then playable[#playable+1] = {i, card} end
    end
    if #playable == 0 then return nil end
    for _, item in ipairs(playable) do
        local _, v = parseCard(item[2])
        if v == "skip" or v == "reverse" or v == "draw2" or v == "wild4" then
            return item[1], item[2]
        end
    end
    return playable[1][1], playable[1][2]
end

-- ========== MIKU LINE ==========
local function getMikuLine(triggerId)
    local action  = nvl(getChatVar(triggerId, "cv_last_action"), "")
    local aiCnt   = tonumber(nvl(getChatVar(triggerId, "cv_ai_count"), "7")) or 7
    local ph      = d(nvl(getChatVar(triggerId, "cv_player_hand"), ""))
    local pCnt    = #ph
    local turn    = nvl(getChatVar(triggerId, "cv_turn"), "player")
    local gameNum = tonumber(nvl(getChatVar(triggerId, "cv_game_num"), "1")) or 1
    local curse   = getChatVar(triggerId, "cv_draw_curse") or ""

    if curse == "ready" then return "😏", pick("event_smug") end
    if curse == "end"   then return "😭", pick("event_collapse") end

    if action == "player_uno"       then return "😱", "야야야!!! UNO?! 진짜야?! 안돼 안돼!!" end
    if action == "ai_uno"           then return "😏", pick("uno") end
    if action == "ai_wild4"         then return "😈", "+4~ 미안~ 안 미안~🤭 받아~" end
    if action == "ai_draw2"         then return "🤭", "+2 선물이야~ 받아~" end
    if action == "player_wild4"     then return "😡", "야!!! 4장이나?! 진심이야?!" end
    if action == "player_draw2"     then return "😤", "치사하게 +2야? 두고 봐." end
    if action == "ai_skip"          then return "😏", "스킵~ 니 턴 없어~ 구경해~" end
    if action == "player_skip"      then return "😠", "야 스킵은 좀 치사하지 않냐!!" end
    if action == "player_reverse"   then return "😮", "어?! 리버스?! 얌체야?" end
    if action == "ai_reverse"       then return "😏", "리버스~ 순서 바꿨어~" end
    if action == "player_wild"      then return "🤔", "색깔 잘 골라봐~ 틀리면 나만 좋아~" end
    if action == "ai_wild"          then return "😏", "색깔은 내가 정할게~" end
    if action == "ai_draw" then
        return (aiCnt >= 8) and "😩" or "😌", "여유 있어서 뽑는 거야~ 전략."
    end
    if action == "player_draw"      then return "😏", "낼 카드 없어? ㅋㅋ 뽑고 있어~" end
    if action == "game_start"       then return "😏", "자 시작이야~ 나이스 트라이나 해봐~" end
    if action == "round_win_ai"     then return "😏", pick("rwon") end
    if action == "round_win_player" then return "😤", pick("rlose") end
    if action == "match_win_ai"     then return "😏", pick("swon") end
    if action == "match_win_player" then return "😭", pick("slose") end

    if aiCnt == 1  then return "😏", "UNO!! 이제 끝이야~ 나이스 트라이나 해봐" end
    if pCnt  == 1  then return "😨", "잠깐...!! 패가 한 장?! 집중해야겠다!!" end
    if aiCnt == 2  then return "🤭", "한 장만 더 내면 끝~ 어떻게 막을 건데?" end
    if pCnt  == 2  then return "😤", "...설마 이길 생각이야? 웃기고 있네." end
    if aiCnt >= 10 then return "😰", "패가 좀 많긴 한데. 전략이야." end
    if aiCnt >= 8  then return "😅", "왜 이렇게 패가 많아... 일부러 모은 거야." end
    if gameNum == 3 then return "😤", "마지막 판이야~ 집중해!!" end
    if gameNum == 2 then return "💪", "1판은 워밍업이었어~ 이제 진짜야." end
    if turn == "player" then return "😏", pick("normal") end
    return "🎴", "집중해~ 방심하면 나한테 져~"
end

-- ========== CARD HTML ==========
local bgCol = {red="#cb0323",yellow="#e8b800",green="#1a8a2e",blue="#1244c7"}

local function cardHTML(card, idx, playable, isBack)
    local c, v = parseCard(card)
    local vm  = {skip="Skip",reverse="Rev",draw2="+2",wild="Wild",wild4="+4"}
    local vd  = vm[v] or v
    local glow = playable and "box-shadow:0 0 12px 3px gold;transform:translateY(-5px);" or ""
    local cur  = playable and "cursor:pointer;" or "cursor:default;"
    local btn  = playable and (' risu-btn="play-' .. idx .. '"') or ""
    local wrap = '<div style="display:inline-block;margin:3px;vertical-align:top;' .. cur .. glow .. '"' .. btn .. '>'
    if isBack then
        return wrap
            .. '<div style="width:60px;height:90px;border-radius:8px;background:linear-gradient(135deg,#0f2027,#203a43,#2c5364);display:flex;align-items:center;justify-content:center;position:relative;overflow:hidden;border:2px solid #39c5bb;">'
            .. '<div style="position:absolute;background:rgba(57,197,187,0.15);inset:0;border-radius:100%;transform:scale(0.85) skewX(-22deg);"></div>'
            .. '<div style="position:absolute;width:82%;height:54%;border-radius:50%;border:1.5px solid rgba(57,197,187,0.4);transform:rotate(-30deg);"></div>'
            .. '<span style="position:relative;font-size:0.85rem;font-weight:900;color:#39c5bb;transform:rotate(-15deg);z-index:1;letter-spacing:1px;">UNO</span>'
            .. '</div></div>'
    end
    local frontBg = (c == "any")
        and 'background:conic-gradient(#cb0323 0% 25%,#e8b800 25% 50%,#1a8a2e 50% 75%,#1244c7 75% 100%);'
        or  ('background:' .. (bgCol[c] or "#555") .. ';')
    return wrap
        .. '<div style="width:60px;height:90px;border-radius:8px;' .. frontBg
        .. 'display:flex;flex-direction:column;align-items:center;justify-content:center;position:relative;overflow:hidden;border:2px solid rgba(255,255,255,0.25);">'
        .. '<div style="position:absolute;width:82%;height:54%;border-radius:50%;border:2px solid rgba(255,255,255,0.4);transform:rotate(-30deg);pointer-events:none;"></div>'
        .. '<span style="position:absolute;top:3px;left:4px;font-size:0.62rem;font-weight:900;color:#fff;text-shadow:-1px -1px 0 #000,1px 1px 0 #000;z-index:1;">' .. vd .. '</span>'
        .. '<span style="position:relative;font-size:1.55rem;font-weight:900;color:#fff;text-shadow:-1px -1px 0 #000,1px 1px 0 #000;z-index:1;">' .. vd .. '</span>'
        .. '<span style="position:absolute;bottom:3px;right:4px;font-size:0.62rem;font-weight:900;color:#fff;text-shadow:-1px -1px 0 #000,1px 1px 0 #000;transform:rotate(180deg);z-index:1;">' .. vd .. '</span>'
        .. '</div></div>'
end

-- ========== PANEL / STATUS / BOTTOM-UI ==========
-- Panel button HTML prefix/mid/suffix (split so cv_panel_label / cv_panel_sub can be interpolated)
local PANEL_BTN_PREFIX =
    '<div style="display:flex;justify-content:center;margin:6px 0;">'
    .. '<div risu-btn="game-start" style="display:flex;align-items:center;gap:10px;padding:8px 14px 8px 10px;'
    .. 'background:linear-gradient(135deg,#0f2027,#203a43,#2c5364);border:1px solid rgba(57,197,187,0.3);'
    .. 'border-radius:10px;cursor:pointer;">'
    .. '<div style="position:relative;width:32px;height:48px;flex-shrink:0;">'
    .. '<div style="position:absolute;top:5px;left:3px;width:28px;height:40px;border-radius:5px;background:#162535;border:1px solid #1e3548;"></div>'
    .. '<div style="position:absolute;top:2px;left:1px;width:28px;height:40px;border-radius:5px;background:#1a2f42;border:1px solid #243f55;"></div>'
    .. '<div style="position:absolute;top:0;left:0;width:28px;height:40px;border-radius:5px;background:linear-gradient(135deg,#0f2027,#203a43,#2c5364);border:1px solid #39c5bb;display:flex;align-items:center;justify-content:center;">'
    .. '<div style="position:absolute;width:76%;height:50%;border-radius:50%;border:1px solid rgba(57,197,187,0.35);transform:rotate(-30deg);"></div>'
    .. '<span style="position:relative;z-index:1;font-size:0.45rem;font-weight:900;color:#39c5bb;transform:rotate(-15deg);letter-spacing:1.5px;font-family:sans-serif;">UNO</span>'
    .. '</div></div>'
    .. '<div style="display:flex;flex-direction:column;gap:2px;margin-left:4px;">'
    .. '<span style="background:#cb0323;color:#e4c713;font-size:0.42rem;font-weight:900;padding:1px 5px;border-radius:3px;letter-spacing:1px;border:1px solid #e4c713;font-family:sans-serif;">UNO</span>'
    .. '<span style="font-size:0.75rem;font-weight:900;color:#39c5bb;font-family:sans-serif;">'
local PANEL_BTN_MID    = '</span><span style="font-size:0.5rem;color:rgba(255,255,255,0.45);font-family:sans-serif;">'
local PANEL_BTN_SUFFIX = '</span></div></div></div>'

local function savePanel(triggerId)
    local phase = getPhase(triggerId)
    if phase == "playing" then
        setChatVar(triggerId, "cv_panel_html", "")
        setChatVar(triggerId, "cv_panel_label", "")
        setChatVar(triggerId, "cv_panel_sub", "")
        return
    end
    setChatVar(triggerId, "cv_panel_html", "show")
    if phase == "match_end" then
        setChatVar(triggerId, "cv_panel_label", "다시 하기")
        setChatVar(triggerId, "cv_panel_sub", "벌칙 RP 후 누르세요")
    elseif phase == "between_games" then
        setChatVar(triggerId, "cv_panel_label", "다음 판 시작")
        setChatVar(triggerId, "cv_panel_sub", "버튼을 눌러 다음 판을 시작하세요")
    else
        setChatVar(triggerId, "cv_panel_label", "게임 시작")
        setChatVar(triggerId, "cv_panel_sub", "카드를 눌러서 시작")
    end
end

local function saveBottomUI(triggerId)
    local phase = getPhase(triggerId)
    if phase == "playing" then
        -- Only inject bottom-UI when the game message is NOT the last message
        -- (prevents duplicating UI that is already shown via {UNO_GAME} placeholder)
        local gameIdx = tonumber(nvl(getChatVar(triggerId, "cv_game_msg_idx"), "-1")) or -1
        local chatLen = getChatLength(triggerId) or 0
        if gameIdx >= 0 and (chatLen - 1) > gameIdx then
            local gameHTML = getChatVar(triggerId, "cv_game_html") or ""
            setChatVar(triggerId, "cv_bottom_ui", "\n" .. gameHTML)
        else
            setChatVar(triggerId, "cv_bottom_ui", "")
        end
        return
    end
    -- match_end / between_games: keep status bar + restart button visible under RP messages
    local statusHtml = getChatVar(triggerId, "cv_status_html") or ""
    local label      = nvl(getChatVar(triggerId, "cv_panel_label"), "다시 하기")
    local sub        = nvl(getChatVar(triggerId, "cv_panel_sub"),   "벌칙 RP 후 누르세요")
    local panelHtml  = PANEL_BTN_PREFIX .. label .. PANEL_BTN_MID .. sub .. PANEL_BTN_SUFFIX
    setChatVar(triggerId, "cv_bottom_ui", "\n" .. statusHtml .. "\n" .. panelHtml)
end

local function saveStatus(triggerId)
    local phase = getPhase(triggerId)
    local wp = nvl(getChatVar(triggerId, "cv_wins_player"), "0")
    local wa = nvl(getChatVar(triggerId, "cv_wins_ai"),     "0")
    local gn = nvl(getChatVar(triggerId, "cv_game_num"),    "1")
    local stateText
    if     phase == "playing"       then stateText = "게임 중"
    elseif phase == "between_games" then stateText = "판 종료"
    elseif phase == "match_end"     then stateText = "매치 종료"
    else                                 stateText = "대기 중" end
    local mono = getChatVar(triggerId, "cv_status_mono") or ""
    if mono == "" or mono == "null" then mono = "..." end
    local html =
        '<div class="uno-status">'
        .. '<div class="us-img" style="background-image:url({{source::char}});"></div>'
        .. '<div class="us-fade"></div>'
        .. '<span class="us-score">나 ' .. wp .. '승 : 미쿠 ' .. wa .. '승</span>'
        .. '<span class="us-sub">'   .. gn .. '/3판 &nbsp;·&nbsp; ' .. stateText .. '</span>'
        .. '<span class="us-mono">'  .. mono .. '</span>'
        .. '</div>'
    setChatVar(triggerId, "cv_status_html", html)
    saveBottomUI(triggerId)
end

-- ========== BUILD GAME UI ==========
local function buildUI(triggerId)
    local phase = getPhase(triggerId)
    if phase ~= "playing" then return "" end

    local top    = nvl(getChatVar(triggerId, "cv_top_card"),       "")
    local cur    = nvl(getChatVar(triggerId, "cv_current_color"),  "red")
    local ph     = d(nvl(getChatVar(triggerId, "cv_player_hand"), ""))
    local aiHand = d(nvl(getChatVar(triggerId, "cv_ai_hand"),     ""))
    local aiCnt  = #aiHand
    local pile   = d(nvl(getChatVar(triggerId, "cv_draw_pile"),   ""))
    local turn   = nvl(getChatVar(triggerId, "cv_turn"),          "player")
    local msg    = nvl(getChatVar(triggerId, "cv_message"),        "")
    local unoCall   = nvl(getChatVar(triggerId, "cv_uno_call"),    "0")
    local choose    = nvl(getChatVar(triggerId, "cv_choose_color"),"0")
    local unoPending= getChatVar(triggerId, "cv_uno_pending") or "0"

    local emoji, line = getMikuLine(triggerId)
    local dotBg = ({red="#cb0323",yellow="#e8b800",green="#1a8a2e",blue="#1244c7"})[cur] or "#888"
    local dot = '<span style="display:inline-block;width:13px;height:13px;border-radius:50%;border:2px solid #fff;background:' .. dotBg .. ';vertical-align:middle;margin:0 3px;"></span>'

    -- Top card
    local topHTML = top ~= "" and cardHTML(top, 0, false, false)
        or '<div style="width:60px;height:90px;border:2px dashed rgba(255,255,255,0.2);border-radius:8px;display:flex;align-items:center;justify-content:center;color:rgba(255,255,255,0.3);">?</div>'

    -- Miku's hand (face-down)
    local aiHTML = '<div style="display:flex;flex-wrap:wrap;gap:1px;justify-content:center;">'
    for i = 1, math.min(aiCnt, 10) do aiHTML = aiHTML .. cardHTML("x_b", i, false, true) end
    if aiCnt > 10 then aiHTML = aiHTML .. '<span style="align-self:center;font-size:0.72rem;opacity:0.55;">+' .. (aiCnt - 10) .. '장</span>' end
    aiHTML = aiHTML .. '</div>'

    -- Player's hand (face-up, playable cards glow)
    local isChoosing   = choose == "1"
    local isPlayerTurn = turn == "player"
    local phHTML = '<div style="display:flex;flex-wrap:wrap;gap:1px;justify-content:center;">'
    for i, card in ipairs(ph) do
        phHTML = phHTML .. cardHTML(card, i, isPlayerTurn and not isChoosing and canPlay(card, top, cur), false)
    end
    phHTML = phHTML .. '</div>'

    -- Action buttons
    local drawBtn = (isPlayerTurn and not isChoosing)
        and '<button style="padding:7px 16px;background:#3a7bd5;color:#fff;border:none;border-radius:7px;font-weight:700;cursor:pointer;" risu-btn="uno-draw">카드 뽑기</button>'
        or ''

    local unoBtn = ""
    if #ph == 2 and unoCall == "0" and isPlayerTurn and not isChoosing then
        local canPlayAny = false
        for _, card in ipairs(ph) do
            if canPlay(card, top, cur) then canPlayAny = true; break end
        end
        if canPlayAny then
            unoBtn = '<button style="padding:7px 16px;background:#e4c713;color:#111;border:none;border-radius:7px;font-size:0.9rem;font-weight:900;cursor:pointer;" risu-btn="uno-call">UNO!</button>'
        end
    end

    local unoPendingBtn = ""
    if unoPending == "1" and turn == "player" then
        unoPendingBtn = '<button style="padding:7px 14px;background:#cb0323;color:#fff;border:none;border-radius:7px;font-size:0.78rem;font-weight:900;cursor:pointer;" risu-btn="penalty-call">😈 UNO 안 외쳤어!</button>'
    end

    -- Color picker (shown after wild card)
    local colorPicker = ""
    if choose == "1" then
        colorPicker = '<div style="display:flex;flex-direction:column;gap:4px;background:rgba(0,0,0,0.55);padding:8px;border-radius:8px;">'
            .. '<p style="font-size:0.78rem;color:#fff;margin-bottom:2px;">색상 선택:</p>'
            .. '<button style="padding:5px;background:#cb0323;color:#fff;border:1px solid #fff;border-radius:5px;font-weight:700;cursor:pointer;" risu-btn="color-red">빨강</button>'
            .. '<button style="padding:5px;background:#e8b800;color:#111;border:1px solid #fff;border-radius:5px;font-weight:700;cursor:pointer;" risu-btn="color-yellow">노랑</button>'
            .. '<button style="padding:5px;background:#1a8a2e;color:#fff;border:1px solid #fff;border-radius:5px;font-weight:700;cursor:pointer;" risu-btn="color-green">초록</button>'
            .. '<button style="padding:5px;background:#1244c7;color:#fff;border:1px solid #fff;border-radius:5px;font-weight:700;cursor:pointer;" risu-btn="color-blue">파랑</button>'
            .. '</div>'
    end

    -- FX badge for last action
    local fxBadge = ""
    local act = getChatVar(triggerId, "cv_last_action") or ""
    if act == "ai_skip" or act == "player_skip" then
        fxBadge = '<span style="display:inline-flex;align-items:center;padding:3px 10px;border-radius:20px;font-weight:900;font-size:0.75rem;font-family:sans-serif;letter-spacing:1px;background:rgba(255,107,53,0.2);border:1.5px solid #ff6b35;color:#ff6b35;margin-right:6px;flex-shrink:0;">SKIP</span>'
    elseif act == "ai_reverse" or act == "player_reverse" then
        fxBadge = '<span style="display:inline-flex;align-items:center;padding:3px 10px;border-radius:20px;font-weight:900;font-size:0.75rem;font-family:sans-serif;letter-spacing:1px;background:rgba(167,139,250,0.2);border:1.5px solid #a78bfa;color:#a78bfa;margin-right:6px;flex-shrink:0;">REV</span>'
    elseif act == "ai_draw2" or act == "player_draw2" then
        fxBadge = '<span style="display:inline-flex;align-items:center;padding:3px 10px;border-radius:20px;font-weight:900;font-size:0.75rem;font-family:sans-serif;letter-spacing:1px;background:rgba(203,3,35,0.2);border:1.5px solid #cb0323;color:#ff6b6b;margin-right:6px;flex-shrink:0;">+2</span>'
    elseif act == "ai_wild4" or act == "player_wild4" then
        fxBadge = '<span style="display:inline-flex;align-items:center;padding:3px 10px;border-radius:20px;font-weight:900;font-size:0.75rem;font-family:sans-serif;letter-spacing:1px;background:rgba(203,3,35,0.2);border:1.5px solid #cb0323;color:#ff6b6b;margin-right:6px;flex-shrink:0;">+4</span>'
    elseif act == "ai_wild" or act == "player_wild" or act == "color_chosen" then
        fxBadge = '<span style="display:inline-flex;align-items:center;padding:3px 10px;border-radius:20px;font-weight:900;font-size:0.75rem;font-family:sans-serif;letter-spacing:1px;background:rgba(57,197,187,0.2);border:1.5px solid #39c5bb;color:#39c5bb;margin-right:6px;flex-shrink:0;">WILD</span>'
    elseif act == "ai_uno" or act == "player_uno" then
        fxBadge = '<span style="display:inline-flex;align-items:center;padding:3px 10px;border-radius:20px;font-weight:900;font-size:0.75rem;font-family:sans-serif;letter-spacing:1.5px;background:rgba(228,199,19,0.2);border:1.5px solid #e4c713;color:#e4c713;margin-right:6px;flex-shrink:0;">UNO!</span>'
    end

    local aiThink = (turn == "ai" and aiCnt > 0) and '<div style="font-size:0.78rem;opacity:0.5;font-style:italic;text-align:center;">미쿠 생각 중...</div>' or ''
    local msgHTML = msg ~= "" and ('<div style="background:rgba(255,255,255,0.09);border-left:3px solid #e4c713;padding:5px 9px;border-radius:0 6px 6px 0;font-size:0.82rem;margin:4px 0;">' .. msg .. '</div>') or ''

    return '<div style="width:100%;max-width:640px;margin:0 auto 8px;padding:10px;background:linear-gradient(135deg,#0f2027,#203a43,#2c5364);border-radius:14px;color:#fff;font-family:sans-serif;position:relative;">'
        .. '<div style="background:rgba(255,255,255,0.07);border:1px solid rgba(255,255,255,0.15);border-radius:10px;padding:8px 12px;margin-bottom:8px;display:flex;align-items:center;gap:8px;">'
            .. fxBadge
            .. '<span style="font-size:1.4rem;">' .. emoji .. '</span>'
            .. '<span style="font-size:0.88rem;color:#f0f0f0;font-style:italic;">&quot;' .. line .. '&quot;</span>'
        .. '</div>'
        .. '<div style="display:flex;justify-content:space-between;padding:4px 8px;background:rgba(255,255,255,0.08);border-radius:7px;margin-bottom:6px;font-size:0.8rem;">'
            .. '<span>미쿠 패: ' .. aiCnt .. '장</span>' .. dot .. '<span>덱: ' .. #pile .. '장</span>'
        .. '</div>'
        .. '<div style="background:rgba(255,255,255,0.04);border-radius:8px;padding:6px;margin-bottom:5px;">' .. aiHTML .. '</div>'
        .. msgHTML
        .. '<div style="display:flex;justify-content:center;align-items:flex-start;gap:14px;margin:5px 0;">'
            .. '<div style="display:flex;flex-direction:column;align-items:center;gap:3px;">'
                .. '<span style="font-size:0.7rem;opacity:0.55;">버린 카드' .. dot .. '</span>'
                .. topHTML
            .. '</div>'
            .. '<div style="display:flex;flex-direction:column;align-items:center;gap:6px;padding-top:14px;">'
                .. drawBtn .. unoBtn .. unoPendingBtn .. colorPicker .. aiThink
            .. '</div>'
        .. '</div>'
        .. '<div style="background:rgba(255,255,255,0.06);border-radius:10px;padding:8px;">'
            .. '<div style="font-size:0.7rem;opacity:0.55;margin-bottom:3px;">내 패: ' .. #ph .. '장</div>'
            .. phHTML
        .. '</div>'
        .. '</div>'
end

local function saveUI(triggerId)
    setChatVar(triggerId, "cv_game_html", buildUI(triggerId))
end

-- ========== RANDOM SEED (wasmoon-safe) ==========
local _seedCounter = 0
local function safeRandomSeed(triggerId)
    _seedCounter = _seedCounter + 1
    local seed = _seedCounter * 31
    local addrStr = tostring({})
    local addr = tonumber(addrStr:match("0x(%x+)") or addrStr:match("(%d+)")) or 0
    seed = seed + addr
    pcall(function() seed = seed + os.time() end)
    pcall(function() seed = seed + math.floor(os.clock() * 100000) end)
    if triggerId then
        local cnt = tonumber(getChatVar(triggerId, "cv_rng_counter") or "0") or 0
        cnt = cnt + 1
        setChatVar(triggerId, "cv_rng_counter", tostring(cnt))
        seed = seed + cnt * 7919
        local chatLen = getChatLength(triggerId) or 0
        seed = seed + chatLen * 1337
    end
    if seed < 1000 then seed = seed + 9999 end
    math.randomseed(seed)
    for i = 1, 10 do math.random() end
end

-- ========== START NEW GAME (internal) ==========
local function startNewGame(triggerId)
    safeRandomSeed(triggerId)
    upsertLocalLoreBook(triggerId, "curse_event_active", "", {key="curse_active", alwaysActive=false})
    local deck = shuffle(createDeck())
    local ph, ah = {}, {}
    for i = 1, 7 do
        ph[#ph+1] = table.remove(deck, 1)
        ah[#ah+1] = table.remove(deck, 1)
    end
    -- First card must be a number card (not wild)
    local top, idx = nil, 1
    while idx <= #deck do
        local c, v = parseCard(deck[idx])
        if c ~= "any" and tonumber(v) then
            top = table.remove(deck, idx); break
        end
        idx = idx + 1
    end
    if not top then top = table.remove(deck, 1) end
    local tc = parseCard(top)
    setChatVar(triggerId, "cv_phase",         "playing")
    setChatVar(triggerId, "cv_draw_pile",     s(deck))
    setChatVar(triggerId, "cv_top_card",      top)
    setChatVar(triggerId, "cv_current_color", tc == "any" and "red" or tc)
    setChatVar(triggerId, "cv_player_hand",   s(ph))
    setChatVar(triggerId, "cv_ai_hand",       s(ah))
    setChatVar(triggerId, "cv_ai_count",      tostring(#ah))
    setChatVar(triggerId, "cv_turn",          "player")
    setChatVar(triggerId, "cv_message",       "게임 시작! 첫 카드: " .. cardName(top))
    setChatVar(triggerId, "cv_uno_call",      "0")
    setChatVar(triggerId, "cv_choose_color",  "0")
    setChatVar(triggerId, "cv_last_action",   "game_start")
    setChatVar(triggerId, "cv_draw_curse",    "")
    setChatVar(triggerId, "cv_curse_attempts","0")
    setChatVar(triggerId, "cv_uno_pending",   "0")
    saveUI(triggerId)
    savePanel(triggerId)
end

-- ========== CHECK WIN ==========
local function checkWin(triggerId, who, hand)
    if #hand > 0 then return false end
    local wp = tonumber(getChatVar(triggerId, "cv_wins_player") or "0")
    local wa = tonumber(getChatVar(triggerId, "cv_wins_ai")     or "0")
    if who == "player" then
        wp = wp + 1
        setChatVar(triggerId, "cv_wins_player", tostring(wp))
        setChatVar(triggerId, "cv_message", "🎉 이겼다! (" .. wp .. "승 : " .. wa .. "승)")
    else
        wa = wa + 1
        setChatVar(triggerId, "cv_wins_ai", tostring(wa))
        setChatVar(triggerId, "cv_message", "😭 졌다... (" .. wp .. "승 : " .. wa .. "승)")
    end
    local prevUI    = getChatVar(triggerId, "cv_game_html") or ""
    local isMatchEnd = (wp >= 2 or wa >= 2)
    if isMatchEnd then
        setChatVar(triggerId, "cv_phase",       "match_end")
        setChatVar(triggerId, "cv_winner",      wp >= 2 and "player" or "ai")
        setChatVar(triggerId, "cv_last_action", wp >= 2 and "match_win_player" or "match_win_ai")
    else
        local gn = tonumber(getChatVar(triggerId, "cv_game_num") or "1") + 1
        setChatVar(triggerId, "cv_game_num",      tostring(gn))
        setChatVar(triggerId, "cv_round_winner",  who)
        setChatVar(triggerId, "cv_last_action",   who == "player" and "round_win_player" or "round_win_ai")
        setChatVar(triggerId, "cv_phase",         "between_games")
    end
    -- Build result overlay
    local titleCls, titleTxt, subTxt, iconHTML
    if isMatchEnd then
        if who == "player" then
            titleCls = "uro-title-win";  titleTxt = "최종 승리!";  iconHTML = '<div class="uro-icon">🏆</div>'
            subTxt = "벌칙 RP 후 하단 버튼으로 재도전"
        else
            titleCls = "uro-title-lose"; titleTxt = "최종 패배";   iconHTML = '<div class="uro-icon">😤</div>'
            subTxt = "벌칙 RP 후 하단 버튼으로 재도전"
        end
    else
        local roundNum = tostring(tonumber(getChatVar(triggerId, "cv_game_num") or "1") - 1)
        if who == "player" then
            titleCls = "uro-title-win";  titleTxt = roundNum .. "판 승리!"; iconHTML = '<div class="uro-icon">🎉</div>'
            subTxt = "하단 버튼을 눌러 다음 판을 시작하세요"
        else
            titleCls = "uro-title-lose"; titleTxt = roundNum .. "판 패배";  iconHTML = '<div class="uro-icon">😤</div>'
            subTxt = "하단 버튼을 눌러 다음 판을 시작하세요"
        end
    end
    local scoreHTML = '<div class="uro-score">나 ' .. wp .. '승 : 미쿠 ' .. wa .. '승</div>'
    local overlay = '<div class="uno-result-overlay">'
        .. iconHTML
        .. '<div class="uro-title ' .. titleCls .. '">' .. titleTxt .. '</div>'
        .. scoreHTML
        .. '<div class="uro-sub">' .. subTxt .. '</div>'
        .. '</div>'
    -- Inject overlay into last </div> of prevUI
    local finalUI
    if prevUI ~= "" then
        local insertPos, searchFrom = nil, 1
        while true do
            local found = prevUI:find("</div>", searchFrom, true)
            if not found then break end
            insertPos = found; searchFrom = found + 1
        end
        if insertPos then
            finalUI = prevUI:sub(1, insertPos - 1) .. overlay .. prevUI:sub(insertPos)
        else
            finalUI = '<div style="position:relative;">' .. overlay .. '</div>'
        end
    else
        finalUI = '<div style="width:100%;max-width:640px;margin:0 auto 8px;padding:10px;background:linear-gradient(135deg,#0f2027,#203a43,#2c5364);border-radius:14px;position:relative;">' .. overlay .. '</div>'
    end
    setChatVar(triggerId, "cv_game_html", finalUI)
    savePanel(triggerId); saveStatus(triggerId)
    return true
end

-- ========== AI TURN ==========
local function processAI(triggerId)
    local maxTurns = 8
    local won      = false
    local ah  = d(nvl(getChatVar(triggerId, "cv_ai_hand"),        ""))
    local top = nvl(getChatVar(triggerId, "cv_top_card"),         "")
    local cur = nvl(getChatVar(triggerId, "cv_current_color"),    "red")
    local finalMsg    = ""
    local finalAction = "ai_play"
    local endTurn     = false
    if #ah == 0 then won = true end

    for _ = 1, maxTurns do
        if won or getPhase(triggerId) ~= "playing" then break end
        if #ah == 0 then won = true; break end
        local ci, cc = aiPick(ah, top, cur)
        if not ci then
            drawCards(triggerId, ah, 1, true)
            finalMsg    = "미쿠가 카드를 뽑았습니다."
            finalAction = "ai_draw"
            endTurn     = true; break
        end
        table.remove(ah, ci)
        top = cc
        local c, v     = parseCard(cc)
        local msg      = "미쿠: " .. cardName(cc) .. " 사용!"
        local action   = "ai_play"
        local loopAgain = false
        if c == "any" then
            -- Choose best color for AI
            local cnt = {red=0,yellow=0,green=0,blue=0}
            for _, card in ipairs(ah) do
                local ac = parseCard(card)
                if cnt[ac] then cnt[ac] = cnt[ac] + 1 end
            end
            local best, bc = "red", -1
            for col, n in pairs(cnt) do if n > bc then bc = n; best = col end end
            cur = best
            msg = msg .. " → " .. colorKr(best)
            if v == "wild4" then
                local p = d(getChatVar(triggerId, "cv_player_hand") or "")
                drawCards(triggerId, p, 4, false)
                setChatVar(triggerId, "cv_player_hand", s(p))
                msg = msg .. " 플레이어 +4!"; action = "ai_wild4"
            else
                action = "ai_wild"
            end
        else
            cur = c
            if v == "draw2" then
                local p = d(getChatVar(triggerId, "cv_player_hand") or "")
                drawCards(triggerId, p, 2, false)
                setChatVar(triggerId, "cv_player_hand", s(p))
                msg = msg .. " 플레이어 +2!"; action = "ai_draw2"
            elseif v == "skip" then
                action = "ai_skip";    msg = msg .. " 플레이어 스킵!"; loopAgain = true
            elseif v == "reverse" then
                action = "ai_reverse"; msg = msg .. " (리버스=스킵)";  loopAgain = true
            end
        end
        -- UNO check & 1% special event trigger
        if #ah == 1 then
            msg = msg .. " UNO!"; action = "ai_uno"
            local curseCount = tonumber(getChatVar(triggerId, "cv_curse_attempts") or "0") or 0
            curseCount = curseCount + 1
            setChatVar(triggerId, "cv_curse_attempts", tostring(curseCount))
            local existingCurse = getChatVar(triggerId, "cv_draw_curse") or ""
            local roll = math.random(1, 100)
            if curseCount >= 3 and roll == 1 and existingCurse ~= "ready" then
                -- 1% event: replace top card with green number, give player all-draw-cards hand
                local gn = {"green_1","green_2","green_3","green_5","green_6","green_7","green_9"}
                top = gn[math.random(#gn)]; cur = "green"
                setChatVar(triggerId, "cv_player_hand", CURSE_HAND)
                setChatVar(triggerId, "cv_draw_curse", "ready")
                loopAgain = false
            end
        end
        finalMsg = msg; finalAction = action
        if #ah == 0 then won = true; break end
        if not loopAgain then endTurn = true; break end
    end

    if not endTurn and not won then endTurn = true end
    setChatVar(triggerId, "cv_ai_hand",        s(ah))
    setChatVar(triggerId, "cv_ai_count",       tostring(#ah))
    setChatVar(triggerId, "cv_top_card",       top)
    setChatVar(triggerId, "cv_current_color",  cur)
    setChatVar(triggerId, "cv_message",        finalMsg)
    setChatVar(triggerId, "cv_last_action",    finalAction)
    if endTurn then
        setChatVar(triggerId, "cv_turn",     "player")
        setChatVar(triggerId, "cv_uno_call", "0")
    end
    if getPhase(triggerId) == "playing" then
        if #ah == 0 then won = true end
        saveUI(triggerId)
    end
    if won then
        checkWin(triggerId, "ai", ah)
    else
        savePanel(triggerId); saveStatus(triggerId)
    end
    reloadDisplay(triggerId)
end

-- ========== PUBLIC GAME FUNCTIONS ==========

function startGame(triggerId)
    local phase = getPhase(triggerId)
    if phase == "match_end" then
        setChatVar(triggerId, "cv_wins_player", "0")
        setChatVar(triggerId, "cv_wins_ai",     "0")
        setChatVar(triggerId, "cv_game_num",    "1")
    end
    setChatVar(triggerId, "cv_last_action", "game_start")
    startNewGame(triggerId)
    savePanel(triggerId); saveStatus(triggerId)
    addChat(triggerId, "char", "{STATUS_BAR}\n{UNO_GAME}\n{SIDE_PANEL}")
    local len = getChatLength(triggerId)
    if len and len > 0 then
        setChatVar(triggerId, "cv_game_msg_idx", tostring(len - 1))
    end
    -- Re-save status after addChat so cv_bottom_ui is correctly set
    saveStatus(triggerId)
    reloadDisplay(triggerId)
end

function onStart(triggerId)
    savePanel(triggerId); saveStatus(triggerId)
    local phase = getPhase(triggerId)
    upsertLocalLoreBook(triggerId, "curse_event_active", "", {key="curse_active", alwaysActive=false})
    -- Recovery: if stuck in ai-turn or color-selection mode, reset to player turn
    if phase == "playing" then
        local turn   = getChatVar(triggerId, "cv_turn")          or "player"
        local choose = getChatVar(triggerId, "cv_choose_color")  or "0"
        if turn == "ai" or choose == "1" then
            setChatVar(triggerId, "cv_turn",          "player")
            setChatVar(triggerId, "cv_choose_color",  "0")
            saveUI(triggerId); savePanel(triggerId); saveStatus(triggerId)
            reloadDisplay(triggerId)
        end
    end
end

function onInput(triggerId)
    local raw = getInput(triggerId) or ""
    local inp = raw:lower():match("^%s*(.-)%s*$")
    if inp == "/start" then
        stopChat(triggerId)
        startGame(triggerId)
    end
end

function playCard(triggerId, idx)
    if getPhase(triggerId) ~= "playing" then return end
    local turn = nvl(getChatVar(triggerId, "cv_turn"), "player")
    if turn ~= "player" then return end
    local choose = nvl(getChatVar(triggerId, "cv_choose_color"), "0")
    if choose == "1" then return end
    local ph   = d(nvl(getChatVar(triggerId, "cv_player_hand"), ""))
    local card = ph[idx]
    if not card then return end
    local top = nvl(getChatVar(triggerId, "cv_top_card"),      "")
    local cur = nvl(getChatVar(triggerId, "cv_current_color"), "red")
    if not canPlay(card, top, cur) then
        setChatVar(triggerId, "cv_message", "그 카드는 낼 수 없어요!")
        saveUI(triggerId); reloadDisplay(triggerId); return
    end
    local unoCall = nvl(getChatVar(triggerId, "cv_uno_call"), "0")
    table.remove(ph, idx)
    setChatVar(triggerId, "cv_player_hand", s(ph))
    setChatVar(triggerId, "cv_top_card",    card)
    local c, v   = parseCard(card)
    local msg    = "나: " .. cardName(card) .. " 사용!"
    local action = "player_play"
    local skipAI = false
    -- 1% special event: playing green_8 when curse is "ready"
    if card == "green_8" then
        local curse = getChatVar(triggerId, "cv_draw_curse") or ""
        if curse == "ready" then
            setChatVar(triggerId, "cv_draw_curse", "end")
            action = "curse_green8"
            upsertLocalLoreBook(triggerId, "curse_event_active", CURSE_LORE,
                {key="curse_active", alwaysActive=true})
        end
    end
    if c == "any" then
        setChatVar(triggerId, "cv_current_color", cur)
        if v == "wild4" then
            local ah = d(getChatVar(triggerId, "cv_ai_hand") or "")
            drawCards(triggerId, ah, 4, true)
            msg = msg .. " 미쿠 +4!"
            if action ~= "curse_green8" then action = "player_wild4" end
        else
            if action ~= "curse_green8" then action = "player_wild" end
        end
        setChatVar(triggerId, "cv_message",     msg)
        setChatVar(triggerId, "cv_last_action", action)
        if #ph == 1 and unoCall == "0" then setChatVar(triggerId, "cv_uno_pending", "1") end
        setChatVar(triggerId, "cv_uno_call", "0")
        if checkWin(triggerId, "player", ph) then reloadDisplay(triggerId); return end
        setChatVar(triggerId, "cv_choose_color", "1")
        setChatVar(triggerId, "cv_turn",         "player")
        saveUI(triggerId); savePanel(triggerId); saveStatus(triggerId); reloadDisplay(triggerId)
        return
    else
        setChatVar(triggerId, "cv_current_color", c)
        if v == "skip" then
            if action ~= "curse_green8" then action = "player_skip" end
            msg = msg .. " 미쿠 스킵!"; skipAI = true
        elseif v == "reverse" then
            if action ~= "curse_green8" then action = "player_reverse" end
            msg = msg .. " (리버스=스킵)"; skipAI = true
        elseif v == "draw2" then
            local ah = d(getChatVar(triggerId, "cv_ai_hand") or "")
            drawCards(triggerId, ah, 2, true)
            msg = msg .. " 미쿠 +2!"
            if action ~= "curse_green8" then action = "player_draw2" end
        end
    end
    setChatVar(triggerId, "cv_message",     msg)
    setChatVar(triggerId, "cv_last_action", action)
    if #ph == 1 and unoCall == "0" then setChatVar(triggerId, "cv_uno_pending", "1") end
    setChatVar(triggerId, "cv_uno_call", "0")
    if checkWin(triggerId, "player", ph) then reloadDisplay(triggerId); return end
    if skipAI then
        setChatVar(triggerId, "cv_turn", "player")
        saveUI(triggerId); savePanel(triggerId); saveStatus(triggerId); reloadDisplay(triggerId)
    else
        setChatVar(triggerId, "cv_turn", "ai")
        saveUI(triggerId); processAI(triggerId)
    end
end

function drawCard(triggerId)
    if getPhase(triggerId) ~= "playing" then return end
    local turn = nvl(getChatVar(triggerId, "cv_turn"), "player")
    if turn ~= "player" then return end
    local choose = nvl(getChatVar(triggerId, "cv_choose_color"), "0")
    if choose == "1" then return end
    local ph = d(nvl(getChatVar(triggerId, "cv_player_hand"), ""))
    drawCards(triggerId, ph, 1, false)
    setChatVar(triggerId, "cv_player_hand", s(ph))
    setChatVar(triggerId, "cv_message",     "카드를 1장 뽑았습니다.")
    setChatVar(triggerId, "cv_last_action", "player_draw")
    setChatVar(triggerId, "cv_uno_call",    "0")
    setChatVar(triggerId, "cv_turn",        "ai")
    saveUI(triggerId); processAI(triggerId)
end

function callUno(triggerId)
    if getPhase(triggerId) ~= "playing" then return end
    setChatVar(triggerId, "cv_uno_call",    "1")
    setChatVar(triggerId, "cv_last_action", "player_uno")
    saveUI(triggerId); savePanel(triggerId); saveStatus(triggerId)
    reloadDisplay(triggerId)
end

function chooseColor(triggerId, color)
    if getPhase(triggerId) ~= "playing" then return end
    local choose = nvl(getChatVar(triggerId, "cv_choose_color"), "0")
    if choose ~= "1" then return end
    setChatVar(triggerId, "cv_current_color",  color)
    setChatVar(triggerId, "cv_choose_color",   "0")
    setChatVar(triggerId, "cv_last_action",    "color_chosen")
    setChatVar(triggerId, "cv_message",        colorKr(color) .. " 선택!")
    local ph = d(nvl(getChatVar(triggerId, "cv_player_hand"), ""))
    if checkWin(triggerId, "player", ph) then reloadDisplay(triggerId); return end
    setChatVar(triggerId, "cv_turn", "ai")
    saveUI(triggerId); processAI(triggerId)
end

function penaltyCall(triggerId)
    if getPhase(triggerId) ~= "playing" then return end
    local unoPending = nvl(getChatVar(triggerId, "cv_uno_pending"), "0")
    if unoPending ~= "1" then return end
    local ph = d(nvl(getChatVar(triggerId, "cv_player_hand"), ""))
    drawCards(triggerId, ph, 2, false)
    setChatVar(triggerId, "cv_player_hand",  s(ph))
    setChatVar(triggerId, "cv_uno_pending",  "0")
    setChatVar(triggerId, "cv_message",      "UNO 미선언 패널티! 카드 2장 드로우")
    setChatVar(triggerId, "cv_last_action",  "penalty")
    saveUI(triggerId); savePanel(triggerId); saveStatus(triggerId)
    reloadDisplay(triggerId)
end

-- ========== BUTTON CLICK ROUTER ==========
function onButtonClick(triggerId, btnValue)
    if     btnValue == "uno-draw"    then drawCard(triggerId)
    elseif btnValue == "uno-call"    then callUno(triggerId)
    elseif btnValue == "penalty-call"then penaltyCall(triggerId)
    elseif btnValue == "color-red"   then chooseColor(triggerId, "red")
    elseif btnValue == "color-yellow"then chooseColor(triggerId, "yellow")
    elseif btnValue == "color-green" then chooseColor(triggerId, "green")
    elseif btnValue == "color-blue"  then chooseColor(triggerId, "blue")
    elseif btnValue == "game-start"  then startGame(triggerId)
    else
        local idx = btnValue:match("^play%-(%d+)$")
        if idx then playCard(triggerId, tonumber(idx)) end
    end
end
