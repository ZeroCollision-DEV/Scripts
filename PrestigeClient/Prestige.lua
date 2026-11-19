local Players = game:GetService("Players")
local UIS = game:GetService("UserInputService")
local RS = game:GetService("RunService")
local HttpService = game:GetService("HttpService")
local TweenService = game:GetService("TweenService")
local Lighting = game:GetService("Lighting")
local LP = Players.LocalPlayer
pcall(setthreadidentity, 8)

if getgenv().PrestigeLauncher then pcall(getgenv().PrestigeLauncher.close, true) end

local RAW = "https://raw.githubusercontent.com/ZeroCollision-DEV/Scripts/main/PrestigeClient/"
local ASSETS = "https://cdn.jsdelivr.net/gh/ZeroCollision-DEV/Scripts@main/PrestigeClient/assets/"
local ROOT = "PrestigeClient"
local PLACE = 76870565041704
local LAUNCHER_BUILD = "1.0.0"
local DEV_CLIENT, DEV_MANIFEST = ROOT .. "/_dev_client.lua", ROOT .. "/_dev_manifest.json"
local function localFile(g, path)
    if g then return g end
    local ok, has = pcall(isfile, path)
    return ok and has and path or nil
end

local manifest = {
    version = "2.0",
    clientUrl = "https://github.com/ZeroCollision-DEV/Scripts/releases/download/prestige-client-v2.0/PrestigeClient.obfuscated.lua",
    changelog = {
        client = {
            { tags = { "CLIENT", "MAJOR UPDATE" }, date = "2026-11-14", title = "Prestige Client 2.0", summary = "The first public build of the Roblox edition.",
              items = { "Hit Sound dropdown with 25 sounds", "Icons and sounds load from GitHub", "Combat, Mace, Misc, Movement, Spear and Visual tabs", "25 built-in themes" } },
        },
        loader = {
            { tags = { "LAUNCHER", "NEW FEATURES" }, date = "2026-11-18", title = "Prestige Launcher", summary = "Boot to the launcher, then inject when you are ready.",
              items = { "Launch, Changelog and Account pages", "Release notes are fetched from GitHub" } },
        },
    },
    offline = true,
}

local C = {
    win = Color3.fromRGB(8, 9, 24), bar = Color3.fromRGB(10, 11, 28), card = Color3.fromRGB(13, 14, 38), row = Color3.fromRGB(12, 13, 33),
    stroke = Color3.fromRGB(33, 34, 66), strokeHi = Color3.fromRGB(70, 62, 170), pill = Color3.fromRGB(40, 36, 100),
    acc = Color3.fromRGB(98, 80, 226), acc2 = Color3.fromRGB(168, 150, 255), accHi = Color3.fromRGB(116, 98, 244),
    text = Color3.fromRGB(236, 236, 248), sub = Color3.fromRGB(128, 130, 168), dim = Color3.fromRGB(84, 86, 122),
    green = Color3.fromRGB(52, 196, 120), greenBg = Color3.fromRGB(14, 52, 44), amber = Color3.fromRGB(236, 176, 64), red = Color3.fromRGB(240, 96, 104),
}
local UIF = "rbxasset://fonts/families/GothamSSm.json"
local SERIF = "rbxasset://fonts/families/Merriweather.json"
local F = {
    reg = Font.new(UIF, Enum.FontWeight.Medium), semi = Font.new(UIF, Enum.FontWeight.SemiBold), bold = Font.new(UIF, Enum.FontWeight.Bold),
    serif = Font.new(SERIF, Enum.FontWeight.Bold), serifI = Font.new(SERIF, Enum.FontWeight.Bold, Enum.FontStyle.Italic),
    mono = Font.fromEnum(Enum.Font.Code),
}

local function ident() pcall(setthreadidentity, 8) end
local function new(class, props, parent)
    local o = Instance.new(class)
    for k, v in pairs(props) do o[k] = v end
    o.Parent = parent
    return o
end
local function tween(inst, props, t, style, dir)
    local tw = TweenService:Create(inst, TweenInfo.new(t or 0.16, style or Enum.EasingStyle.Quint, dir or Enum.EasingDirection.Out), props)
    tw:Play()
    return tw
end
local function round(inst, r) return new("UICorner", { CornerRadius = UDim.new(0, r) }, inst) end
local function stroke(inst, col, th, tr) return new("UIStroke", { Color = col or C.stroke, Thickness = th or 1, Transparency = tr or 0, ApplyStrokeMode = Enum.ApplyStrokeMode.Border }, inst) end
local function frame(parent, x, y, w, h, col, props)
    props = props or {}
    props.Position = UDim2.fromOffset(x, y)
    props.Size = UDim2.fromOffset(w, h)
    props.BackgroundColor3 = col or C.card
    props.BackgroundTransparency = props.BackgroundTransparency or (col and 0 or 1)
    props.BorderSizePixel = 0
    return new("Frame", props, parent)
end
local function text(parent, str, x, y, w, h, size, col, font, align, extra)
    local p = {
        BackgroundTransparency = 1, Text = str, TextSize = size, TextColor3 = col or C.text, FontFace = font or F.reg,
        Position = UDim2.fromOffset(x, y), Size = UDim2.fromOffset(w, h), TextXAlignment = align or Enum.TextXAlignment.Left,
        TextYAlignment = Enum.TextYAlignment.Center, TextTruncate = Enum.TextTruncate.AtEnd,
    }
    if extra then for k, v in pairs(extra) do p[k] = v end end
    return new("TextLabel", p, parent)
