--[[
    ═══════════════════════════════════════════════════════
      LEMON HUB v4.1  —  Sell Lemons 🍋
      Clean UI • Lucide icons • Full auto-farm engine
      UI builds instantly; game modules load async with
      timeouts so a hung require can never freeze the client.
    ═══════════════════════════════════════════════════════
]]

print("[LemonHub] v4.1 loading...")

-- ══════════════ Cleanup previous instance ══════════════
if getgenv().LemonHubV4 then
    pcall(function() getgenv().LemonHubV4.Destroy() end)
    getgenv().LemonHubV4 = nil
end

-- ══════════════ Services ══════════════
local Players            = game:GetService("Players")
local RS                 = game:GetService("ReplicatedStorage")
local TweenService       = game:GetService("TweenService")
local UserInputService   = game:GetService("UserInputService")
local RunService         = game:GetService("RunService")
local CollectionService  = game:GetService("CollectionService")
local HttpService        = game:GetService("HttpService")

local LP = Players.LocalPlayer
local alive = true

-- ══════════════ Theme ══════════════
local T = {
    Bg        = Color3.fromRGB(8, 10, 15),
    Surface   = Color3.fromRGB(15, 18, 25),
    Elevated  = Color3.fromRGB(22, 26, 35),
    Elevated2 = Color3.fromRGB(30, 35, 45),
    Stroke    = Color3.fromRGB(255, 255, 255),
    Text      = Color3.fromRGB(245, 248, 255),
    TextDim   = Color3.fromRGB(148, 156, 175),
    TextFaint = Color3.fromRGB(100, 108, 125),
    Accent    = Color3.fromRGB(255, 215, 0),
    AccentTxt = Color3.fromRGB(35, 30, 5),
    AccentGlow = Color3.fromRGB(255, 220, 50),
    Green     = Color3.fromRGB(34, 197, 94),
    Red       = Color3.fromRGB(239, 68, 68),
    Violet    = Color3.fromRGB(139, 92, 246),
    Blue      = Color3.fromRGB(59, 130, 246),
    Glass     = Color3.fromRGB(255, 255, 255),
}
local FONT_B, FONT_M, FONT_R = Enum.Font.GothamBold, Enum.Font.GothamMedium, Enum.Font.Gotham

-- ══════════════ Async Lucide icons ══════════════
-- UI builds immediately; icons pop in once the sprite lib downloads.
local Lucide = nil
local pendingIcons = {}   -- ImageLabel -> icon name
local function applyIcon(img, name)
    if not Lucide then return end
    local ok, a = pcall(Lucide.GetAsset, name, 48)
    if ok and a then
        img.Image = a.Url
        img.ImageRectOffset = a.ImageRectOffset
        img.ImageRectSize = a.ImageRectSize
    end
end
task.spawn(function()
    local ok, lib = pcall(function()
        return loadstring(game:HttpGet(
            "https://github.com/latte-soft/lucide-roblox/releases/latest/download/lucide-roblox.luau"))()
    end)
    if ok and lib then
        Lucide = lib
        for img, name in pairs(pendingIcons) do
            if img.Parent then applyIcon(img, name) end
        end
        pendingIcons = {}
        print("[LemonHub] Lucide icons loaded")
    else
        print("[LemonHub] Lucide failed to load (UI still works)")
    end
end)

-- ══════════════ UI helpers ══════════════
local connections = {}
local function track(con) table.insert(connections, con) return con end

local function mk(class, props, children)
    local inst = Instance.new(class)
    for k, v in pairs(props or {}) do
        if k ~= "Parent" then inst[k] = v end
    end
    for _, c in ipairs(children or {}) do c.Parent = inst end
    if props and props.Parent then inst.Parent = props.Parent end
    return inst
end

local function corner(r) return mk("UICorner", { CornerRadius = UDim.new(0, r) }) end
local function stroke(transp, color, thickness)
    return mk("UIStroke", {
        Color = color or T.Stroke, Transparency = transp or 0.92, Thickness = thickness or 1,
        ApplyStrokeMode = Enum.ApplyStrokeMode.Border,
    })
end
local function shadow(color, offset, blur, transp)
    return mk("Frame", {
        Name = "Shadow", BackgroundColor3 = color or Color3.fromRGB(0, 0, 0),
        BackgroundTransparency = transp or 0.85,
        Size = UDim2.fromScale(1, 1), Position = UDim2.fromOffset(offset or 4, offset or 4),
        ZIndex = -1, Parent = nil,
    }, { corner(12) })
end
local function glass(transp)
    return mk("Frame", {
        Name = "Glass", BackgroundColor3 = T.Glass,
        BackgroundTransparency = transp or 0.92,
        Size = UDim2.fromScale(1, 1), ZIndex = 0,
    }, { corner(0) })
end
local function pad(t, r, b, l)
    return mk("UIPadding", {
        PaddingTop = UDim.new(0, t), PaddingRight = UDim.new(0, r or t),
        PaddingBottom = UDim.new(0, b or t), PaddingLeft = UDim.new(0, l or r or t),
    })
end

local function icon(name, size, color, parent)
    local img = mk("ImageLabel", {
        BackgroundTransparency = 1,
        Size = UDim2.fromOffset(size, size),
        ImageColor3 = color or T.Text,
        ScaleType = Enum.ScaleType.Fit,
        Parent = parent,
    })
    if Lucide then applyIcon(img, name) else pendingIcons[img] = name end
    return img
end

local function tween(inst, ti, props)
    local tw = TweenService:Create(inst, ti, props)
    tw:Play()
    return tw
end
local TI_FAST = TweenInfo.new(0.16, Enum.EasingStyle.Quart, Enum.EasingDirection.Out)
local TI_MED  = TweenInfo.new(0.24, Enum.EasingStyle.Quart, Enum.EasingDirection.Out)
local TI_POP  = TweenInfo.new(0.32, Enum.EasingStyle.Back, Enum.EasingDirection.Out)
local TI_SMOOTH = TweenInfo.new(0.4, Enum.EasingStyle.Quart, Enum.EasingDirection.Out)

-- ══════════════ State & config ══════════════
local State = {
    buyTiles = false, upgradeEarners = false, wakeEarners = false, powers = false,
    cashDrops = false, phoneDeals = false, minigame = false, harvest = false,
    rebirth = false, evolve = false, ascend = false,
    antiAfk = true, wsEnabled = false, wsValue = 16,
    tradeMinigame = false, autoAds = false, voidEvents = false,
}
local CONFIG_FILE = "LemonHubV4.json"
local function saveConfig()
    pcall(function()
        if writefile then writefile(CONFIG_FILE, HttpService:JSONEncode(State)) end
    end)
end
pcall(function()
    if readfile and isfile and isfile(CONFIG_FILE) then
        local data = HttpService:JSONDecode(readfile(CONFIG_FILE))
        for k, v in pairs(data) do
            if State[k] ~= nil then State[k] = v end
        end
    end
end)
State.ascend = false -- never auto-load the dangerous one

local saveQueued = false
local function queueSave()
    if saveQueued then return end
    saveQueued = true
    task.delay(1, function() saveQueued = false saveConfig() end)
end

