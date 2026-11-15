local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local UIS = game:GetService("UserInputService")
local VIM = game:GetService("VirtualInputManager")
local HttpService = game:GetService("HttpService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Workspace = game:GetService("Workspace")
local lp = Players.LocalPlayer

if getgenv and getgenv().__Kairo then
    pcall(getgenv().__Kairo)
    getgenv().__Kairo = nil
end

local cfg = {
    autoFight = false, style = "Smart", pauseWhenUnlocked = true, fightOutside = false, outsideRange = 40,
    punchRange = 3.8, comboPause = 0.6, speedScale = 1.0, jitter = 30, antiRepeat = 0.55, upperVsGuard = 2.5, heavyWhenTired = 0.4,
    staminaFloor = 24, resumeAt = 58, finisherReserve = 12, maxIdle = 3.0,
    dropGuardToPunch = false, punchWhileGuard = true,
    finisherOn = true, finisherStam = 14, finisherHead = 22, finisherBoost = 2.2, finisherSpeed = 0.8,

    defOn = true, defMode = "Adaptive", reactMs = 115, reactJitter = 35, blockChance = 94, holdPad = 140, guardIdle = true,
    respondRange = 7.0, slipDir = "Away", slipTime = 280,
    counterOn = true, counterChance = 70, counterDelay = 110, counterWindow = 1.0,

    moveOn = true, idealMin = 2.7, idealMax = 3.5, strafeOn = true, strafeMin = 0.9, strafeMax = 2.4, retreatLow = true,
    faceOn = true, faceSpeed = 10, faceDeadzone = 3, faceYOffset = 0.2, faceMaxSpeed = 380,

    humanOn = true, humanFocus = 0.5, humanPauseChance = 0.12, maxCps = 4.2, holdMin = 45, holdMax = 105,
    aimSway = 0.7, predictOn = true, safetyMargin = 0.12, breathScale = 0.8,

    learnOn = true, learnStrength = 0.65, explore = 14, defExplore = 12, aimZone = "Adaptive", chestOffset = -1.0,
    resetLearnPerFight = true, hitMove = true, hitMoveTime = 0.26, interruptChance = 10,
    windowPunch = true, rangeLearn = true, phaseLearn = true, lenLearn = true, counterLearn = true, strafeLearn = true,

    espOn = true, espBox = true, boxStyle = "Corners", espBars = true, espCard = true, espGuardInfo = true, espDistance = true,
    espValues = true, espHeadDot = true, espGhost = true, espHighlight = true, espPulse = true, espOffscreen = true,
    espColorStam = true, espColor = Color3.fromRGB(70, 220, 110), espScale = 1.0,
    rangeRing = false, tracer = false, incomingWarn = true, hudOn = true,
    espPlayers = true, espPlayerMode = "Closest N", espPlayerCount = 8, espPlayerRange = 300, espPlayerBars = true, espPlayerDist = true,

    fxOn = true, fxSparks = true, fxRings = true, fxNumbers = true, fxCombo = true, fxFlash = true, fxAura = true, fxAuraAlways = false,
    fxAuraStrength = 0.6, fxVignette = true, fxGlove = true, fxEmbers = true, fxShake = 0, fxQuality = "Medium",
    fxColor = Color3.fromRGB(154, 123, 255),

    gloveOn = false, gloveChoice = "", trunksOn = false, trunksChoice = "", skinCycle = false, cycleDelay = 4, skinRandomFight = false,

    noFatigue = false, infStamina = false, autoSpar = false, sparDelay = 4, getUpOn = true, getUpDelay = 80,
    antiAfk = false, fovOn = false, fov = 100, logPunches = false, notifyFight = true, notifyGassed = true,
}

local COMBOS = {
    { key = "w_jab",   name = "Single jab",     steps = { "jab" },                          w = 3 },
    { key = "w_dbl",   name = "Double jab",     steps = { "jab", "jab" },                   w = 3 },
    { key = "w_12",    name = "1-2",            steps = { "jab", "cross" },                 w = 5 },
    { key = "w_112",   name = "1-1-2",          steps = { "jab", "jab", "cross" },          w = 4 },
    { key = "w_123",   name = "1-2-3 (L hook)", steps = { "jab", "cross", "hookL" },        w = 4, heavy = true },
    { key = "w_1232",  name = "1-2-3-2",        steps = { "jab", "cross", "hookL", "cross" }, w = 2, heavy = true },
    { key = "w_12u",   name = "1-2-uppercut",   steps = { "jab", "cross", "upperL" },       w = 2, heavy = true, upper = true },
    { key = "w_hxc",   name = "Hook-cross",     steps = { "hookL", "cross" },               w = 2, heavy = true },
    { key = "w_hr",    name = "Right hook",     steps = { "hookR" },                        w = 1, heavy = true },
    { key = "w_over",  name = "Jab-overhand",   steps = { "jab", "over" },                  w = 1, heavy = true },
    { key = "w_dhook", name = "Double hook",    steps = { "hookL", "hookR" },               w = 1, heavy = true },
    { key = "w_uu",    name = "Uppercut pair",  steps = { "upperR", "upperL" },             w = 1, heavy = true, upper = true },
    { key = "w_jjh",   name = "Jab-jab-hook",   steps = { "jab", "jab", "hookL" },          w = 2, heavy = true },
    { key = "w_chk",   name = "Cross-hook",     steps = { "cross", "hookL" },               w = 2, heavy = true },
    { key = "w_jjj",   name = "Triple jab",     steps = { "jab", "jab", "jab" },            w = 1 },
}
for _, c in ipairs(COMBOS) do cfg[c.key] = c.w end

local DEFAULTS = {}
for k, v in pairs(cfg) do DEFAULTS[k] = v end
cfg.autoFight = false
local UIState = { open = false }
local FXS = { flashUntil = 0, punch = nil }
if getgenv then getgenv().__KairoCfg = cfg end

local conns, cleanups = {}, {}
local function track(c) conns[#conns + 1] = c; return c end
local function onCleanup(f) cleanups[#cleanups + 1] = f end

local container = (gethui and gethui()) or game:GetService("CoreGui")
local function mk(class, props, parent)
    local i = Instance.new(class)
    for k, v in pairs(props or {}) do i[k] = v end
    if parent then i.Parent = parent end
    return i
end

local gui = mk("ScreenGui", { Name = "Kairo", ResetOnSpawn = false, DisplayOrder = 999, IgnoreGuiInset = true,
    ZIndexBehavior = Enum.ZIndexBehavior.Sibling }, container)
local world = mk("Folder", { Name = "KairoWorld" }, container)
onCleanup(function() gui:Destroy(); world:Destroy() end)

local KB
pcall(function() KB = require(ReplicatedStorage:WaitForChild("VRBoxingKeybinds", 3)) end)

local function bindOf(id, default)
    if KB and KB.get then
        local ok, v = pcall(KB.get, id)
        if ok and type(v) == "string" and v ~= "" then return v end
    end
    return default
end

local held = {}
local function sendInput(s, down)
    local cam = Workspace.CurrentCamera
    if s:sub(1, 5) == "Mouse" then
        local b = (s == "MouseButton1" and 0) or (s == "MouseButton2" and 1) or 2
        local c = cam.ViewportSize / 2
        VIM:SendMouseButtonEvent(c.X, c.Y, b, down, game, 0)
    else
        local kc = Enum.KeyCode[s]
        if kc then VIM:SendKeyEvent(down, kc, false, game) end
    end
end
local function setHeld(s, on)
    if on and not held[s] then held[s] = true; sendInput(s, true)
    elseif not on and held[s] then held[s] = nil; sendInput(s, false) end
end
local function tap(s, dur)
    if held[s] then return end
    held[s] = true; sendInput(s, true)
    task.delay(dur or 0.06, function() if held[s] then held[s] = nil; sendInput(s, false) end end)
end
local function releaseAll()
    for s in pairs(held) do held[s] = nil; pcall(sendInput, s, false) end
end
onCleanup(releaseAll)

local function findTable(pred)
    for _, t in ipairs(getgc(true)) do
        if type(t) == "table" then
            local ok, r = pcall(pred, t)
            if ok and r then return t end
        end
    end
end

local G = { state = nil, me = nil, hands = {}, scanned = 0, scanning = false }
local function validate()
    if G.state and not rawget(G.state, "cardioK") then G.state = nil end
    if G.me and rawget(G.me, "cardioTxt") == nil and rawget(G.me, "stamina") == nil then G.me = nil end
    for s, h in pairs(G.hands) do if rawget(h, "live") == nil then G.hands[s] = nil end end
end
local function rescan(force)
    local now = os.clock()
    if G.scanning then return end
    if not force and now - G.scanned < 6 then return end
    G.scanned = now
    validate()
    local needState, needMe = not G.state, not G.me
    local needHands = not (G.hands.L and G.hands.R)
    if not (needState or needMe or needHands) then return end
    G.scanning = true
    task.spawn(function()
        local ok = pcall(function()
            local list = getgc(true)
            for i = 1, #list do
                local t = list[i]
                if type(t) == "table" then
                    if needState and rawget(t, "cardioK") and rawget(t, "fat") ~= nil then G.state = t; needState = false
                    elseif needMe and rawget(t, "cardioTxt") ~= nil then G.me = t; needMe = false
                    elseif needHands and rawget(t, "live") ~= nil and rawget(t, "ext") ~= nil and rawget(t, "kind") ~= nil then
                        local side = rawget(t, "side")
                        if (side == "L" or side == "R") and not G.hands[side] then G.hands[side] = t end
                    end
                end
                if i % 25000 == 0 then task.wait() end
            end
        end)
        G.scanning = false
    end)
end
rescan(true)

local function myStam()
    local m = G.me
    return m and tonumber(rawget(m, "stamina")) or 1
end
local function handReady(side)
    local h = G.hands[side]
    if not h then return true end
    return not rawget(h, "live") and not rawget(h, "loading") and (tonumber(rawget(h, "cool")) or 0) <= 0
end

local E = { model = nil, hrp = nil, head = nil, dist = 99, at = 0, attr = {}, attrAt = 0, fight = false, player = nil }
local function myRoot() local c = lp.Character; return c and c:FindFirstChild("HumanoidRootPart") end

local function pickOutside()
    local r = myRoot()
    if not r then return nil end
    local best, bd = nil, cfg.outsideRange
    for _, p in ipairs(Players:GetPlayers()) do
        local c = p ~= lp and p.Character
        local h = c and c:FindFirstChild("HumanoidRootPart")
        if h and p:GetAttribute("BoxKO") ~= true then
            local d = (h.Position - r.Position).Magnitude
            if d < bd then best, bd = c, d end
        end
    end
    return best
end
local function pickEnemy()
    local ring = lp:GetAttribute("InRing")
    if not ring then
        if cfg.fightOutside then return pickOutside() end
        return nil
    end
    for _, m in ipairs(Workspace:GetChildren()) do
        if m:IsA("Model") and m ~= lp.Character and m:GetAttribute("InRing") == ring and m:FindFirstChild("HumanoidRootPart") then
            return m
        end
    end
    for _, p in ipairs(Players:GetPlayers()) do
        if p ~= lp and p:GetAttribute("InRing") == ring and p.Character and p.Character:FindFirstChild("HumanoidRootPart") then
            return p.Character
        end
    end
end
local function updateEnemy()
    local now = os.clock()
    if now - E.at > 0.25 or not (E.model and E.model.Parent and E.hrp and E.hrp.Parent) then
        E.at = now
        E.model = pickEnemy()
        E.hrp = E.model and E.model:FindFirstChild("HumanoidRootPart")
        E.head = E.model and (E.model:FindFirstChild("Head") or E.hrp)
        E.player = E.model and Players:GetPlayerFromCharacter(E.model) or nil
        E.attrAt = 0
    end
    if E.model and now - E.attrAt > 0.05 then
        E.attrAt = now
        local a = E.model:GetAttributes()
        if E.player then
            for k, v in pairs(E.player:GetAttributes()) do if a[k] == nil then a[k] = v end end
        end
        E.attr = a
    elseif not E.model then
        E.attr = {}
    end
    local r = myRoot()
    if E.model and E.hrp and r then
        local d = E.hrp.Position - r.Position
        E.dist = Vector3.new(d.X, 0, d.Z).Magnitude
    else
        E.dist = 99
    end
    E.fight = E.model ~= nil and E.hrp ~= nil and (lp:GetAttribute("InRing") ~= nil or cfg.fightOutside)
        and lp:GetAttribute("BoxKO") ~= true and E.attr.BoxKO ~= true
end
local function enemyAttr(name, default)
    local v = E.attr[name]
    if v == nil then return default end
    return v
end

local gassedSeen = 0
local lastGassedVal
local function enemyStam() return tonumber(enemyAttr("Stam", nil)) end
local function enemyGassed()
    local s = enemyStam()
    local gv = enemyAttr("GassedUntil", nil)
    if gv ~= lastGassedVal then lastGassedVal = gv; if gv then gassedSeen = os.clock() end end
    if os.clock() - gassedSeen < 2.5 then return true end
    return s ~= nil and s * 100 <= cfg.finisherStam
end
local function enemyHeadPct()
    local hp, mx = tonumber(enemyAttr("HeadHP", nil)), tonumber(enemyAttr("MaxHP", nil))
    if hp and mx and mx > 0 then return hp / mx end
end
local function fighting()
    return E.fight
end

local P = { gaps = {}, kinds = {}, lastStart = 0 }
function P.record(t0, kind)
    if P.lastStart > 0 then
        local g = t0 - P.lastStart
        if g > 0.08 and g < 3.5 then
            table.insert(P.gaps, g)
            if #P.gaps > 20 then table.remove(P.gaps, 1) end
        end
    end
    P.lastStart = t0
    P.kinds[kind] = (P.kinds[kind] or 0) + 1
end
function P.median()
    if #P.gaps < 4 then return nil end
    local c = table.clone(P.gaps)
    table.sort(c)
    return c[math.ceil(#c / 2)]
end
function P.reset() P.gaps = {}; P.kinds = {}; P.lastStart = 0 end

local Atk = { kind = nil, hand = nil, t0 = 0, eta = 0, untilT = 0, endedAt = -9, interrupted = false }
local KIND_ETA = { straight = 0.32, hook = 0.45, upper = 0.45, over = 0.5 }
local net = ReplicatedStorage:FindFirstChild("VRBoxingNet")
local defence
if net and net:FindFirstChild("PunchStart") then
    track(net.PunchStart.OnClientEvent:Connect(function(who, hand, kind, flag, t)
        if who ~= E.model or flag == true then return end
        local eta = KIND_ETA[tostring(kind)] or 0.4
        if typeof(t) == "number" and t > 0.05 and t < 1.5 then eta = t end
        Atk.kind, Atk.hand, Atk.t0, Atk.eta = tostring(kind), hand, os.clock(), eta
        Atk.untilT = os.clock() + eta + 0.15
        Atk.interrupted = false
        P.record(Atk.t0, Atk.kind)
        if defence then defence(Atk) end
    end))
end

local ACT = {
    jab    = { id = "StraightL", def = "MouseButton1", side = "L", delay = 0.30, cost = 5 },
    cross  = { id = "StraightR", def = "MouseButton2", side = "R", delay = 0.40, cost = 6 },
    hookL  = { id = "HookL",     def = "E",            side = "L", delay = 0.50, cost = 11 },
    hookR  = { id = "HookR",     def = "R",            side = "R", delay = 0.55, cost = 11 },
    upperL = { id = "UpperL",    def = "C",            side = "L", delay = 0.55, cost = 12 },
    upperR = { id = "UpperR",    def = "V",            side = "R", delay = 0.60, cost = 12 },
    over   = { id = "Overhand",  def = "X",            side = "R", delay = 0.65, cost = 14 },
}
local HIGH_GUARDS = { high = true, peekaboo = true, philly = true, crossarm = true, bulldog = true, ropeadope = true, hitman = true }
local DEF_MODES = { "Guard", "Slip", "Pull", "Backstep" }

local Bot = { state = "idle", combo = nil, comboName = "-", nextComboAt = 0, recovering = false,
              guardUntil = 0, slipUntil = 0, counterAt = nil, strafeDir = 0, strafeUntil = 0, lastCombo = nil,
              punches = 0, zone = "head", backUntil = 0, noGuardUntil = 0, enemyKey = nil, windowAt = nil, pendSlip = nil, coInit = false, lastCO = nil, lastFire = {}, lastModel = nil, pauseUntil = 0, winLeft = nil, lastAtk = 0,
              hpPrev = nil, dmgAcc = 0, segAt = 0 }
local function rnd(a, b) return a + math.random() * (b - a) end
local function gauss()
    local u1, u2 = math.max(1e-6, math.random()), math.random()
    return math.sqrt(-2 * math.log(u1)) * math.cos(2 * math.pi * u2)
end

local function jit(x)
    local s = cfg.jitter / 100
    if cfg.humanOn then return x * math.clamp(1 + gauss() * s * 0.5, 1 - s, 1 + s * 1.6) end
    return x * (1 + (math.random() * 2 - 1) * s)
end

local function focus()
    if not (cfg.humanOn and cfg.humanFocus > 0) then return 1 end
    local n = math.noise(os.clock() * 0.06, 7.31) * 0.5 + 0.5
    return 1 - cfg.humanFocus * 0.35 * (1 - n)
end
local function humanReact(eta)
    local base = cfg.reactMs / 1000
    local r = cfg.humanOn and (base * math.exp(gauss() * (cfg.reactJitter / 100) * 0.6) + (1 - focus()) * 0.12)
        or math.max(0, base + (math.random() * 2 - 1) * cfg.reactJitter / 1000)
    return math.clamp(r, 0.03, eta * 0.75)
end
local cpsLog = {}
local function cpsOK(now)
    for i = #cpsLog, 1, -1 do if now - cpsLog[i] > 1 then table.remove(cpsLog, i) end end
    return #cpsLog < cfg.maxCps
end

local L
local function resetLearning()
    L = { combo = {}, zone = { head = 0.32, chest = 0.3 }, zoneN = { head = 0, chest = 0 }, def = {}, kind = {}, strafe = {},
          phase = { busy = 0.3, s0 = 0.3, s1 = 0.3, s2 = 0.3, s3 = 0.3 }, phaseN = {}, dist = { [2.5] = 0.25, [3.0] = 0.3, [3.5] = 0.3 }, distN = {},
          idx = {}, idxN = {}, cd = { [0.12] = 0.3, [0.4] = 0.3, [0.8] = 0.3 }, cdN = {},
          tot = { n = 0, hit = 0, blocked = 0, dodged = 0, miss = 0 }, dtot = { n = 0, hit = 0, defended = 0, avoided = 0, countered = 0 },
          sd = {}, wp = { cross = 0.4, hookR = 0.3, hookL = 0.3 }, cnt = 0, wpN = 0 }
end
resetLearning()
local function ema(old, new, a) return old * (1 - a) + new * a end
local SCORE = { hit = 1, blocked = 0.2, dodged = 0.1, miss = 0 }
local function phaseBucket(busy, since)
    if busy then return "busy" end
    since = since or 9
    if since < 0.3 then return "s0" elseif since < 0.7 then return "s1" elseif since < 1.5 then return "s2" end
    return "s3"
end
local function recordPunch(pend, class, kind)
    if FXS.punch then FXS.punch(class) end
    L.tot.n += 1; L.tot[class] += 1
    if kind then
        L.kind[kind] = L.kind[kind] or { n = 0, hit = 0 }
        L.kind[kind].n += 1
        if class == "hit" then L.kind[kind].hit += 1 end
    end
    if not pend then return end
    local s = SCORE[class]
    if pend.key then L.combo[pend.key] = ema(L.combo[pend.key] or 0.3, s, 0.15) end
    if pend.key == "window" and pend.step then
        L.wp[pend.step] = ema(L.wp[pend.step] or 0.3, s, 0.2)
        L.wpN = L.wpN + 1
    end
    if pend.key ~= "counter" and pend.key ~= "window" then
        local pb = phaseBucket(pend.busy, pend.since)
        L.phase[pb] = ema(L.phase[pb], s, 0.12)
        L.phaseN[pb] = (L.phaseN[pb] or 0) + 1
    end
    if pend.dist then
        local db = math.clamp(math.floor(pend.dist * 2 + 0.5) / 2, 2.5, 3.5)
        L.dist[db] = ema(L.dist[db], s, 0.12)
        L.distN[db] = (L.distN[db] or 0) + 1
    end
    if pend.idx and pend.idx > 0 then
        L.idx[pend.idx] = ema(L.idx[pend.idx] or 0.3, s, 0.15)
        L.idxN[pend.idx] = (L.idxN[pend.idx] or 0) + 1
    end
    if pend.cd then
        L.cd[pend.cd] = ema(L.cd[pend.cd], s, 0.2)
        L.cdN[pend.cd] = (L.cdN[pend.cd] or 0) + 1
    end
    if pend.zone then
        L.zone[pend.zone] = ema(L.zone[pend.zone], s, 0.1)
        L.zoneN[pend.zone] += 1
    end
end
local function classify(h)
    local r = rawget(h, "lastResult")
    if type(r) == "string" then
        if r:find("^head") or r:find("^body") then return "hit" end
        if r:find("dodg") or r == "slip" then return "dodged" end
        return "blocked"
    end
    return rawget(h, "landed") and "blocked" or "miss"
end
local Tr = { L = { live = false }, R = { live = false } }
local function trackPunches()
    for side, tr in pairs(Tr) do
        local h = G.hands[side]
        if h then
            local live = rawget(h, "live") == true
            if live and not tr.live then
                tr.live = true; tr.pend = Bot.lastFire[side]; Bot.lastFire[side] = nil
                tr.kind = rawget(h, "kind")
            elseif tr.live and not live then
                tr.live = false
                recordPunch(tr.pend, classify(h), tr.kind)
                tr.pend = nil
            end
        end
    end
end

local function pickZone()
    local m = cfg.aimZone
    if m == "Head" then return "head" elseif m == "Body" then return "chest" end
    if math.random() * 100 < cfg.explore then return math.random() < 0.5 and "head" or "chest" end
    return (L.zone.chest > L.zone.head) and "chest" or "head"
end
local function zoneOffset() return Bot.zone == "chest" and cfg.chestOffset or cfg.faceYOffset end

local function lenCap()
    local cap = 4
    if cfg.lenLearn and cfg.learnOn and L.idx[1] then
        for i = 2, 4 do
            if (L.idxN[i] or 0) >= 6 and (L.idx[i] or 0) < 0.55 * L.idx[1] then cap = i - 1 break end
        end
    end
    return cap
end

local COUNTER_DELAYS = { 0.12, 0.4, 0.8 }
local function chooseCounterDelay()
    if math.random() < 0.15 then return COUNTER_DELAYS[math.random(1, #COUNTER_DELAYS)] end
    local best, bs = COUNTER_DELAYS[1], -1
    for _, d in ipairs(COUNTER_DELAYS) do
        if L.cd[d] > bs then best, bs = d, L.cd[d] end
    end
    return best
end

local RANGE_CENTERS = { 2.5, 3.0, 3.5 }
local rangeC, rangeAt = 3.0, 0
local function rangeBand(now)
    if not cfg.rangeLearn then return cfg.idealMin, cfg.idealMax end
    if now - rangeAt > 3 then
        rangeAt = now
        if math.random() < 0.15 then
            rangeC = RANGE_CENTERS[math.random(1, #RANGE_CENTERS)]
        else
            local best, bs = rangeC, -1
            for _, d in ipairs(RANGE_CENTERS) do
                if L.dist[d] > bs then best, bs = d, L.dist[d] end
            end
            rangeC = best
        end
    end
    return rangeC - 0.28, rangeC + 0.28
end

local function pickCombo()
    local cap = lenCap()
    local finisher = cfg.finisherOn and (enemyGassed() or (enemyHeadPct() or 1) * 100 <= cfg.finisherHead)
    local guard = tostring(enemyAttr("AIGuard", ""))
    local tired = myStam() < 0.5
    local total, weights = 0, {}
    for i, c in ipairs(COMBOS) do
        local w = tonumber(cfg[c.key]) or 0
        if c.heavy and finisher then w = w * cfg.finisherBoost end
        if c.heavy and tired and not finisher then w = w * cfg.heavyWhenTired end
        if c.upper and HIGH_GUARDS[guard] then w = w * cfg.upperVsGuard end
        if Bot.lastCombo == c.key then w = w * (1 - cfg.antiRepeat) end
        if #c.steps > cap and not finisher then w = w * 0.08 end
        if Bot.winLeft and not finisher then
            local dur = 0.12
            for si = 1, #c.steps - 1 do dur = dur + ACT[c.steps[si]].delay * cfg.speedScale end
            if dur > Bot.winLeft then w = w * 0.12 end
        end
        if cfg.learnOn and L.combo[c.key] then
            local r = math.clamp(L.combo[c.key] / 0.3, 0.3, 2.6)
            w = w * math.max(0.05, 1 + cfg.learnStrength * (r - 1))
        end
        weights[i] = w; total = total + w
    end
    if total <= 0 then return nil end
    local r = math.random() * total
    for i, c in ipairs(COMBOS) do
        r = r - weights[i]
        if r <= 0 then return c, finisher end
    end
    return COMBOS[#COMBOS], finisher
end

local function guardHeld() return Bot.guardUntil > os.clock() end
local function canPunchNow()
    if guardHeld() and not cfg.punchWhileGuard then return false end
    if Bot.slipUntil > os.clock() then return false end
    return true
end

local function startCombo()
    local c, fin = pickCombo()
    if not c then return end
    Bot.zone = pickZone()
    Bot.combo = { steps = c.steps, i = 1, nextAt = 0, deadline = os.clock() + 0.9, fin = fin, key = c.key, zone = Bot.zone }
    Bot.comboName = c.name .. (Bot.zone == "chest" and " [body]" or "")
    Bot.lastCombo = c.key
end

local function fire(def, cb)
    if cfg.dropGuardToPunch then setHeld(bindOf("Guard", "F"), false); setHeld(bindOf("GuardAlt", "LeftShift"), false) end
    local fnow = os.clock()
    Bot.lastFire[def.side] = { key = cb and cb.key, zone = cb and cb.zone, act = def.id, t = fnow, phase = fnow - Atk.t0, busy = Atk.untilT > fnow, dist = E.dist,
        idx = cb and cb.i or 0, step = cb and cb.steps[cb.i], guardUp = held[bindOf("Guard", "F")] == true, since = fnow - (Atk.endedAt or -9), cd = cb and cb.cd }
    tap(bindOf(def.id, def.def), cfg.humanOn and rnd(cfg.holdMin, cfg.holdMax) / 1000 or 0.06)
    cpsLog[#cpsLog + 1] = os.clock()
    Bot.lastAtk = os.clock()
    Bot.punches = Bot.punches + 1
end

local function stepCombo(now)
    local cb = Bot.combo
    if not cb or now < cb.nextAt then return end
    if not canPunchNow() then cb.deadline = cb.deadline + 0.02; return end
    local def = ACT[cb.steps[cb.i]]
    if not handReady(def.side) then
        if now > cb.deadline then Bot.combo = nil; Bot.nextComboAt = now + 0.2 end
        return
    end
    if E.dist > cfg.punchRange + 0.6 then Bot.combo = nil; Bot.nextComboAt = now + 0.15; return end
    local after = myStam() * 100 - def.cost
    if (not cb.fin and after < cfg.staminaFloor) or (cb.fin and after < cfg.finisherReserve) then Bot.combo = nil; Bot.nextComboAt = now + 0.3; return end
    if not cpsOK(now) then cb.deadline = cb.deadline + 0.03; return end
    fire(def, cb)
    cb.i = cb.i + 1
    local speed = cfg.speedScale * (cb.fin and cfg.finisherSpeed or 1)
    if cb.i > #cb.steps then
        Bot.combo = nil
        Bot.nextComboAt = now + jit(cfg.comboPause) * (cb.fin and cfg.finisherSpeed or 1) + (cb.fin and 0 or (1 - myStam()) * cfg.breathScale)
        if cfg.hitMove and not cb.fin and cb.key ~= "interrupt" then Bot.backUntil = now + cfg.hitMoveTime end
    else
        cb.nextAt = now + jit(def.delay) * speed
        cb.deadline = cb.nextAt + 0.8
    end
end

local pendDef = {}
local function myHP() return (tonumber(lp:GetAttribute("HeadHP")) or 0) + (tonumber(lp:GetAttribute("BodyHP")) or 0) end
local function newDefPrior(kind)
    return { Guard = 0.5, Slip = 0.5, Pull = 0.5, Backstep = 0.5 }
end
local WINDOW_PUNCHES = { "cross", "hookR", "hookL" }
local function pickWindowPunch()
    if math.random() < 0.2 then return WINDOW_PUNCHES[math.random(1, #WINDOW_PUNCHES)] end
    local best, bs = "cross", -1
    for _, k in ipairs(WINDOW_PUNCHES) do
        local v = L.wp[k] or 0.3
        if v > bs then best, bs = k, v end
    end
    return best
end
local function chooseSlipKey(hand)
    local base = (hand == 1) == (cfg.slipDir == "Away") and "A" or "D"
    local other = base == "A" and "D" or "A"
    local kb, ko = tostring(hand) .. "|" .. base, tostring(hand) .. "|" .. other
    L.sd[kb] = L.sd[kb] or 0.5
    L.sd[ko] = L.sd[ko] or 0.5
    if math.random() < 0.15 then return other end
    return L.sd[ko] > L.sd[kb] and other or base
end
local function checkCounterWindow(now)
    local st = G.state
    if not st then return end
    local co = rawget(st, "counterOpenAt")
    if not Bot.coInit then
        Bot.coInit, Bot.lastCO = true, co
        return
    end
    if Bot.pendSlip and now - Bot.pendSlip.t > 1.4 then
        local ps = Bot.pendSlip
        if ps.key then
            local k = tostring(ps.hand) .. "|" .. ps.key
            L.sd[k] = ema(L.sd[k] or 0.5, 0, 0.25)
        end
        Bot.pendSlip = nil
    end
    if type(co) ~= "number" or co == Bot.lastCO then return end
    Bot.lastCO = co
    L.cnt = L.cnt + 1
    if cfg.windowPunch then Bot.windowAt = now end
    local ps = Bot.pendSlip
    if ps and now - ps.t < 1.4 then
        if ps.key then
            local k = tostring(ps.hand) .. "|" .. ps.key
            L.sd[k] = ema(L.sd[k] or 0.5, 1, 0.25)
        end
        Bot.pendSlip = nil
    end
    for _, p in ipairs(pendDef) do p.counter = true end
end
local function chooseDefMode(kind)
    local m = cfg.defMode
    if m == "Smart" then return (kind == "hook" or kind == "over") and "Slip" or "Guard" end
    if m ~= "Adaptive" then return m end
    L.def[kind] = L.def[kind] or newDefPrior(kind)
    if math.random() * 100 < cfg.defExplore then return DEF_MODES[math.random(1, #DEF_MODES)] end
    local best, bs = "Guard", -1
    for _, md in ipairs(DEF_MODES) do if L.def[kind][md] > bs then best, bs = md, L.def[kind][md] end end
    return best
end
local function settleDefence(now)
    for i = #pendDef, 1, -1 do
        local p = pendDef[i]
        if now >= p.at then
            table.remove(pendDef, i)
            local s, tag
            local lost = math.max(0, p.hp0 - myHP())
            if p.counter then
                tag = "countered"
                s = 1
            elseif (lp:GetAttribute("RingDefended") or 0) > p.def0 then
                tag = "defended"
                s = lost <= 1 and 0.9 or math.clamp(0.75 - lost / 14, 0.2, 0.7)
            elseif lost > 3 then
                tag = "hit"
                s = math.clamp(0.3 - lost / 30, 0, 0.25)
            else
                tag = "avoided"
                s = 1
            end
            L.dtot.n += 1; L.dtot[tag] += 1
            if tag == "hit" then
                local d = L.dtot
                d.hitUp = (d.hitUp or 0) + (p.up and 1 or 0)
                d.hitPunching = (d.hitPunching or 0) + (p.punching and 1 or 0)
                d.byKind = d.byKind or {}
                d.byKind[p.kind] = (d.byKind[p.kind] or 0) + 1
            end
            L.def[p.kind] = L.def[p.kind] or newDefPrior(p.kind)
            L.def[p.kind][p.mode] = ema(L.def[p.kind][p.mode], s, 0.2)
        end
    end
end

defence = function(a)
    if not (cfg.autoFight and cfg.defOn and fighting()) then return end
    if E.dist > cfg.respondRange then return end
    if math.random() * 100 > cfg.blockChance * (cfg.humanOn and (0.94 + 0.06 * focus()) or 1) then return end
    local mode = chooseDefMode(a.kind)
    pendDef[#pendDef + 1] = { kind = a.kind, mode = mode, hp0 = myHP(), def0 = lp:GetAttribute("RingDefended") or 0, at = a.t0 + a.eta + 0.4,
        up = held[bindOf("Guard", "F")] == true, punching = Bot.combo ~= nil, eta = a.eta }
    local react = humanReact(a.eta)
    if mode == "Slip" or mode == "Pull" then
        react = math.max(react, a.eta - cfg.slipTime / 1000 * 0.55)
    elseif mode == "Backstep" then
        react = math.max(react, a.eta - 0.2)
    end
    local gKey = bindOf("Guard", "F")
    task.delay(react, function()
        if not cfg.autoFight then return end
        local now = os.clock()
        local dur = math.max(0.12, (a.t0 + a.eta + cfg.holdPad / 1000) - now)
        if mode == "Guard" then
            Bot.guardUntil = math.max(Bot.guardUntil, now + dur)
            setHeld(gKey, true)
            Bot.combo = cfg.punchWhileGuard and Bot.combo or nil
        elseif mode == "Slip" or mode == "Pull" then
            local st = cfg.slipTime / 1000
            Bot.slipUntil = now + st
            Bot.noGuardUntil = now + st
            Bot.guardUntil = 0
            setHeld(gKey, false)
            local dirKey = mode == "Pull" and "S" or chooseSlipKey(a.hand)
            if mode == "Slip" and cfg.slipDir == "Random" then dirKey = math.random() < 0.5 and "A" or "D" end
            local head = bindOf("Head", "Space")
            setHeld(head, true); setHeld(dirKey, true)
            task.delay(st, function() setHeld(dirKey, false); setHeld(head, false) end)
            Bot.pendSlip = { t = now, key = mode == "Slip" and dirKey or nil, hand = a.hand, mode = mode }
            Bot.combo = nil
        elseif mode == "Backstep" then
            Bot.slipUntil = now + 0.3
            setHeld("S", true); task.delay(0.3, function() setHeld("S", false) end)
            Bot.combo = nil
        end
        if cfg.counterOn and math.random() * 100 <= cfg.counterChance then
            local cd = cfg.counterLearn and chooseCounterDelay() or cfg.counterDelay / 1000
            Bot.counterAt = a.t0 + a.eta + cd
            Bot.counterCd = cfg.counterLearn and cd or nil
        end
    end)
end

local function updateMovement(now, dt)
    local wantW, wantS, wantA, wantD = false, false, false, false
    if cfg.moveOn and fighting() and Bot.slipUntil < now then
        local lo, hi = rangeBand(now)
        local retreat = Bot.recovering and cfg.retreatLow
        local backing = Bot.backUntil > now and E.dist < hi + 0.8
        if retreat then
            if E.dist < hi + 2 then wantS = true end
        elseif backing then
            wantS = true
        else
            if E.dist > hi then wantW = true elseif E.dist < lo then wantS = true end
        end
        if cfg.strafeOn and not retreat and not backing and not guardHeld() then
            if now > Bot.strafeUntil then

                local dur = now - Bot.segAt
                if Bot.strafeDir ~= 0 and dur > 0.3 and cfg.strafeLearn then
                    L.strafe[Bot.strafeDir] = ema(L.strafe[Bot.strafeDir] or 4, Bot.dmgAcc / dur, 0.25)
                end
                Bot.dmgAcc, Bot.segAt = 0, now
                local nd
                if cfg.strafeLearn and L.strafe[-1] and L.strafe[1] and math.random() > 0.2 then
                    nd = (L.strafe[-1] <= L.strafe[1]) and -1 or 1
                    if math.random() < 0.25 then nd = 0 end
                else
                    nd = ({ -1, 0, 1 })[math.random(1, 3)]
                end
                if nd ~= 0 and nd == -Bot.strafeDir and math.random() < 0.6 then nd = Bot.strafeDir end
                Bot.strafeDir = nd
                Bot.strafeUntil = now + rnd(cfg.strafeMin, cfg.strafeMax)
            end
            wantA, wantD = Bot.strafeDir == -1, Bot.strafeDir == 1
        end
    end
    if Bot.slipUntil < now then
        setHeld("W", wantW); setHeld("S", wantS); setHeld("A", wantA); setHeld("D", wantD)
    end
end

local lastSpar = 0
local function botStep(dt)
    local now = os.clock()
    rescan(false)
    trackPunches()
    checkCounterWindow(now)
    settleDefence(now)
    local hpNow = myHP()
    if Bot.hpPrev and hpNow < Bot.hpPrev - 1 then Bot.dmgAcc = Bot.dmgAcc + (Bot.hpPrev - hpNow) end
    Bot.hpPrev = hpNow
    if E.model ~= Bot.lastModel then
        Bot.lastModel = E.model
        Bot.combo = nil; Bot.counterAt = nil; table.clear(pendDef)
    end
    if E.model and E.attr.DisplayName then
        local key = tostring(E.attr.DisplayName) .. "|" .. tostring(lp:GetAttribute("InRing"))
        if key ~= Bot.enemyKey then
            Bot.enemyKey = key
            P.reset()
            if cfg.resetLearnPerFight then resetLearning() end
        end
    end
    if not cfg.autoFight then
        if next(held) then releaseAll() end
        Bot.state = "off"; return
    end

    if not lp:GetAttribute("InRing") and not cfg.fightOutside then
        Bot.state = "waiting"
        if next(held) then releaseAll() end
        if cfg.autoSpar and now - lastSpar > cfg.sparDelay and UIS.MouseBehavior == Enum.MouseBehavior.LockCenter then
            lastSpar = now; tap(bindOf("PlayCPU", "P"), 0.08)
        end
        return
    end
    if not fighting() then Bot.state = "no target"; releaseAll(); return end
    if cfg.pauseWhenUnlocked and UIS.MouseBehavior ~= Enum.MouseBehavior.LockCenter then
        Bot.state = "paused"; releaseAll(); return
    end

    local st = myStam() * 100
    local fin = cfg.finisherOn and enemyGassed()
    if (st < cfg.staminaFloor and not fin) or st < cfg.finisherReserve then Bot.recovering = true
    elseif st >= cfg.resumeAt then Bot.recovering = false end

    updateMovement(now, dt)

    local gKey = bindOf("Guard", "F")
    if Bot.noGuardUntil > now then setHeld(gKey, false)
    elseif not guardHeld() and not cfg.guardIdle then setHeld(gKey, false)
    elseif cfg.guardIdle and not guardHeld() then setHeld(gKey, not (Bot.combo ~= nil and cfg.dropGuardToPunch)) end

    if Bot.counterAt and now >= Bot.counterAt and not Bot.recovering then
        Bot.counterAt = nil
        if E.dist <= cfg.punchRange + 0.6 and handReady("L") then
            Bot.zone = pickZone()
            local steps = lenCap() >= 2 and { "jab", "cross" } or { "jab" }
            Bot.combo = { steps = steps, i = 1, nextAt = 0, deadline = now + 0.8, fin = false, key = "counter", zone = Bot.zone, cd = Bot.counterCd }
            Bot.comboName = #steps > 1 and "Counter 1-2" or "Counter jab"
            Bot.guardUntil = 0
        end
    end

    if Bot.windowAt then
        if now - Bot.windowAt >= 0.85 then
            Bot.windowAt = nil
        elseif not Bot.combo and E.dist <= cfg.punchRange + 0.8 and not Bot.recovering then
            local step = pickWindowPunch()
            if handReady(ACT[step].side) then
                Bot.zone = pickZone()
                Bot.combo = { steps = { step }, i = 1, nextAt = 0, deadline = now + 0.6, fin = true, key = "window", zone = Bot.zone }
                Bot.comboName = "Counter window"
                Bot.windowAt = nil
            end
        end
    end

    local enemyBusy = Atk.untilT > now
    local style = cfg.style
    local allow = true
    Bot.winLeft = nil
    if Bot.recovering then allow = false
    elseif style == "Counter" then allow = fin or (now - Atk.endedAt) < cfg.counterWindow and not enemyBusy
    elseif style == "Balanced" then allow = not enemyBusy
    elseif style == "Smart" then
        allow = fin or not enemyBusy or (E.dist > cfg.punchRange)
        if allow and not fin and cfg.predictOn and not enemyBusy then
            local med = P.median()
            if med then
                local left = (P.lastStart + med) - now - cfg.safetyMargin
                if left <= 0 then left = 0.4 end
                Bot.winLeft = left
            end
        end
    end
    if Atk.untilT > 0 and not enemyBusy and Atk.endedAt < Atk.untilT then Atk.endedAt = Atk.untilT end

    if not allow and not Bot.recovering and cfg.maxIdle > 0 and now - Bot.lastAtk > cfg.maxIdle and E.dist <= cfg.punchRange then
        allow = true; Bot.winLeft = 0.3
    end
    if allow and cfg.humanOn and not fin then
        if now < Bot.pauseUntil then allow = false
        elseif cfg.humanPauseChance > 0 and math.random() < cfg.humanPauseChance * dt then
            Bot.pauseUntil = now + rnd(0.35, 1.0)
            allow = false
        end
    end

    if not Bot.combo and enemyBusy and not allow and cfg.interruptChance > 0 and not Atk.interrupted and not Bot.recovering
        and (Atk.t0 + Atk.eta - now) > 0.3 and E.dist <= cfg.punchRange and canPunchNow() and handReady("L") then
        Atk.interrupted = true
        if math.random() * 100 < cfg.interruptChance then
            Bot.zone = pickZone()
            Bot.combo = { steps = { "jab" }, i = 1, nextAt = 0, deadline = now + 0.4, fin = false, key = "interrupt", zone = Bot.zone }
            Bot.comboName = "Interrupt jab"
        end
    end

    if not Bot.combo and allow and cfg.phaseLearn and cfg.learnOn and not fin and now - Bot.lastAtk < cfg.maxIdle then
        local pb = phaseBucket(enemyBusy, now - (Atk.endedAt or -9))
        local best = 0.05
        for _, v in pairs(L.phase) do best = math.max(best, v) end
        local p = math.clamp((L.phase[pb] + 0.05) / (best + 0.05), 0.2, 1)
        p = 1 - cfg.learnStrength * (1 - p)
        if math.random() > p then
            Bot.nextComboAt = now + 0.18
            allow = false
        end
    end
    if not Bot.combo and allow and now >= Bot.nextComboAt and E.dist <= cfg.punchRange and canPunchNow() then
        startCombo()
    end
    stepCombo(now)

    Bot.state = Bot.recovering and "recovering" or (guardHeld() and "guarding") or (Bot.combo and (Bot.combo.fin and "FINISHER" or "attacking")) or "positioning"
end
track(RunService.Heartbeat:Connect(function(dt) local ok, e = pcall(botStep, dt); if not ok then Bot.state = "err"; Bot.err = tostring(e) end end))

pcall(function() RunService:UnbindFromRenderStep("KairoFace") end)
RunService:BindToRenderStep("KairoFace", Enum.RenderPriority.Camera.Value + 2, function(dt)
    if not (cfg.autoFight and cfg.faceOn and fighting()) then return end
    if UIS.MouseBehavior ~= Enum.MouseBehavior.LockCenter then return end
    local cam = Workspace.CurrentCamera
    local tgt = (E.head and E.head.Position or E.hrp.Position) + Vector3.new(0, zoneOffset(), 0)
    if cfg.humanOn and cfg.aimSway > 0 then
        local t = os.clock()
        tgt = tgt + Vector3.new(math.noise(t * 0.9, 1.3), math.noise(t * 0.7, 4.1) * 0.6, math.noise(t * 0.8, 8.7)) * (cfg.aimSway * 0.0175 * 2 * math.max(E.dist, 1))
    end
    local want = CFrame.lookAt(cam.CFrame.Position, tgt)
    local ang = math.deg(cam.CFrame.LookVector:Angle(want.LookVector))
    if ang < cfg.faceDeadzone then return end
    local a = 1 - math.exp(-cfg.faceSpeed * dt)
    if cfg.humanOn then a = math.min(a, (cfg.faceMaxSpeed * dt) / math.max(ang, 0.01)) end
    cam.CFrame = cam.CFrame:Lerp(want, a)
end)
onCleanup(function() pcall(function() RunService:UnbindFromRenderStep("KairoFace") end) end)

local function learnSummary()
    local t = L.tot
    local lines = {}
    lines[#lines + 1] = string.format("punches %d  hit %d  blocked %d  dodged %d  miss %d  (hit rate %s)", t.n, t.hit, t.blocked, t.dodged, t.miss, t.n > 0 and string.format("%d%%", t.hit / t.n * 100) or "-")
    lines[#lines + 1] = string.format("aim: head %.0f%% (%d)  body %.0f%% (%d)  -> %s", L.zone.head * 100, L.zoneN.head, L.zone.chest * 100, L.zoneN.chest, (L.zone.chest > L.zone.head) and "body" or "head")
    local bestK, bestS = "-", -1
    for _, c in ipairs(COMBOS) do local s = L.combo[c.key]; if s and s > bestS then bestK, bestS = c.name, s end end
    lines[#lines + 1] = string.format("best combo: %s (%.0f%%)", bestK, math.max(0, bestS) * 100)
    local bestP, bpv = "-", -1
    for k, v in pairs(L.phase) do if (L.phaseN[k] or 0) >= 4 and v > bpv then bestP, bpv = k, v end end
    local names = { busy = "while they punch", s0 = "right after their punch", s1 = "0.3-0.7s after", s2 = "0.7-1.5s after", s3 = "1.5s+ after" }
    lines[#lines + 1] = string.format("best moment: %s  |  best range: %.1f  |  combo cap: %d punches", names[bestP] or "learning", rangeC, lenCap())
    lines[#lines + 1] = string.format("counter windows opened: %d  |  punches thrown inside them: %d", L.cnt, L.wpN)
    local d = L.dtot
    lines[#lines + 1] = string.format("defence: %d seen  defended %d  avoided %d  got hit %d", d.n, d.defended, d.avoided, d.hit)
    for kind, tbl in pairs(L.def) do
        lines[#lines + 1] = string.format("defence vs %s: guard %.0f%%  slip %.0f%%  pull %.0f%%  back %.0f%%", kind, tbl.Guard * 100, tbl.Slip * 100, tbl.Pull * 100, tbl.Backstep * 100)
    end
    if d.hit > 0 then
        local ks = {}
        for k, v in pairs(d.byKind or {}) do ks[#ks + 1] = k .. " " .. v end
        lines[#lines + 1] = string.format("hits taken: guard up %d / down %d, while punching %d  (%s)", d.hitUp or 0, d.hit - (d.hitUp or 0), d.hitPunching or 0, table.concat(ks, ", "))
    end
    return table.concat(lines, "\n")
end

local fatMT = {
    __index = function(_, k) if k == "fat" then return 0 end end,
    __newindex = function(t, k, v) if k == "fat" then return end rawset(t, k, v) end,
}
local fatOn = false
local function applyNoFatigue()
    rescan(true)
    local s = G.state
    if not s then return end
    if cfg.noFatigue and not fatOn then rawset(s, "fat", nil); setmetatable(s, fatMT); fatOn = true
    elseif not cfg.noFatigue and fatOn then setmetatable(s, nil); rawset(s, "fat", 0); fatOn = false end
end
local origStam = lp:GetAttribute("FightStamina")
local function applyInfStamina()
    if cfg.infStamina then
        local cur = lp:GetAttribute("FightStamina")
        if cur ~= "inf" then origStam = cur or origStam; lp:SetAttribute("FightStamina", "inf") end
    else
        if lp:GetAttribute("FightStamina") == "inf" then lp:SetAttribute("FightStamina", origStam or "full") end
    end
end
do

local stamFns, lastStamScan, scanning = {}, 0, false
local function findStamFns()
    if scanning then return end
    scanning = true
    task.spawn(function()
        local found = {}
        local ok, err = pcall(function()
            local list = getgc(false)
            for i = 1, #list do
                local f = list[i]
                if type(f) == "function" and islclosure(f) then
                    local okc, consts = pcall(debug.getconstants, f)
                    if okc and type(consts) == "table" and table.find(consts, "FightStamina") then
                        local info = debug.getinfo(f, "s")
                        if info and info.short_src and info.short_src:find("VRBoxing", 1, true) then
                            local oku, ups = pcall(debug.getupvalues, f)
                            if oku and type(ups) == "table" then
                                local idx = {}
                                for ui, v in pairs(ups) do if type(v) == "number" and v >= 0 and v <= 100 then idx[#idx + 1] = ui end end
                                table.sort(idx)
                                for k = 1, #idx - 1 do
                                    if idx[k + 1] == idx[k] + 1 then found[#found + 1] = { f = f, a = idx[k] }; break end
                                end
                            end
                        end
                    end
                end
                if i % 30000 == 0 then task.wait() end
            end
        end)
        if ok then stamFns = found end
        scanning = false
    end)
end
local function pinStamina()
    local now = os.clock()
    if #stamFns == 0 and not scanning and now - lastStamScan > 3 then lastStamScan = now; findStamFns() end
    for i = #stamFns, 1, -1 do
        local t = stamFns[i]
        local ok = pcall(function() debug.setupvalue(t.f, t.a, 100); debug.setupvalue(t.f, t.a + 1, 100) end)
        if not ok then table.remove(stamFns, i) end
    end
end
track(RunService.RenderStepped:Connect(function()
    if cfg.infStamina then pcall(pinStamina) end
end))

local lastFatCheck = 0
track(RunService.Heartbeat:Connect(function()
    if cfg.infStamina then applyInfStamina() end
    local now = os.clock()
    if now - lastFatCheck < 0.5 then return end
    lastFatCheck = now

    if cfg.noFatigue then
        local st = G.state
        if not fatOn or not st or not rawget(st, "cardioK") or getmetatable(st) ~= fatMT then fatOn = false; applyNoFatigue() end
    elseif fatOn then
        applyNoFatigue()
    end
end))
end
onCleanup(function() cfg.noFatigue = false; cfg.infStamina = false; applyNoFatigue(); applyInfStamina() end)

local function lerpColor(a, b, t) return a:Lerp(b, math.clamp(t, 0, 1)) end
local GREEN, YELLOW, RED = Color3.fromRGB(104, 214, 134), Color3.fromRGB(238, 198, 88), Color3.fromRGB(228, 82, 82)
local ORANGE, ACC, BLUE = Color3.fromRGB(255, 158, 62), Color3.fromRGB(154, 123, 255), Color3.fromRGB(92, 166, 255)
local WHITE, MUTED, BLACK = Color3.fromRGB(238, 238, 244), Color3.fromRGB(150, 152, 168), Color3.new(0, 0, 0)
local function stamColor(f) return f > 0.5 and lerpColor(YELLOW, GREEN, (f - 0.5) * 2) or lerpColor(RED, YELLOW, f * 2) end
local function cleanName(n) return (tostring(n):gsub("%s*%b()", "")) end
local function pct(a, b) return b > 0 and string.format("%d%%", a / b * 100) or "-" end

do
    local hasDrawing = pcall(function() return Drawing.new end) and Drawing ~= nil
    local FONT = 0
    local pool, ringLines = {}, {}

    local function new(kind, props)
        local o = Drawing.new(kind)
        for k, v in pairs(props) do o[k] = v end
        o.Visible = false
        pool[#pool + 1] = o
        return o
    end

    local D = { cShadow = {}, cLine = {}, ticks = {} }
    if hasDrawing then
        D.boxShadow = new("Square", { Thickness = 3, Color = BLACK, Filled = false, Transparency = 0.55 })
        D.box = new("Square", { Thickness = 1, Color = WHITE, Filled = false, Transparency = 1 })
        for i = 1, 8 do
            D.cShadow[i] = new("Line", { Thickness = 3, Color = BLACK, Transparency = 0.55 })
            D.cLine[i] = new("Line", { Thickness = 1, Color = WHITE, Transparency = 1 })
        end
        D.hpBg = new("Square", { Filled = true, Color = BLACK, Transparency = 0.7 })
        D.hpGhost = new("Square", { Filled = true, Color = WHITE, Transparency = 0.5 })
        D.hp = new("Square", { Filled = true, Color = GREEN, Transparency = 1 })
        D.stBg = new("Square", { Filled = true, Color = BLACK, Transparency = 0.7 })
        D.st = new("Square", { Filled = true, Color = BLUE, Transparency = 1 })
        for i = 1, 6 do D.ticks[i] = new("Line", { Thickness = 1, Color = BLACK, Transparency = 0.6 }) end
        D.hpVal = new("Text", { Size = 13, Center = true, Outline = true, Font = FONT, Color = WHITE, Transparency = 1 })
        D.stVal = new("Text", { Size = 13, Center = true, Outline = true, Font = FONT, Color = WHITE, Transparency = 1 })
        D.name = new("Text", { Size = 20, Center = true, Outline = true, Font = FONT, Color = WHITE, Transparency = 1 })
        D.sub = new("Text", { Size = 17, Center = true, Outline = true, Font = FONT, Color = MUTED, Transparency = 1 })
        D.foot = new("Text", { Size = 18, Center = true, Outline = true, Font = FONT, Color = WHITE, Transparency = 1 })
        D.timer = new("Line", { Thickness = 2, Color = RED, Transparency = 1 })
        D.tracer = new("Line", { Thickness = 1, Color = WHITE, Transparency = 0.75 })
        D.headRing = new("Circle", { Thickness = 1, NumSides = 20, Radius = 6, Filled = false, Color = WHITE, Transparency = 1 })
        D.headDot = new("Circle", { Thickness = 1, NumSides = 10, Radius = 1.6, Filled = true, Color = WHITE, Transparency = 1 })
        D.arrow = new("Triangle", { Filled = true, Color = WHITE, Transparency = 1 })
        D.arrowT = new("Text", { Size = 18, Center = true, Outline = true, Font = FONT, Color = WHITE, Transparency = 1 })
        D.warn = new("Text", { Size = 30, Center = true, Outline = true, Font = FONT, Color = RED, Transparency = 1 })
        D.dirShadow = new("Line", { Thickness = 10, Color = BLACK, Transparency = 0.6 })
        D.dir = new("Line", { Thickness = 6, Color = RED, Transparency = 1 })
        for i = 1, 28 do ringLines[i] = new("Line", { Thickness = 1, Color = WHITE, Transparency = 0.7 }) end
    end

    local function hideAll()
        for i = 1, #pool do
            local o = pool[i]
            if o.Visible then o.Visible = false end
        end
    end

    local hl, hlModel, hlFlash = nil, nil, false
    local function dropHighlight()
        if hl then pcall(function() hl:Destroy() end) end
        hl, hlModel, hlFlash = nil, nil, false
    end
    local function ensureHighlight(model)
        if hlModel == model and hl and hl.Parent then return end
        dropHighlight()
        hl = Instance.new("Highlight")
        hl.Adornee = model
        hl.FillTransparency = 1
        hl.OutlineTransparency = 0.2
        hl.DepthMode = Enum.HighlightDepthMode.AlwaysOnTop
        hl.Parent = world
        hlModel = model
    end

    onCleanup(function()
        dropHighlight()
        for i = 1, #pool do pcall(function() pool[i]:Remove() end) end
        pool = {}
    end)

    local function titleCase(str)
        return (tostring(str):lower():gsub("(%a)([%w']*)", function(a, b) return a:upper() .. b end))
    end

    local T = { at = 0, name = "", sub = "", foot = "", footCol = WHITE, warn = "", hh = 1, hhG = 1, hhVal = 0, st = 1, gassed = false, attacking = false,
        left = 0, eta = 0.1, inRange = false, col = WHITE, hand = 1 }

    local function refreshText(now)
        T.name = titleCase(cleanName(enemyAttr("DisplayName", E.model.Name)))
        local parts = {}
        if cfg.espGuardInfo then
            local diff, g, s = enemyAttr("AIDiff", nil), enemyAttr("AIGuard", nil), enemyAttr("AIStyle", nil)
            if diff then parts[#parts + 1] = titleCase(diff) end
            if g then parts[#parts + 1] = titleCase(g) end
            if s then parts[#parts + 1] = titleCase(s) end
        end
        T.sub = table.concat(parts, "  -  ")
        local mx = tonumber(enemyAttr("MaxHP", 100)) or 100
        local hv = tonumber(enemyAttr("HeadHP", mx)) or mx
        T.hhVal = hv
        T.hh = math.clamp(hv / mx, 0, 1)
        local stam = enemyStam()
        T.st = stam or 1
        T.gassed = enemyGassed()
        T.inRange = E.dist <= cfg.punchRange
        T.attacking = Atk.untilT > now
        T.hand = Atk.hand
        local f = cfg.espDistance and string.format("%.1f m", E.dist) or ""
        local status
        if T.attacking then
            T.eta = math.max(Atk.eta, 0.05)
            T.warn = string.format("%s  %s", string.upper(Atk.kind or "?"), Atk.hand == 1 and "LEFT" or "RIGHT")
            T.footCol = RED
            status = titleCase(Atk.kind or "punch")
        elseif T.gassed then
            T.footCol = ORANGE
            status = "Gassed"
        elseif T.hh < 0.2 then
            T.footCol = RED
            status = "Almost down"
        elseif T.inRange then
            T.footCol = GREEN
            status = "In range"
        else
            T.footCol = MUTED
        end
        if status then f = f .. (f ~= "" and "   " or "") .. status end
        T.foot = f
        T.col = (cfg.espColorStam and stam) and stamColor(stam) or cfg.espColor
        if T.gassed then T.col = ORANGE end
    end

    local lastFrame = os.clock()
    local ringTick = 0

    local function frame()
        local now = os.clock()
        local dt = math.clamp(now - lastFrame, 0.001, 0.1)
        lastFrame = now
        updateEnemy()
        if not (cfg.espOn and E.fight) or UIState.open then
            hideAll()
            dropHighlight()
            return
        end
        if now - T.at >= 0.08 then
            T.at = now
            refreshText(now)
        end
        T.left = math.max(0, Atk.t0 + Atk.eta - now)
        if T.hh > T.hhG then T.hhG = T.hh else T.hhG = T.hhG + (T.hh - T.hhG) * math.min(1, dt * 1.6) end

        if cfg.espHighlight then
            ensureHighlight(E.model)
            hl.OutlineColor = T.attacking and RED or T.col
            local flashing = cfg.fxFlash and cfg.fxOn and now < FXS.flashUntil
            if flashing ~= hlFlash then
                hlFlash = flashing
                hl.FillTransparency = flashing and 0.45 or 1
                hl.FillColor = WHITE
            end
        else
            dropHighlight()
        end

        if not hasDrawing then return end

        local cam = Workspace.CurrentCamera
        local vs = cam.ViewportSize
        local pos = E.hrp.Position
        local right = cam.CFrame.RightVector * 1.25
        local topY = (E.head and E.head.Position.Y or pos.Y + 1.5) + 0.65
        local botY = pos.Y - 3.0
        local tl = cam:WorldToViewportPoint(Vector3.new(pos.X, topY, pos.Z) - right)
        local tr = cam:WorldToViewportPoint(Vector3.new(pos.X, topY, pos.Z) + right)
        local bl = cam:WorldToViewportPoint(Vector3.new(pos.X, botY, pos.Z) - right)
        local br = cam:WorldToViewportPoint(Vector3.new(pos.X, botY, pos.Z) + right)
        local center = cam:WorldToViewportPoint(pos)
        local front = tl.Z > 0 and tr.Z > 0 and bl.Z > 0 and br.Z > 0
        local minX, maxX = math.min(tl.X, tr.X, bl.X, br.X), math.max(tl.X, tr.X, bl.X, br.X)
        local minY, maxY = math.min(tl.Y, tr.Y, bl.Y, br.Y), math.max(tl.Y, tr.Y, bl.Y, br.Y)
        local onScreen = front and maxX > 0 and minX < vs.X and maxY > 0 and minY < vs.Y

        local s = cfg.espScale
        local boxCol = T.col
        if T.attacking and cfg.espPulse and (now % 0.32) < 0.16 then boxCol = RED end

        if onScreen then
            local w, h = maxX - minX, maxY - minY
            local cx = (minX + maxX) / 2

            local corners = cfg.espBox and cfg.boxStyle == "Corners"
            local full = cfg.espBox and cfg.boxStyle ~= "Corners"
            D.boxShadow.Visible, D.box.Visible = full, full
            if full then
                D.boxShadow.Position, D.boxShadow.Size = Vector2.new(minX, minY), Vector2.new(w, h)
                D.box.Position, D.box.Size, D.box.Color = Vector2.new(minX, minY), Vector2.new(w, h), boxCol
            end
            if corners then
                local lx, ly = math.clamp(w * 0.26, 6, 44), math.clamp(h * 0.16, 6, 56)
                local pts = {
                    { minX, minY, lx, 0 }, { minX, minY, 0, ly }, { maxX, minY, -lx, 0 }, { maxX, minY, 0, ly },
                    { minX, maxY, lx, 0 }, { minX, maxY, 0, -ly }, { maxX, maxY, -lx, 0 }, { maxX, maxY, 0, -ly },
                }
                for i = 1, 8 do
                    local p = pts[i]
                    local a, b = Vector2.new(p[1], p[2]), Vector2.new(p[1] + p[3], p[2] + p[4])
                    local sh, ln = D.cShadow[i], D.cLine[i]
                    sh.From, sh.To, sh.Visible = a, b, true
                    ln.From, ln.To, ln.Color, ln.Visible = a, b, boxCol, true
                end
            else
                for i = 1, 8 do D.cShadow[i].Visible, D.cLine[i].Visible = false, false end
            end

            if cfg.espBars then
                local bw = math.max(3, math.floor(4 * s))
                local hx, sx = minX - bw - 6, maxX + 6
                D.hpBg.Position, D.hpBg.Size, D.hpBg.Visible = Vector2.new(hx - 1, minY - 1), Vector2.new(bw + 2, h + 2), true
                if cfg.espGhost and T.hhG > T.hh + 0.004 then
                    local gf = h * T.hhG
                    D.hpGhost.Position, D.hpGhost.Size, D.hpGhost.Visible = Vector2.new(hx, minY + h - gf), Vector2.new(bw, gf), true
                else
                    D.hpGhost.Visible = false
                end
                local hf = h * T.hh
                D.hp.Position, D.hp.Size, D.hp.Color, D.hp.Visible = Vector2.new(hx, minY + h - hf), Vector2.new(bw, hf), lerpColor(RED, GREEN, T.hh), true
                D.stBg.Position, D.stBg.Size, D.stBg.Visible = Vector2.new(sx - 1, minY - 1), Vector2.new(bw + 2, h + 2), true
                local sf = h * math.clamp(T.st, 0, 1)
                local gassPulse = T.gassed and (0.55 + 0.45 * math.abs(math.sin(now * 5))) or 1
                D.st.Position, D.st.Size, D.st.Color, D.st.Visible = Vector2.new(sx, minY + h - sf), Vector2.new(bw, sf), T.gassed and ORANGE or BLUE, true
                D.st.Transparency = gassPulse
                for k = 1, 3 do
                    local y = minY + h * (1 - k * 0.25)
                    local a, b = D.ticks[k], D.ticks[k + 3]
                    a.From, a.To, a.Visible = Vector2.new(hx, y), Vector2.new(hx + bw, y), true
                    b.From, b.To, b.Visible = Vector2.new(sx, y), Vector2.new(sx + bw, y), true
                end
                if cfg.espValues then
                    D.hpVal.Size, D.stVal.Size = math.floor(13 * s), math.floor(13 * s)
                    D.hpVal.Text, D.hpVal.Position, D.hpVal.Visible = string.format("%d", T.hhVal), Vector2.new(hx + bw / 2, minY - 17 * s), true
                    D.stVal.Text, D.stVal.Position, D.stVal.Visible = string.format("%d", T.st * 100), Vector2.new(sx + bw / 2, minY - 17 * s), true
                else
                    D.hpVal.Visible, D.stVal.Visible = false, false
                end
            else
                D.hpBg.Visible, D.hpGhost.Visible, D.hp.Visible, D.stBg.Visible, D.st.Visible, D.hpVal.Visible, D.stVal.Visible = false, false, false, false, false, false, false
                for i = 1, 6 do D.ticks[i].Visible = false end
            end

            if cfg.espCard then
                D.name.Size, D.sub.Size, D.foot.Size = math.floor(20 * s), math.floor(17 * s), math.floor(18 * s)
                local hasSub = T.sub ~= ""
                local nameY = math.max(4, minY - (hasSub and 52 or 30) * s)
                D.name.Text, D.name.Position, D.name.Visible = T.name, Vector2.new(cx, nameY), true
                D.sub.Text, D.sub.Position, D.sub.Visible = T.sub, Vector2.new(cx, nameY + 25 * s), hasSub
                local footY = math.min(maxY + 6, vs.Y - 110)
                D.foot.Text, D.foot.Color, D.foot.Position, D.foot.Visible = T.foot, T.footCol, Vector2.new(cx, footY), T.foot ~= ""
                if T.attacking and cfg.incomingWarn then
                    local frac = math.clamp(T.left / T.eta, 0, 1)
                    local ty = footY + 26 * s
                    D.timer.From, D.timer.To, D.timer.Visible = Vector2.new(cx - 44 * s, ty), Vector2.new(cx - 44 * s + 88 * s * frac, ty), true
                else
                    D.timer.Visible = false
                end
            else
                D.name.Visible, D.sub.Visible, D.foot.Visible, D.timer.Visible = false, false, false, false
            end

            if cfg.espHeadDot and E.head then
                local hp2 = cam:WorldToViewportPoint(E.head.Position)
                if hp2.Z > 0 then
                    local p2 = Vector2.new(hp2.X, hp2.Y)
                    D.headRing.Position, D.headRing.Color, D.headRing.Radius, D.headRing.Visible = p2, boxCol, math.clamp(900 / math.max(hp2.Z, 1) * 0.5, 4, 16), true
                    D.headDot.Position, D.headDot.Color, D.headDot.Visible = p2, boxCol, true
                else
                    D.headRing.Visible, D.headDot.Visible = false, false
                end
            else
                D.headRing.Visible, D.headDot.Visible = false, false
            end

            if cfg.tracer then
                D.tracer.From, D.tracer.To, D.tracer.Color, D.tracer.Visible = Vector2.new(vs.X / 2, vs.Y), Vector2.new(cx, maxY), boxCol, true
            else
                D.tracer.Visible = false
            end
            D.arrow.Visible, D.arrowT.Visible = false, false
        else
            D.boxShadow.Visible, D.box.Visible, D.hpBg.Visible, D.hpGhost.Visible, D.hp.Visible, D.stBg.Visible, D.st.Visible = false, false, false, false, false, false, false
            D.name.Visible, D.sub.Visible, D.foot.Visible, D.timer.Visible, D.tracer.Visible, D.hpVal.Visible, D.stVal.Visible = false, false, false, false, false, false, false
            D.headRing.Visible, D.headDot.Visible = false, false
            for i = 1, 8 do D.cShadow[i].Visible, D.cLine[i].Visible = false, false end
            for i = 1, 6 do D.ticks[i].Visible = false end
            if cfg.espOffscreen then
                local ctr = vs / 2
                local dir = Vector2.new(center.X - ctr.X, center.Y - ctr.Y)
                if center.Z <= 0 then dir = -dir end
                if dir.Magnitude < 1 then dir = Vector2.new(0, -1) end
                dir = dir.Unit
                local edge = ctr + dir * (math.min(ctr.X, ctr.Y) - 56)
                local perp = Vector2.new(-dir.Y, dir.X)
                D.arrow.PointA, D.arrow.PointB, D.arrow.PointC = edge + dir * 14, edge - dir * 9 + perp * 10, edge - dir * 9 - perp * 10
                D.arrow.Color, D.arrow.Visible = boxCol, true
                D.arrowT.Text, D.arrowT.Position, D.arrowT.Visible = string.format("%.0f m", E.dist), edge - dir * 32 - Vector2.new(0, 10), true
            else
                D.arrow.Visible, D.arrowT.Visible = false, false
            end
        end

        if cfg.incomingWarn and T.attacking and E.dist <= 9 then
            D.warn.Text = string.format("%s  %.2f", T.warn, T.left)
            D.warn.Position = Vector2.new(vs.X / 2, vs.Y * 0.3)
            local urgent = T.left < 0.15
            D.warn.Color = urgent and RED or ORANGE
            D.warn.Visible = true
            local side = T.hand == 1 and 1 or -1
            local dx = vs.X / 2 + side * 210
            local a, b = Vector2.new(dx, vs.Y * 0.4), Vector2.new(dx, vs.Y * 0.58)
            D.dirShadow.From, D.dirShadow.To, D.dirShadow.Visible = a, b, true
            D.dir.From, D.dir.To, D.dir.Color, D.dir.Visible = a, b, urgent and RED or ORANGE, true
            D.dir.Transparency = 0.55 + 0.45 * math.abs(math.sin(now * 14))
        else
            D.warn.Visible, D.dir.Visible, D.dirShadow.Visible = false, false, false
        end

        if cfg.rangeRing then
            ringTick = ringTick + 1
            if ringTick % 2 == 0 then
                local y = pos.Y - 2.95
                local r = cfg.punchRange
                local col = T.inRange and GREEN or RED
                local prev
                for i = 0, #ringLines do
                    local a = (i / #ringLines) * math.pi * 2
                    local p = cam:WorldToViewportPoint(Vector3.new(pos.X + math.cos(a) * r, y, pos.Z + math.sin(a) * r))
                    if i > 0 then
                        local ln = ringLines[i]
                        if prev.Z > 0 and p.Z > 0 then
                            ln.From, ln.To, ln.Color, ln.Visible = Vector2.new(prev.X, prev.Y), Vector2.new(p.X, p.Y), col, true
                        else
                            ln.Visible = false
                        end
                    end
                    prev = p
                end
            end
        else
            for i = 1, #ringLines do
                if ringLines[i].Visible then ringLines[i].Visible = false end
            end
        end
    end
    track(RunService.RenderStepped:Connect(function() pcall(frame) end))
end

do
    local hasDrawing = pcall(function() return Drawing.new end) and Drawing ~= nil
    if hasDrawing then
        local slots, sel, selAt, dataAt = {}, {}, 0, 0
        local MAXS = 25

        local function mkSlot()
            local o = {
                shadow = Drawing.new("Square"), box = Drawing.new("Square"), name = Drawing.new("Text"), info = Drawing.new("Text"),
                hpBg = Drawing.new("Square"), hp = Drawing.new("Square"), stBg = Drawing.new("Square"), st = Drawing.new("Square"),
                hh = 1, sm = nil, nm = "", inf = "", ring = false, ko = false,
            }
            o.shadow.Thickness, o.shadow.Filled, o.shadow.Color, o.shadow.Transparency = 3, false, BLACK, 0.55
            o.box.Thickness, o.box.Filled, o.box.Transparency = 1, false, 1
            for _, t in ipairs({ o.name, o.info }) do t.Center, t.Outline, t.Font, t.Transparency = true, true, 0, 1 end
            o.name.Size, o.info.Size = 17, 15
            o.name.Color, o.info.Color = WHITE, MUTED
            for _, q in ipairs({ o.hpBg, o.stBg }) do q.Filled, q.Color, q.Transparency = true, BLACK, 0.7 end
            o.hp.Filled, o.st.Filled, o.hp.Transparency, o.st.Transparency = true, true, 1, 1
            o.st.Color = BLUE
            o.parts = { o.shadow, o.box, o.name, o.info, o.hpBg, o.hp, o.stBg, o.st }
            for _, d in ipairs(o.parts) do d.Visible = false end
            return o
        end
        local function hideSlot(o)
            for _, d in ipairs(o.parts) do if d.Visible then d.Visible = false end end
        end
        local function hideAll()
            for i = 1, #slots do hideSlot(slots[i]) end
        end
        onCleanup(function()
            for i = 1, #slots do for _, d in ipairs(slots[i].parts) do pcall(function() d:Remove() end) end end
            slots = {}
        end)

        local function attrOf(pl, ch, name)
            local v = ch:GetAttribute(name)
            if v == nil then v = pl:GetAttribute(name) end
            return v
        end

        local function choose(now)
            selAt = now
            table.clear(sel)
            local r = myRoot()
            if not r then return end
            local myRing = lp:GetAttribute("InRing")
            local mode = cfg.espPlayerMode
            local list = {}
            for _, pl in ipairs(Players:GetPlayers()) do
                local ch = pl ~= lp and pl.Character
                local hrp = ch and ch:FindFirstChild("HumanoidRootPart")
                if hrp and not (cfg.espOn and E.fight and E.model == ch) then
                    local d = (hrp.Position - r.Position).Magnitude
                    if d <= cfg.espPlayerRange and (mode ~= "Same ring only" or (myRing ~= nil and pl:GetAttribute("InRing") == myRing)) then
                        list[#list + 1] = { pl = pl, ch = ch, hrp = hrp, d = d }
                    end
                end
            end
            table.sort(list, function(a, b) return a.d < b.d end)
            local cap = mode == "Closest only" and 1 or math.min(cfg.espPlayerCount, MAXS)
            if mode == "Same ring only" then cap = MAXS end
            for i = 1, math.min(#list, cap) do sel[i] = list[i] end
        end

        local function refreshData(e, o)
            local ch, pl = e.ch, e.pl
            o.nm = pl.DisplayName ~= "" and pl.DisplayName or pl.Name
            local mx = tonumber(attrOf(pl, ch, "MaxHP")) or 100
            local hv = tonumber(attrOf(pl, ch, "HeadHP")) or mx
            o.hh = mx > 0 and math.clamp(hv / mx, 0, 1) or 1
            local sv = tonumber(attrOf(pl, ch, "Stam"))
            if sv == nil then sv = tonumber(attrOf(pl, ch, "FightStamina")) end
            if sv and sv > 1.001 then sv = sv / 100 end
            o.sm = sv and math.clamp(sv, 0, 1) or nil
            o.ring = attrOf(pl, ch, "InRing") ~= nil
            o.ko = attrOf(pl, ch, "BoxKO") == true
            o.inf = (cfg.espPlayerDist and string.format("%.0f m", e.d) or "") .. (o.ko and "  KO" or (o.ring and "  In ring" or ""))
        end

        track(RunService.RenderStepped:Connect(function()
            local ok = pcall(function()
                local now = os.clock()
                if not cfg.espPlayers or UIState.open then hideAll(); return end
                if now - selAt > 0.2 then choose(now) end
                local doData = now - dataAt > 0.1
                if doData then dataAt = now end
                local cam = Workspace.CurrentCamera
                local vs = cam.ViewportSize
                local sc = cfg.espScale
                for i = 1, #sel do
                    local e = sel[i]
                    local o = slots[i]
                    if not o then o = mkSlot(); slots[i] = o end
                    if e.slot ~= o then e.slot = o; refreshData(e, o) elseif doData then refreshData(e, o) end
                    if not (e.hrp.Parent and e.ch.Parent) then
                        hideSlot(o)
                    else
                        local pos = e.hrp.Position
                        local head = e.ch:FindFirstChild("Head")
                        local topY = (head and head.Position.Y or pos.Y + 1.5) + 0.65
                        local right = cam.CFrame.RightVector * 1.25
                        local tl = cam:WorldToViewportPoint(Vector3.new(pos.X, topY, pos.Z) - right)
                        local tr = cam:WorldToViewportPoint(Vector3.new(pos.X, topY, pos.Z) + right)
                        local bl = cam:WorldToViewportPoint(Vector3.new(pos.X, pos.Y - 3, pos.Z) - right)
                        local br = cam:WorldToViewportPoint(Vector3.new(pos.X, pos.Y - 3, pos.Z) + right)
                        local minX, maxX = math.min(tl.X, tr.X, bl.X, br.X), math.max(tl.X, tr.X, bl.X, br.X)
                        local minY, maxY = math.min(tl.Y, tr.Y, bl.Y, br.Y), math.max(tl.Y, tr.Y, bl.Y, br.Y)
                        if tl.Z > 0 and tr.Z > 0 and bl.Z > 0 and br.Z > 0 and maxX > 0 and minX < vs.X and maxY > 0 and minY < vs.Y then
                            local w, h = maxX - minX, maxY - minY
                            local col = o.ko and MUTED or ((o.sm and cfg.espColorStam) and stamColor(o.sm) or cfg.espColor)
                            if cfg.espBox then
                                o.shadow.Position, o.shadow.Size, o.shadow.Visible = Vector2.new(minX, minY), Vector2.new(w, h), true
                                o.box.Position, o.box.Size, o.box.Color, o.box.Visible = Vector2.new(minX, minY), Vector2.new(w, h), col, true
                            else
                                o.shadow.Visible, o.box.Visible = false, false
                            end
                            local cx = (minX + maxX) / 2
                            o.name.Size, o.info.Size = math.floor(17 * sc), math.floor(15 * sc)
                            o.name.Text, o.name.Position, o.name.Visible = o.nm, Vector2.new(cx, math.max(4, minY - 22 * sc)), true
                            o.info.Text, o.info.Position, o.info.Visible = o.inf, Vector2.new(cx, math.min(maxY + 4, vs.Y - 40)), o.inf ~= ""
                            if cfg.espPlayerBars and (o.ring or o.hh < 1) then
                                local bw = 3
                                local hx, sx = minX - bw - 5, maxX + 5
                                o.hpBg.Position, o.hpBg.Size, o.hpBg.Visible = Vector2.new(hx - 1, minY - 1), Vector2.new(bw + 2, h + 2), true
                                local hf = h * o.hh
                                o.hp.Position, o.hp.Size, o.hp.Color, o.hp.Visible = Vector2.new(hx, minY + h - hf), Vector2.new(bw, hf), lerpColor(RED, GREEN, o.hh), true
                                if o.sm then
                                    o.stBg.Position, o.stBg.Size, o.stBg.Visible = Vector2.new(sx - 1, minY - 1), Vector2.new(bw + 2, h + 2), true
                                    local sf = h * o.sm
                                    o.st.Position, o.st.Size, o.st.Visible = Vector2.new(sx, minY + h - sf), Vector2.new(bw, sf), true
                                else
                                    o.stBg.Visible, o.st.Visible = false, false
                                end
                            else
                                o.hpBg.Visible, o.hp.Visible, o.stBg.Visible, o.st.Visible = false, false, false, false
                            end
                        else
                            hideSlot(o)
                        end
                    end
                end
                for i = #sel + 1, #slots do hideSlot(slots[i]) end
            end)
            if not ok then hideAll() end
        end))
    end
end

do
    local hud = mk("Frame", { Name = "HUD", Position = UDim2.new(1, -246, 0, 70), Size = UDim2.fromOffset(232, 124), BackgroundColor3 = Color3.fromRGB(14, 14, 18),
        BackgroundTransparency = 0.12, BorderSizePixel = 0, Active = true, Draggable = true }, gui)
    mk("UICorner", { CornerRadius = UDim.new(0, 6) }, hud)
    mk("UIStroke", { Color = Color3.fromRGB(44, 44, 56), Thickness = 1 }, hud)
    local txt = mk("TextLabel", { Position = UDim2.fromOffset(12, 9), Size = UDim2.new(1, -24, 1, -16), BackgroundTransparency = 1, Font = Enum.Font.BuilderSans, TextSize = 14,
        TextColor3 = Color3.fromRGB(206, 208, 220), TextXAlignment = Enum.TextXAlignment.Left, TextYAlignment = Enum.TextYAlignment.Top, RichText = true, Text = "" }, hud)
    local last, lastText = 0, ""
    track(RunService.Heartbeat:Connect(function()
        local now = os.clock()
        if now - last < 0.2 then return end
        last = now
        hud.Visible = cfg.hudOn
        if not cfg.hudOn then return end
        local th, ld, df = lp:GetAttribute("RingThrown") or 0, lp:GetAttribute("RingLanded") or 0, lp:GetAttribute("RingDefended") or 0
        local ath, ald, abl = enemyAttr("AIThrown", 0), enemyAttr("AILanded", 0), enemyAttr("AIBlocked", 0)
        local function c(s, col) return string.format('<font color="%s">%s</font>', col, s) end
        local state = Bot.state:sub(1, 1):upper() .. Bot.state:sub(2)
        local out = table.concat({
            c("<b>Kairo</b>", "#ffffff") .. c("<b>.cc</b>", "#9a7bff") .. "   " .. (cfg.autoFight and c("Auto on", "#68d686") or c("Auto off", "#8a8c9c")),
            c(state .. (Bot.combo and ("  -  " .. Bot.comboName) or ""), "#8a8c9c"),
            "",
            string.format("You   %s thrown  -  %s landed  -  %s", c(th, "#ffffff"), c(ld, "#68d686"), pct(ld, th)),
            string.format("Enemy   %s thrown  -  %s landed  -  %s", c(ath, "#ffffff"), c(ald, "#e45252"), pct(ald, ath)),
            string.format("Blocked %s   -   Stamina %d%%", c(df, "#5ca6ff"), myStam() * 100),
            string.format("Distance %.1f   -   Reach %.1f", E.dist, cfg.punchRange),
        }, "\n")
        if out ~= lastText then lastText = out; txt.Text = out end
    end))
end

do
    local QMUL = { Low = 0.5, Medium = 1, High = 1.7 }
    local TEX = "rbxasset://textures/particles/sparkles_main.dds"
    local hasDrawing = pcall(function() return Drawing.new end) and Drawing ~= nil
    local shake, takenAt = 0, -10
    local combo = { n = 0, at = -10 }

    local folder = Instance.new("Folder")
    folder.Name = "KairoFX"
    folder.Parent = Workspace.CurrentCamera

    local function seq(a, b) return NumberSequence.new({ NumberSequenceKeypoint.new(0, a), NumberSequenceKeypoint.new(1, b) }) end
    local function emitter(parent, props)
        local e = Instance.new("ParticleEmitter")
        e:SetAttribute("KairoFx", true)
        e.Texture = TEX
        e.Rate = 0
        e.LightEmission = 1
        e.LightInfluence = 0
        e.Transparency = seq(0, 1)
        for k, v in pairs(props) do e[k] = v end
        e.Parent = parent
        return e
    end
    local function quality() return QMUL[cfg.fxQuality] or 1 end

    local fxPart = mk("Part", { Name = "fx", Anchored = true, CanCollide = false, CanQuery = false, CanTouch = false, Transparency = 1, Size = Vector3.new(0.2, 0.2, 0.2) }, folder)
    local fxAtt = mk("Attachment", {}, fxPart)
    local sparkA = emitter(fxAtt, { Lifetime = NumberRange.new(0.25, 0.5), Speed = NumberRange.new(16, 30), SpreadAngle = Vector2.new(180, 180), Size = seq(0.7, 0), Drag = 4 })
    local sparkB = emitter(fxAtt, { Lifetime = NumberRange.new(0.25, 0.5), Speed = NumberRange.new(14, 26), SpreadAngle = Vector2.new(180, 180), Size = seq(0.7, 0), Drag = 4,
        Color = ColorSequence.new(Color3.fromRGB(255, 150, 50)) })
    local flash = emitter(fxAtt, { Lifetime = NumberRange.new(0.14, 0.2), Speed = NumberRange.new(0, 0), Size = seq(3.5, 9), Color = ColorSequence.new(Color3.fromRGB(255, 255, 255)) })
    local sparkBlock = emitter(fxAtt, { Lifetime = NumberRange.new(0.2, 0.35), Speed = NumberRange.new(8, 16), SpreadAngle = Vector2.new(180, 180), Size = seq(0.45, 0),
        Color = ColorSequence.new(Color3.fromRGB(190, 220, 255)) })

    local function burst(kind, pos)
        fxPart.Position = pos
        local q = quality()
        if kind == "block" then
            sparkBlock:Emit(math.max(1, math.floor(10 * q)))
            return
        end
        local em = kind == "body" and sparkB or sparkA
        if kind ~= "body" then em.Color = ColorSequence.new(cfg.fxColor) end
        em:Emit(math.max(1, math.floor(22 * q)))
        flash:Emit(1)
    end

    local rings = {}
    for i = 1, 4 do
        local part = mk("Part", { Anchored = true, CanCollide = false, CanQuery = false, CanTouch = false, Transparency = 1, Size = Vector3.new(0.2, 0.2, 0.2) }, folder)
        local bb = mk("BillboardGui", { AlwaysOnTop = true, Size = UDim2.fromOffset(60, 60), LightInfluence = 0, Enabled = false, Adornee = part }, part)
        local f = mk("Frame", { Size = UDim2.fromScale(1, 1), BackgroundTransparency = 1 }, bb)
        mk("UICorner", { CornerRadius = UDim.new(1, 0) }, f)
        local st = mk("UIStroke", { Thickness = 3, Color = WHITE }, f)
        rings[i] = { part = part, bb = bb, st = st, on = false, t0 = 0, size = 1 }
    end
    local function spawnRing(pos, color, size)
        for i = 1, #rings do
            local r = rings[i]
            if not r.on then
                r.on, r.t0, r.size = true, os.clock(), size
                r.part.Position = pos
                r.st.Color = color
                r.bb.Enabled = true
                return
            end
        end
    end

    local drawings, nums, comboT, comboL = {}, {}, nil, nil
    local function newText(size)
        local t = Drawing.new("Text")
        t.Size, t.Center, t.Outline, t.Font, t.Visible, t.Transparency, t.Color = size, true, true, 0, false, 1, WHITE
        drawings[#drawings + 1] = t
        return t
    end
    if hasDrawing then
        for i = 1, 8 do nums[i] = { t = newText(24), on = false, t0 = 0, size = 24, vx = 0 } end
        comboT = newText(54)
        comboL = newText(18)
    end
    local function spawnNumber(text, color, size, worldPos, screenPos)
        if not hasDrawing then return end
        for i = 1, #nums do
            local n = nums[i]
            if not n.on then
                n.on, n.t0, n.world, n.screen, n.size = true, os.clock(), worldPos, screenPos, size
                n.vx = (math.random() - 0.5) * 0.9
                n.t.Text, n.t.Color = text, color
                return
            end
        end
    end

    local function onEnemyHit(zone, amt)
        local now = os.clock()
        local pos = zone == "head" and E.head.Position or (E.hrp.Position + Vector3.new(0, 0.4, 0))
        pos = pos + Vector3.new((math.random() - 0.5) * 0.6, (math.random() - 0.5) * 0.4, (math.random() - 0.5) * 0.6)
        if cfg.fxSparks then burst(zone, pos) end
        local big = amt >= 12
        if cfg.fxRings then spawnRing(pos, zone == "head" and cfg.fxColor or ORANGE, big and 1.5 or 1) end
        if cfg.fxNumbers then spawnNumber(string.format("%d", math.floor(amt + 0.5)), zone == "head" and WHITE or ORANGE, big and 34 or 26, pos) end
        if now - combo.at < 1.8 then combo.n = combo.n + 1 else combo.n = 1 end
        combo.at = now
        FXS.flashUntil = now + 0.12
        if cfg.fxShake > 0 then shake = math.max(shake, cfg.fxShake * 0.004 * math.min(amt, 25)) end
    end

    local function onTaken(dmg)
        takenAt = os.clock()
        local cm = Workspace.CurrentCamera
        if cfg.fxNumbers and cm then
            local vs = cm.ViewportSize
            spawnNumber("-" .. math.floor(dmg + 0.5), RED, 28, nil, Vector2.new(vs.X * 0.5, vs.Y * 0.62))
        end
        if cfg.fxShake > 0 then shake = math.max(shake, cfg.fxShake * 0.006 * math.min(dmg, 30)) end
    end

    track(lp:GetAttributeChangedSignal("RingDefended"):Connect(function()
        if not (cfg.fxOn and cfg.fxSparks) then return end
        local cm = Workspace.CurrentCamera
        if not cm then return end
        burst("block", cm.CFrame.Position + cm.CFrame.LookVector * 2.4 + Vector3.new(0, -0.3, 0))
        if cfg.fxNumbers then
            local vs = cm.ViewportSize
            spawnNumber("Block", BLUE, 22, nil, Vector2.new(vs.X * 0.5, vs.Y * 0.56))
        end
    end))

    FXS.punch = function(class)
        if class == "blocked" and cfg.fxOn and cfg.fxSparks and E.fight and E.head then
            burst("block", E.head.Position + Vector3.new(0, -0.3, 0))
        end
    end

    local aura = {}
    local function auraEdge(anchor, pos, size, rot)
        local f = mk("Frame", { AnchorPoint = anchor, Position = pos, Size = size, BackgroundColor3 = cfg.fxColor, BackgroundTransparency = 1, BorderSizePixel = 0, Active = false }, gui)
        mk("UIGradient", { Rotation = rot, Transparency = NumberSequence.new({ NumberSequenceKeypoint.new(0, 0), NumberSequenceKeypoint.new(1, 1) }) }, f)
        aura[#aura + 1] = f
    end
    auraEdge(Vector2.new(0, 0), UDim2.new(0, 0, 0, 0), UDim2.new(1, 0, 0, 150), 90)
    auraEdge(Vector2.new(0, 1), UDim2.new(0, 0, 1, 0), UDim2.new(1, 0, 0, 150), 270)
    auraEdge(Vector2.new(0, 0), UDim2.new(0, 0, 0, 0), UDim2.new(0, 150, 1, 0), 0)
    auraEdge(Vector2.new(1, 0), UDim2.new(1, 0, 0, 0), UDim2.new(0, 150, 1, 0), 180)

    local auraShown = { c = nil, a = -1 }
    local function setAura(color, alpha)
        alpha = math.clamp(alpha, 0, 0.9)
        if auraShown.c == color and math.abs(auraShown.a - alpha) < 0.01 then return end
        auraShown.c, auraShown.a = color, alpha
        for i = 1, #aura do
            aura[i].BackgroundColor3 = color
            aura[i].BackgroundTransparency = 1 - alpha
        end
    end
    local function updateAura(now, gassed)
        if not (cfg.fxOn and cfg.fxAura) then setAura(cfg.fxColor, 0) return end
        local s = cfg.fxAuraStrength
        local flashK = math.max(0, 1 - (now - takenAt) / 0.5)
        local mh, mx = tonumber(lp:GetAttribute("HeadHP")), tonumber(lp:GetAttribute("MaxHP")) or 150
        local low = mh ~= nil and mh / mx < 0.3
        if cfg.fxVignette and flashK > 0 then
            setAura(RED, 0.8 * flashK * math.max(s, 0.5))
        elseif E.fight and cfg.fxVignette and low then
            setAura(RED, (0.28 + 0.2 * math.sin(now * 6)) * s)
        elseif E.fight and gassed then
            setAura(ORANGE, 0.3 * s * (0.7 + 0.3 * math.sin(now * 2.4)))
        elseif E.fight then
            setAura(cfg.fxColor, 0.22 * s * (0.75 + 0.25 * math.sin(now * 1.6)))
        elseif cfg.fxAuraAlways then
            setAura(cfg.fxColor, 0.1 * s)
        else
            setAura(cfg.fxColor, 0)
        end
    end

    local gloves = {}
    local function ensureGloves()
        local vm = Workspace:FindFirstChild("VRBoxing_Local")
        for _, side in ipairs({ "L", "R" }) do
            local part = vm and vm:FindFirstChild("Glove" .. side, true)
            local g = gloves[side]
            if part and (not g or g.att.Parent ~= part) then
                if g then pcall(function() g.att:Destroy() end) end
                local att = Instance.new("Attachment")
                att.Parent = part
                local em = emitter(att, { Lifetime = NumberRange.new(0.45, 0.9), Speed = NumberRange.new(0.5, 2.5), SpreadAngle = Vector2.new(180, 180), Size = seq(0.32, 0),
                    Acceleration = Vector3.new(0, 1.5, 0) })
                gloves[side] = { att = att, em = em }
                g = gloves[side]
            end
            if g then
                local on = cfg.fxOn and cfg.fxGlove
                g.em.Rate = on and (16 * cfg.fxAuraStrength * quality()) or 0
                g.em.Color = ColorSequence.new(cfg.fxColor)
            end
        end
    end

    local ember = { em = nil, att = nil, model = nil }
    local function updateEmbers(gassed)
        if not (cfg.fxOn and cfg.fxEmbers and E.fight and E.hrp) then
            if ember.em then ember.em.Rate = 0 end
            return
        end
        if ember.model ~= E.model or not ember.att or not ember.att.Parent then
            if ember.att then pcall(function() ember.att:Destroy() end) end
            ember.att = Instance.new("Attachment")
            ember.att.Parent = E.hrp
            ember.em = emitter(ember.att, { Lifetime = NumberRange.new(0.8, 1.4), Speed = NumberRange.new(1, 3), SpreadAngle = Vector2.new(40, 40), Size = seq(0.4, 0),
                Acceleration = Vector3.new(0, 4, 0), Color = ColorSequence.new(Color3.fromRGB(255, 150, 50)) })
            ember.model = E.model
        end
        ember.em.Rate = gassed and (22 * quality()) or 0
    end

    local prev = { model = nil, eh = nil, eb = nil, mh = nil }
    local lastTick, lastSlow = 0, 0
    track(RunService.Heartbeat:Connect(function()
        local now = os.clock()
        if now - lastTick < 0.05 then return end
        lastTick = now
        pcall(function()
            if folder.Parent ~= Workspace.CurrentCamera then folder.Parent = Workspace.CurrentCamera end
            if cfg.fxOn then
                if E.model ~= prev.model then prev.model, prev.eh, prev.eb = E.model, nil, nil end
                if E.fight and E.head then
                    local eh, eb = tonumber(E.attr.HeadHP), tonumber(E.attr.BodyHP)
                    if prev.eh and eh and eh < prev.eh - 1.5 then onEnemyHit("head", prev.eh - eh) end
                    if prev.eb and eb and eb < prev.eb - 1.5 then onEnemyHit("body", prev.eb - eb) end
                    prev.eh, prev.eb = eh, eb
                else
                    prev.eh, prev.eb = nil, nil
                end
                local mh = (tonumber(lp:GetAttribute("HeadHP")) or 0) + (tonumber(lp:GetAttribute("BodyHP")) or 0)
                if prev.mh and mh < prev.mh - 2.5 and E.fight then onTaken(prev.mh - mh) end
                prev.mh = mh
            end
            local gassed = E.fight and enemyGassed()
            updateAura(now, gassed)
            updateEmbers(gassed)
            if now - lastSlow > 0.5 then
                lastSlow = now
                ensureGloves()
            end
        end)
    end))

    local function frame()
        local now = os.clock()
        for i = 1, #rings do
            local r = rings[i]
            if r.on then
                local k = (now - r.t0) / 0.38
                if k >= 1 or not cfg.fxOn then
                    r.on = false
                    r.bb.Enabled = false
                else
                    local d = 44 + 230 * k * r.size
                    r.bb.Size = UDim2.fromOffset(d, d)
                    r.st.Transparency = k * k
                    r.st.Thickness = 1 + 4 * (1 - k)
                end
            end
        end
        if not hasDrawing then return end
        local cm = Workspace.CurrentCamera
        local vs = cm.ViewportSize
        local show = cfg.fxOn and not UIState.open
        for i = 1, #nums do
            local n = nums[i]
            if n.on then
                local age = now - n.t0
                if age > 0.9 or not show then
                    n.on = false
                    n.t.Visible = false
                else
                    local p
                    if n.world then
                        local sp = cm:WorldToViewportPoint(n.world + Vector3.new(n.vx * age, age * 2.2, 0))
                        if sp.Z > 0 then p = Vector2.new(sp.X, sp.Y) end
                    else
                        p = Vector2.new(n.screen.X + n.vx * age * 60, n.screen.Y - age * 70)
                    end
                    if p then
                        n.t.Size = math.floor(n.size * (1 + 0.5 * math.max(0, 1 - age * 7)))
                        n.t.Position = p
                        n.t.Transparency = 1 - (age / 0.9) ^ 2
                        n.t.Visible = true
                    else
                        n.t.Visible = false
                    end
                end
            end
        end
        local since = now - combo.at
        if show and cfg.fxCombo and combo.n >= 2 and since < 1.8 then
            local fade = since < 1.3 and 1 or (1 - (since - 1.3) / 0.5)
            comboT.Text = string.format("x%d", combo.n)
            comboT.Size = math.floor(54 * (1 + 0.4 * math.max(0, 1 - since * 8)))
            comboT.Position = Vector2.new(vs.X * 0.5, vs.Y * 0.66)
            comboT.Color = combo.n >= 6 and ORANGE or cfg.fxColor
            comboT.Transparency = fade
            comboT.Visible = true
            comboL.Text = "COMBO"
            comboL.Position = Vector2.new(vs.X * 0.5, vs.Y * 0.66 + 62)
            comboL.Transparency = fade
            comboL.Visible = true
        else
            comboT.Visible, comboL.Visible = false, false
        end
    end
    track(RunService.RenderStepped:Connect(function() pcall(frame) end))

    pcall(function() RunService:UnbindFromRenderStep("KairoShake") end)
    RunService:BindToRenderStep("KairoShake", Enum.RenderPriority.Camera.Value + 4, function()
        if shake < 0.0004 then
            shake = 0
            return
        end
        local cm = Workspace.CurrentCamera
        cm.CFrame = cm.CFrame * CFrame.Angles((math.random() - 0.5) * shake, (math.random() - 0.5) * shake, (math.random() - 0.5) * shake * 0.5)
        shake = shake * 0.84
    end)

    onCleanup(function()
        FXS.punch = nil
        pcall(function() RunService:UnbindFromRenderStep("KairoShake") end)
        for i = 1, #aura do pcall(function() aura[i]:Destroy() end) end
        for _, side in ipairs({ "L", "R" }) do
            if gloves[side] then pcall(function() gloves[side].att:Destroy() end) end
        end
        if ember.att then pcall(function() ember.att:Destroy() end) end
        for i = 1, #drawings do pcall(function() drawings[i]:Remove() end) end
        pcall(function() folder:Destroy() end)
    end)
end

local Skin = { gloves = {}, gloveMap = {}, trunks = {}, trunkMap = {},
    origGlove = lp:GetAttribute("GloveSkin"), origTrunks = lp:GetAttribute("TrunksSkin"), gOn = false, tOn = false }
do
    local SC
    pcall(function() SC = require(ReplicatedStorage:WaitForChild("ShopCatalog", 5)) end)
    local function build(t, extra)
        local ids = {}
        for id, d in pairs(t or {}) do if type(id) == "number" and type(d) == "table" then ids[#ids + 1] = id end end
        table.sort(ids)
        local names, map = {}, {}
        if extra then names[#names + 1] = extra.label; map[extra.label] = extra.id end
        for _, id in ipairs(ids) do
            local d = t[id]
            local nm = string.format("%02d  %s", id, tostring(d.name or id))
            if d.rarity and d.rarity ~= "Default" then nm = nm .. "  -  " .. tostring(d.rarity) end
            names[#names + 1] = nm; map[nm] = id
        end
        return names, map
    end
    if SC then
        Skin.gloves, Skin.gloveMap = build(SC.GLOVES)
        Skin.trunks, Skin.trunkMap = build(SC.TRUNKS, { label = "00  Default (no trunks skin)", id = 0 })
    end
end
local function setAttrIf(attr, id) if id ~= nil and lp:GetAttribute(attr) ~= id then lp:SetAttribute(attr, id) end end

track(lp:GetAttributeChangedSignal("GloveSkin"):Connect(function() if not Skin.gOn then Skin.origGlove = lp:GetAttribute("GloveSkin") end end))
track(lp:GetAttributeChangedSignal("TrunksSkin"):Connect(function() if not Skin.tOn then Skin.origTrunks = lp:GetAttribute("TrunksSkin") end end))
local lastSkin, lastCycle = 0, os.clock()
function Skin.randomize()
    if #Skin.gloves > 0 and cfg.gloveOn then cfg.gloveChoice = Skin.gloves[math.random(1, #Skin.gloves)] end
    if #Skin.trunks > 0 and cfg.trunksOn then cfg.trunksChoice = Skin.trunks[math.random(1, #Skin.trunks)] end
end
track(RunService.Heartbeat:Connect(function()
    local now = os.clock()
    if now - lastSkin < 0.15 then return end
    lastSkin = now
    if cfg.skinCycle and now - lastCycle > cfg.cycleDelay then
        lastCycle = now
        local list, key = Skin.gloves, "gloveChoice"
        if #list > 0 then
            local i = table.find(list, cfg[key]) or 0
            cfg[key] = list[i % #list + 1]
        end
    end
    if cfg.gloveOn then
        Skin.gOn = true
        setAttrIf("GloveSkin", Skin.gloveMap[cfg.gloveChoice])
    elseif Skin.gOn then
        Skin.gOn = false; setAttrIf("GloveSkin", Skin.origGlove)
    end
    if cfg.trunksOn then
        Skin.tOn = true
        setAttrIf("TrunksSkin", Skin.trunkMap[cfg.trunksChoice])
    elseif Skin.tOn then
        Skin.tOn = false; setAttrIf("TrunksSkin", Skin.origTrunks)
    end
end))
onCleanup(function()
    if Skin.gOn then setAttrIf("GloveSkin", Skin.origGlove) end
    if Skin.tOn then setAttrIf("TrunksSkin", Skin.origTrunks) end
end)

pcall(function() getgenv().RAYFIELD_ANALYTICS = false end)
local Rayfield = loadstring(game:HttpGet("https://sirius.menu/gen2"))()
local window = Rayfield:CreateWindow({
    name = "Kairo.cc",
    subtitle = "First Person Boxing  |  v2.7",
    sidebarLayout = true,
    configuration = { autoSave = true, autoLoad = true, fileName = "Kairo" },
})
pcall(function() window.settings.usageAnalytics = false end)
pcall(function() window.settings.toggleKeybind = Enum.KeyCode.RightShift; window:SaveSettings() end)

local BRAND = '<font color="#ffffff">Kairo</font><font color="#9a7bff">.cc</font>'
task.spawn(function()
    for _ = 1, 10 do
        local done = false
        pcall(function()
            for _, d in ipairs(window.screenGui:GetDescendants()) do
                if d:IsA("TextLabel") and d.Text == "Kairo.cc" then d.RichText = true; d.Text = BRAND; done = true end
            end
        end)
        if done then break end
        task.wait(0.2)
    end
end)

local ctl = {}
track(RunService.Heartbeat:Connect(function() UIState.open = not (window.hidden or window.minimised) end))
local function reg(key, el) ctl[key] = el; return el end
local function tog(tab, name, key, desc, hook, forget)
    return reg(key, tab:CreateToggle({ name = name, flag = key, description = desc, value = cfg[key], forgetState = forget,
        callback = function(v) cfg[key] = v; if hook then hook(v) end end }))
end
local function sld(tab, name, key, mn, mx, step, suffix, desc)
    return reg(key, tab:CreateSlider({ name = name, flag = key, description = desc, range = { mn, mx }, increment = step, value = cfg[key],
        suffix = suffix, callback = function(v) cfg[key] = v end }))
end
local function dd(tab, name, key, options, desc)
    return reg(key, tab:CreateDropdown({ name = name, flag = key, description = desc, options = options, value = cfg[key],
        callback = function(v) cfg[key] = v end }))
end
local logConsole
local function log(msg) if logConsole then pcall(function() logConsole:Append(string.format("[%s] %s", os.date("%H:%M:%S"), msg)) end) end end
local function notify(title, content) pcall(function() window:Notify({ title = title, content = content }) end) end

local ICON_A, ICON_B, ICON_C, ICON_D = 93364949241311, 84750991656135, 100604009889706, 85925158736685

do
    local ok, GU = pcall(function() return require(ReplicatedStorage:WaitForChild("VRBoxingGetUp", 5)) end)
    if ok and type(GU) == "table" and GU.isActive and GU.state and GU.setInput then
        local active, startedAt, lastPos, lastT = false, 0, nil, 0
        local function step()
            if not cfg.getUpOn then
                active = false
                return
            end
            if not GU.isActive() then
                if active then
                    active = false
                    log("back on your feet")
                end
                lastPos = nil
                return
            end
            local st = GU.state()
            if not st then return end
            local now = os.clock()
            if not active then
                active, startedAt, lastPos, lastT = true, now, nil, now
                log("knocked down: auto get-up engaged")
            end
            if now - startedAt < cfg.getUpDelay / 1000 then return end
            local dt = math.max(now - lastT, 1 / 240)
            lastT = now
            local vel = lastPos and (st.pos - lastPos) / dt or 0
            lastPos = st.pos
            local target = (st.zoneMin + st.zoneMax) / 2
            GU.setInput(math.clamp(10 * (target - st.pos) - 2.5 * vel, -1, 1))
        end
        pcall(function() RunService:UnbindFromRenderStep("KairoGetUp") end)
        RunService:BindToRenderStep("KairoGetUp", Enum.RenderPriority.First.Value, function() pcall(step) end)
        onCleanup(function() pcall(function() RunService:UnbindFromRenderStep("KairoGetUp") end) end)
    end
end

local optimizing = false
local function runOptimize(done)
    if optimizing then return end
    optimizing = true
    task.spawn(function()
        local counts = { parts = 0, fx = 0, lights = 0 }
        pcall(function() settings().Rendering.QualityLevel = Enum.QualityLevel.Level01 end)
        pcall(function() settings().Rendering.MeshPartDetailLevel = Enum.MeshPartDetailLevel.Level04 end)
        pcall(function() if setfpscap then setfpscap(0) end end)
        local Lighting = game:GetService("Lighting")
        pcall(function()
            Lighting.GlobalShadows = false
            Lighting.ShadowSoftness = 0
            Lighting.EnvironmentDiffuseScale = 0
            Lighting.EnvironmentSpecularScale = 0
        end)
        local function simplifyLighting(v)
            pcall(function()
                if v:IsA("PostEffect") then v.Enabled = false
                elseif v:IsA("Atmosphere") then v.Density = 0; v.Haze = 0 end
            end)
        end
        for _, v in ipairs(Lighting:GetChildren()) do simplifyLighting(v) end
        pcall(function()
            local t = Workspace.Terrain
            t.Decoration = false
            t.WaterWaveSize = 0
            t.WaterWaveSpeed = 0
            t.WaterReflectance = 0
        end)
        local keepMaterial = { [Enum.Material.Neon] = true, [Enum.Material.Glass] = true, [Enum.Material.ForceField] = true, [Enum.Material.SmoothPlastic] = true }
        local function simplify(d)
            pcall(function()
                if d:IsA("BasePart") then
                    d.CastShadow = false
                    d.Reflectance = 0
                    if not keepMaterial[d.Material] then d.Material = Enum.Material.SmoothPlastic end
                    counts.parts = counts.parts + 1
                elseif d:IsA("ParticleEmitter") then
                    if not d:GetAttribute("KairoFx") then d.Enabled = false; counts.fx = counts.fx + 1 end
                elseif d:IsA("Trail") or d:IsA("Beam") or d:IsA("Smoke") or d:IsA("Fire") or d:IsA("Sparkles") then
                    d.Enabled = false
                    counts.fx = counts.fx + 1
                elseif d:IsA("PointLight") or d:IsA("SpotLight") or d:IsA("SurfaceLight") then
                    d.Enabled = false
                    counts.lights = counts.lights + 1
                end
            end)
        end
        if getgenv and not getgenv().__KairoOptimized then
            getgenv().__KairoOptimized = true
            getgenv().__KairoFpsHooks = {
                Workspace.DescendantAdded:Connect(simplify),
                Lighting.ChildAdded:Connect(simplifyLighting),
            }
        end
        local list = Workspace:GetDescendants()
        for i = 1, #list do
            simplify(list[i])
            if i % 2500 == 0 then task.wait() end
        end
        cfg.fxQuality = "Low"
        if ctl.fxQuality then pcall(function() ctl.fxQuality:Set("Low") end) end
        optimizing = false
        local summary = string.format("Active. %d parts simplified, %d effects and %d lights switched off. Rejoin the game to undo it.", counts.parts, counts.fx, counts.lights)
        log("fps optimizer applied: " .. summary)
        notify("FPS optimizer applied", "Rejoin the game to undo it.")
        if done then pcall(done, summary) end
    end)
end


local applyPreset
window:CreateSection({ name = "Overview" })
local tHome = window:CreateTab({ name = "Home", icon = ICON_A })
tHome:CreateSection({ name = "Kairo.cc  -  v2.7" })
local homeStatus = tHome:CreateText({ name = "Status", text = "Idle - not in a fight." })
local homeRow = tHome:CreateGroup()
homeRow:CreateButton({ name = "Start / stop Auto Fight", callback = function() if ctl.autoFight then ctl.autoFight:Set(not cfg.autoFight) end end })
homeRow:CreateButton({ name = "Apply best config", callback = function() applyPreset("Best (Human Pro)") end })
tHome:CreateText({ name = "Quick start", text = "1. Step into the ring.  2. Pick a built-in config on the Auto Fight tab (Best, Humanized or Very Legit).  3. Switch Auto Fight on.  The bot learns your opponent as the fight goes on." })
tHome:CreateText({ name = "Hotkeys", text = "RightShift menu   |   F6 Auto Fight   |   F7 ESP   |   Delete panic stop. All rebindable in Misc." })
tHome:CreateText({ name = "Updates", text = "Open the Updates tab for the full changelog, newest first." })

local CHANGELOG = {
    { title = "v2.7  -  Outside the ring and player ESP", items = {
        "New Fight outside the ring toggle in Auto Fight: the bot also fights when you are not in a ring, targeting the nearest player within the set range. Off by default.",
        "ESP now works on other players, not only CPUs: box, name, distance, and health and stamina bars when they are fighting.",
        "Player limit slider (1 to 25), a range slider, and a mode: Closest N, Closest only, or Same ring only.",
    } },
    { title = "v2.6  -  Counter windows and dodges", items = {
        "Found how the game's counter system works: a real dodge (slip sideways, pull your head back or duck) opens a one second window where your next punch does about 1.8 to 2 times damage.",
        "Slip and the new Pull defence now drop the guard so the punch actually passes the head, instead of landing on the guard.",
        "The bot detects the moment a counter window opens and throws a heavy punch inside it, learning which punch works best.",
        "Learns which side to slip toward for each of the enemy's hands.",
        "Defence learning now rewards dodges that open counter windows, and the Learning tab shows how many windows opened.",
    } },
    { title = "v2.5  -  Smarter against hard CPUs", items = {
        "The bot now keeps its guard up while throwing punches. Hits taken used to land mostly while the guard was down.",
        "Learns the best fighting distance (close, medium or far) and holds it.",
        "Learns the best moment to attack after an enemy punch and waits for it instead of attacking straight away.",
        "Learns the best counter-punch timing after a block: quick, medium or late.",
        "Shortens combos automatically when later punches keep getting blocked.",
        "Four new toggles for these in the Learning tab.",
    } },
    { title = "v2.4  -  Auto get-up and FPS optimizer", items = {
        "Auto get-up: after a knockout the bot holds the balance indicator in the middle of the zone, so the get-up never fails. Adjustable start delay in Misc.",
        "FPS optimizer button in Misc: lowers render quality, turns off shadows, post effects, particles, trails and lights, and simplifies materials. It needs a second press to confirm and can only be undone by leaving and rejoining.",
        "The optimizer also unlocks the frame rate cap where the executor allows it, and sets Kairo effects to Low quality.",
    } },
    { title = "v2.3  -  Effects and ESP upgrade", items = {
        "New Effects tab: hit sparks, shockwave rings, floating damage numbers, combo counter, enemy hit flash, optional camera shake.",
        "Screen aura that reacts to the fight: brand glow in a fight, orange when the enemy is gassed, red flash when you are hit, slow red pulse when you are low.",
        "Glove aura sparkles and embers rising off an exhausted enemy. Quality setting scales every effect.",
        "ESP upgrades: bar values, damage trail on the health bar, bar tick marks, head marker, punch-side indicator, almost-down status, hit flash, pulsing gassed bar.",
        "All effects use pooled objects and throttled updates, and hide while the menu is open.",
    } },
    { title = "v2.2  -  ESP rebuild and performance", items = {
        "ESP redrawn in a clean flat style: corner or full box, slim health and stamina bars, and clean sans-serif text in title case. The glowing card, gradients, pills and badges are gone.",
        "New ESP options: Box and box style, Health and stamina bars, Name and info text, Guard and style, Distance, Outline highlight, Flash when punching, Off-screen arrow, Tracer, Reach ring, Text size, Colour. The ESP hides itself while the menu is open.",
        "Reach ring is now a light line ring and is off by default.",
        "Fight stats panel simplified to plain text.",
        "Performance: memory scans for the game's state run in small slices across frames instead of one long freeze.",
        "Performance: enemy data is read in one call 20 times a second and shared by the bot, ESP and menu.",
        "Performance: ESP text is rebuilt 12 times a second while the box and bars still follow every frame.",
        "Performance: menu live stats only change when a value changes, and stop entirely while the menu is closed.",
        "Performance: stamina pin runs once per frame, and idle UI work is throttled.",
        "Added this Updates tab. All code comments removed.",
    } },
    { title = "v2.1  -  Stamina and stability", items = {
        "Infinite Stamina pins the game's stamina and cardio directly, so it works everywhere, not only in rings.",
        "No Fatigue and Infinite Stamina stay on across reloads. No Fatigue re-applies itself if the game swaps its state.",
        "Fixed a silent failure where the script passed Luau's 200 local variable limit and stopped reloading.",
        "Defence tracker no longer counts blocked punches as hits.",
        "Finisher keeps a stamina reserve. The bot takes a short shot after a few idle seconds against non-stop punchers.",
    } },
    { title = "v2.0  -  Human layer and boxing IQ", items = {
        "Human layer: reaction curve, focus drift, breathers, aim tremor, turn-speed cap and punch-rate cap.",
        "Opponent rhythm model that fits combos between their punches, plus strafe learning.",
        "Three built-in configs: Best (Human Pro), Humanized and Very Legit. Config export and import.",
        "Home tab with live status.",
    } },
    { title = "v1.x  -  Foundations", items = {
        "Auto-fight bot with combos, defence, counters, footwork and a finisher.",
        "Adaptive learning of combos, aim zone and defence.",
        "Skin changer for gloves and trunks, client side only.",
        "Enemy ESP, fight stats panel, live stats and event log.",
        "No Fatigue and Infinite Stamina.",
        "Rayfield menu branded Kairo.cc with autosaved configs.",
    } },
}
local tUpdates = window:CreateTab({ name = "Updates", icon = ICON_C })
for _, entry in ipairs(CHANGELOG) do
    tUpdates:CreateSection({ name = entry.title })
    tUpdates:CreateText({ text = "- " .. table.concat(entry.items, "\n- ") })
end

window:CreateSection({ name = "Fighting" })
local tFight = window:CreateTab({ name = "Auto Fight", icon = ICON_B })
tFight:CreateSection({ name = "Master" })
tog(tFight, "Auto Fight", "autoFight", "Master switch. Throws punches, defends and moves for you. Bound to a key in Misc.", function(on) if not on then releaseAll() end end, true)
dd(tFight, "Fight style", "style", { "Smart", "Pressure", "Balanced", "Counter" },
    "Smart: attack in openings and when the enemy is gassed. Pressure: never stop. Balanced: only between enemy punches. Counter: only right after they punch.")
tog(tFight, "Fight outside the ring", "fightOutside", "Also auto fights when you are not in a ring. Targets the nearest player within range. Off by default.")
sld(tFight, "Outside target range", "outsideRange", 5, 150, 1, " studs")
tog(tFight, "Pause when cursor is unlocked", "pauseWhenUnlocked", "Stops the bot while a menu is open so it never clicks into your UI.")
local PRESETS = {

    ["Best (Human Pro)"] = {},

    ["Humanized"] = { reactMs = 150, reactJitter = 45, blockChance = 88, jitter = 40, humanFocus = 0.7, humanPauseChance = 0.2, maxCps = 3.6,
        aimSway = 1.0, faceMaxSpeed = 320, faceSpeed = 8, comboPause = 0.75, counterChance = 60, counterDelay = 150, holdPad = 160,
        staminaFloor = 28, interruptChance = 5, learnStrength = 0.55, breathScale = 1.0, strafeMin = 1.1, strafeMax = 2.8 },

    ["Very Legit"] = { reactMs = 185, reactJitter = 50, blockChance = 78, jitter = 45, humanFocus = 0.9, humanPauseChance = 0.28, maxCps = 3.0,
        holdMin = 55, holdMax = 120, aimSway = 1.3, faceMaxSpeed = 240, faceSpeed = 6, faceDeadzone = 5, comboPause = 0.95, counterChance = 45,
        counterDelay = 190, holdPad = 170, staminaFloor = 32, resumeAt = 65, interruptChance = 0, learnStrength = 0.4, explore = 10, defExplore = 10,
        breathScale = 1.2, strafeMin = 1.3, strafeMax = 3.2, finisherBoost = 1.6, finisherSpeed = 0.95, safetyMargin = 0.2 },
}
local PRESET_NAMES = { "Best (Human Pro)", "Humanized", "Very Legit" }
local function setVal(key, v)
    cfg[key] = v
    if ctl[key] then pcall(function() ctl[key]:Set(v) end) end
end
applyPreset = function(name)
    local preset = PRESETS[name]; if not preset then return end
    local keys = {}
    for _, pr in pairs(PRESETS) do for k in pairs(pr) do keys[k] = true end end
    for k in pairs(keys) do setVal(k, preset[k] ~= nil and preset[k] or DEFAULTS[k]) end
    notify("Config applied", name)
    log("config: " .. name)
end
local presetChoice = PRESET_NAMES[1]
tFight:CreateDropdown({ name = "Built-in config", flag = "presetChoice",
    description = "Best (Human Pro): strong but natural. Humanized: slower and looser. Very Legit: plays like a decent club fighter.",
    options = PRESET_NAMES, value = presetChoice, forgetState = true, callback = function(v) presetChoice = v end })
tFight:CreateButton({ name = "Apply built-in config", callback = function() applyPreset(presetChoice) end })
tFight:CreateSection({ name = "Offence" })
sld(tFight, "Punch reach", "punchRange", 3, 10, 0.1, " studs", "Only throw punches when the enemy is closer than this.")
sld(tFight, "Pause between combos", "comboPause", 0.1, 2.5, 0.05, " s")
sld(tFight, "Punch tempo", "speedScale", 0.5, 2, 0.05, "x", "Lower is faster. Multiplies the delay between punches inside a combo.")
sld(tFight, "Timing randomness", "jitter", 0, 80, 1, "%", "Humanises every delay so the rhythm is never identical.")
sld(tFight, "Stamina floor", "staminaFloor", 0, 70, 1, "%", "Stop attacking when your stamina would drop below this.")
sld(tFight, "Resume attacking at", "resumeAt", 20, 100, 1, "%")
sld(tFight, "Max time without attacking", "maxIdle", 0, 10, 0.5, " s", "Against a non-stop puncher the safe windows never come. After this long the bot takes a short shot anyway. 0 = never.")
sld(tFight, "Interrupt jab chance", "interruptChance", 0, 100, 1, "%", "Throws a fast jab while the enemy is still winding up a punch.")
tog(tFight, "Drop guard to punch", "dropGuardToPunch")
tog(tFight, "Punch while guarding", "punchWhileGuard")
tFight:CreateSection({ name = "Finisher" })
tog(tFight, "Finisher mode", "finisherOn", "Goes aggressive with heavy punches when the enemy is gassed or nearly beaten.")
sld(tFight, "Stamina kept in reserve", "finisherReserve", 0, 40, 1, "%", "Even in finisher mode the bot stops short of this so you never gas out.")
sld(tFight, "Enemy stamina trigger", "finisherStam", 0, 50, 1, "%")
sld(tFight, "Enemy head HP trigger", "finisherHead", 0, 100, 1, "%")
sld(tFight, "Heavy punch boost", "finisherBoost", 1, 6, 0.1, "x")
sld(tFight, "Finisher tempo", "finisherSpeed", 0.4, 1.2, 0.05, "x", "Lower is faster.")

local tCombo = window:CreateTab({ name = "Combos", icon = ICON_C })
tCombo:CreateSection({ name = "Combo weights (0 = never)" })
for _, c in ipairs(COMBOS) do sld(tCombo, c.name, c.key, 0, 10, 0.5, "", table.concat(c.steps, " > ")) end
tCombo:CreateSection({ name = "Adaptation" })
sld(tCombo, "Uppercut boost vs high guards", "upperVsGuard", 1, 6, 0.1, "x")
sld(tCombo, "Heavy punches when tired", "heavyWhenTired", 0, 1, 0.05, "x")
sld(tCombo, "Avoid repeating last combo", "antiRepeat", 0, 1, 0.05, "")

local tHuman = window:CreateTab({ name = "Human", icon = ICON_C })
tHuman:CreateSection({ name = "Human layer" })
tog(tHuman, "Human-like behaviour", "humanOn", "Bell-curve reaction times, drifting focus, breathers, aim tremor and a punch-rate cap. Turn off for raw machine speed.")
sld(tHuman, "Focus drift", "humanFocus", 0, 1, 0.05, "", "How much your concentration wanders. Higher means slower, sloppier stretches now and then.")
sld(tHuman, "Breather chance", "humanPauseChance", 0, 0.6, 0.02, " /s", "Chance per second of a short pause in offence, like resetting.")
sld(tHuman, "Max punches per second", "maxCps", 1.5, 8, 0.1, " /s", "A hard cap so punch rate never goes superhuman.")
sld(tHuman, "Key hold (min)", "holdMin", 25, 120, 1, " ms")
sld(tHuman, "Key hold (max)", "holdMax", 40, 200, 1, " ms")
sld(tHuman, "Aim tremor", "aimSway", 0, 3, 0.1, " deg", "Slow drifting wobble in the camera aim.")
sld(tHuman, "Max turn speed", "faceMaxSpeed", 120, 900, 10, " deg/s", "Aim assist can never turn faster than this.")
sld(tHuman, "Breath pacing", "breathScale", 0, 2, 0.05, " s", "Extra rest between combos when your stamina is low.")
tHuman:CreateSection({ name = "Boxing IQ" })
tog(tHuman, "Opponent rhythm model", "predictOn", "Learns how often this opponent punches and only throws combos that fit before their next one.")
sld(tHuman, "Safety margin", "safetyMargin", 0, 0.5, 0.01, " s")
tog(tHuman, "Strafe learning", "strafeLearn", "Learns which way to circle to take less damage against this opponent.")

local tLearn = window:CreateTab({ name = "Learning", icon = ICON_D })
tLearn:CreateSection({ name = "Adaptive AI" })
tog(tLearn, "Adaptive learning", "learnOn", "Tracks the result of every punch and favours the combos that land against this opponent.")
sld(tLearn, "Learning strength", "learnStrength", 0, 1, 0.05, "")
dd(tLearn, "Aim zone", "aimZone", { "Adaptive", "Head", "Body" }, "Adaptive tries head and body and keeps whichever lands more.")
sld(tLearn, "Aim exploration", "explore", 0, 50, 1, "%")
sld(tLearn, "Body aim offset", "chestOffset", -2.5, 0, 0.1)
sld(tLearn, "Defence exploration", "defExplore", 0, 40, 1, "%")
tog(tLearn, "Punch inside counter windows", "windowPunch", "After a successful dodge the game opens a one second window where your next hit does nearly double damage. The bot throws a heavy punch straight away.")
tog(tLearn, "Learn best fighting range", "rangeLearn", "Tries close, medium and far spacing and settles on the distance where punches land most.")
tog(tLearn, "Learn best attack timing", "phaseLearn", "Learns how soon after the enemy punches your attacks land, and waits for those moments.")
tog(tLearn, "Learn combo length", "lenLearn", "Shortens combos when the later punches keep getting blocked.")
tog(tLearn, "Learn counter timing", "counterLearn", "Tests quick, medium and late counter-punches after you defend and keeps the best.")
tog(tLearn, "Reset learning each fight", "resetLearnPerFight", "Every opponent blocks differently, so start fresh against each one.")
tLearn:CreateSection({ name = "What it has learned" })
local learnTxt = tLearn:CreateText({ name = "Summary", text = "Waiting for a fight." })
tLearn:CreateButton({ name = "Reset learning now", callback = function() resetLearning() end })

local tDef = window:CreateTab({ name = "Defence", icon = ICON_A })
tDef:CreateSection({ name = "Auto defence" })
tog(tDef, "Auto defend", "defOn", "Reacts to the game's incoming-punch warning.")
dd(tDef, "Defence mode", "defMode", { "Adaptive", "Guard", "Slip", "Pull", "Backstep", "Smart" },
    "Adaptive learns, per punch type, whether guarding, slipping or backing off works best against this opponent.")
sld(tDef, "Reaction time", "reactMs", 0, 400, 5, " ms")
sld(tDef, "Reaction randomness", "reactJitter", 0, 200, 5, " ms")
sld(tDef, "Defend chance", "blockChance", 0, 100, 1, "%")
sld(tDef, "Guard hold padding", "holdPad", 0, 400, 5, " ms")
sld(tDef, "Respond within", "respondRange", 3, 14, 0.5, " studs")
tog(tDef, "Keep guard up when idle", "guardIdle")
dd(tDef, "Slip direction", "slipDir", { "Away", "Into", "Random" })
sld(tDef, "Slip duration", "slipTime", 100, 600, 10, " ms")
tDef:CreateSection({ name = "Counter-punch" })
tog(tDef, "Counter after defending", "counterOn")
sld(tDef, "Counter chance", "counterChance", 0, 100, 1, "%")
sld(tDef, "Counter delay", "counterDelay", 0, 400, 5, " ms")
sld(tDef, "Counter window", "counterWindow", 0.3, 2.5, 0.05, " s")

local tMove = window:CreateTab({ name = "Movement", icon = ICON_D })
tMove:CreateSection({ name = "Spacing" })
tog(tMove, "Control movement", "moveOn")
sld(tMove, "Closest distance", "idealMin", 2, 8, 0.1, " studs")
sld(tMove, "Farthest distance", "idealMax", 3, 10, 0.1, " studs")
tog(tMove, "Strafe / circle", "strafeOn")
sld(tMove, "Strafe change (min)", "strafeMin", 0.3, 4, 0.1, " s")
sld(tMove, "Strafe change (max)", "strafeMax", 0.5, 6, 0.1, " s")
tog(tMove, "Back off when tired", "retreatLow")
tog(tMove, "Hit and move", "hitMove", "Steps back briefly after each combo so counters miss you.")
sld(tMove, "Step-back time", "hitMoveTime", 0.1, 0.8, 0.02, " s")
tMove:CreateSection({ name = "Aim assist" })
tog(tMove, "Face opponent", "faceOn")
sld(tMove, "Aim speed", "faceSpeed", 1, 25, 0.5)
sld(tMove, "Aim dead-zone", "faceDeadzone", 0, 30, 1, " deg")
sld(tMove, "Aim height offset", "faceYOffset", -3, 2, 0.1)

window:CreateSection({ name = "Visuals" })
local tEsp = window:CreateTab({ name = "Enemy ESP", icon = ICON_B })
tEsp:CreateSection({ name = "Overlay" })
tog(tEsp, "ESP enabled", "espOn")
tEsp:CreateSection({ name = "Other players" })
tog(tEsp, "Player ESP", "espPlayers", "Shows a box, name, distance and health for other players, in and out of the ring. Uses the box, colour and text size settings below.")
dd(tEsp, "Players to show", "espPlayerMode", { "Closest N", "Closest only", "Same ring only" }, "Closest N shows the nearest players up to the limit below. Closest only shows one player. Same ring only shows players in your ring.")
sld(tEsp, "Player limit", "espPlayerCount", 1, 25, 1, " players")
sld(tEsp, "Player range", "espPlayerRange", 25, 1000, 25, " studs")
tog(tEsp, "Player bars", "espPlayerBars", "Health and stamina bars for players who are fighting or hurt.")
tog(tEsp, "Player distance", "espPlayerDist")
tEsp:CreateSection({ name = "Enemy" })
tog(tEsp, "Box", "espBox", "A clean box around the enemy.")
dd(tEsp, "Box style", "boxStyle", { "Corners", "Full" })
tog(tEsp, "Health and stamina bars", "espBars", "Head HP on the left of the box, stamina on the right.")
tog(tEsp, "Name and info text", "espCard", "Name and difficulty above the box, numbers beside it, status below.")
tog(tEsp, "Guard and style", "espGuardInfo", "Adds the enemy's guard and fighting style under their name.")
tog(tEsp, "Distance", "espDistance")
tog(tEsp, "Bar values", "espValues", "Shows the exact head HP and stamina above the bars.")
tog(tEsp, "Head marker", "espHeadDot", "A small ring on the enemy's head so you always know where to aim.")
tog(tEsp, "Damage trail on health bar", "espGhost", "Shows how much health was just lost.")
tog(tEsp, "Outline highlight", "espHighlight", "A clean coloured outline on the enemy's body, visible through walls.")
tog(tEsp, "Flash when punching", "espPulse", "The box flashes red while the enemy is throwing a punch.")
tog(tEsp, "Off-screen arrow", "espOffscreen", "Points to the enemy when they leave your view.")
tog(tEsp, "Tracer line", "tracer")
tog(tEsp, "Reach ring on floor", "rangeRing", "Draws your punch reach on the floor around the enemy. Costs a little performance.")
tEsp:CreateSection({ name = "Colour and size" })
tog(tEsp, "Colour by enemy stamina", "espColorStam", "Green when fresh, red when tired, orange when gassed.")
reg("espColor", tEsp:CreateColorPicker({ name = "Fixed ESP colour", flag = "espColor", color = cfg.espColor, callback = function(c) cfg.espColor = c end }))
sld(tEsp, "Text size", "espScale", 0.7, 1.8, 0.05, "x")
tEsp:CreateSection({ name = "HUD" })
tog(tEsp, "Incoming punch warning", "incomingWarn")
tog(tEsp, "Fight stats panel", "hudOn")

local tFx = window:CreateTab({ name = "Effects", icon = ICON_D })
tFx:CreateSection({ name = "Master" })
tog(tFx, "Effects enabled", "fxOn")
dd(tFx, "Quality", "fxQuality", { "Low", "Medium", "High" }, "Low spawns fewer particles. High is the most spectacular.")
reg("fxColor", tFx:CreateColorPicker({ name = "Effect colour", flag = "fxColor", color = cfg.fxColor, callback = function(c) cfg.fxColor = c end }))
tFx:CreateSection({ name = "Hit effects" })
tog(tFx, "Hit sparks", "fxSparks", "A burst of sparks where your punch lands, and blue sparks on blocks.")
tog(tFx, "Shockwave rings", "fxRings", "An expanding ring on every hit.")
tog(tFx, "Damage numbers", "fxNumbers", "Floating damage on the enemy, and what you take.")
tog(tFx, "Combo counter", "fxCombo", "Counts consecutive hits and pops on screen.")
tog(tFx, "Enemy hit flash", "fxFlash", "The enemy flashes white for a moment when hit.")
sld(tFx, "Impact camera shake", "fxShake", 0, 3, 0.1, "", "0 is off. Keep it low so aim stays steady.")
tFx:CreateSection({ name = "Aura" })
tog(tFx, "Screen aura", "fxAura", "A soft glow around the edges of your screen that reacts to the fight.")
tog(tFx, "Aura outside fights", "fxAuraAlways")
sld(tFx, "Aura strength", "fxAuraStrength", 0.1, 1.5, 0.05, "x")
tog(tFx, "Damage flash and low health pulse", "fxVignette", "Red flash when you are hit and a slow red pulse when you are low.")
tog(tFx, "Glove aura", "fxGlove", "Sparkles trailing from your gloves.")
tog(tFx, "Embers on gassed enemy", "fxEmbers", "Orange embers rise off an exhausted opponent.")

local tLive = window:CreateTab({ name = "Live Stats", icon = ICON_D })
tLive:CreateSection({ name = "Opponent" })
local liveName  = tLive:CreateText({ name = "Opponent", text = "Not in a fight" })
local liveHead  = tLive:CreateProgress({ name = "Head HP", range = { 0, 100 }, value = 0 })
local liveBody  = tLive:CreateProgress({ name = "Body HP", range = { 0, 100 }, value = 0 })
local liveStam  = tLive:CreateProgress({ name = "Enemy stamina", range = { 0, 100 }, value = 0 })
local liveDist  = tLive:CreateText({ name = "Distance", text = "-" })
tLive:CreateSection({ name = "You" })
local liveMe    = tLive:CreateProgress({ name = "Your stamina", range = { 0, 100 }, value = 100 })
local liveBot   = tLive:CreateText({ name = "Bot", text = "off" })
local liveAcc   = tLive:CreateText({ name = "Accuracy", text = "-" })
tLive:CreateSection({ name = "Session" })
local sCoins  = tLive:CreateStat({ name = "Coins gained", value = 0 })
local sRate   = tLive:CreateStat({ name = "Coins / hour", value = 0 })
local sFights = tLive:CreateStat({ name = "Fights", value = 0 })
local sKO     = tLive:CreateStat({ name = "Knockouts", value = 0 })
local sPunch  = tLive:CreateStat({ name = "Punches sent", value = 0 })

local tLog = window:CreateTab({ name = "Log", icon = ICON_C })
tLog:CreateSection({ name = "Events" })
tog(tLog, "Log enemy punches", "logPunches")
tog(tLog, "Notify on fight start / end", "notifyFight")
tog(tLog, "Notify when enemy is gassed", "notifyGassed")
logConsole = tLog:CreateConsole({ name = "Console", text = "kairo.cc ready", height = 220, follow = true, maxLines = 120 })
local logRow = tLog:CreateGroup()
logRow:CreateButton({ name = "Copy", callback = function() pcall(function() logConsole:Copy() end) end })
logRow:CreateButton({ name = "Clear", callback = function() pcall(function() logConsole:Clear() end) end })

window:CreateSection({ name = "Skin Changer" })
local function pickRandom(list) return list[math.random(1, math.max(1, #list))] end
if cfg.gloveChoice == "" then cfg.gloveChoice = Skin.gloves[1] or "" end
if cfg.trunksChoice == "" then cfg.trunksChoice = Skin.trunks[1] or "" end

local tGlove = window:CreateTab({ name = "Gloves", icon = ICON_B })
tGlove:CreateSection({ name = "Glove changer" })
tGlove:CreateText({ name = "Client side only", text = "Changes how your gloves look on your own screen. The server and other players never see it. Turn it off to get your real glove back." })
tog(tGlove, "Enable glove changer", "gloveOn")
if #Skin.gloves > 0 then
    reg("gloveChoice", tGlove:CreateDropdown({ name = "Glove", flag = "gloveChoice", description = "Every glove in the game, by id.", options = Skin.gloves,
        value = cfg.gloveChoice, callback = function(v) cfg.gloveChoice = v end }))
end
local gloveRow = tGlove:CreateGroup()
gloveRow:CreateButton({ name = "Random glove", callback = function()
    local v = pickRandom(Skin.gloves); cfg.gloveChoice = v
    if ctl.gloveOn then ctl.gloveOn:Set(true) end
    if ctl.gloveChoice then pcall(function() ctl.gloveChoice:Set(v) end) end
end })
gloveRow:CreateButton({ name = "Restore real glove", callback = function() if ctl.gloveOn then ctl.gloveOn:Set(false) end end })

local tTrunks = window:CreateTab({ name = "Trunks", icon = ICON_C })
tTrunks:CreateSection({ name = "Trunks changer" })
tTrunks:CreateText({ name = "Client side only", text = "Changes the trunks you see on yourself (customize screen, replays, previews). Others never see it." })
tog(tTrunks, "Enable trunks changer", "trunksOn")
if #Skin.trunks > 0 then
    reg("trunksChoice", tTrunks:CreateDropdown({ name = "Trunks", flag = "trunksChoice", description = "Every trunks skin in the game, by id.", options = Skin.trunks,
        value = cfg.trunksChoice, callback = function(v) cfg.trunksChoice = v end }))
end
local trunkRow = tTrunks:CreateGroup()
trunkRow:CreateButton({ name = "Random trunks", callback = function()
    local v = pickRandom(Skin.trunks); cfg.trunksChoice = v
    if ctl.trunksOn then ctl.trunksOn:Set(true) end
    if ctl.trunksChoice then pcall(function() ctl.trunksChoice:Set(v) end) end
end })
trunkRow:CreateButton({ name = "Restore real trunks", callback = function() if ctl.trunksOn then ctl.trunksOn:Set(false) end end })

local tSkinExtra = window:CreateTab({ name = "Skin Extras", icon = ICON_D })
tSkinExtra:CreateSection({ name = "Automation" })
tog(tSkinExtra, "Random skins every fight", "skinRandomFight", "Picks a new random glove and trunks each time a fight starts (for the changers you have enabled).")
tog(tSkinExtra, "Cycle gloves", "skinCycle", "Steps through every glove in order.")
sld(tSkinExtra, "Cycle speed", "cycleDelay", 1, 20, 0.5, " s")

window:CreateSection({ name = "Player" })
local tMisc = window:CreateTab({ name = "Misc", icon = ICON_A })
tMisc:CreateSection({ name = "Stamina" })
tog(tMisc, "No Fatigue", "noFatigue", "Pins fatigue at zero so your punches never slow down or weaken.", function() applyNoFatigue() end)
tog(tMisc, "Infinite Stamina", "infStamina", "Keeps stamina and cardio full at all times, in rings, the gym and everywhere else.", function() applyInfStamina() end)
tMisc:CreateSection({ name = "Convenience" })
tog(tMisc, "Auto-spar CPU", "autoSpar", "Taps your Spar key whenever you are not in a ring.")
sld(tMisc, "Auto-spar retry delay", "sparDelay", 2, 20, 1, " s")
tog(tMisc, "Anti-AFK", "antiAfk", "Stops Roblox kicking you for idling.")
tog(tMisc, "Custom field of view", "fovOn")
sld(tMisc, "Field of view", "fov", 60, 120, 1, " deg")
tMisc:CreateSection({ name = "Knockout recovery" })
tog(tMisc, "Auto get up after a knockout", "getUpOn", "Holds the balance indicator in the middle of the zone for you while you get back up, so the count never beats you.")
sld(tMisc, "Start delay", "getUpDelay", 0, 400, 5, " ms", "How long to wait after going down before taking over.")
tMisc:CreateSection({ name = "Performance" })
local optText = tMisc:CreateText({ name = "FPS optimizer", text = (getgenv and getgenv().__KairoOptimized) and "Active. Rejoin the game to undo it." or "Not applied." })
local optConfirmAt = 0
tMisc:CreateButton({ name = "Optimize FPS (permanent until you rejoin)", callback = function()
    if getgenv and getgenv().__KairoOptimized then
        notify("Already optimized", "Leave and rejoin the game to undo it.")
        return
    end
    local now = os.clock()
    if now - optConfirmAt > 6 then
        optConfirmAt = now
        notify("Are you sure?", "This cannot be undone without leaving and rejoining. Press the button again within 6 seconds to confirm.")
        return
    end
    optConfirmAt = 0
    runOptimize(function(summary) pcall(optText.Set, optText, summary) end)
end })
tMisc:CreateSection({ name = "Hotkeys" })
local function hotkey(name, default, fn)
    tMisc:CreateKeybind({ name = name, flag = "hk_" .. name, value = default, hold = true, callback = function(down) if down then fn() end end })
end
hotkey("Toggle Auto Fight", Enum.KeyCode.F6, function() if ctl.autoFight then ctl.autoFight:Set(not cfg.autoFight) end end)
hotkey("Toggle ESP", Enum.KeyCode.F7, function() if ctl.espOn then ctl.espOn:Set(not cfg.espOn) end end)
hotkey("Panic (stop bot)", Enum.KeyCode.Delete, function()
    if ctl.autoFight then ctl.autoFight:Set(false) end
    cfg.autoFight = false; releaseAll(); notify("Panic", "Auto Fight stopped, keys released.")
end)
tMisc:CreateSection({ name = "Config" })
local CONFIG_DIR = "Kairo"
local cfgName = "my_config"
local function cfgPath(n) return CONFIG_DIR .. "/" .. n .. ".json" end
local function serializable(k, v)
    return k ~= "autoFight" and (type(v) == "number" or type(v) == "string" or type(v) == "boolean")
end
local function exportCfg(n)
    if not (writefile and makefolder) then return false end
    pcall(makefolder, CONFIG_DIR)
    local out = {}
    for k, v in pairs(cfg) do
        if serializable(k, v) then out[k] = v end
    end
    return pcall(writefile, cfgPath(n), HttpService:JSONEncode(out))
end
local function importCfg(n)
    if not (readfile and isfile and isfile(cfgPath(n))) then return false end
    local ok, data = pcall(function() return HttpService:JSONDecode(readfile(cfgPath(n))) end)
    if not ok or type(data) ~= "table" then return false end
    for k, v in pairs(data) do if k ~= "autoFight" and cfg[k] ~= nil and type(v) == type(cfg[k]) then setVal(k, v) end end
    return true
end
tMisc:CreateInput({ name = "Config file name", placeholder = "my_config", value = cfgName, callback = function(v)
    local clean = tostring(v):gsub("[^%w_%-]", "")
    cfgName = clean ~= "" and clean or "my_config"
end })
local cfgRow = tMisc:CreateGroup()
cfgRow:CreateButton({ name = "Export to file", callback = function() local ok = exportCfg(cfgName); notify(ok and "Exported" or "Export failed", ok and ("Saved as " .. cfgPath(cfgName)) or "Your executor has no file access.") end })
cfgRow:CreateButton({ name = "Import from file", callback = function() local ok = importCfg(cfgName); notify(ok and "Imported" or "Import failed", ok and cfgName or ("No file " .. cfgPath(cfgName))) end })

task.spawn(function()
    if not (writefile and isfile and makefolder) then return end
    pcall(makefolder, CONFIG_DIR)
    for _, name in ipairs(PRESET_NAMES) do
        local file = cfgPath(name:gsub("[^%w]+", "_"))
        if not isfile(file) then
            local out = {}
            for k, v in pairs(DEFAULTS) do
                local value = PRESETS[name][k]
                if value == nil then value = v end
                if serializable(k, value) then out[k] = value end
            end
            pcall(writefile, file, HttpService:JSONEncode(out))
        end
    end
end)
tMisc:CreateText({ name = "Saving", text = "Every setting autosaves and reloads next time. Named configs live in the settings page (gear icon, top right)." })
tMisc:CreateButton({ name = "Save now", callback = function()
    local ok = pcall(function() window:Save() end)
    notify(ok and "Saved" or "Autosave is on", ok and "Configuration saved." or "Your settings save automatically.")
end })
tMisc:CreateButton({ name = "Reset every setting to default", callback = function()
    for key, el in pairs(ctl) do
        if DEFAULTS[key] ~= nil then pcall(function() el:Set(DEFAULTS[key]) end) end
    end
    notify("Reset", "All settings are back to their defaults.")
end })
tMisc:CreateButton({ name = "Unload Kairo.cc", callback = function() if getgenv and getgenv().__Kairo then getgenv().__Kairo() end end })

pcall(function()
    local VU = game:GetService("VirtualUser")
    track(lp.Idled:Connect(function()
        if cfg.antiAfk then VU:CaptureController(); VU:ClickButton2(Vector2.new()) end
    end))
end)

local baseFov
RunService:BindToRenderStep("KairoFov", Enum.RenderPriority.Camera.Value + 3, function()
    local cam = Workspace.CurrentCamera
    if not cam then return end
    if cfg.fovOn then
        baseFov = baseFov or cam.FieldOfView
        cam.FieldOfView = cfg.fov
    elseif baseFov then
        cam.FieldOfView = baseFov; baseFov = nil
    end
end)
onCleanup(function() pcall(function() RunService:UnbindFromRenderStep("KairoFov") end) end)

local Sess = { t0 = os.clock(), coins0 = lp:GetAttribute("Coins") or 0, fights = 0, kos = 0, inFight = false, enemyKO = false, gassedNotified = 0, shown = {} }
local function put(key, el, value)
    if Sess.shown[key] ~= value then
        Sess.shown[key] = value
        pcall(el.Set, el, value)
    end
end
local function putProg(key, el, frac) put(key, el, math.floor(math.clamp(frac, 0, 1) * 100 + 0.5)) end
local lastLive = 0
track(RunService.Heartbeat:Connect(function()
    local now = os.clock()
    if now - lastLive < 0.25 then return end
    lastLive = now
    local f = fighting()
    if f and not Sess.inFight then
        Sess.inFight = true; Sess.fights += 1; Sess.enemyKO = false
        if cfg.skinRandomFight then
            Skin.randomize()
            pcall(function()
                if ctl.gloveChoice and cfg.gloveOn then ctl.gloveChoice:Set(cfg.gloveChoice) end
                if ctl.trunksChoice and cfg.trunksOn then ctl.trunksChoice:Set(cfg.trunksChoice) end
            end)
        end
        log("fight started vs " .. tostring(enemyAttr("DisplayName", "?")))
        if cfg.notifyFight then notify("Fight started", tostring(enemyAttr("DisplayName", "Opponent"))) end
    elseif not f and Sess.inFight then
        Sess.inFight = false
        log("fight ended")
        if cfg.notifyFight then notify("Fight ended", string.format("Accuracy %s", pct(lp:GetAttribute("RingLanded") or 0, lp:GetAttribute("RingThrown") or 0))) end
    end
    if E.model and enemyAttr("BoxKO", false) == true and not Sess.enemyKO then
        Sess.enemyKO = true; Sess.kos += 1; log("enemy knocked out"); if cfg.notifyFight then notify("KNOCKOUT", "Enemy is down.") end
    end
    if f and enemyGassed() and now - Sess.gassedNotified > 6 then
        Sess.gassedNotified = now; log("enemy is gassed")
        if cfg.notifyGassed then notify("Enemy gassed", "Press the attack.") end
    end
    if window.hidden or window.minimised then return end
    local coins = (lp:GetAttribute("Coins") or 0) - Sess.coins0
    local th, ld = lp:GetAttribute("RingThrown") or 0, lp:GetAttribute("RingLanded") or 0
    put("coins", sCoins, coins)
    put("rate", sRate, math.floor(coins / math.max(1, now - Sess.t0) * 3600))
    put("fights", sFights, Sess.fights)
    put("kos", sKO, Sess.kos)
    put("punches", sPunch, Bot.punches)
    putProg("me", liveMe, myStam())
    put("bot", liveBot, Bot.state .. (Bot.combo and (" - " .. Bot.comboName) or ""))
    put("home", homeStatus, string.format("Auto %s  |  %s%s  |  %s", cfg.autoFight and "ON" or "off", Bot.state, Bot.combo and (" - " .. Bot.comboName) or "",
        f and (cleanName(enemyAttr("DisplayName", "?")) .. "  (hit rate " .. (L.tot.n > 0 and string.format("%d%%", L.tot.hit / L.tot.n * 100) or "-") .. ")") or "no fight"))
    put("learn", learnTxt, learnSummary())
    put("acc", liveAcc, string.format("you %s (%d/%d)   enemy %s", pct(ld, th), ld, th, pct(enemyAttr("AILanded", 0), enemyAttr("AIThrown", 0))))
    if f then
        local mx = tonumber(enemyAttr("MaxHP", 100)) or 100
        put("name", liveName, string.format("%s  |  %s  |  %s", tostring(enemyAttr("DisplayName", "?")), tostring(enemyAttr("AIGuard", "?")), tostring(enemyAttr("AIDiff", "?"))))
        putProg("head", liveHead, (tonumber(enemyAttr("HeadHP", mx)) or mx) / mx)
        putProg("body", liveBody, (tonumber(enemyAttr("BodyHP", mx)) or mx) / mx)
        putProg("stam", liveStam, enemyStam() or 0)
        put("dist", liveDist, string.format("%.1f studs", E.dist))
    else
        put("name", liveName, "Not in a fight")
        put("dist", liveDist, "-")
        putProg("head", liveHead, 0)
        putProg("body", liveBody, 0)
        putProg("stam", liveStam, 0)
    end
end))

if net and net:FindFirstChild("PunchStart") then
    track(net.PunchStart.OnClientEvent:Connect(function(who, hand, kind, flag)
        if cfg.logPunches and who == E.model and flag ~= true then log(string.format("enemy %s (%s)", tostring(kind), hand == 1 and "L" or "R")) end
    end))
end

window:Navigate("Home")
notify("Kairo.cc v2.7", "Loaded. Press RightShift to open the menu.")

applyNoFatigue(); applyInfStamina()

if getgenv then
    getgenv().__Kairo = function()
        cfg.autoFight = false
        for _, c in ipairs(conns) do pcall(function() c:Disconnect() end) end
        for i = #cleanups, 1, -1 do pcall(cleanups[i]) end
        pcall(function() window:Unload() end)
    end
end
print("[Kairo.cc] v2.0 loaded. RightShift = menu")