end
local function button(parent, x, y, w, h, col, onClick)
    local b = new("TextButton", {
        Position = UDim2.fromOffset(x, y), Size = UDim2.fromOffset(w, h), BackgroundColor3 = col, BorderSizePixel = 0, Text = "",
        AutoButtonColor = false, ClipsDescendants = true,
    }, parent)
    if onClick then b.MouseButton1Click:Connect(function() ident(); onClick() end) end
    return b
end

local function httpGet(url)
    local ok, body = pcall(game.HttpGet, game, url)
    if ok and type(body) == "string" and #body > 0 then return body end
    local fn = (syn and syn.request) or (http and http.request) or request or http_request
    if fn then
        local ok2, res = pcall(fn, { Url = url, Method = "GET" })
        if ok2 and res and (res.Success == nil or res.Success) and res.StatusCode ~= 404 and res.Body and #res.Body > 0 then return res.Body end
    end
    return nil
end
local function asset(name)
    local ok, id = pcall(function()
        local path = ROOT .. "/icons/" .. name .. ".png"
        if not isfile(path) then
            if not isfolder(ROOT) then makefolder(ROOT) end
            if not isfolder(ROOT .. "/icons") then makefolder(ROOT .. "/icons") end
            local bytes = httpGet(ASSETS .. name .. ".png")
            if not bytes then return "" end
            writefile(path, bytes)
        end
        return getcustomasset(path)
    end)
    return ok and id or ""
end

local guiParent = (gethui and gethui()) or game:GetService("CoreGui")
local gui = new("ScreenGui", { Name = HttpService:GenerateGUID(false), ResetOnSpawn = false, IgnoreGuiInset = true, DisplayOrder = 1000, ZIndexBehavior = Enum.ZIndexBehavior.Sibling }, guiParent)
local dim = new("Frame", { Size = UDim2.fromScale(1, 1), BackgroundColor3 = Color3.fromRGB(2, 3, 10), BackgroundTransparency = 1, BorderSizePixel = 0, Active = true }, gui)
local blur = new("BlurEffect", { Name = HttpService:GenerateGUID(false), Size = 0 }, Lighting)
local win = new("CanvasGroup", { AnchorPoint = Vector2.new(0.5, 0.5), Position = UDim2.fromScale(0.5, 0.5), Size = UDim2.fromOffset(980, 590), BackgroundColor3 = C.win, BorderSizePixel = 0, GroupTransparency = 1 }, gui)
round(win, 16)
stroke(win, C.stroke, 1)
local scale = new("UIScale", { Scale = 1 }, win)
local function fit()
    local cam = workspace.CurrentCamera
    local vp = cam and cam.ViewportSize or Vector2.new(1280, 720)
    scale.Scale = math.clamp(math.min(vp.X / 1060, vp.Y / 660), 0.5, 1.25)
end
pcall(fit)