-- ══════════════ ScreenGui (PlayerGui — executor threads can't touch gethui) ══════════════
local pg = LP:WaitForChild("PlayerGui")
local gui = mk("ScreenGui", {
    Name = "LemonHubV4", ResetOnSpawn = false, IgnoreGuiInset = true,
    ZIndexBehavior = Enum.ZIndexBehavior.Sibling, DisplayOrder = 999, Parent = pg,
})

-- ══════════════ Toasts ══════════════
local toastHolder = mk("Frame", {
    BackgroundTransparency = 1, AnchorPoint = Vector2.new(1, 1),
    Position = UDim2.new(1, -16, 1, -16), Size = UDim2.fromOffset(272, 400),
    Parent = gui,
}, {
    mk("UIListLayout", {
        FillDirection = Enum.FillDirection.Vertical, VerticalAlignment = Enum.VerticalAlignment.Bottom,
        HorizontalAlignment = Enum.HorizontalAlignment.Right, Padding = UDim.new(0, 8),
        SortOrder = Enum.SortOrder.LayoutOrder,
    }),
})
local toastOrder = 0
local function toast(title, msg, iconName, color)
    if not alive then return end
    toastOrder += 1
    local card = mk("Frame", {
        BackgroundColor3 = T.Surface, Size = UDim2.new(1, 40, 0, 58),
        LayoutOrder = toastOrder, ClipsDescendants = true, Parent = toastHolder,
    }, { corner(10), stroke(0.88), pad(10, 12, 10, 12) })
    local ic = icon(iconName or "citrus", 22, color or T.Accent, card)
    ic.Position = UDim2.fromOffset(0, 7)
    mk("TextLabel", {
        BackgroundTransparency = 1, Font = FONT_B, Text = title, TextSize = 13,
        TextColor3 = T.Text, TextXAlignment = Enum.TextXAlignment.Left,
        Position = UDim2.fromOffset(34, 2), Size = UDim2.new(1, -34, 0, 16), Parent = card,
    })
    mk("TextLabel", {
        BackgroundTransparency = 1, Font = FONT_R, Text = msg or "", TextSize = 12,
        TextColor3 = T.TextDim, TextXAlignment = Enum.TextXAlignment.Left,
        TextTruncate = Enum.TextTruncate.AtEnd,
        Position = UDim2.fromOffset(34, 20), Size = UDim2.new(1, -34, 0, 16), Parent = card,
    })
    card.BackgroundTransparency = 1
    tween(card, TI_MED, { Size = UDim2.new(1, 0, 0, 58), BackgroundTransparency = 0 })
    task.delay(4, function()
        if card.Parent then
            tween(card, TI_MED, { Size = UDim2.new(1, 40, 0, 58), BackgroundTransparency = 1 })
            task.wait(0.25)
            card:Destroy()
        end
    end)
end

-- ══════════════ Main window ══════════════
local WIN_W, WIN_H = 700, 460
local win = mk("Frame", {
    Name = "Window", BackgroundColor3 = T.Bg, AnchorPoint = Vector2.new(0.5, 0.5),
    Position = UDim2.fromScale(0.5, 0.5), Size = UDim2.fromOffset(WIN_W, WIN_H),
    ClipsDescendants = true, Parent = gui,
}, { corner(16), stroke(0.88) })
local winShadow = shadow(nil, 8, nil, 0.75)
winShadow.Parent = win
local winGlass = glass(0.94)
winGlass.Parent = win

-- ── Topbar ──
local topbar = mk("Frame", {
    BackgroundTransparency = 1, Size = UDim2.new(1, 0, 0, 56), Parent = win,
})
local titleIcon = icon("citrus", 22, T.Accent, topbar)
titleIcon.Position = UDim2.fromOffset(20, 17)
mk("TextLabel", {
    BackgroundTransparency = 1, Font = FONT_B, Text = "Lemon Hub", TextSize = 16,
    TextColor3 = T.Text, TextXAlignment = Enum.TextXAlignment.Left,
    Position = UDim2.fromOffset(50, 10), Size = UDim2.fromOffset(120, 20), Parent = topbar,
})
mk("TextLabel", {
    BackgroundTransparency = 1, Font = FONT_R, Text = "Sell Lemons 🍋  •  v4.1", TextSize = 11,
    TextColor3 = T.TextFaint, TextXAlignment = Enum.TextXAlignment.Left,
    Position = UDim2.fromOffset(50, 30), Size = UDim2.fromOffset(160, 14), Parent = topbar,
})

local statusDot = mk("Frame", {
    BackgroundColor3 = T.TextFaint, AnchorPoint = Vector2.new(1, 0.5),
    Position = UDim2.new(1, -104, 0.5, 0), Size = UDim2.fromOffset(8, 8), Parent = topbar,
}, { corner(4) })
local statusLbl = mk("TextLabel", {
    BackgroundTransparency = 1, Font = FONT_M, Text = "booting", TextSize = 11,
    TextColor3 = T.TextDim, TextXAlignment = Enum.TextXAlignment.Left,
    AnchorPoint = Vector2.new(1, 0.5), Position = UDim2.new(1, -44, 0.5, 0),
    Size = UDim2.fromOffset(52, 14), Parent = topbar,
})

local function winButton(iconName, xOff, hoverColor)
    local btn = mk("TextButton", {
        BackgroundColor3 = T.Surface, Text = "", AutoButtonColor = false,
        AnchorPoint = Vector2.new(1, 0.5), Position = UDim2.new(1, xOff, 0.5, 0),
        Size = UDim2.fromOffset(32, 32), Parent = topbar,
    }, { corner(10) })
    local ic = icon(iconName, 16, T.TextDim, btn)
    ic.AnchorPoint = Vector2.new(0.5, 0.5)
    ic.Position = UDim2.fromScale(0.5, 0.5)
    track(btn.MouseEnter:Connect(function()
        tween(btn, TI_FAST, { BackgroundColor3 = hoverColor or T.Elevated })
        tween(ic, TI_FAST, { ImageColor3 = T.Text })
    end))
    track(btn.MouseLeave:Connect(function()
        tween(btn, TI_FAST, { BackgroundColor3 = T.Surface })
        tween(ic, TI_FAST, { ImageColor3 = T.TextDim })
    end))
    return btn
end
-- keep window buttons clear of the status text
local minBtn = winButton("minus", -160)
local closeBtn = winButton("x", -120)

-- reposition: buttons on far right, status to their left
minBtn.Position = UDim2.new(1, -56, 0.5, 0)
closeBtn.Position = UDim2.new(1, -16, 0.5, 0)
statusDot.Position = UDim2.new(1, -170, 0.5, 0)
statusLbl.Position = UDim2.new(1, -100, 0.5, 0)

-- ── Drag ──
local function makeDraggable(handle, target)
    local dragging, dragStart, startPos = false, nil, nil
    track(handle.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1
        or input.UserInputType == Enum.UserInputType.Touch then
            dragging = true
            dragStart = input.Position
            startPos = target.Position
        end
    end))
    track(handle.InputEnded:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1
        or input.UserInputType == Enum.UserInputType.Touch then dragging = false end
    end))
    track(UserInputService.InputChanged:Connect(function(input)
        if dragging and (input.UserInputType == Enum.UserInputType.MouseMovement
        or input.UserInputType == Enum.UserInputType.Touch) then
            local d = input.Position - dragStart
            target.Position = UDim2.new(
                startPos.X.Scale, startPos.X.Offset + d.X,
                startPos.Y.Scale, startPos.Y.Offset + d.Y)
        end
    end))
end
makeDraggable(topbar, win)

-- ── Sidebar ──
local sidebar = mk("Frame", {
    BackgroundColor3 = T.Surface, Position = UDim2.fromOffset(12, 64),
    Size = UDim2.fromOffset(160, WIN_H - 64 - 12), Parent = win,
}, { corner(14), stroke(0.92) })
local sidebarGlass = glass(0.96)
sidebarGlass.Parent = sidebar

mk("TextLabel", {
    BackgroundTransparency = 1, Font = FONT_R, TextSize = 10,
    Text = LP.Name, TextColor3 = T.TextFaint, TextTruncate = Enum.TextTruncate.AtEnd,
    AnchorPoint = Vector2.new(0.5, 1), Position = UDim2.new(0.5, 0, 1, -10),
    Size = UDim2.new(1, -20, 0, 12), Parent = sidebar,
})

local content = mk("Frame", {
    BackgroundTransparency = 1, Position = UDim2.fromOffset(184, 64),
    Size = UDim2.new(1, -196, 1, -76), Parent = win,
})

-- ── Tabs ──
local tabs, tabOrder = {}, 0
local activeTab = nil
local tabIndicator = mk("Frame", {
    BackgroundColor3 = T.Accent, Size = UDim2.fromOffset(4, 24),
    Position = UDim2.fromOffset(0, 14), Parent = sidebar, Visible = false,
}, { corner(2) })

local function makePage()
    local page = mk("ScrollingFrame", {
        BackgroundTransparency = 1, Size = UDim2.fromScale(1, 1),
        CanvasSize = UDim2.new(), AutomaticCanvasSize = Enum.AutomaticSize.Y,
        ScrollBarThickness = 3, ScrollBarImageColor3 = T.Elevated2,
        BorderSizePixel = 0, Visible = false, Parent = content,
    }, {
        mk("UIListLayout", { Padding = UDim.new(0, 8), SortOrder = Enum.SortOrder.LayoutOrder }),
        pad(2, 6, 12, 2),
    })
    return page
end

local function addTab(name, iconName)
    tabOrder += 1
    local order = tabOrder
    local page = makePage()
    local btn = mk("TextButton", {
        BackgroundColor3 = T.Surface, BackgroundTransparency = 1, Text = "",
        AutoButtonColor = false, Position = UDim2.fromOffset(10, 14 + (order - 1) * 46),
        Size = UDim2.new(1, -20, 0, 40), Parent = sidebar,
    }, { corner(10) })
    local ic = icon(iconName, 18, T.TextDim, btn)
    ic.Position = UDim2.fromOffset(12, 10)
    local lbl = mk("TextLabel", {
        BackgroundTransparency = 1, Font = FONT_M, Text = name, TextSize = 14,
        TextColor3 = T.TextDim, TextXAlignment = Enum.TextXAlignment.Left,
        Position = UDim2.fromOffset(42, 0), Size = UDim2.new(1, -42, 1, 0), Parent = btn,
    })
    local tab = { name = name, page = page, btn = btn, ic = ic, lbl = lbl, order = order }
    table.insert(tabs, tab)

    local function select()
        for _, t2 in ipairs(tabs) do
            t2.page.Visible = false
            tween(t2.btn, TI_FAST, { BackgroundTransparency = 1 })
            tween(t2.ic, TI_FAST, { ImageColor3 = T.TextDim })
            tween(t2.lbl, TI_FAST, { TextColor3 = T.TextDim })
        end
        activeTab = tab
        page.Visible = true
        tween(btn, TI_FAST, { BackgroundTransparency = 0, BackgroundColor3 = T.Elevated })
        tween(ic, TI_FAST, { ImageColor3 = T.Accent })
        tween(lbl, TI_FAST, { TextColor3 = T.Text })
        tabIndicator.Visible = true
        tween(tabIndicator, TI_MED, { Position = UDim2.fromOffset(0, 14 + (order - 1) * 46 + 8) })
    end
    track(btn.MouseButton1Click:Connect(select))
    track(btn.MouseEnter:Connect(function()
        if activeTab ~= tab then tween(btn, TI_FAST, { BackgroundTransparency = 0.5, BackgroundColor3 = T.Elevated }) end
    end))
    track(btn.MouseLeave:Connect(function()
        if activeTab ~= tab then tween(btn, TI_FAST, { BackgroundTransparency = 1 }) end
    end))
    tab.select = select
    return page, tab
end

-- ══════════════ Row components ══════════════
local Toggles = {}   -- key -> { Set = fn }

local function sectionLabel(page, text)
    mk("TextLabel", {
        BackgroundTransparency = 1, Font = FONT_B, Text = string.upper(text), TextSize = 11,
        TextColor3 = T.TextFaint, TextXAlignment = Enum.TextXAlignment.Left,
        Size = UDim2.new(1, 0, 0, 22), Parent = page,
    })
end

local function baseRow(page, height)
    return mk("Frame", {
        BackgroundColor3 = T.Surface, Size = UDim2.new(1, 0, 0, height or 58), Parent = page,
    }, { corner(12), stroke(0.92) })
end

local function rowHeader(row, opt)
    local iconBg = mk("Frame", {
        BackgroundColor3 = T.Elevated, Position = UDim2.fromOffset(14, 13),
        Size = UDim2.fromOffset(36, 36), Parent = row,
    }, { corner(10) })
    local ic = icon(opt.icon, 18, opt.iconColor or T.TextDim, iconBg)
    ic.AnchorPoint = Vector2.new(0.5, 0.5)
    ic.Position = UDim2.fromScale(0.5, 0.5)
    mk("TextLabel", {
        BackgroundTransparency = 1, Font = FONT_M, Text = opt.title, TextSize = 14,
        TextColor3 = opt.danger and T.Red or T.Text, TextXAlignment = Enum.TextXAlignment.Left,
        Position = UDim2.fromOffset(60, 10), Size = UDim2.new(1, -130, 0, 18), Parent = row,
    })
    mk("TextLabel", {
        BackgroundTransparency = 1, Font = FONT_R, Text = opt.desc or "", TextSize = 12,
        TextColor3 = T.TextFaint, TextXAlignment = Enum.TextXAlignment.Left,
        TextTruncate = Enum.TextTruncate.AtEnd,
        Position = UDim2.fromOffset(60, 30), Size = UDim2.new(1, -130, 0, 16), Parent = row,
    })
    return iconBg, ic
end

local function toggleRow(page, opt)
    local row = baseRow(page)
    local iconBg, ic = rowHeader(row, opt)
    local onColor = opt.danger and T.Red or T.Accent

    local pill = mk("Frame", {
        BackgroundColor3 = T.Elevated2, AnchorPoint = Vector2.new(1, 0.5),
        Position = UDim2.new(1, -16, 0.5, 0), Size = UDim2.fromOffset(44, 24), Parent = row,
    }, { corner(12) })
    local knob = mk("Frame", {
        BackgroundColor3 = Color3.fromRGB(200, 205, 215), Position = UDim2.fromOffset(3, 3),
        Size = UDim2.fromOffset(18, 18), Parent = pill,
    }, { corner(9) })

    local function render(v, instant)
        local ti = instant and TweenInfo.new(0) or TI_MED
        tween(pill, ti, { BackgroundColor3 = v and onColor or T.Elevated2 })
        tween(knob, ti, {
            Position = v and UDim2.fromOffset(23, 3) or UDim2.fromOffset(3, 3),
            BackgroundColor3 = v and (opt.danger and Color3.fromRGB(255, 235, 235) or T.AccentTxt) or Color3.fromRGB(200, 205, 215),
        })
        tween(ic, ti, { ImageColor3 = v and onColor or (opt.iconColor or T.TextDim) })
    end
    render(State[opt.key], true)

    local function set(v)
        if opt.confirm and v and not opt._confirmed then
            opt._confirmed = true
            toast("Are you sure?", "Click again within 3s to enable " .. opt.title, "crown", T.Red)
            task.delay(3, function() opt._confirmed = false end)
            return
        end
        State[opt.key] = v
        render(v)
        queueSave()
        if opt.onChange then opt.onChange(v) end
    end

    local hit = mk("TextButton", {
        BackgroundTransparency = 1, Text = "", Size = UDim2.fromScale(1, 1), Parent = row,
    })
    track(hit.MouseButton1Click:Connect(function() set(not State[opt.key]) end))
    track(hit.MouseEnter:Connect(function() tween(row, TI_FAST, { BackgroundColor3 = T.Elevated }) end))
    track(hit.MouseLeave:Connect(function() tween(row, TI_FAST, { BackgroundColor3 = T.Surface }) end))

    Toggles[opt.key] = { Set = function(v) set(v) end, Render = render }
    return row
end

local function sliderRow(page, opt)
    local row = baseRow(page, 68)
    rowHeader(row, opt)
    local valLbl = mk("TextLabel", {
        BackgroundTransparency = 1, Font = FONT_B, TextSize = 12, TextColor3 = T.Accent,
        Text = tostring(State[opt.key]), TextXAlignment = Enum.TextXAlignment.Right,
        AnchorPoint = Vector2.new(1, 0), Position = UDim2.new(1, -14, 0, 12),
        Size = UDim2.fromOffset(80, 16), Parent = row,
    })
    local trackBar = mk("Frame", {
        BackgroundColor3 = T.Elevated2, Position = UDim2.fromOffset(54, 50),
        Size = UDim2.new(1, -70, 0, 5), Parent = row,
    }, { corner(3) })
    local fill = mk("Frame", {
        BackgroundColor3 = T.Accent, Size = UDim2.fromScale(0, 1), Parent = trackBar,
    }, { corner(3) })
    local knob = mk("Frame", {
        BackgroundColor3 = Color3.fromRGB(255, 255, 255), AnchorPoint = Vector2.new(0.5, 0.5),
        Position = UDim2.new(0, 0, 0.5, 0), Size = UDim2.fromOffset(13, 13), Parent = trackBar,
    }, { corner(7), stroke(0.7) })

    local function render(v)
        local a = (v - opt.min) / (opt.max - opt.min)
        fill.Size = UDim2.fromScale(a, 1)
        knob.Position = UDim2.new(a, 0, 0.5, 0)
        valLbl.Text = tostring(v) .. (opt.suffix or "")
    end
    render(State[opt.key])

    local draggingSlider = false
    local function applyFromX(x)
        local a = math.clamp((x - trackBar.AbsolutePosition.X) / trackBar.AbsoluteSize.X, 0, 1)
        local v = math.floor(opt.min + a * (opt.max - opt.min) + 0.5)
        if v ~= State[opt.key] then
            State[opt.key] = v
            render(v)
            queueSave()
            if opt.onChange then opt.onChange(v) end
        end
    end
    local hit = mk("TextButton", {
        BackgroundTransparency = 1, Text = "", Position = UDim2.fromOffset(48, 38),
        Size = UDim2.new(1, -58, 0, 26), Parent = row,
    })
    track(hit.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1
        or input.UserInputType == Enum.UserInputType.Touch then
            draggingSlider = true
            applyFromX(input.Position.X)
        end
    end))
    track(UserInputService.InputEnded:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1
        or input.UserInputType == Enum.UserInputType.Touch then draggingSlider = false end
    end))
    track(UserInputService.InputChanged:Connect(function(input)
        if draggingSlider and (input.UserInputType == Enum.UserInputType.MouseMovement
        or input.UserInputType == Enum.UserInputType.Touch) then
            applyFromX(input.Position.X)
        end
    end))
    return row
end