local conns, alive, injected, injecting = {}, true, false, false
local function on(sig, fn) local c = sig:Connect(fn); conns[#conns + 1] = c; return c end
local Launcher = {}
getgenv().PrestigeLauncher = Launcher

local mouseFreed = false
local function freeMouse(on_)
    pcall(function() RS:UnbindFromRenderStep("PrestigeLauncherMouse") end)
    if on_ then
        RS:BindToRenderStep("PrestigeLauncherMouse", Enum.RenderPriority.Last.Value + 2, function()
            UIS.MouseBehavior = Enum.MouseBehavior.Default
            UIS.MouseIconEnabled = true
        end)
    end
    pcall(function()
        local I = require(LP.PlayerScripts.MC.Input)
        if on_ then I.mouseFree = true; mouseFreed = true elseif mouseFreed then I.mouseFree = false; mouseFreed = false end
    end)
end

local function checkIcon(parent, x, y, size, ring)
    local box = frame(parent, x, y, size, size, ring and C.greenBg or nil)
    if ring then round(box, size) stroke(box, C.green, 1, 0.35) end
    local k = size / 18
    local function bar(w, h, cx, cy, rot)
        local b = frame(box, 0, 0, w * k, h * k, C.green)
        b.AnchorPoint = Vector2.new(0.5, 0.5)
        b.Position = UDim2.fromOffset(cx * k, cy * k)
        b.Rotation = rot
        round(b, 1)
    end
    bar(2, 4.6, 6.6, 11, -45)
    bar(2, 8.4, 10.8, 9.4, 45)
    return box
end
local function minusIcon(parent, x, y, size)
    local box = frame(parent, x, y, size, size, Color3.fromRGB(18, 19, 44))
    round(box, size)
    stroke(box, C.stroke, 1)
    local b = frame(box, 0, 0, size * 0.4, 2, C.dim)
    b.AnchorPoint = Vector2.new(0.5, 0.5)
    b.Position = UDim2.fromScale(0.5, 0.5)
    return box
end

local titleBar = frame(win, 0, 0, 980, 38, C.bar, { ZIndex = 5 })
frame(win, 0, 38, 980, 1, C.stroke, { ZIndex = 5 })
local logoWrap = frame(titleBar, 14, 7, 24, 24, Color3.fromRGB(30, 28, 76), { ZIndex = 6 })
round(logoWrap, 12)
local logo = new("ImageLabel", { BackgroundTransparency = 1, Size = UDim2.fromOffset(16, 16), Position = UDim2.fromOffset(4, 4), ImageColor3 = C.acc2, ZIndex = 7 }, logoWrap)
task.spawn(function()
    ident()
    local id = asset("v3_logo")
    if alive and id ~= "" then logo.Image = id end
end)
text(titleBar, "Prestige", 46, 0, 120, 38, 13, C.text, F.semi, nil, { ZIndex = 6 })

local pages, tabBtns, curTab = {}, {}, "launch"
local function setTab(name)
    curTab = name
    for k, p in pairs(pages) do p.Visible = (k == name) end
    for k, t in pairs(tabBtns) do
        tween(t.bg, { BackgroundTransparency = k == name and 0 or 1 }, 0.16)
        t.lbl.TextColor3 = k == name and C.text or C.sub
    end
end
do
    local defs = { { "launch", "Launch", 70 }, { "changelog", "Changelog", 92 }, { "account", "Account", 78 } }
    local total = 0
    for _, d in ipairs(defs) do total += d[3] end
    total += 18 * (#defs - 1)
    local x = 490 - total / 2
    for i, d in ipairs(defs) do
        local b = button(titleBar, x, 6, d[3], 26, C.pill, function() setTab(d[1]) end)
        b.ZIndex = 6
        b.BackgroundTransparency = 1
        round(b, 8)
        local l = text(b, d[2], 0, 0, d[3], 26, 12, C.sub, F.semi, Enum.TextXAlignment.Center, { ZIndex = 7 })
        tabBtns[d[1]] = { bg = b, lbl = l }
        b.MouseEnter:Connect(function() if curTab ~= d[1] then l.TextColor3 = C.text end end)
        b.MouseLeave:Connect(function() if curTab ~= d[1] then l.TextColor3 = C.sub end end)
        x += d[3]
        if i < #defs then
            local dot = frame(titleBar, x + 8, 17, 3, 3, C.dim, { ZIndex = 6 })
            round(dot, 2)
            x += 18
        end
    end
end

local pill
local function minimize(on_)
    if not alive then return end
    if on_ then
        tween(win, { GroupTransparency = 1 }, 0.16)
        tween(dim, { BackgroundTransparency = 1 }, 0.16)
        tween(blur, { Size = 0 }, 0.16)
        task.delay(0.18, function() if alive then win.Visible = false; dim.Active = false; pill.Visible = true end end)
        freeMouse(false)
    else
        pill.Visible = false
        win.Visible = true
        dim.Active = true
        tween(win, { GroupTransparency = 0 }, 0.2)
        tween(dim, { BackgroundTransparency = 0.45 }, 0.2)
        tween(blur, { Size = 10 }, 0.2)
        freeMouse(true)
    end
end
local function windowBtn(x, glyph, fn)
    local b = button(titleBar, x, 5, 28, 28, C.bar, fn)
    b.ZIndex = 6
    b.BackgroundTransparency = 1
    round(b, 8)
    b.MouseEnter:Connect(function() tween(b, { BackgroundTransparency = 0.6 }, 0.1) end)
    b.MouseLeave:Connect(function() tween(b, { BackgroundTransparency = 1 }, 0.12) end)
    return b
end
do
    local mb = windowBtn(906, "-", function() minimize(true) end)
    local mline = frame(mb, 8, 13, 12, 2, C.sub, { ZIndex = 7 })
    round(mline, 1)
    local xb = windowBtn(938, "x", function() Launcher.close() end)
    for _, rot in ipairs({ 45, -45 }) do
        local l = frame(xb, 0, 0, 13, 2, C.sub, { ZIndex = 7 })
        l.AnchorPoint = Vector2.new(0.5, 0.5)
        l.Position = UDim2.fromScale(0.5, 0.5)
        l.Rotation = rot
        round(l, 1)
    end
end

do
    local dragging, start, origin
    titleBar.InputBegan:Connect(function(i)
        if i.UserInputType == Enum.UserInputType.MouseButton1 then
            dragging = true
            start = UIS:GetMouseLocation()
            origin = win.Position
        end
    end)
    on(UIS.InputEnded, function(i) if i.UserInputType == Enum.UserInputType.MouseButton1 then dragging = false end end)
    on(UIS.InputChanged, function(i)
        if dragging and i.UserInputType == Enum.UserInputType.MouseMovement then
            local d = (UIS:GetMouseLocation() - start) / scale.Scale
            win.Position = UDim2.new(origin.X.Scale, origin.X.Offset + d.X, origin.Y.Scale, origin.Y.Offset + d.Y)
        end
    end)
end

pill = button(gui, 18, 18, 120, 34, C.bar, function() minimize(false) end)
pill.Visible = false
round(pill, 17)
stroke(pill, C.strokeHi, 1)
text(pill, "Prestige", 0, 0, 120, 34, 13, C.text, F.semi, Enum.TextXAlignment.Center)

local function segmented(parent, x, y, labelA, labelB, onPick)
    local wrap = frame(parent, x, y, 223, 54, Color3.fromRGB(10, 11, 30))
    round(wrap, 27)
    stroke(wrap, C.stroke, 1)
    local sel = frame(wrap, 6, 6, 105, 42, Color3.fromRGB(38, 34, 98))
    round(sel, 21)
    stroke(sel, C.strokeHi, 1)
    local opts = {}
    for i, name in ipairs({ labelA, labelB }) do
        local b = button(wrap, 6 + (i - 1) * 106, 6, 105, 42, C.pill, function()
            tween(sel, { Position = UDim2.fromOffset(6 + (i - 1) * 106, 6) }, 0.2)
            for j, o in ipairs(opts) do o.TextColor3 = j == i and C.text or C.sub end
            onPick(i)
        end)
        b.BackgroundTransparency = 1
        local l = text(b, name, 0, 0, 105, 42, 13, i == 1 and C.text or C.sub, F.semi, Enum.TextXAlignment.Center)
        opts[i] = l
    end
    return wrap
end

local function isSupported() return game.PlaceId == PLACE end
local function clientRunning()
    local h = getgenv().PrestigeClient
    return h and h.alive and true or false
end

local statusChipText, statusDot, injectBtn, injectLbl, injectFill, footText, footDot, buildLbl
local logBox, logCount = nil, 0
local logLines = {}
local function addLog(msg, kind)
    local line = { os.date("%H:%M:%S"), msg, kind }
    logLines[#logLines + 1] = line
    if logBox then
        logCount += 1
        new("TextLabel", {
            LayoutOrder = logCount, BackgroundTransparency = 1, Size = UDim2.new(1, -10, 0, 16), FontFace = F.mono, TextSize = 12,
            TextXAlignment = Enum.TextXAlignment.Left, TextTruncate = Enum.TextTruncate.AtEnd,
            TextColor3 = kind == "err" and C.red or (kind == "ok" and C.green or C.sub), Text = line[1] .. "  " .. msg,
        }, logBox)
        task.defer(function()
            if logBox and logBox.Parent then logBox.CanvasPosition = Vector2.new(0, math.max(0, logBox.AbsoluteCanvasSize.Y - logBox.AbsoluteSize.Y)) end
        end)
    end
end

local launchPage = frame(win, 0, 39, 980, 551, nil, { ClipsDescendants = true })
pages.launch = launchPage
local clientView = frame(launchPage, 0, 0, 980, 551, nil)
local injView = frame(launchPage, 0, 0, 980, 551, nil, { Visible = false })
segmented(launchPage, 378, 21, "Client", "Injection", function(i)
    clientView.Visible = i == 1
    injView.Visible = i == 2
end)

local function card(parent, x, y, w, h)
    local c = frame(parent, x, y, w, h, Color3.new(1, 1, 1))
    round(c, 18)
    stroke(c, C.stroke, 1)
    new("UIGradient", { Rotation = 90, Color = ColorSequence.new(Color3.fromRGB(16, 16, 44), Color3.fromRGB(11, 12, 32)) }, c)
    return c
end

local clientCard = card(clientView, 30, 91, 920, 450)
local appIcon = frame(clientView, 56, 117, 36, 36, C.acc)
round(appIcon, 10)
do
    local o = frame(appIcon, 0, 0, 18, 18, nil)
    o.AnchorPoint = Vector2.new(0.5, 0.5); o.Position = UDim2.fromScale(0.5, 0.5)
    round(o, 9); stroke(o, Color3.new(1, 1, 1), 2)
    local i = frame(appIcon, 0, 0, 6, 6, Color3.new(1, 1, 1))
    i.AnchorPoint = Vector2.new(0.5, 0.5); i.Position = UDim2.fromScale(0.5, 0.5)
    round(i, 3)
end
local chip = frame(clientView, 102, 121, 190, 28, Color3.fromRGB(24, 22, 62))
round(chip, 14)
stroke(chip, C.strokeHi, 1, 0.3)
statusDot = frame(chip, 12, 11, 6, 6, C.green)
round(statusDot, 3)
statusChipText = text(chip, "Checking game", 26, 0, 160, 28, 11, C.acc2, F.semi)

text(clientView, "Prestige", 56, 170, 400, 56, 44, C.text, F.serif, nil, { TextTruncate = Enum.TextTruncate.None })
text(clientView, "Client", 56, 224, 400, 56, 44, C.acc2, F.serifI, nil, { TextTruncate = Enum.TextTruncate.None })
local sup = frame(clientView, 56, 292, 76, 22, nil)
round(sup, 6)
stroke(sup, C.stroke, 1)
text(sup, "SUPPORTED", 0, 0, 76, 22, 9, C.sub, F.semi, Enum.TextXAlignment.Center)
text(clientView, "Unstable SMP FFA [JAVA PVP!]", 142, 292, 330, 22, 11, C.sub, F.reg)
text(clientView, "A focused competitive client built for Unstable SMP FFA: 49 modules, shareable configs and a clean, themeable menu.", 56, 326, 420, 54, 13, C.sub, F.reg, nil, { TextWrapped = true, TextYAlignment = Enum.TextYAlignment.Top, TextTruncate = Enum.TextTruncate.None })

footDot = frame(clientView, 58, 449, 6, 6, C.green)
round(footDot, 3)
footText = text(clientView, "Injects into this game session", 70, 442, 400, 20, 11, C.sub, F.reg)

injectBtn = button(clientView, 56, 470, 437, 52, C.acc)
round(injectBtn, 12)
stroke(injectBtn, C.accHi, 1, 0.5)
injectFill = frame(injectBtn, 0, 0, 0, 52, Color3.fromRGB(150, 132, 255), { BackgroundTransparency = 0.55 })
injectLbl = text(injectBtn, "Inject Prestige Client  \xE2\x86\x92", 0, 0, 437, 52, 14, Color3.new(1, 1, 1), F.semi, Enum.TextXAlignment.Center, { ZIndex = 3 })
injectBtn.MouseEnter:Connect(function() if not injecting then tween(injectBtn, { BackgroundColor3 = C.accHi }, 0.12) end end)
injectBtn.MouseLeave:Connect(function() tween(injectBtn, { BackgroundColor3 = C.acc }, 0.14) end)

text(clientView, "INCLUDED CAPABILITIES", 520, 117, 260, 16, 10, C.sub, F.semi)
buildLbl = text(clientView, "BUILD " .. manifest.version, 780, 117, 150, 16, 10, C.sub, F.semi, Enum.TextXAlignment.Right)
local included = { "49 modules across 6 tabs", "25 themes plus a custom colour editor", "Config sharing and public configs", "Friends protection and 25 hit sounds" }
for i, s in ipairs(included) do
    local r = frame(clientView, 520, 141 + (i - 1) * 35, 420, 30, C.row)
    round(r, 9)
    stroke(r, C.stroke, 1)
    checkIcon(r, 10, 6, 18, true)
    text(r, s, 38, 0, 370, 30, 12, C.text, F.reg)
end
text(clientView, "NOT INCLUDED IN THIS EDITION", 520, 292, 300, 14, 9, C.dim, F.semi)
for i, s in ipairs({ "Friends protection for projectiles", "Automatic updates (run the launcher again)" }) do
    local r = frame(clientView, 520, 310 + (i - 1) * 35, 420, 30, C.row, { BackgroundTransparency = 0.3 })
    round(r, 9)
    stroke(r, C.stroke, 1, 0.3)
    minusIcon(r, 10, 6, 18)
    text(r, s, 38, 0, 370, 30, 12, C.dim, F.reg)
end
local chan = frame(clientView, 520, 453, 420, 69, C.row)
round(chan, 12)
stroke(chan, C.stroke, 1)
text(chan, "Update channel", 16, 12, 260, 18, 12, C.text, F.semi)
local chanSub = text(chan, "Stable  \xC2\xB7  checking GitHub", 16, 33, 280, 18, 10, C.sub, F.reg)
local clBtn = button(chan, 304, 19, 100, 30, Color3.fromRGB(14, 15, 38), function() setTab("changelog") end)
round(clBtn, 9)
stroke(clBtn, C.stroke, 1)
text(clBtn, "Changelog", 0, 0, 100, 30, 11, C.text, F.semi, Enum.TextXAlignment.Center)

local function refreshStatus()
    local running = clientRunning()
    local sup_ = isSupported()
    if running then
        statusChipText.Text = "Client already injected"; statusDot.BackgroundColor3 = C.acc2
        injectLbl.Text = "Re-inject Prestige Client  \xE2\x86\x92"
    elseif sup_ then
        statusChipText.Text = "Game detected"; statusDot.BackgroundColor3 = C.green
    else
        statusChipText.Text = "Unsupported game"; statusDot.BackgroundColor3 = C.amber
    end
    footDot.BackgroundColor3 = sup_ and C.green or C.amber
    footText.Text = sup_ and "Injects into this game session" or "Not Unstable SMP FFA: only the menu will work"
end
refreshStatus()

local envCard = card(injView, 30, 91, 440, 450)
text(injView, "ENVIRONMENT", 56, 112, 300, 16, 10, C.sub, F.semi)
local envRows = {}
local function runChecks()
    for _, r in ipairs(envRows) do r:Destroy() end
    envRows = {}
    local exName = "Unknown"
    pcall(function() exName = tostring((identifyexecutor and identifyexecutor()) or "Unknown") end)
    local checks = {
        { "Executor", true, exName },
        { "HTTP requests", (request or http_request or (syn and syn.request) or (http and http.request) or game.HttpGet) ~= nil, "" },
        { "File system", writefile ~= nil and readfile ~= nil and isfile ~= nil, "" },
        { "Thread identity", setthreadidentity ~= nil, "" },
        { "Hidden UI", gethui ~= nil, gethui and "" or "using CoreGui" },
        { "Game modules", LP:FindFirstChild("PlayerScripts") and LP.PlayerScripts:FindFirstChild("MC") ~= nil, isSupported() and "" or "not this game" },
    }
    for i, c in ipairs(checks) do
        local r = frame(injView, 56, 138 + (i - 1) * 40, 388, 34, C.row)
        round(r, 9)
        stroke(r, C.stroke, 1)
        if c[2] then checkIcon(r, 10, 8, 18, true) else minusIcon(r, 10, 8, 18) end
        text(r, c[1], 38, 0, 160, 34, 12, C.text, F.reg)
        text(r, c[3], 190, 0, 188, 34, 11, c[2] and C.sub or C.amber, F.reg, Enum.TextXAlignment.Right)
        envRows[#envRows + 1] = r
    end
    local src = localFile(getgenv().PrestigeLauncherFile, DEV_CLIENT) and "Local file (dev)" or ("GitHub release " .. manifest.version)
    local r = frame(injView, 56, 138 + #checks * 40 + 6, 388, 34, C.row)
    round(r, 9)
    stroke(r, C.strokeHi, 1, 0.4)
    text(r, "Client source", 14, 0, 160, 34, 12, C.text, F.reg)
    text(r, src, 150, 0, 228, 34, 11, C.acc2, F.semi, Enum.TextXAlignment.Right)
    envRows[#envRows + 1] = r
end
runChecks()

card(injView, 490, 91, 460, 450)
text(injView, "INJECTION LOG", 516, 112, 300, 16, 10, C.sub, F.semi)
logBox = new("ScrollingFrame", {
    Position = UDim2.fromOffset(516, 138), Size = UDim2.fromOffset(410, 380), BackgroundTransparency = 1, BorderSizePixel = 0,
    ScrollBarThickness = 3, ScrollBarImageColor3 = Color3.fromRGB(70, 62, 170), CanvasSize = UDim2.new(), AutomaticCanvasSize = Enum.AutomaticSize.Y,
}, injView)
new("UIListLayout", { SortOrder = Enum.SortOrder.LayoutOrder, Padding = UDim.new(0, 2) }, logBox)
if #logLines == 0 then addLog("Ready. Press Inject on the Client view.") end

local clPage = frame(win, 0, 39, 980, 551, nil, { Visible = false })
pages.changelog = clPage
local rn = frame(clPage, 22, 19, 118, 26, Color3.fromRGB(24, 22, 62))
round(rn, 13)
stroke(rn, C.strokeHi, 1, 0.4)
local rnDot = frame(rn, 12, 10, 6, 6, C.acc2)
round(rnDot, 3)
text(rn, "RELEASE NOTES", 24, 0, 92, 26, 9, C.acc2, F.semi)
text(clPage, "What's", 22, 56, 200, 50, 34, C.text, F.serif, nil, { TextTruncate = Enum.TextTruncate.None })
text(clPage, "new", 136, 56, 200, 50, 34, C.acc2, F.serifI, nil, { TextTruncate = Enum.TextTruncate.None })
local clSub = text(clPage, "Latest improvements to the Prestige Client.", 22, 106, 500, 20, 12, C.sub, F.reg)
local clWhich = "client"
local clList
local TAGC = {
    ["NEW FEATURES"] = { Color3.fromRGB(26, 44, 96), Color3.fromRGB(110, 160, 255) },
    ["MAJOR UPDATE"] = { Color3.fromRGB(70, 48, 14), Color3.fromRGB(240, 176, 64) },
    ["IMPROVEMENTS"] = { Color3.fromRGB(44, 34, 100), Color3.fromRGB(176, 156, 255) },
    ["FIXES"] = { Color3.fromRGB(14, 56, 44), Color3.fromRGB(60, 200, 130) },
}
local function renderChangelog()
    if clList then clList:Destroy() end
    clList = new("ScrollingFrame", {
        Position = UDim2.fromOffset(22, 142), Size = UDim2.fromOffset(938, 396), BackgroundTransparency = 1, BorderSizePixel = 0,
        ScrollBarThickness = 3, ScrollBarImageColor3 = Color3.fromRGB(70, 62, 170), CanvasSize = UDim2.new(), AutomaticCanvasSize = Enum.AutomaticSize.Y,
    }, clPage)
    new("UIListLayout", { SortOrder = Enum.SortOrder.LayoutOrder, Padding = UDim.new(0, 12) }, clList)
    local entries = manifest.changelog[clWhich] or {}
    if manifest.offline then
        local n = text(clList, "Offline: showing the notes bundled with the launcher.", 0, 0, 900, 18, 11, C.amber, F.reg, nil, { LayoutOrder = 0, Size = UDim2.new(1, -18, 0, 18) })
    end
    for idx, e in ipairs(entries) do
        local h = 116 + 26 * #(e.items or {})
        local cd = new("Frame", { LayoutOrder = idx, Size = UDim2.new(1, -18, 0, h), BackgroundColor3 = Color3.new(1, 1, 1), BorderSizePixel = 0 }, clList)
        round(cd, 14)
        stroke(cd, C.stroke, 1)
        new("UIGradient", { Rotation = 90, Color = ColorSequence.new(Color3.fromRGB(16, 16, 44), Color3.fromRGB(11, 12, 32)) }, cd)
        local tags = new("Frame", { Position = UDim2.fromOffset(18, 14), Size = UDim2.fromOffset(400, 22), BackgroundTransparency = 1 }, cd)
        new("UIListLayout", { FillDirection = Enum.FillDirection.Horizontal, Padding = UDim.new(0, 6), SortOrder = Enum.SortOrder.LayoutOrder }, tags)
        for ti, tg in ipairs(e.tags or {}) do
            local style = TAGC[tg]
            local p = new("TextLabel", {
                LayoutOrder = ti, AutomaticSize = Enum.AutomaticSize.X, Size = UDim2.fromOffset(0, 22), BackgroundColor3 = style and style[1] or Color3.fromRGB(22, 20, 56),
                BorderSizePixel = 0, Text = tg, TextSize = 9, FontFace = F.semi, TextColor3 = style and style[2] or C.acc2,
            }, tags)
            round(p, 11)
            stroke(p, style and style[2] or C.strokeHi, 1, 0.6)
            new("UIPadding", { PaddingLeft = UDim.new(0, 10), PaddingRight = UDim.new(0, 10) }, p)
        end
        text(cd, e.date or "", 0, 14, 0, 22, 11, C.sub, F.reg, Enum.TextXAlignment.Right, { Position = UDim2.new(1, -90, 0, 14), Size = UDim2.fromOffset(72, 22) })
        text(cd, e.title or "", 18, 44, 860, 24, 16, C.text, F.semi)
        text(cd, e.summary or "", 18, 68, 860, 18, 11, C.sub, F.reg)
        frame(cd, 18, 98, 880, 1, C.stroke)
        for ii, it in ipairs(e.items or {}) do
            checkIcon(cd, 18, 110 + (ii - 1) * 26 + 3, 14, false)
            text(cd, it, 42, 110 + (ii - 1) * 26, 840, 20, 12, C.text, F.reg)
        end
    end
    clList.CanvasPosition = Vector2.zero
end
do
    local seg = segmented(clPage, 735, 56, "Client", "Launcher", function(i)
        clWhich = i == 1 and "client" or "loader"
        clSub.Text = i == 1 and "Latest improvements to the Prestige Client." or "Latest improvements to the Prestige Launcher."
        renderChangelog()
    end)
    seg.Size = UDim2.fromOffset(223, 54)
end
renderChangelog()

local acPage = frame(win, 0, 39, 980, 551, nil, { Visible = false })
pages.account = acPage
card(acPage, 30, 30, 920, 200)
local av = new("ImageLabel", { Position = UDim2.fromOffset(62, 62), Size = UDim2.fromOffset(120, 120), BackgroundColor3 = Color3.fromRGB(20, 20, 52), BorderSizePixel = 0 }, acPage)
round(av, 60)
stroke(av, C.strokeHi, 2, 0.2)
pcall(function() av.Image = string.format("rbxthumb://type=AvatarHeadShot&id=%d&w=150&h=150", LP.UserId) end)
text(acPage, LP.DisplayName, 214, 70, 500, 44, 32, C.text, F.serif, nil, { TextTruncate = Enum.TextTruncate.None })
text(acPage, "@" .. LP.Name, 214, 114, 400, 20, 13, C.acc2, F.semi)
text(acPage, string.format("User ID %d  \xC2\xB7  account age %d days", LP.UserId, LP.AccountAge), 214, 138, 600, 20, 12, C.sub, F.reg)
local acChip = frame(acPage, 214, 170, 150, 26, Color3.fromRGB(24, 22, 62))
round(acChip, 13)
stroke(acChip, C.strokeHi, 1, 0.4)
local acDot = frame(acChip, 12, 10, 6, 6, C.green)
round(acDot, 3)
local acState = text(acChip, "Signed in", 26, 0, 120, 26, 11, C.acc2, F.semi)

local acRows = {}
local function accountRows()
    for _, r in ipairs(acRows) do r:Destroy() end
    acRows = {}
    local exName = "Unknown"
    pcall(function() exName = tostring((identifyexecutor and identifyexecutor()) or "Unknown") end)
    local nCfg = 0
    pcall(function()
        for _, f in ipairs(listfiles(ROOT .. "/configs")) do if f:lower():sub(-5) == ".json" then nCfg += 1 end end
    end)
    local gameName = "Unstable SMP FFA"
    local info = {
        { "Game", isSupported() and gameName or ("Place " .. tostring(game.PlaceId)) },
        { "Executor", exName },
        { "Client", clientRunning() and ("Injected  \xC2\xB7  v" .. tostring(getgenv().PrestigeClient.version or "?")) or "Not injected" },
        { "Personal configs", tostring(nCfg) .. " saved" },
        { "Autosave", (pcall(isfile, ROOT .. "/autosave_v2.json") and isfile(ROOT .. "/autosave_v2.json")) and "Present" or "None yet" },
        { "Launcher build", LAUNCHER_BUILD },
    }
    for i, r in ipairs(info) do
        local col, row = (i - 1) % 2, math.floor((i - 1) / 2)
        local f = frame(acPage, 30 + col * 466, 250 + row * 56, 454, 46, C.row)
        round(f, 12)
        stroke(f, C.stroke, 1)
        text(f, r[1], 18, 0, 170, 46, 12, C.sub, F.reg)
        text(f, r[2], 190, 0, 246, 46, 12, C.text, F.semi, Enum.TextXAlignment.Right)
        acRows[#acRows + 1] = f
    end
end
accountRows()
local setTabBase = setTab
setTab = function(name)
    if name == "account" then accountRows() elseif name == "launch" then refreshStatus(); runChecks() end
    setTabBase(name)
end

local function setBtn(label, frac)
    injectLbl.Text = label
    if frac then tween(injectFill, { Size = UDim2.fromOffset(437 * frac, 52) }, 0.25) end
end
local function fail(msg)
    addLog(msg, "err")
    injectLbl.Text = "Failed: click to retry"
    injectBtn.BackgroundColor3 = Color3.fromRGB(150, 54, 70)
    tween(injectFill, { Size = UDim2.fromOffset(0, 52) }, 0.3)
    task.delay(1.6, function()
        if alive and not injecting then
            injectLbl.Text = "Inject Prestige Client  \xE2\x86\x92"
            tween(injectBtn, { BackgroundColor3 = C.acc }, 0.2)
        end
    end)
    injecting = false
end

local function inject()
    if injecting or not alive then return end
    injecting = true
    injectBtn.BackgroundColor3 = C.acc
    setBtn("Checking environment", 0.06)
    addLog("Starting injection")
    task.spawn(function()
        ident()
        if not loadstring then return fail("This executor has no loadstring") end
        local src
        local devFile = localFile(getgenv().PrestigeLauncherFile, DEV_CLIENT)
        if devFile then
            setBtn("Reading local client", 0.2)
            addLog("Reading local file " .. tostring(devFile))
            local ok, body = pcall(readfile, devFile)
            if not ok or not body or #body == 0 then return fail("Could not read " .. tostring(devFile)) end
            src = body
        else
            setBtn("Downloading client", 0.12)
            addLog("Downloading " .. manifest.clientUrl:match("[^/]+$"))
            local done, t0 = false, os.clock()
            task.spawn(function()
                while not done and alive do
                    local p = 0.12 + 0.62 * (1 - math.exp(-(os.clock() - t0) / 14))
                    tween(injectFill, { Size = UDim2.fromOffset(437 * p, 52) }, 0.4)
                    task.wait(0.4)
                end
            end)
            src = httpGet(manifest.clientUrl)
            done = true
            if not src then return fail("Download failed, check your connection") end
            addLog(string.format("Downloaded %.1f MB in %.1fs", #src / 1048576, os.clock() - t0), "ok")
        end
        setBtn("Compiling client", 0.82)
        addLog("Compiling (large builds can take about a minute)")
        task.wait(0.15)
        local fn, err = loadstring(src)
        src = nil
        if not fn then return fail("Compile error: " .. tostring(err)) end
        setBtn("Injecting client", 0.92)
        addLog("Running client")
        task.wait(0.1)
        ident()
        local ok, e = pcall(fn)
        if not ok then return fail("Client error: " .. tostring(e)) end
        local t1 = os.clock()
        while not clientRunning() and os.clock() - t1 < 8 do task.wait(0.1) end
        if not clientRunning() then return fail("Client did not start") end
        injected = true
        setBtn("Injected", 1)
        addLog("Prestige Client injected", "ok")
        task.wait(0.6)
        Launcher.close(true)
    end)
end
injectBtn.MouseButton1Click:Connect(function() ident(); inject() end)

function Launcher.close(keepMouse)
    if not alive then return end
    alive = false
    for _, c in ipairs(conns) do pcall(function() c:Disconnect() end) end
    if not (keepMouse and injected) then freeMouse(false) else pcall(function() RS:UnbindFromRenderStep("PrestigeLauncherMouse") end) end
    pcall(function() tween(win, { GroupTransparency = 1 }, 0.2) end)
    pcall(function() tween(dim, { BackgroundTransparency = 1 }, 0.2) end)
    pcall(function() tween(blur, { Size = 0 }, 0.2) end)
    task.delay(0.3, function()
        pcall(function() gui:Destroy() end)
        pcall(function() blur:Destroy() end)
    end)
    if getgenv().PrestigeLauncher == Launcher then getgenv().PrestigeLauncher = nil end
end
Launcher.setTab = setTab

on(workspace:GetPropertyChangedSignal("CurrentCamera"), function() pcall(fit) end)
pcall(function() on(workspace.CurrentCamera:GetPropertyChangedSignal("ViewportSize"), fit) end)

setTab("launch")
freeMouse(true)
tween(win, { GroupTransparency = 0 }, 0.35)
tween(dim, { BackgroundTransparency = 0.45 }, 0.35)
tween(blur, { Size = 10 }, 0.35)

task.spawn(function()
    ident()
    local body
    local devManifest = localFile(getgenv().PrestigeLauncherManifest, DEV_MANIFEST)
    if devManifest then
        local okf, b = pcall(readfile, devManifest)
        body = okf and b or nil
    else
        body = httpGet(RAW .. "manifest.json?v=" .. tostring(math.floor(os.time() / 60)))
    end
    if not alive then return end
    local ok, data = pcall(function() return HttpService:JSONDecode(body) end)
    if ok and type(data) == "table" and type(data.changelog) == "table" then
        manifest = { version = tostring(data.version or manifest.version), clientUrl = data.clientUrl or manifest.clientUrl, changelog = data.changelog, offline = false }
        buildLbl.Text = "BUILD " .. manifest.version
        chanSub.Text = "Stable  \xC2\xB7  v" .. manifest.version .. " from GitHub"
        renderChangelog()
        runChecks()
        addLog("Release info loaded (v" .. manifest.version .. ")", "ok")
    else
        chanSub.Text = "Stable  \xC2\xB7  offline, using bundled info"
        addLog("Could not reach GitHub, using bundled release info", "err")
    end
end)