local function _inputRow_deleted()
    local row = baseRow(page)
    local _, ic = rowHeader(row, opt)
    local tb = mk("TextBox", {
        BackgroundTransparency = 1, Font = FONT_R, TextSize = 12, TextColor3 = T.Text,
        Text = State[opt.key] or "", PlaceholderText = opt.placeholder or "",
        TextXAlignment = Enum.TextXAlignment.Right,
        AnchorPoint = Vector2.new(1, 0.5), Position = UDim2.new(1, -14, 0.5, 0),
        Size = UDim2.fromOffset(150, 20), Parent = row,
        ClearTextOnFocus = false,
    })
    track(tb.FocusLost:Connect(function()
        State[opt.key] = tb.Text
        queueSave()
    end))
    return row
end

local function buttonRow(page, opt)
    local row = baseRow(page)
    local _, ic = rowHeader(row, opt)
    local hit = mk("TextButton", {
        BackgroundTransparency = 1, Text = "", Size = UDim2.fromScale(1, 1), Parent = row,
    })
    track(hit.MouseButton1Click:Connect(opt.onClick))
    track(hit.MouseEnter:Connect(function()
        tween(row, TI_FAST, { BackgroundColor3 = opt.danger and Color3.fromRGB(60, 25, 25) or T.Elevated })
    end))
    track(hit.MouseLeave:Connect(function() tween(row, TI_FAST, { BackgroundColor3 = T.Surface }) end))
    return row
end

-- ══════════════ Build tabs ══════════════
local dashPage, dashTab = addTab("Dashboard", "layout-dashboard")
local farmPage  = addTab("Farm", "sprout")
local prestigePage = addTab("Prestige", "crown")
local extrasPage = addTab("Extras", "sparkles")
local settingsPage = addTab("Settings", "settings")

-- ── Dashboard: stat grid ──
sectionLabel(dashPage, "Live stats")
local statGrid = mk("Frame", {
    BackgroundTransparency = 1, Size = UDim2.new(1, 0, 0, 160), Parent = dashPage,
}, {
    mk("UIGridLayout", {
        CellSize = UDim2.new(0.5, -6, 0, 52), CellPadding = UDim2.fromOffset(10, 8),
        SortOrder = Enum.SortOrder.LayoutOrder,
    }),
})
local statValues = {}
local function statCard(iconName, label, color)
    local card = mk("Frame", { BackgroundColor3 = T.Surface, Parent = statGrid },
        { corner(12), stroke(0.92) })
    local ic = icon(iconName, 18, color or T.Accent, card)
    ic.Position = UDim2.fromOffset(14, 17)
    mk("TextLabel", {
        BackgroundTransparency = 1, Font = FONT_R, Text = label, TextSize = 11,
        TextColor3 = T.TextFaint, TextXAlignment = Enum.TextXAlignment.Left,
        Position = UDim2.fromOffset(42, 8), Size = UDim2.new(1, -52, 0, 14), Parent = card,
    })
    local val = mk("TextLabel", {
        BackgroundTransparency = 1, Font = FONT_B, Text = "—", TextSize = 16,
        TextColor3 = T.Text, TextXAlignment = Enum.TextXAlignment.Left,
        TextTruncate = Enum.TextTruncate.AtEnd,
        Position = UDim2.fromOffset(42, 24), Size = UDim2.new(1, -52, 0, 20), Parent = card,
    })
    statValues[label] = val
    return card
end
statCard("circle-dollar-sign", "Cash", T.Accent)
statCard("star", "Investors", T.Violet)
statCard("refresh-cw", "Rebirths", T.Green)
statCard("wallet", "Session earned", T.Blue)
statCard("gauge", "Rate", T.Green)
statCard("timer", "Race cooldown", T.TextDim)

-- ── Dashboard: quick actions ──
sectionLabel(dashPage, "Quick actions")
local qa = mk("Frame", {
    BackgroundTransparency = 1, Size = UDim2.new(1, 0, 0, 38), Parent = dashPage,
}, {
    mk("UIListLayout", {
        FillDirection = Enum.FillDirection.Horizontal, Padding = UDim.new(0, 10),
        SortOrder = Enum.SortOrder.LayoutOrder,
    }),
})
local FARM_KEYS = { "buyTiles", "upgradeEarners", "wakeEarners", "powers", "cashDrops", "phoneDeals", "minigame", "rebirth", "evolve" }
local function quickBtn(text, iconName, accent, cb)
    local btn = mk("TextButton", {
        BackgroundColor3 = accent and T.Accent or T.Surface, Text = "", AutoButtonColor = false,
        Size = UDim2.fromOffset(115, 38), Parent = qa,
    }, { corner(10), stroke(accent and 1 or 0.92) })
    local ic = icon(iconName, 16, accent and T.AccentTxt or T.TextDim, btn)
    ic.Position = UDim2.fromOffset(14, 11)
    mk("TextLabel", {
        BackgroundTransparency = 1, Font = FONT_B, Text = text, TextSize = 13,
        TextColor3 = accent and T.AccentTxt or T.Text, TextXAlignment = Enum.TextXAlignment.Left,
        Position = UDim2.fromOffset(38, 0), Size = UDim2.new(1, -38, 1, 0), Parent = btn,
    })
    track(btn.MouseButton1Click:Connect(cb))
    track(btn.MouseEnter:Connect(function()
        tween(btn, TI_FAST, { BackgroundColor3 = accent and T.AccentGlow or T.Elevated })
    end))
    track(btn.MouseLeave:Connect(function()
        tween(btn, TI_FAST, { BackgroundColor3 = accent and T.Accent or T.Surface })
    end))
    return btn
end
quickBtn("Start all", "play", true, function()
    for _, k in ipairs(FARM_KEYS) do if Toggles[k] then Toggles[k].Set(true) end end
    toast("Farm started", #FARM_KEYS .. " features enabled", "play", T.Green)
end)
quickBtn("Stop all", "pause", false, function()
    for _, k in ipairs(FARM_KEYS) do if Toggles[k] then Toggles[k].Set(false) end end
    if Toggles.harvest then Toggles.harvest.Set(false) end
    if Toggles.ascend then Toggles.ascend.Set(false) end
    toast("Farm stopped", "All features disabled", "pause", T.Red)
end)

-- ── Dashboard: activity feed ──
sectionLabel(dashPage, "Activity")
local feedFrame = mk("Frame", {
    BackgroundColor3 = T.Surface, Size = UDim2.new(1, 0, 0, 140), Parent = dashPage,
}, { corner(12), stroke(0.92), pad(10, 14, 10, 14),
    mk("UIListLayout", { Padding = UDim.new(0, 3), SortOrder = Enum.SortOrder.LayoutOrder }) })
local feedLines = {}
local feedCount = 0
local MAX_FEED = 6
local function log(text, color)
    if not alive then return end
    feedCount += 1
    local line = mk("TextLabel", {
        BackgroundTransparency = 1, Font = FONT_R, TextSize = 12,
        Text = os.date("%H:%M:%S") .. "  " .. text,
        TextColor3 = color or T.TextDim, TextXAlignment = Enum.TextXAlignment.Left,
        TextTruncate = Enum.TextTruncate.AtEnd,
        Size = UDim2.new(1, 0, 0, 18), LayoutOrder = feedCount, Parent = feedFrame,
    })
    table.insert(feedLines, line)
    if #feedLines > MAX_FEED then
        local old = table.remove(feedLines, 1)
        old:Destroy()
    end
end
log("Lemon Hub v4.1 loaded", T.Accent)

-- ── Farm tab ──
sectionLabel(farmPage, "Economy")
toggleRow(farmPage, { key = "buyTiles", icon = "shopping-cart", title = "Auto Buy Tiles",
    desc = "Purchases every unlocked tycoon tile" })
toggleRow(farmPage, { key = "upgradeEarners", icon = "trending-up", title = "Auto Upgrade Stands",
    desc = "Bulk-buys as many levels as affordable" })
toggleRow(farmPage, { key = "wakeEarners", icon = "mouse-pointer", title = "Auto Click Income",
    desc = "Wakes up streams constantly (Heartbeat)" })
toggleRow(farmPage, { key = "powers", icon = "zap", title = "Auto Upgrade Powers",
    desc = "Spends investors on power levels" })
sectionLabel(farmPage, "Income")
toggleRow(farmPage, { key = "cashDrops", icon = "hand-coins", title = "Auto Collect Cash Drops",
    desc = "Redeems drops instantly, no walking" })
toggleRow(farmPage, { key = "phoneDeals", icon = "phone", title = "Auto Phone Deals",
    desc = "Accepts lucrative phone offers" })
toggleRow(farmPage, { key = "harvest", icon = "citrus", title = "Auto Harvest Lemons",
    desc = "⚠ Teleports your character to fruit" })

sectionLabel(farmPage, "Orchard")
toggleRow(farmPage, { key = "harvestOrchard", icon = "tractor", title = "Auto Harvest Orchard",
    desc = "Harvests all fruit from orchard plots" })
toggleRow(farmPage, { key = "sellFruits", icon = "coins", title = "Auto Sell Fruits",
    desc = "Sells all fruits from your inventory" })
toggleRow(farmPage, { key = "autoPlant", icon = "sprout", title = "Auto Plant Trees", desc = "Plants seed ID 3 in empty plots" })
toggleRow(farmPage, { key = "autoUseItems", icon = "flask-conical", title = "Auto Use Items on Trees", desc = "Uses all items EXCEPT Cleanse" })
toggleRow(farmPage, { key = "autoUseCleanse", icon = "sparkles", title = "Auto Use Cleanse on Trees", desc = "Uses FertilizerCleanse" })
toggleRow(farmPage, { key = "autoDestroyTree", icon = "trash", title = "Auto Destroy Trees", desc = "Destroys all trees" })
-- dynamic fruit toggles will go here

sectionLabel(farmPage, "Buy Orchard Items")
toggleRow(farmPage, { key = "buy_Clover", icon = "leaf", title = "Auto Buy Clover", desc = "" })
toggleRow(farmPage, { key = "buy_Radioactive", icon = "radiation", title = "Auto Buy Radioactive", desc = "" })
toggleRow(farmPage, { key = "buy_Irrigation", icon = "droplets", title = "Auto Buy Irrigation", desc = "" })
toggleRow(farmPage, { key = "buy_FertilizerQuickGrow", icon = "zap", title = "Auto Buy FertilizerQuickGrow", desc = "" })
toggleRow(farmPage, { key = "buy_FertilizerCleanse", icon = "sparkles", title = "Auto Buy FertilizerCleanse", desc = "" })
toggleRow(farmPage, { key = "buy_FertilizerMutate", icon = "flask-conical", title = "Auto Buy FertilizerMutate", desc = "" })
toggleRow(farmPage, { key = "buy_Enricher", icon = "flower", title = "Auto Buy Enricher", desc = "" })

-- ── Prestige tab ──
sectionLabel(prestigePage, "Prestige loops")
toggleRow(prestigePage, { key = "rebirth", icon = "refresh-cw", title = "Auto Rebirth",
    desc = "Rebirths when investors are available" })
toggleRow(prestigePage, { key = "evolve", icon = "dna", title = "Auto Evolve",
    desc = "Evolves at 100% progress" })
sectionLabel(prestigePage, "Danger zone")
toggleRow(prestigePage, { key = "ascend", icon = "crown", title = "Auto Ascend", danger = true, confirm = true,
    desc = "RESETS ALL PROGRESS — double-click to arm" })

-- ── Extras tab ──
sectionLabel(extrasPage, "Minigames")
toggleRow(extrasPage, { key = "tradeMinigame", icon = "trending-up", title = "Auto Trade Minigame",
    desc = "Auto-plays stock trading minigame for profit" })
toggleRow(extrasPage, { key = "minigame", icon = "gamepad-2", title = "Auto Race Minigame",
    desc = "Instant 1st place reward (~5 min CD)" })
sectionLabel(extrasPage, "Rewards")
toggleRow(extrasPage, { key = "autoAds", icon = "tv", title = "Auto Watch Ads",
    desc = "Auto-watches available ads for rewards" })
toggleRow(extrasPage, { key = "voidEvents", icon = "zap", title = "Auto Void Events",
    desc = "Auto-participates in void events for multipliers" })

-- ── Settings tab ──
sectionLabel(settingsPage, "Player")
toggleRow(settingsPage, { key = "antiAfk", icon = "shield-check", title = "Anti-AFK",
    desc = "Blocks the 20-minute idle kick" })
toggleRow(settingsPage, { key = "wsEnabled", icon = "footprints", title = "WalkSpeed Override",
    desc = "Applies the speed below every frame" })
sliderRow(settingsPage, { key = "wsValue", icon = "gauge", title = "WalkSpeed", min = 16, max = 120,
    desc = "Drag to adjust", suffix = " studs/s" })
sectionLabel(settingsPage, "Interface")
buttonRow(settingsPage, { icon = "move", title = "Toggle UI  —  RightShift",
    desc = "Hide / show this window", onClick = function() end })
buttonRow(settingsPage, { icon = "power", title = "Unload Lemon Hub", danger = true,
    desc = "Removes the GUI and stops all loops",
    onClick = function() getgenv().LemonHubV4.Destroy() end })

-- ══════════════ Minimize bubble ══════════════
local bubble = mk("TextButton", {
    BackgroundColor3 = T.Accent, Text = "", AutoButtonColor = false, Visible = false,
    AnchorPoint = Vector2.new(0, 0.5), Position = UDim2.new(0, 16, 0.5, 0),
    Size = UDim2.fromOffset(48, 48), Parent = gui,
}, { corner(24), stroke(0.6) })
local bubbleIc = icon("citrus", 24, T.AccentTxt, bubble)
bubbleIc.AnchorPoint = Vector2.new(0.5, 0.5)
bubbleIc.Position = UDim2.fromScale(0.5, 0.5)
makeDraggable(bubble, bubble)

local minimized = false
local function setMinimized(v)
    minimized = v
    if v then
        tween(win, TI_MED, { Size = UDim2.fromOffset(WIN_W, 0) })
        task.delay(0.2, function() if minimized then win.Visible = false end end)
        bubble.Visible = true
        bubble.Size = UDim2.fromOffset(0, 0)
        tween(bubble, TI_POP, { Size = UDim2.fromOffset(48, 48) })
    else
        win.Visible = true
        tween(win, TI_POP, { Size = UDim2.fromOffset(WIN_W, WIN_H) })
        bubble.Visible = false
    end
end
track(minBtn.MouseButton1Click:Connect(function() setMinimized(true) end))
local bubbleDownPos
track(bubble.MouseButton1Down:Connect(function(x, y) bubbleDownPos = Vector2.new(x, y) end))
track(bubble.MouseButton1Up:Connect(function(x, y)
    if bubbleDownPos and (Vector2.new(x, y) - bubbleDownPos).Magnitude < 6 then
        setMinimized(false)
    end
end))
track(UserInputService.InputBegan:Connect(function(input, gpe)
    if gpe then return end
    if input.KeyCode == Enum.KeyCode.RightShift then
        if minimized then setMinimized(false) else gui.Enabled = not gui.Enabled end
    end
end))

-- close button = minimize to bubble (unload lives in Settings)
track(closeBtn.MouseButton1Click:Connect(function() setMinimized(true) end))

-- open animation
win.Size = UDim2.fromOffset(WIN_W, 0)
tween(win, TI_POP, { Size = UDim2.fromOffset(WIN_W, WIN_H) })
dashTab.select()
print("[LemonHub] UI built")

-- ══════════════════════════════════════════
--        ASYNC GAME-MODULE BOOTSTRAP
-- ══════════════════════════════════════════
-- Every require runs in its own thread with a timeout, so a module
-- that hangs on require can never freeze the executor pipeline.
local G = {}          -- loaded game modules
local bootDone = false

local function tryRequireAsync(label, timeout, getter)
    local done, val = false, nil
    task.spawn(function()
        local ok, m = pcall(getter)
        if ok then val = m end
        done = true
    end)
    local t0 = os.clock()
    while not done and os.clock() - t0 < (timeout or 3) do
        task.wait(0.1)
    end
    if not done then print("[LemonHub] require TIMEOUT: " .. label) end
    return val
end

local POWER_NAMES = { "UpgradeStack", "BuyNext", "Manage", "WalkSpeed", "ClickFruitValue" }

local function fmt(v)
    if v == nil then return "—" end
    if G.Huge then
        local ok, s = pcall(G.Huge.formatAbbreviated, v)
        if ok and s then return tostring(s) end
    end
    return tostring(v)
end

-- ══════════════ Engine state ══════════════
local lastErr, lastErrAt = nil, 0
local function reportErr(tag, err)
    local key = tag .. tostring(err)
    if key == lastErr and os.clock() - lastErrAt < 10 then return end
    lastErr, lastErrAt = key, os.clock()
    log("⚠ " .. tag .. ": " .. tostring(err):sub(1, 80), T.Red)
end

-- fresh handles every call — tycoon instance changes on respawn
local function ctx()
    if not G.Tycoon then return nil end
    local ok, c = pcall(function()
        local t = G.Tycoon.getLocal()
        if not t then return nil end
        return {
            t    = t,
            inst = t.Instance,
            bal  = G.CompBalances and t:GetComponent(G.CompBalances) or nil,
            reb  = G.CompRebirth and t:GetComponent(G.CompRebirth) or nil,
            evo  = G.CompEvolution and t:GetComponent(G.CompEvolution) or nil,
            asc  = G.CompAscension and t:GetComponent(G.CompAscension) or nil,
            pow  = G.CompPowers and t:GetComponent(G.CompPowers) or nil,
            pho  = G.CompPhone and t:GetComponent(G.CompPhone) or nil,
            ocf  = G.CompOrchard and t:GetComponent(G.CompOrchard) or nil,
        }
    end)
    if ok then return c end
    return nil
end

local function tycoonRemotes(c)
    if c and c.inst then
        local r = c.inst:FindFirstChild("Remotes")
        if r then return r end
    end
    return nil
end

-- ── Feature: buy tiles ──
local buyLock = {}
local function runBuyTiles(c)
    if not c or not c.inst then return end
    for _, inst in ipairs(CollectionService:GetTagged("Tycoon.Purchase")) do
        if inst:IsDescendantOf(c.inst)
        and inst:GetAttribute("Shown") == true
        and inst:GetAttribute("Purchased") ~= true then
            if buyLock[inst] then continue end
            local rf = inst:FindFirstChild("Purchase")
            if rf and rf:IsA("RemoteFunction") then
                buyLock[inst] = true
                task.spawn(function()
                    pcall(function() rf:InvokeServer(false) end)
                    task.wait(0.1)
                    buyLock[inst] = nil
                end)
            end
        end
    end
end

local INCOME_STREAMS = {
    "LemonDash", "LemonDepot", "LemonLabs",
    "LemonTrading", "LemonRepublic", "LemonRobotics",
    "LemonStand", "LemonX"
}
local function runAutoClickIncome(c)
    if not c or not c.inst then return end
    local remotes = tycoonRemotes(c)
    local rf = remotes and remotes:FindFirstChild("WakeIncomeStream")
    if not rf then return end
    for _, stream in ipairs(INCOME_STREAMS) do
        task.spawn(function() pcall(function() rf:InvokeServer(stream) end) end)
    end
end

-- ── Feature: upgrade earners (exponential bulk-buy via raw remote) ──
local earnerBulk = {}   -- inst -> last successful count (start point)
local function runUpgradeEarners(c)
    if not c then return end
    for _, inst in ipairs(CollectionService:GetTagged("Tycoon.Earner")) do
        if inst:IsDescendantOf(c.inst) then
            local rf = inst:FindFirstChild("Upgrade")
            if rf and rf:IsA("RemoteFunction") then
                task.spawn(function()
                    -- exponential doubling: buy 1, 2, 4, 8... until "cannot afford"
                    local total = 0
                    local count = earnerBulk[inst] or 1
                    while alive and State.upgradeEarners do
                        local ok = pcall(function() return rf:InvokeServer(count) end)
                        if ok then
                            total += count
                            count *= 2
                        else
                            count = math.max(1, math.floor(count / 2))
                            break
                        end
                        if total > 4096 then break end
                        task.wait()
                    end
                    earnerBulk[inst] = math.max(1, math.floor(count / 2))
                    if total > 0 then
                        log(("Upgraded %s +%d levels"):format(inst.Name, total), T.Green)
                    end
                end)
            end
        end
    end
end

-- ── Feature: wake earners ──
local function runWakeEarners(c)
    if not c then return end
    local remotes = tycoonRemotes(c)
    if not remotes then return end
    local rf = remotes:FindFirstChild("WakeIncomeStream")
    if not rf then return end
    for _, inst in ipairs(CollectionService:GetTagged("Tycoon.Earner")) do
        if inst:IsDescendantOf(c.inst) then
            task.spawn(function() pcall(function() rf:InvokeServer(inst.Name) end) end)
        end
    end
end

-- ── Feature: powers (cost INVESTORS, not cash — server validates) ──
local function runPowers(c)
    if not c then return end
    if c.pow and c.bal then
        local ok, investors = pcall(function() return c.bal:GetInvestors() end)
        if ok then
            for _, name in ipairs(POWER_NAMES) do
                pcall(function()
                    local lvl, max = c.pow:GetLevel(name), c.pow:GetMaxLevel(name)
                    if lvl and max and lvl < max then
                        local price = c.pow:GetUpgradePrice(name)
                        if price and price <= investors then
                            c.pow:UpgradeAsync(name)
                            log("Power up: " .. name, T.Violet)
                        end
                    end
                end)
            end
            return
        end
    end
    -- raw fallback: server rejects if unaffordable
    local remotes = tycoonRemotes(c)
    local rf = remotes and remotes:FindFirstChild("UpgradePowerLevel")
    if rf then
        for _, name in ipairs(POWER_NAMES) do
            task.spawn(function() pcall(function() rf:InvokeServer(name) end) end)
        end
    end
end

-- ── Feature: phone deals ──
local function runPhone(c)
    if not c then return end
    task.spawn(function()
        if c.pho then
            local handled = pcall(function()
                if c.pho:GetCurrentOffer() ~= nil then
                    pcall(function() c.pho:RaiseOffer() end)
                    task.wait(0.8)
                    pcall(function() c.pho:AcceptOffer() end)
                    log("Accepted phone deal (Raised then Accepted)", T.Green)
                end
            end)
            if handled then return end
        end
        local remotes = tycoonRemotes(c)
        local re = remotes and remotes:FindFirstChild("PhoneOffer")
        if re then
            pcall(function() re:FireServer("Raise") end)
            task.wait(0.8)
            pcall(function() re:FireServer("Accept") end)
        end
    end)
end

-- ── Feature: rebirth / evolve / ascend ──
local function runRebirth(c)
    if not c then return end
    if c.reb and G.Huge then
        local eligible = false
        pcall(function() eligible = G.Huge.one < c.reb:GetPotentialInvestors() end)
        if not eligible then return end
    end
    local remotes = tycoonRemotes(c)
    local rf = remotes and remotes:FindFirstChild("Rebirth")
    if rf then
        task.spawn(function() pcall(function() rf:InvokeServer() end) end)
    end
end

local function runEvolve(c)
    if not c then return end
    if c.evo then
        local eligible = true
        pcall(function() eligible = (c.evo:GetEvolutionProgress() or 0) >= 1 end)
        if not eligible then return end
    end
    local remotes = tycoonRemotes(c)
    local rf = remotes and remotes:FindFirstChild("Evolve")
    if rf then
        task.spawn(function() pcall(function() rf:InvokeServer() end) end)
    end
end

local function runAscend(c)
    if not c then return end
    if c.asc then
        local eligible = false
        pcall(function() eligible = (c.asc:GetAscension() or 0) >= 1 and c.asc:IsDiscovered() end)
        if not eligible then return end
    end
    local remotes = tycoonRemotes(c)
    local rf = remotes and remotes:FindFirstChild("Ascend")
    if rf then
        task.spawn(function() pcall(function() rf:InvokeServer() end) end)
    end
end

-- ── Feature: race minigame exploit ──
local raceNext = 0
local function runMinigame()
    task.spawn(function()
        if not G.raceStart or not G.raceEnd then return end
        if os.clock() < raceNext then return end
        raceNext = os.clock() + 20 -- assume cooldown until proven otherwise
        local ok, res = pcall(function() return G.raceStart:InvokeServer() end)
        if ok and res ~= nil then
            task.wait(0.4)
            pcall(function() G.raceEnd:InvokeServer(1) end)
            raceNext = os.clock() + 310
            log("Race minigame: 1st place claimed 🏆", T.Accent)
            toast("Minigame reward", "Fake 1st place payout collected", "trophy", T.Accent)
        end
    end)
end

-- ── Feature: trade minigame exploit ──
local tradeNext = 0
local function runTradeMinigame()
    task.spawn(function()
        if not G.tradeStart or not G.tradeEnd then return end
        if os.clock() < tradeNext then return end
        tradeNext = os.clock() + 30 -- assume cooldown
        local ok, res = pcall(function() return G.tradeStart:InvokeServer() end)
        if ok and res ~= nil then
            task.wait(2) -- wait for trading period
            pcall(function() G.tradeEnd:InvokeServer(1) end) -- 1st place
            tradeNext = os.clock() + 300 -- 5 min cooldown
            log("Trade minigame: 1st place claimed 📈", T.Green)
            toast("Trade reward", "Stock trading profit collected", "trending-up", T.Green)
        end
    end)
end

-- ── Feature: auto watch ads ──
local adNext = 0
local function runAutoAds()
    task.spawn(function()
        if os.clock() < adNext then return end
        if not G.showAd then return end
        adNext = os.clock() + 60 -- check every minute
        local ok = pcall(function() return G.showAd:InvokeServer() end)
        if ok then
            adNext = os.clock() + 300 -- 5 min cooldown after success
            log("Ad watched for rewards 📺", T.Blue)
        end
    end)
end

-- ── Feature: auto void events ──
local voidNext = 0
local function runVoidEvents()
    if os.clock() < voidNext then return end
    voidNext = os.clock() + 10 -- check every 10 seconds
    -- Void events are handled via RemoteSignal, we'll listen for them
    -- This is a placeholder for void event participation
end

-- ── Feature: harvest lemons ──
local harvestIdx = 0
local function collectFruit(c)
    local cds = {}
    for _, tree in ipairs(workspace:GetChildren()) do
        if tree.Name == "LemonTree" then
            for _, d in ipairs(tree:GetDescendants()) do
                if d:IsA("ClickDetector") then table.insert(cds, d) end
            end
        end
    end
    if c and c.inst then
        for _, d in ipairs(c.inst:GetDescendants()) do
            if d:IsA("ClickDetector") and d.Parent and d.Parent.Name == "ClickPart" then
                table.insert(cds, d)
            end
        end
    end
    return cds
end
local function runHarvestOrchard(c)
    if not c or not c.inst then return end
    local req = RS:FindFirstChild("Core") and RS.Core:FindFirstChild("RemoteRequest")
    local harvRemote = req and req:FindFirstChild("OrchardPlot.Harvest")
    if not harvRemote then return end
    
    local orchard = c.inst:FindFirstChild("Orchard")
    local plots = orchard and orchard:FindFirstChild("Plots")
    if plots then
        for _, plot in ipairs(plots:GetChildren()) do
            task.spawn(function() pcall(function() harvRemote:InvokeServer(plot) end) end)
        end
    end
end

local spawnedFruitToggles = {}
local function clickSellButtons()
    local gui = LP:FindFirstChild("PlayerGui")
    if not gui then return end
    for _, obj in ipairs(gui:GetDescendants()) do
        if obj:IsA("TextButton") or obj:IsA("ImageButton") then
            local txt = ""
            pcall(function() txt = (obj.Text or "") end)
            if txt == "" and obj:FindFirstChildOfClass("TextLabel") then
                pcall(function() txt = (obj:FindFirstChildOfClass("TextLabel").Text or "") end)
            end
            txt = string.lower(txt)
            if string.find(txt, "sell all") or string.find(txt, "sell") then
                -- Ensure it's the orchard sell button by checking hierarchy or just firing it
                -- The game usually has 'Sell' for other things too, but 'sell all fruits' is specific.
                -- Let's just fire anything with "sell all fruits" or "sell all"
                if string.find(txt, "sell all fruits") or string.find(txt, "sell") then
                    pcall(function()
                        for _, conn in ipairs(getconnections(obj.MouseButton1Click)) do
                            conn:Fire()
                        end
                    end)
                    pcall(function()
                        for _, conn in ipairs(getconnections(obj.Activated)) do
                            conn:Fire()
                        end
                    end)
                end
            end
        end
    end
end

local function runSellFruits(c)
    if not c or not c.inst then return end
    local sellEvent = c.inst:FindFirstChild("Values") and c.inst.Values:FindFirstChild("SellFruit")
    
    if c.ocf and c.ocf._Table then
        local t = nil
        pcall(function() t = c.ocf._Table:Get() end)
        if type(t) == "table" then
            local toSell = {}
            local anySold = false
            for fruitObj, amount in pairs(t) do
                local name = "Unknown Fruit"
                pcall(function() name = c.ocf:GetFruitName(fruitObj) or fruitObj[2] or "Unknown Fruit" end)
                if not spawnedFruitToggles[name] then
                    spawnedFruitToggles[name] = true
                    local key = "keep_" .. name
                    State[key] = false
                    toggleRow(farmPage, { key = key, icon = "apple", title = "Keep " .. name, desc = "Check to NOT sell this fruit" })
                end
                
                local key = "keep_" .. name
                if not State[key] and amount > 0 then
                    -- Direct invoke bypass
                    if sellEvent then
                        pcall(function() sellEvent:InvokeServer(fruitObj, amount) end)
                    end
                    toSell[fruitObj] = amount
                    anySold = true
                end
            end
            if anySold then
                pcall(function() c.ocf:SellFruitsAsync(toSell) end)
            end
        end
    end
    
    -- Fallback: aggressively click all UI sell buttons
    clickSellButtons()
end

local function runHarvest(c)
    local char = LP.Character
    local hrp = char and char:FindFirstChild("HumanoidRootPart")
    if not hrp then return end
    local cds = collectFruit(c)
    if #cds == 0 then return end
    harvestIdx = (harvestIdx % #cds) + 1
    local target = cds[harvestIdx]
    local treePart = target.Parent
    if not (treePart and treePart:IsA("BasePart")) then return end
    hrp.CFrame = treePart.CFrame + Vector3.new(0, 3, 0)
    -- Click ALL lemons on this tree
    for _, cd in ipairs(cds) do
        local p = cd.Parent
        if p and p:IsA("BasePart") and p == treePart then
            pcall(function() fireclickdetector(cd) end)
        end
    end
    harvestIdx = harvestIdx + 7 -- skip just-harvested neighbours
end

local dropTeleporting = false
local function runCollectCashDropsFallback()
    task.spawn(function()
        if dropTeleporting then return end
        local char = LP.Character
        local hrp = char and char:FindFirstChild("HumanoidRootPart")
        if not hrp then return end
        local dropsFolder = workspace:FindFirstChild("CashDrops")
        if not dropsFolder then return end
        local parts = {}
        for _, obj in ipairs(dropsFolder:GetDescendants()) do
            if obj:IsA("BasePart") then table.insert(parts, obj) end
        end
        if #parts == 0 then return end
        dropTeleporting = true
        local saved = hrp.CFrame
        for _, part in ipairs(parts) do
            if not alive or not State.cashDrops then break end
            if part and part.Parent then
                pcall(function() hrp.CFrame = CFrame.new(part.Position + Vector3.new(0, 1, 0)) end)
                task.wait(0.4) -- wait longer to collect
            end
        end
        pcall(function() hrp.CFrame = saved end)
        dropTeleporting = false
    end)
end

-- ── Anti-AFK ──
track(LP.Idled:Connect(function()
    if State.antiAfk then
        pcall(function()
            local vu = game:GetService("VirtualUser")
            vu:CaptureController()
            vu:ClickButton2(Vector2.new())
        end)
    end
end))

-- ── WalkSpeed enforce ──
track(RunService.Heartbeat:Connect(function()
    if State.wsEnabled and alive then
        local char = LP.Character
        local hum = char and char:FindFirstChildOfClass("Humanoid")
        if hum and hum.WalkSpeed ~= State.wsValue then hum.WalkSpeed = State.wsValue end
    end
    if alive then
        local c = ctx()
        if c then
            if State.buyTiles then runBuyTiles(c) end
            if State.upgradeEarners then runUpgradeEarners(c) end
            if State.wakeEarners then runAutoClickIncome(c) end
        end
    end
end))

local DEFAULT_PLANT_DATA = { 3, { WalkSpeed1 = 1, Luck1 = 1, Rate1 = 1, Slimy = 1, Rate3 = 1, ValueBad1 = 1, GrowthRate1 = 2, Rate4 = 1, Rate2 = 1, Value3 = 1, Void = 1, RateBad1 = 2, Value2 = 1, GrowthRateBad1 = 3, Value1 = 1 } }
local USE_ITEMS_LIST = { "FertilizerMutate", "FertilizerQuickGrow", "Radioactive", "Irrigation", "Clover", "Enricher" }

local function runOrchardActions(c)
    if not c or not c.inst then return end
    local req = RS:FindFirstChild("Core") and RS.Core:FindFirstChild("RemoteRequest")
    if not req then return end
    
    local plantRemote = req:FindFirstChild("OrchardPlot.Plant")
    local useRemote = req:FindFirstChild("OrchardPlot.UseItem")
    local destroyRemote = req:FindFirstChild("OrchardPlot.DestroyTree")
    
    local orchard = c.inst:FindFirstChild("Orchard")
    local plots = orchard and orchard:FindFirstChild("Plots")
    if not plots then return end
    
    for _, plot in ipairs(plots:GetChildren()) do
        if State.autoPlant and plantRemote then
            task.spawn(function() pcall(function() plantRemote:InvokeServer(plot, DEFAULT_PLANT_DATA) end) end)
        end
        if State.autoUseItems and useRemote then
            for _, item in ipairs(USE_ITEMS_LIST) do
                task.spawn(function() pcall(function() useRemote:InvokeServer(plot, item) end) end)
            end
        end
        if State.autoUseCleanse and useRemote then
            task.spawn(function() pcall(function() useRemote:InvokeServer(plot, "FertilizerCleanse") end) end)
        end
        if State.autoDestroyTree and destroyRemote then
            task.spawn(function() pcall(function() destroyRemote:InvokeServer(plot) end) end)
        end
    end
end

-- ── Scheduler ──
local features = {
        { key = "wakeEarners",    fn = runWakeEarners,    every = 5.0 },
    { key = "powers",         fn = runPowers,         every = 3.0 },
    { key = "phoneDeals",     fn = runPhone,          every = 4.0 },
    { key = "rebirth",        fn = runRebirth,        every = 5.0 },
    { key = "evolve",         fn = runEvolve,         every = 5.0 },
    { key = "ascend",         fn = runAscend,         every = 10.0 },
    { key = "minigame",       fn = runMinigame,       every = 5.0 },
    { key = "tradeMinigame",  fn = runTradeMinigame,  every = 5.0 },
    { key = "autoAds",        fn = runAutoAds,        every = 30.0 },
    { key = "voidEvents",     fn = runVoidEvents,     every = 10.0 },
    { key = "harvest",        fn = runHarvest,        every = 3.0 },
    { key = "cashDrops",      fn = runCollectCashDropsFallback, every = 4.0 },
        { key = "harvestOrchard", fn = runHarvestOrchard, every = 4.0 },
    { key = "sellFruits",     fn = runSellFruits,     every = 8.0 },
    { key = "orchardLoop",    fn = runOrchardActions, every = 2.0, alwaysRun = true },
}

local ORCHARD_ITEMS = { "Clover", "Radioactive", "Irrigation", "FertilizerQuickGrow", "FertilizerCleanse", "FertilizerMutate", "Enricher" }
for _, item in ipairs(ORCHARD_ITEMS) do
    table.insert(features, { key = "buy_" .. item, fn = function(c) 
        local rem = tycoonRemotes(c)
        local rf = rem and rem:FindFirstChild("BuyOrchardItems")
        if rf then pcall(function() rf:InvokeServer(item, 1, nil) end) end
    end, every = 2.0 })
end
for _, f in ipairs(features) do f.nextRun = 0 end

-- ══════════════ Boot + loops (all async) ══════════════
task.spawn(function()
    -- load game modules with timeouts
    G.Tycoon = tryRequireAsync("Tycoon", 3, function() return require(RS.Modules.Tycoon.Tycoon) end)
    G.Huge   = tryRequireAsync("Huge", 3, function() return require(RS.Modules.Huge) end)
    G.CompBalances  = tryRequireAsync("Balances", 3, function() return require(RS.Modules.Tycoon.Component.TycoonBalances) end)
    G.CompRebirth   = tryRequireAsync("Rebirth", 3, function() return require(RS.Modules.Tycoon.Component.Client.ClientTycoonRebirth) end)
    G.CompEvolution = tryRequireAsync("Evolution", 3, function() return require(RS.Modules.Tycoon.Component.Client.ClientTycoonEvolution) end)
    G.CompAscension = tryRequireAsync("Ascension", 3, function() return require(RS.Modules.Tycoon.Component.Client.ClientTycoonAscension) end)
    G.CompPowers    = tryRequireAsync("Powers", 3, function() return require(RS.Modules.Tycoon.Component.Client.ClientTycoonPowers) end)
    G.CompPhone     = tryRequireAsync("Phone", 3, function() return require(RS.Modules.Tycoon.Component.Client.ClientTycoonPhoneOffers) end)
    G.CompOrchard   = tryRequireAsync("Orchard", 3, function() return require(RS.Modules.Tycoon.Orchard.Client.ClientOrchardFruits) end)
    G.SerializationService = tryRequireAsync("SerializationService", 3, function() return require(RS.Core.SerializationService) end)
    local RemoteRequest = tryRequireAsync("RemoteRequest", 3, function() return require(RS.Core.RemoteRequest) end)
    local RemoteSignal  = tryRequireAsync("RemoteSignal", 3, function() return require(RS.Core.RemoteSignal) end)

    if RemoteRequest then
        pcall(function() G.raceStart = RemoteRequest.new("MinigameRaceService.Start") end)
        pcall(function() G.raceEnd = RemoteRequest.new("MinigameRaceService.End") end)
        pcall(function() G.tradeStart = RemoteRequest.new("MinigameTradeService.Start") end)
        pcall(function() G.tradeEnd = RemoteRequest.new("MinigameTradeService.End") end)
        pcall(function() G.redeem = RemoteRequest.new("CashDropService.Redeem") end)
        pcall(function() G.showAd = RemoteRequest.new("VideoAdService.ShowAd") end)
    end
    -- cash drops: event-driven redeem
    if RemoteSignal and G.redeem then
        pcall(function()
            local sig = RemoteSignal.new("CashDropService.New")
            local connFn
            for _, m in ipairs({ "Connect", "connect" }) do
                local okI, f = pcall(function() return sig[m] end)
                if okI and type(f) == "function" then connFn = f break end
            end
            if connFn then
                track(connFn(sig, function(id)
                    if State.cashDrops and alive then
                        task.wait(0.2)
                        pcall(function() G.redeem:InvokeServer(id) end)
                        log("Cash drop redeemed", T.Green)
                    end
                end))
                print("[LemonHub] cash drop listener attached")
            end
        end)
    end

    local loaded = 0
    for _ in pairs(G) do loaded += 1 end
    bootDone = true
    print("[LemonHub] boot done, modules loaded: " .. loaded)
    log("Engine ready (" .. loaded .. " modules)", T.Green)

    -- main scheduler loop
    while alive do
        local now = os.clock()
        local c = nil
        for _, f in ipairs(features) do
            if (f.alwaysRun or State[f.key]) and now >= f.nextRun then
                if c == nil then c = ctx() or false end
                f.nextRun = now + f.every
                if c then
                    local ok, err = pcall(f.fn, c)
                    if not ok then reportErr(f.key, err) end
                end
            end
        end
        task.wait(0.25)
    end
end)

-- ── Stats loop ──
task.spawn(function()
    local lastCash, earned = nil, nil
    local windowEarned, windowT, rateStr = nil, os.clock(), "…"
    local lastRebirths, lastEvolves, lastAscension = nil, nil, nil
    while alive do
        if bootDone then
            local c = ctx()
            if c and c.bal then
                pcall(function()
                    local cash = c.bal:GetCash()
                    statValues["Cash"].Text = "$" .. fmt(cash)
                    statValues["Investors"].Text = fmt(c.bal:GetInvestors())
                    pcall(function()
                        if lastCash ~= nil and lastCash < cash then
                            local delta = cash - lastCash
                            earned = earned ~= nil and (earned + delta) or delta
                        end
                        lastCash = cash
                        if earned ~= nil then
                            statValues["Session earned"].Text = "$" .. fmt(earned)
                            if os.clock() - windowT >= 60 then
                                if windowEarned ~= nil then
                                    rateStr = "$" .. fmt(earned - windowEarned) .. "/min"
                                end
                                windowEarned = earned
                                windowT = os.clock()
                            end
                            statValues["Rate"].Text = rateStr
                        end
                    end)
                end)
                pcall(function()
                    if c.reb then
                        local rs = fmt(c.reb:GetRebirths())
                        if lastRebirths and rs ~= lastRebirths then
                            toast("Rebirthed!", "Investor count increased", "refresh-cw", T.Green)
                            log("Rebirthed → " .. rs .. " total", T.Accent)
                        end
                        lastRebirths = rs
                        statValues["Rebirths"].Text = rs
                    end
                    if c.evo then
                        local e = c.evo:GetTotalEvolves()
                        if lastEvolves and e ~= lastEvolves then
                            toast("Evolved!", "Evolution " .. tostring(e), "dna", T.Violet)
                            log("Evolved → " .. tostring(e), T.Violet)
                        end
                        lastEvolves = e
                    end
                    if c.asc then
                        local a = c.asc:GetAscension()
                        if lastAscension and a ~= lastAscension then
                            toast("Ascended!", "Ascension " .. tostring(a), "crown", T.Accent)
                            log("ASCENDED → " .. tostring(a), T.Accent)
                        end
                        lastAscension = a
                    end
                end)
            end
            if statValues["Race cooldown"] then
                local left = raceNext - os.clock()
                statValues["Race cooldown"].Text =
                    (not State.minigame) and "off"
                    or (left <= 0 and "ready…"
                    or ("%d:%02d"):format(math.floor(left / 60), math.floor(left % 60)))
            end
        end
        local active = 0
        for _, f in ipairs(features) do if State[f.key] then active += 1 end end
        statusDot.BackgroundColor3 = active > 0 and T.Green or T.TextFaint
        statusLbl.Text = not bootDone and "booting" or (active > 0 and (active .. " active") or "idle")
        task.wait(1)
    end
end)

-- ══════════════ Public handle / destroy ══════════════
getgenv().LemonHubV4 = {
    Destroy = function()
        alive = false
        for _, con in ipairs(connections) do
            pcall(function() con:Disconnect() end)
        end
        pcall(function() gui:Destroy() end)
        getgenv().LemonHubV4 = nil
    end,
    State = State,
    Toggles = Toggles,
}

toast("Lemon Hub v4.1", "Loaded — RightShift to toggle UI", "citrus", T.Accent)
print("[LemonHub] v4.1 ready")
