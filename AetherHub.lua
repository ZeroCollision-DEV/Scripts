local g = (getgenv and getgenv()) or _G
if g.AetherUnload then pcall(g.AetherUnload) end
if g.AetherHubUnload then pcall(g.AetherHubUnload) end

local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local UIS = game:GetService("UserInputService")
local TweenService = game:GetService("TweenService")
local Lighting = game:GetService("Lighting")
local SoundService = game:GetService("SoundService")
local Debris = game:GetService("Debris")
local HttpService = game:GetService("HttpService")
local TeleportService = game:GetService("TeleportService")
local CAS = game:GetService("ContextActionService")
local Stats = game:GetService("Stats")

local lp = Players.LocalPlayer
local cam = workspace.CurrentCamera
local origFov = cam and cam.FieldOfView or 70
local origGravity = workspace.Gravity
local startTime = os.clock()

local function rgb(r, gg, b) return Color3.fromRGB(r, gg, b) end

local function guiParent()
	local ok, p = pcall(function() return (gethui and gethui()) or game:GetService("CoreGui") end)
	if ok and p then return p end
	return lp:WaitForChild("PlayerGui")
end

local Theme = { text = rgb(233, 239, 248), dim = rgb(143, 156, 180) }
local Backgrounds = {
	["Holystone"] = rgb(23, 28, 38),
	["Night Sky"] = rgb(14, 20, 38),
	["Deep Water"] = rgb(12, 29, 41),
	["Zanite"] = rgb(27, 22, 45),
	["Warm Stone"] = rgb(33, 29, 27),
}
local Accents = {
	["Glowstone"] = { rgb(255, 196, 71), rgb(74, 157, 255) },
	["Water"] = { rgb(74, 157, 255), rgb(120, 228, 214) },
	["Zanite"] = { rgb(150, 122, 255), rgb(110, 200, 255) },
	["Aether Grass"] = { rgb(110, 220, 160), rgb(255, 196, 71) },
}
local Custom = { h1 = .12, h2 = .58 }
local painters = {}
local function reg(fn) painters[#painters + 1] = fn; fn(false) end
local function repaint() for _, fn in ipairs(painters) do pcall(fn, true) end end

local function setBackground(name)
	local base = Backgrounds[name]; if not base then return end
	Theme.bg = base
	Theme.side = base:Lerp(Color3.new(0, 0, 0), .25)
	Theme.card = base:Lerp(Color3.new(1, 1, 1), .045)
	Theme.row = base:Lerp(Color3.new(1, 1, 1), .09)
	Theme.line = base:Lerp(Color3.new(1, 1, 1), .15)
	Theme.off = base:Lerp(Color3.new(1, 1, 1), .22)
	repaint()
end
local function setAccent(name)
	if name == "Custom" then
		Theme.accent, Theme.accent2 = Color3.fromHSV(Custom.h1, .75, 1), Color3.fromHSV(Custom.h2, .7, 1)
	else
		local set = Accents[name]; if not set then return end
		Theme.accent, Theme.accent2 = set[1], set[2]
	end
	repaint()
end
setBackground("Holystone")
setAccent("Glowstone")

local Anim = { speed = 1 }
local function tween(inst, t, props, style, dir)
	local tw = TweenService:Create(inst, TweenInfo.new(t / Anim.speed, style or Enum.EasingStyle.Quint, dir or Enum.EasingDirection.Out), props)
	tw:Play()
	return tw
end

local function new(class, props, parent)
	local inst = Instance.new(class)
	for k, v in pairs(props or {}) do
		if type(v) == "string" and v:sub(1, 1) == "@" then
			local key = v:sub(2)
			reg(function(animate)
				if animate then tween(inst, .35, { [k] = Theme[key] }, Enum.EasingStyle.Sine) else inst[k] = Theme[key] end
			end)
		else
			inst[k] = v
		end
	end
	if parent then inst.Parent = parent end
	return inst
end

local conns = {}
local function connect(sig, fn) local c = sig:Connect(fn); conns[#conns + 1] = c; return c end
local function corner(p, r) return new("UICorner", { CornerRadius = UDim.new(0, r) }, p) end
local function stroke(p, color, th, tr)
	return new("UIStroke", { Color = color or "@line", Thickness = th or 1, Transparency = tr or 0, ApplyStrokeMode = Enum.ApplyStrokeMode.Border }, p)
end
local function pad(p, t, r, b, l)
	return new("UIPadding", { PaddingTop = UDim.new(0, t), PaddingRight = UDim.new(0, r), PaddingBottom = UDim.new(0, b), PaddingLeft = UDim.new(0, l) }, p)
end
local function text(parent, str, size, color, font, align)
	return new("TextLabel", {
		BackgroundTransparency = 1, Text = str, TextSize = size, TextColor3 = color or "@text",
		Font = font or Enum.Font.BuilderSansMedium, TextXAlignment = align or Enum.TextXAlignment.Left, BorderSizePixel = 0,
	}, parent)
end
local order = setmetatable({}, { __mode = "k" })
local function nextOrder(p) order[p] = (order[p] or 0) + 1; return order[p] end

local Icons = {
	["traffic-cone"] = { 16898613869, 820, 355 }, ["car"] = { 16898612819, 918, 147 }, ["sparkles"] = { 16898613777, 918, 49 },
	["cloud-sun"] = { 16898613044, 0, 967 }, ["wand-sparkles"] = { 16898613869, 453, 918 }, ["palette"] = { 16898613613, 453, 918 },
	["settings"] = { 16898613777, 771, 257 }, ["x"] = { 16898613869, 869, 906 }, ["chevron-down"] = { 16898612819, 196, 918 },
	["gauge"] = { 16898613353, 771, 955 }, ["zap"] = { 16898613869, 918, 906 }, ["camera"] = { 16898612819, 967, 563 },
	["map-pin"] = { 16898613613, 820, 257 }, ["keyboard"] = { 16898613509, 453, 820 }, ["user"] = { 16898613869, 661, 869 },
	["save"] = { 16898613699, 918, 453 }, ["trash-2"] = { 16898613869, 257, 918 }, ["check"] = { 16898612819, 710, 869 },
	["gem"] = { 16898613353, 918, 857 }, ["layout-grid"] = { 16898613509, 918, 404 }, ["bell"] = { 16898612819, 820, 257 },
	["folder-open"] = { 16898613353, 820, 759 }, ["rotate-ccw"] = { 16898613699, 967, 355 }, ["refresh-cw"] = { 16898613699, 404, 869 },
	["flag"] = { 16898613353, 98, 918 }, ["eye"] = { 16898613353, 771, 563 }, ["plus"] = { 16898613699, 257, 918 },
	["navigation"] = { 16898613613, 771, 759 }, ["shield"] = { 16898613777, 869, 0 }, ["users"] = { 16898613869, 967, 98 },
}
local function icon(parent, name, size, color)
	local d = Icons[name]
	return new("ImageLabel", {
		BackgroundTransparency = 1, Image = "rbxassetid://" .. d[1], ImageRectSize = Vector2.new(48, 48), ImageRectOffset = Vector2.new(d[2], d[3]),
		Size = UDim2.fromOffset(size, size), ImageColor3 = color or "@text", BorderSizePixel = 0,
	}, parent)
end

local Sfx = { on = true, vol = .6 }
local SND_CLICK, SND_HOVER = "rbxassetid://6895079853", "rbxassetid://6895079853"
local function snd(id, pitch, vol)
	if not Sfx.on then return end
	local s = new("Sound", { SoundId = id, Volume = (vol or .5) * Sfx.vol, PlaybackSpeed = pitch or 1 }, SoundService)
	s:Play()
	Debris:AddItem(s, 3)
end

local Gui = new("ScreenGui", { Name = "AetherHub", ResetOnSpawn = false, DisplayOrder = 999, IgnoreGuiInset = true, ZIndexBehavior = Enum.ZIndexBehavior.Sibling }, guiParent())
local HudGui = new("ScreenGui", { Name = "AetherHubHUD", ResetOnSpawn = false, DisplayOrder = 998, IgnoreGuiInset = true }, guiParent())

local LogoMap = {
	"....WWW.....",
	"..WWWWWWW...",
	".WWWWWWWWWW.",
	"WWWWWWWWWWWW",
	".BBBBBBBBBB.",
	"..LLLLLLLL..",
	"..LYYYYYYy..",
	"..LYyYYyYy..",
	"..LYYYyYYy..",
	"..yyyyyyyy..",
}
local LogoColors = { W = rgb(246, 250, 255), B = rgb(166, 198, 236), L = rgb(255, 233, 150), Y = rgb(255, 196, 71), y = rgb(212, 146, 38) }
local twinkle = {}
local function makeLogo(parent, cell, position, anchor)
	local c = new("Frame", { BackgroundTransparency = 1, Size = UDim2.fromOffset(cell * 12, cell * 10), Position = position, AnchorPoint = anchor or Vector2.new(.5, .5) }, parent)
	for r, rowStr in ipairs(LogoMap) do
		for col = 1, 12 do
			local ch = rowStr:sub(col, col)
			if ch ~= "." then
				local f = new("Frame", { Size = UDim2.fromOffset(cell, cell), Position = UDim2.fromOffset((col - 1) * cell, (r - 1) * cell), BackgroundColor3 = LogoColors[ch], BorderSizePixel = 0 }, c)
				if ch == "Y" then twinkle[#twinkle + 1] = f end
			end
		end
	end
	return c
end

local NotifOn = true
local NotifHolder = new("Frame", { BackgroundTransparency = 1, AnchorPoint = Vector2.new(1, 1), Position = UDim2.new(1, -18, 1, -18), Size = UDim2.fromOffset(280, 400) }, Gui)
new("UIListLayout", { Padding = UDim.new(0, 8), VerticalAlignment = Enum.VerticalAlignment.Bottom, HorizontalAlignment = Enum.HorizontalAlignment.Right, SortOrder = Enum.SortOrder.LayoutOrder }, NotifHolder)

local function notify(title, body, dur, iconName)
	if not NotifOn then return end
	dur = dur or 3
	local t = Instance.new("CanvasGroup")
	t.Size = UDim2.fromOffset(270, 56); t.BackgroundColor3 = Theme.card; t.BorderSizePixel = 0; t.GroupTransparency = 1; t.LayoutOrder = nextOrder(NotifHolder)
	t.Parent = NotifHolder
	corner(t, 6)
	local st = Instance.new("UIStroke"); st.Color = Theme.line; st.Thickness = 1; st.ApplyStrokeMode = Enum.ApplyStrokeMode.Border; st.Parent = t
	local bar = Instance.new("Frame"); bar.Size = UDim2.new(0, 3, 1, 0); bar.BackgroundColor3 = Theme.accent; bar.BorderSizePixel = 0; bar.Parent = t
	local ic = Instance.new("ImageLabel")
	local d = Icons[iconName or "bell"]
	ic.BackgroundTransparency = 1; ic.Image = "rbxassetid://" .. d[1]; ic.ImageRectSize = Vector2.new(48, 48); ic.ImageRectOffset = Vector2.new(d[2], d[3])
	ic.Size = UDim2.fromOffset(18, 18); ic.Position = UDim2.fromOffset(16, 19); ic.ImageColor3 = Theme.accent; ic.Parent = t
	local tl = Instance.new("TextLabel")
	tl.BackgroundTransparency = 1; tl.Text = title; tl.TextSize = 14; tl.Font = Enum.Font.BuilderSansBold; tl.TextColor3 = Theme.text
	tl.TextXAlignment = Enum.TextXAlignment.Left; tl.Position = UDim2.fromOffset(44, 10); tl.Size = UDim2.new(1, -54, 0, 16); tl.TextTruncate = Enum.TextTruncate.AtEnd; tl.Parent = t
	local sl = Instance.new("TextLabel")
	sl.BackgroundTransparency = 1; sl.Text = body; sl.TextSize = 12; sl.Font = Enum.Font.BuilderSans; sl.TextColor3 = Theme.dim
	sl.TextXAlignment = Enum.TextXAlignment.Left; sl.Position = UDim2.fromOffset(44, 28); sl.Size = UDim2.new(1, -54, 0, 14); sl.TextTruncate = Enum.TextTruncate.AtEnd; sl.Parent = t
	local prog = Instance.new("Frame")
	prog.AnchorPoint = Vector2.new(0, 1); prog.Position = UDim2.fromScale(0, 1); prog.Size = UDim2.new(1, 0, 0, 2); prog.BackgroundColor3 = Theme.accent; prog.BorderSizePixel = 0; prog.Parent = t
	tween(t, .35, { GroupTransparency = 0 })
	tween(prog, dur, { Size = UDim2.new(0, 0, 0, 2) }, Enum.EasingStyle.Linear)
	task.delay(dur, function()
		if t.Parent then tween(t, .3, { GroupTransparency = 1 }).Completed:Wait(); t:Destroy() end
	end)
end

local Objs = {}
local DEFAULT_UI_KEY, DEFAULT_PANIC_KEY = Enum.KeyCode.RightShift, Enum.KeyCode.Delete
local uiKey, panicKey = DEFAULT_UI_KEY, DEFAULT_PANIC_KEY
local Window = {}
local sliderDrag
local listening
local infoRows = {}

local Root = new("Frame", { Name = "Root", AnchorPoint = Vector2.new(.5, .5), Position = UDim2.fromScale(.5, .5), Size = UDim2.fromOffset(700, 450), BackgroundTransparency = 1 }, Gui)
local RootScale = new("UIScale", { Scale = 1 }, Root)
local Shadow = new("ImageLabel", { BackgroundTransparency = 1, Image = "rbxassetid://6014261993", ImageColor3 = Color3.new(0, 0, 0), ImageTransparency = .5, ScaleType = Enum.ScaleType.Slice, SliceCenter = Rect.new(49, 49, 450, 450), AnchorPoint = Vector2.new(.5, .5), Position = UDim2.fromScale(.5, .5), Size = UDim2.new(1, 60, 1, 60), ZIndex = 0 }, Root)
local Main = new("CanvasGroup", { Size = UDim2.fromScale(1, 1), BackgroundColor3 = "@bg", BorderSizePixel = 0, GroupTransparency = 1 }, Root)
local MainCorner = corner(Main, 8)
local MainStroke = stroke(Main, "@line", 1, 0)

local Flecks = {}
local fleckLayer = new("Frame", { BackgroundTransparency = 1, Size = UDim2.fromScale(1, 1), ZIndex = 1 }, Main)
for i = 1, 22 do
	local sz = ({ 2, 3, 4 })[math.random(1, 3)]
	local f = new("Frame", { Size = UDim2.fromOffset(sz, sz), BackgroundColor3 = i % 4 == 0 and "@accent" or Color3.new(1, 1, 1), BackgroundTransparency = .93, BorderSizePixel = 0 }, fleckLayer)
	Flecks[i] = { f = f, x = math.random(), y = math.random(), s = .008 + math.random() * .02, ph = math.random() * 6.28 }
end

local Header = new("Frame", { Size = UDim2.new(1, 0, 0, 50), BackgroundTransparency = 1, ZIndex = 3 }, Main)
makeLogo(Header, 3, UDim2.fromOffset(18, 25), Vector2.new(0, .5))
local title = text(Header, "AETHER HUB", 17, "@text", Enum.Font.Arcade)
title.Position = UDim2.fromOffset(64, 0); title.Size = UDim2.fromOffset(130, 50)
local tag = new("Frame", { Position = UDim2.fromOffset(196, 17), Size = UDim2.fromOffset(34, 16), BackgroundColor3 = "@accent", BorderSizePixel = 0 }, Header)
corner(tag, 3)
local tagText = text(tag, "v2.0", 11, rgb(24, 20, 10), Enum.Font.BuilderSansBold, Enum.TextXAlignment.Center); tagText.Size = UDim2.fromScale(1, 1)
local closeBtn = new("TextButton", { AnchorPoint = Vector2.new(1, .5), Position = UDim2.new(1, -14, .5, 0), Size = UDim2.fromOffset(30, 30), BackgroundColor3 = "@row", BackgroundTransparency = 1, Text = "", AutoButtonColor = false, BorderSizePixel = 0 }, Header)
corner(closeBtn, 6)
local closeIcon = icon(closeBtn, "x", 16, "@dim"); closeIcon.AnchorPoint = Vector2.new(.5, .5); closeIcon.Position = UDim2.fromScale(.5, .5)
new("Frame", { Position = UDim2.new(0, 0, 1, -1), Size = UDim2.new(1, 0, 0, 1), BackgroundColor3 = "@line", BorderSizePixel = 0 }, Header)

local Sidebar = new("Frame", { Position = UDim2.fromOffset(0, 50), Size = UDim2.new(0, 168, 1, -50), BackgroundColor3 = "@side", BorderSizePixel = 0, ZIndex = 2 }, Main)
new("Frame", { AnchorPoint = Vector2.new(1, 0), Position = UDim2.fromScale(1, 0), Size = UDim2.new(0, 1, 1, 0), BackgroundColor3 = "@line", BorderSizePixel = 0 }, Sidebar)
local Indicator = new("Frame", { Size = UDim2.fromOffset(3, 20), Position = UDim2.fromOffset(0, 19), BackgroundColor3 = "@accent", BorderSizePixel = 0, ZIndex = 4 }, Sidebar)
corner(Indicator, 2)

local prof = new("Frame", { AnchorPoint = Vector2.new(.5, 1), Position = UDim2.new(.5, 0, 1, -12), Size = UDim2.new(1, -20, 0, 46), BackgroundColor3 = "@card", BorderSizePixel = 0, ZIndex = 3 }, Sidebar)
corner(prof, 6); stroke(prof, "@line", 1, 0)
local av = new("ImageLabel", { Position = UDim2.fromOffset(8, 7), Size = UDim2.fromOffset(32, 32), BackgroundColor3 = "@off", BorderSizePixel = 0 }, prof)
corner(av, 4)
task.spawn(function()
	local ok, img = pcall(Players.GetUserThumbnailAsync, Players, lp.UserId, Enum.ThumbnailType.HeadShot, Enum.ThumbnailSize.Size100x100)
	if ok then av.Image = img end
end)
local pn = text(prof, lp.DisplayName, 13, "@text", Enum.Font.BuilderSansBold); pn.Position = UDim2.fromOffset(48, 7); pn.Size = UDim2.new(1, -54, 0, 16); pn.TextTruncate = Enum.TextTruncate.AtEnd
local pr = text(prof, "", 12, "@dim", Enum.Font.BuilderSans); pr.Text = "@" .. lp.Name; pr.Position = UDim2.fromOffset(48, 24); pr.Size = UDim2.new(1, -54, 0, 14); pr.TextTruncate = Enum.TextTruncate.AtEnd

local Content = new("Frame", { Position = UDim2.fromOffset(168, 50), Size = UDim2.new(1, -168, 1, -50), BackgroundTransparency = 1, ZIndex = 3 }, Main)

local function ripple(btn)
	local mp = UIS:GetMouseLocation() - btn.AbsolutePosition
	local sc = RootScale.Scale
	local dot = new("Frame", { AnchorPoint = Vector2.new(.5, .5), Position = UDim2.fromOffset(mp.X / sc, mp.Y / sc), Size = UDim2.fromOffset(0, 0), BackgroundColor3 = Color3.new(1, 1, 1), BackgroundTransparency = .82, BorderSizePixel = 0, ZIndex = 20 }, btn)
	corner(dot, 999)
	local d = math.max(btn.AbsoluteSize.X, btn.AbsoluteSize.Y) * 2.4 / sc
	tween(dot, .55, { Size = UDim2.fromOffset(d, d), BackgroundTransparency = 1 })
	Debris:AddItem(dot, .6)
end

local Tabs, currentTab = {}, nil
local function selectTab(t)
	if currentTab == t then return end
	local prev = currentTab
	local dir = prev and (t.idx > prev.idx and 1 or -1) or 1
	if prev then
		tween(prev.page, .18, { GroupTransparency = 1 })
		tween(prev.scroll, .2, { Position = UDim2.fromOffset(0, -14 * dir) })
		tween(prev.lbl, .3, { TextColor3 = Theme.dim })
		tween(prev.ico, .3, { ImageColor3 = Theme.dim })
		tween(prev.btn, .3, { BackgroundTransparency = 1 })
		task.delay(.2, function() if currentTab ~= prev then prev.page.Visible = false end end)
	end
	currentTab = t
	t.page.Visible = true; t.page.GroupTransparency = 1
	t.scroll.Position = UDim2.fromOffset(0, 18 * dir)
	tween(t.page, .4, { GroupTransparency = 0 })
	tween(t.scroll, .5, { Position = UDim2.fromOffset(0, 0) }, Enum.EasingStyle.Back)
	tween(t.lbl, .3, { TextColor3 = Theme.text })
	tween(t.ico, .3, { ImageColor3 = Theme.accent })
	tween(t.btn, .3, { BackgroundTransparency = 0 })
	local oldY, newY = Indicator.Position.Y.Offset, t.y + 7
	tween(Indicator, .15, { Position = UDim2.fromOffset(0, math.min(oldY, newY)), Size = UDim2.fromOffset(3, math.abs(newY - oldY) + 20) }, Enum.EasingStyle.Sine)
	task.delay(.15, function()
		if currentTab == t then tween(Indicator, .3, { Position = UDim2.fromOffset(0, newY), Size = UDim2.fromOffset(3, 20) }, Enum.EasingStyle.Back) end
	end)
	snd(SND_CLICK, 1.1, .3)
end

local Section = {}; Section.__index = Section
local Tab = {}; Tab.__index = Tab

function Window:Tab(name, iconName)
	local idx = #Tabs + 1
	local y = 12 + (idx - 1) * 38
	local btn = new("TextButton", { Position = UDim2.fromOffset(10, y), Size = UDim2.new(1, -20, 0, 34), BackgroundColor3 = "@row", BackgroundTransparency = 1, Text = "", AutoButtonColor = false, BorderSizePixel = 0, ClipsDescendants = true }, Sidebar)
	corner(btn, 6)
	local ico = icon(btn, iconName, 16, "@dim"); ico.Position = UDim2.fromOffset(12, 9)
	local lbl = text(btn, name, 14, "@dim", Enum.Font.BuilderSansBold); lbl.Position = UDim2.fromOffset(38, 0); lbl.Size = UDim2.new(1, -38, 1, 0)
	local page = new("CanvasGroup", { Size = UDim2.fromScale(1, 1), BackgroundTransparency = 1, Visible = false }, Content)
	local scroll = new("ScrollingFrame", { Size = UDim2.fromScale(1, 1), BackgroundTransparency = 1, BorderSizePixel = 0, ScrollBarThickness = 3, CanvasSize = UDim2.new(), AutomaticCanvasSize = Enum.AutomaticSize.Y, ScrollingDirection = Enum.ScrollingDirection.Y, ScrollBarImageColor3 = "@accent", ScrollBarImageTransparency = .3 }, page)
	pad(scroll, 14, 16, 14, 14)
	new("UIListLayout", { Padding = UDim.new(0, 12), SortOrder = Enum.SortOrder.LayoutOrder }, scroll)
	local t = setmetatable({ page = page, scroll = scroll, lbl = lbl, ico = ico, btn = btn, y = y, name = name, idx = idx }, Tab)
	Tabs[idx] = t
	connect(btn.MouseEnter, function() if currentTab ~= t then tween(btn, .2, { BackgroundTransparency = .55 }); snd(SND_HOVER, 1.3, .1) end end)
	connect(btn.MouseLeave, function() if currentTab ~= t then tween(btn, .2, { BackgroundTransparency = 1 }) end end)
	connect(btn.MouseButton1Click, function() ripple(btn); selectTab(t) end)
	if idx == 1 then task.defer(selectTab, t) end
	return t
end

function Tab:Section(name)
	local card = new("Frame", { Size = UDim2.new(1, 0, 0, 0), AutomaticSize = Enum.AutomaticSize.Y, BackgroundColor3 = "@card", BorderSizePixel = 0, LayoutOrder = nextOrder(self.scroll) }, self.scroll)
	corner(card, 8); stroke(card, "@line", 1, 0)
	pad(card, 10, 12, 12, 12)
	new("UIListLayout", { Padding = UDim.new(0, 6), SortOrder = Enum.SortOrder.LayoutOrder }, card)
	local head = new("Frame", { Size = UDim2.new(1, 0, 0, 18), BackgroundTransparency = 1, LayoutOrder = nextOrder(card) }, card)
	new("Frame", { Position = UDim2.fromOffset(0, 6), Size = UDim2.fromOffset(6, 6), BackgroundColor3 = "@accent", BorderSizePixel = 0 }, head)
	local hl = text(head, string.upper(name), 12, "@dim", Enum.Font.BuilderSansBold); hl.Position = UDim2.fromOffset(14, 0); hl.Size = UDim2.new(1, -14, 1, 0)
	return setmetatable({ body = card }, Section)
end

local function row(sec, h)
	local f = new("Frame", { Size = UDim2.new(1, 0, 0, h), BackgroundColor3 = "@row", BorderSizePixel = 0, LayoutOrder = nextOrder(sec.body) }, sec.body)
	corner(f, 6)
	connect(f.MouseEnter, function() tween(f, .2, { BackgroundColor3 = Theme.line }) end)
	connect(f.MouseLeave, function() tween(f, .2, { BackgroundColor3 = Theme.row }) end)
	return f
end
local function nameLabels(r, o, rightPad)
	local l = text(r, o.Name, 14, "@text", Enum.Font.BuilderSansMedium)
	l.Position = UDim2.fromOffset(12, o.Desc and 6 or 0); l.Size = UDim2.new(1, -(rightPad or 60), 0, o.Desc and 18 or r.Size.Y.Offset)
	if o.Desc then
		local d = text(r, o.Desc, 12, "@dim", Enum.Font.BuilderSans); d.Position = UDim2.fromOffset(12, 25); d.Size = UDim2.new(1, -(rightPad or 60), 0, 14)
	end
end

function Section:Label(str)
	local r = new("Frame", { Size = UDim2.new(1, 0, 0, 22), BackgroundTransparency = 1, LayoutOrder = nextOrder(self.body) }, self.body)
	local l = text(r, str, 13, "@dim", Enum.Font.BuilderSans); l.Size = UDim2.fromScale(1, 1); l.Position = UDim2.fromOffset(2, 0)
	return { Set = function(_, s) l.Text = s end }
end

function Section:Info(name, fn)
	local r = row(self, 32)
	local l = text(r, name, 14, "@dim", Enum.Font.BuilderSansMedium); l.Position = UDim2.fromOffset(12, 0); l.Size = UDim2.new(.5, 0, 1, 0)
	local v = text(r, "", 14, "@text", Enum.Font.BuilderSansBold, Enum.TextXAlignment.Right); v.Position = UDim2.new(.4, 0, 0, 0); v.Size = UDim2.new(.6, -12, 1, 0)
	infoRows[#infoRows + 1] = function() v.Text = tostring(fn()) end
	v.Text = tostring(fn())
end

function Section:Tiles(list)
	local grid = new("Frame", { Size = UDim2.new(1, 0, 0, 64), BackgroundTransparency = 1, LayoutOrder = nextOrder(self.body) }, self.body)
	new("UIGridLayout", { CellSize = UDim2.new(1 / #list, -math.floor(8 * (#list - 1) / #list), 1, 0), CellPadding = UDim2.fromOffset(8, 0), SortOrder = Enum.SortOrder.LayoutOrder }, grid)
	local out = {}
	for i, d in ipairs(list) do
		local tile = new("Frame", { BackgroundColor3 = "@row", BorderSizePixel = 0, LayoutOrder = i }, grid)
		corner(tile, 6); stroke(tile, "@line", 1, 0)
		local v = text(tile, "0", 22, "@text", Enum.Font.BuilderSansExtraBold); v.Position = UDim2.fromOffset(12, 8); v.Size = UDim2.new(1, -24, 0, 26)
		local c = text(tile, d[2], 12, "@dim", Enum.Font.BuilderSansMedium); c.Position = UDim2.fromOffset(12, 36); c.Size = UDim2.new(1, -24, 0, 16)
		out[d[1]] = v
	end
	return out
end

function Section:Toggle(o)
	local r = row(self, o.Desc and 48 or 38)
	nameLabels(r, o, 70)
	local pill = new("Frame", { AnchorPoint = Vector2.new(1, .5), Position = UDim2.new(1, -12, .5, 0), Size = UDim2.fromOffset(40, 20), BackgroundColor3 = Theme.off, BorderSizePixel = 0 }, r)
	corner(pill, 4)
	local knob = new("Frame", { AnchorPoint = Vector2.new(0, .5), Position = UDim2.new(0, 3, .5, 0), Size = UDim2.fromOffset(14, 14), BackgroundColor3 = Color3.new(1, 1, 1), BorderSizePixel = 0 }, pill)
	corner(knob, 3)
	local obj = { Value = false }
	local function paint(anim)
		local col = obj.Value and Theme.accent or Theme.off
		local pos = obj.Value and UDim2.new(1, -17, .5, 0) or UDim2.new(0, 3, .5, 0)
		if anim then tween(pill, .25, { BackgroundColor3 = col }); tween(knob, .3, { Position = pos }, Enum.EasingStyle.Back)
		else pill.BackgroundColor3 = col; knob.Position = pos end
	end
	reg(function(animate) paint(animate) end)
	function obj.Set(v, silent)
		obj.Value = v and true or false; paint(true)
		if not silent and o.Callback then task.spawn(o.Callback, obj.Value) end
	end
	local hit = new("TextButton", { Size = UDim2.fromScale(1, 1), BackgroundTransparency = 1, Text = "" }, r)
	connect(hit.MouseButton1Click, function() obj.Set(not obj.Value); snd(SND_CLICK, obj.Value and 1.25 or .85, .4) end)
	if o.Default then obj.Value = true; paint(false); if o.Callback then task.defer(o.Callback, true) end end
	if o.Flag then Objs[o.Flag] = obj end
	return obj
end

function Section:Slider(o)
	local r = row(self, 54)
	local l = text(r, o.Name, 14, "@text", Enum.Font.BuilderSansMedium); l.Position = UDim2.fromOffset(12, 6); l.Size = UDim2.new(.6, 0, 0, 18)
	local vl = text(r, "", 13, "@accent", Enum.Font.BuilderSansBold, Enum.TextXAlignment.Right); vl.Position = UDim2.new(.5, 0, 0, 6); vl.Size = UDim2.new(.5, -12, 0, 18)
	local track = new("Frame", { Position = UDim2.new(0, 12, 0, 34), Size = UDim2.new(1, -24, 0, 6), BackgroundColor3 = "@off", BorderSizePixel = 0 }, r)
	corner(track, 3)
	local fill = new("Frame", { Size = UDim2.fromScale(0, 1), BackgroundColor3 = "@accent", BorderSizePixel = 0 }, track)
	corner(fill, 3)
	if o.Rainbow then
		track.BackgroundColor3 = Color3.new(1, 1, 1); fill.BackgroundTransparency = 1
		local keys = {}
		for i = 0, 6 do keys[#keys + 1] = ColorSequenceKeypoint.new(i / 6, Color3.fromHSV(i / 6, .7, 1)) end
		new("UIGradient", { Color = ColorSequence.new(keys) }, track)
	end
	local knob = new("Frame", { AnchorPoint = Vector2.new(.5, .5), Position = UDim2.fromScale(0, .5), Size = UDim2.fromOffset(12, 12), BackgroundColor3 = Color3.new(1, 1, 1), BorderSizePixel = 0, ZIndex = 4 }, track)
	corner(knob, 3)
	local obj = { Value = o.Default or o.Min }
	local dec, suf, step = o.Decimals or 0, o.Suffix or "", o.Step or (1 / 10 ^ (o.Decimals or 0))
	local function show(anim)
		local a = (obj.Value - o.Min) / (o.Max - o.Min)
		vl.Text = string.format("%." .. dec .. "f", obj.Value) .. suf
		if anim then tween(fill, .08, { Size = UDim2.fromScale(a, 1) }); tween(knob, .08, { Position = UDim2.fromScale(a, .5) })
		else fill.Size = UDim2.fromScale(a, 1); knob.Position = UDim2.fromScale(a, .5) end
	end
	function obj.Set(v, silent)
		v = math.clamp(math.floor(v / step + .5) * step, o.Min, o.Max); obj.Value = v; show(true)
		if not silent and o.Callback then task.spawn(o.Callback, v) end
	end
	local hit = new("TextButton", { Position = UDim2.new(0, 0, 0, 24), Size = UDim2.new(1, 0, 0, 30), BackgroundTransparency = 1, Text = "" }, r)
	local active = false
	local function fromX(x)
		obj.Set(o.Min + (o.Max - o.Min) * math.clamp((x - track.AbsolutePosition.X) / track.AbsoluteSize.X, 0, 1))
	end
	connect(hit.InputBegan, function(i)
		if i.UserInputType == Enum.UserInputType.MouseButton1 or i.UserInputType == Enum.UserInputType.Touch then
			active = true; sliderDrag = fromX; fromX(i.Position.X)
			tween(knob, .15, { Size = UDim2.fromOffset(16, 16) }, Enum.EasingStyle.Back)
			snd(SND_HOVER, 1.5, .2)
		end
	end)
	connect(UIS.InputEnded, function(i)
		if active and (i.UserInputType == Enum.UserInputType.MouseButton1 or i.UserInputType == Enum.UserInputType.Touch) then
			active = false; sliderDrag = nil
			tween(knob, .2, { Size = UDim2.fromOffset(12, 12) }, Enum.EasingStyle.Back)
		end
	end)
	show(false)
	if o.Flag then Objs[o.Flag] = obj end
	if o.Default and o.Callback then task.defer(o.Callback, obj.Value) end
	return obj
end

function Section:Button(o)
	local b = new("TextButton", { Size = UDim2.new(1, 0, 0, 36), BackgroundColor3 = o.Danger and rgb(190, 62, 62) or (o.Primary and "@accent" or "@off"), Text = "", AutoButtonColor = false, BorderSizePixel = 0, LayoutOrder = nextOrder(self.body), ClipsDescendants = true }, self.body)
	corner(b, 6)
	local lbl = text(b, o.Name, 14, (o.Primary and not o.Danger) and rgb(24, 20, 10) or "@text", Enum.Font.BuilderSansBold, Enum.TextXAlignment.Center); lbl.Size = UDim2.fromScale(1, 1)
	connect(b.MouseEnter, function() tween(b, .2, { BackgroundTransparency = .12 }) end)
	connect(b.MouseLeave, function() tween(b, .2, { BackgroundTransparency = 0 }) end)
	connect(b.MouseButton1Down, function() tween(b, .12, { Size = UDim2.new(1, -8, 0, 33) }) end)
	connect(b.MouseButton1Up, function() tween(b, .25, { Size = UDim2.new(1, 0, 0, 36) }, Enum.EasingStyle.Back) end)
	connect(b.MouseButton1Click, function() ripple(b); snd(SND_CLICK, 1, .45); if o.Callback then task.spawn(o.Callback) end end)
end

function Section:TextBox(o)
	local r = row(self, 38)
	nameLabels(r, o, 190)
	local tb = new("TextBox", { AnchorPoint = Vector2.new(1, .5), Position = UDim2.new(1, -10, .5, 0), Size = UDim2.fromOffset(170, 26), BackgroundColor3 = "@side", Text = "", PlaceholderText = o.Placeholder or "", PlaceholderColor3 = "@dim", TextColor3 = "@text", TextSize = 13, Font = Enum.Font.BuilderSansMedium, ClearTextOnFocus = false, BorderSizePixel = 0 }, r)
	corner(tb, 5)
	local st = stroke(tb, "@accent", 1.2, 1)
	connect(tb.Focused, function() tween(st, .2, { Transparency = 0 }) end)
	connect(tb.FocusLost, function() tween(st, .2, { Transparency = 1 }); if o.Callback then task.spawn(o.Callback, tb.Text) end end)
	return tb
end

function Section:Dropdown(o)
	local outer = new("Frame", { Size = UDim2.new(1, 0, 0, 0), AutomaticSize = Enum.AutomaticSize.Y, BackgroundTransparency = 1, LayoutOrder = nextOrder(self.body) }, self.body)
	new("UIListLayout", { Padding = UDim.new(0, 4), SortOrder = Enum.SortOrder.LayoutOrder }, outer)
	local head = new("Frame", { Size = UDim2.new(1, 0, 0, 38), BackgroundColor3 = "@row", BorderSizePixel = 0, LayoutOrder = 1 }, outer)
	corner(head, 6)
	local l = text(head, o.Name, 14, "@text", Enum.Font.BuilderSansMedium); l.Position = UDim2.fromOffset(12, 0); l.Size = UDim2.new(.5, 0, 1, 0)
	local vl = text(head, "", 13, "@accent", Enum.Font.BuilderSansBold, Enum.TextXAlignment.Right); vl.Position = UDim2.new(.4, 0, 0, 0); vl.Size = UDim2.new(.6, -34, 1, 0)
	local arrow = icon(head, "chevron-down", 16, "@dim"); arrow.AnchorPoint = Vector2.new(1, .5); arrow.Position = UDim2.new(1, -10, .5, 0)
	local list = new("Frame", { Size = UDim2.new(1, 0, 0, 0), BackgroundColor3 = "@side", ClipsDescendants = true, BorderSizePixel = 0, LayoutOrder = 2 }, outer)
	corner(list, 6)
	new("UIListLayout", { SortOrder = Enum.SortOrder.LayoutOrder }, list)
	local obj, open = { Value = o.Default or o.Options[1] }, false
	local function setOpen(v)
		open = v
		tween(list, .35, { Size = UDim2.new(1, 0, 0, v and (#o.Options * 30) or 0) })
		tween(arrow, .3, { Rotation = v and 180 or 0 })
	end
	function obj.Set(v, silent)
		obj.Value = v; vl.Text = v
		if not silent and o.Callback then task.spawn(o.Callback, v) end
	end
	function obj.Refresh(opts)
		o.Options = opts
		for _, c in ipairs(list:GetChildren()) do if c:IsA("TextButton") then c:Destroy() end end
		for i, opt in ipairs(opts) do
			local ob = new("TextButton", { Size = UDim2.new(1, 0, 0, 30), BackgroundTransparency = 1, Text = opt, TextSize = 13, Font = Enum.Font.BuilderSansMedium, TextColor3 = "@dim", LayoutOrder = i, BorderSizePixel = 0 }, list)
			ob.MouseEnter:Connect(function() tween(ob, .15, { TextColor3 = Theme.accent }) end)
			ob.MouseLeave:Connect(function() tween(ob, .15, { TextColor3 = Theme.dim }) end)
			ob.MouseButton1Click:Connect(function() obj.Set(opt); setOpen(false); snd(SND_CLICK, 1.1, .4) end)
		end
		if open then tween(list, .3, { Size = UDim2.new(1, 0, 0, #opts * 30) }) end
	end
	obj.Refresh(o.Options)
	local hit = new("TextButton", { Size = UDim2.fromScale(1, 1), BackgroundTransparency = 1, Text = "" }, head)
	connect(hit.MouseButton1Click, function() setOpen(not open); snd(SND_CLICK, .95, .35) end)
	connect(head.MouseEnter, function() tween(head, .2, { BackgroundColor3 = Theme.line }) end)
	connect(head.MouseLeave, function() tween(head, .2, { BackgroundColor3 = Theme.row }) end)
	obj.Set(obj.Value, true)
	if o.Flag then Objs[o.Flag] = obj end
	return obj
end

function Section:Keybind(o)
	local r = row(self, o.Desc and 48 or 38)
	nameLabels(r, o, 130)
	local btn = new("TextButton", { AnchorPoint = Vector2.new(1, .5), Position = UDim2.new(1, -10, .5, 0), Size = UDim2.fromOffset(96, 26), BackgroundColor3 = Theme.off, Text = "", TextSize = 13, Font = Enum.Font.BuilderSansBold, TextColor3 = "@text", AutoButtonColor = false, BorderSizePixel = 0 }, r)
	corner(btn, 5)
	local obj = { Value = o.Default }
	local function paint() btn.Text = obj.Value and obj.Value.Name or "None" end
	function obj.Set(k, silent) obj.Value = k; paint(); if not silent and o.Callback then task.spawn(o.Callback, k) end end
	connect(btn.MouseButton1Click, function()
		btn.Text = "press a key"; tween(btn, .2, { BackgroundColor3 = Theme.accent, TextColor3 = rgb(24, 20, 10) })
		listening = function(k)
			listening = nil
			tween(btn, .2, { BackgroundColor3 = Theme.off, TextColor3 = Theme.text })
			obj.Set(k ~= Enum.KeyCode.Escape and k or nil)
		end
		snd(SND_CLICK, 1, .35)
	end)
	reg(function() if not listening then btn.BackgroundColor3 = Theme.off end end)
	paint()
	if o.Flag then Objs[o.Flag] = obj end
	return obj
end

local uiOpen = false
local function setUI(v)
	if v == uiOpen then return end
	uiOpen = v
	if v then
		Root.Visible = true; Main.GroupTransparency = 1; RootScale.Scale = (g.AetherHubScale or 1) * .93
		tween(Main, .35, { GroupTransparency = 0 }); tween(RootScale, .45, { Scale = g.AetherHubScale or 1 }, Enum.EasingStyle.Back)
		snd(SND_CLICK, .7, .45)
	else
		tween(Main, .25, { GroupTransparency = 1 }); tween(RootScale, .25, { Scale = (g.AetherHubScale or 1) * .95 })
		task.delay(.26, function() if not uiOpen then Root.Visible = false end end)
		snd(SND_CLICK, .6, .35)
	end
end
connect(closeBtn.MouseButton1Click, function() setUI(false) end)
connect(closeBtn.MouseEnter, function() tween(closeBtn, .2, { BackgroundTransparency = 0 }); tween(closeIcon, .2, { ImageColor3 = rgb(255, 120, 120) }) end)
connect(closeBtn.MouseLeave, function() tween(closeBtn, .2, { BackgroundTransparency = 1 }); tween(closeIcon, .2, { ImageColor3 = Theme.dim }) end)

local dragStart, startOff, dragging
local dragCur, dragTar = Vector2.zero, Vector2.zero
local hudDragStart, hudStartPos
local function dragFx(on)
	dragging = on
	tween(RootScale, .35, { Scale = (g.AetherHubScale or 1) * (on and 1.015 or 1) }, Enum.EasingStyle.Back)
	tween(Shadow, .35, { ImageTransparency = on and .3 or .5, Size = on and UDim2.new(1, 100, 1, 100) or UDim2.new(1, 60, 1, 60) })
	tween(MainStroke, .3, { Color = on and Theme.accent or Theme.line })
end
connect(Header.InputBegan, function(i)
	if i.UserInputType == Enum.UserInputType.MouseButton1 or i.UserInputType == Enum.UserInputType.Touch then
		dragStart, startOff = i.Position, dragTar; dragFx(true)
	end
end)
local hud
connect(UIS.InputChanged, function(i)
	if i.UserInputType == Enum.UserInputType.MouseMovement or i.UserInputType == Enum.UserInputType.Touch then
		if dragStart then
			local d = i.Position - dragStart
			dragTar = startOff + Vector2.new(d.X, d.Y)
		end
		if hudDragStart and hud then
			local d = i.Position - hudDragStart
			hud.Position = UDim2.new(hudStartPos.X.Scale, hudStartPos.X.Offset + d.X, hudStartPos.Y.Scale, hudStartPos.Y.Offset + d.Y)
		end
		if sliderDrag then sliderDrag(i.Position.X) end
	end
end)
connect(UIS.InputEnded, function(i)
	if i.UserInputType == Enum.UserInputType.MouseButton1 or i.UserInputType == Enum.UserInputType.Touch then
		if dragStart then dragStart = nil; dragFx(false) end
		hudDragStart = nil
	end
end)
connect(RunService.RenderStepped, function(dt)
	local d = dragTar - dragCur
	if d.Magnitude < .05 and not dragging and math.abs(Root.Rotation) < .01 then return end
	dragCur += d * (1 - math.exp(-dt * 16))
	Root.Position = UDim2.new(.5, dragCur.X, .5, dragCur.Y)
	local tilt = dragging and math.clamp(d.X * .03, -3, 3) or 0
	Root.Rotation += (tilt - Root.Rotation) * math.min(1, dt * 9)
end)

Root.Visible = false

local S = {
	trafficOn = false, trafficMode = "Ghost",
	assist = 0, nitroOn = true, nitro = 140, nitroKey = Enum.KeyCode.LeftShift,
	limitOn = false, topSpeed = 400, autoflip = true, hud = true,
	fovOn = false, fov = 80, fovDyn = true,
	glowOn = false, glow = 3, fxMode = "Glowstone", hue = .12, sparks = true, trail = true, drift = true,
	moteStyle = "Lumes", cycle = false, cycleSpeed = 6,
	preset = "Game Default", lockTime = false, clock = 14,
	sat = 0, con = 0, bloom = 0,
	hopOn = true, hopKey = Enum.KeyCode.H, hopPower = 45,
	gravOn = false, grav = 100, clickTp = true,
	free = false, freeSpeed = 60,
	watermark = true, antiAfk = true,
}

local function getCar()
	local ch = lp.Character
	local h = ch and ch:FindFirstChildOfClass("Humanoid")
	local seat = h and h.SeatPart
	if not seat then return end
	local m = seat:FindFirstAncestorOfClass("Model")
	local r = m and (m:FindFirstChild("Root") or m.PrimaryPart)
	if r then return m, r, seat end
end

local TrafficStore = {}
local TRAFFIC_PROPS = {
	BasePart = { "CanCollide", "CanTouch", "CanQuery", "Transparency" },
	Decal = { "Transparency" }, Texture = { "Transparency" },
	Light = { "Enabled" }, ParticleEmitter = { "Enabled" }, Trail = { "Enabled" }, Beam = { "Enabled" },
}
local function ghost(i)
	for cls, props in pairs(TRAFFIC_PROPS) do
		if i:IsA(cls) then
			if not TrafficStore[i] then
				local st = {}
				for _, p in ipairs(props) do st[p] = i[p] end
				TrafficStore[i] = st
			end
			for _, p in ipairs(props) do
				pcall(function() i[p] = (p == "Transparency") and 1 or false end)
			end
			return
		end
	end
end
local trafficConns = {}
local function trafficFolder() return workspace:FindFirstChild("Traffic") end
local function trafficCount() local f = trafficFolder(); return f and #f:GetChildren() or 0 end
local function sweepTraffic()
	local f = trafficFolder(); if not f then return end
	if S.trafficMode == "Destroy" then
		for _, c in ipairs(f:GetChildren()) do pcall(c.Destroy, c) end
	else
		for _, d in ipairs(f:GetDescendants()) do ghost(d) end
	end
end
local function hookTraffic(f)
	for _, c in ipairs(trafficConns) do c:Disconnect() end
	table.clear(trafficConns)
	if not f then return end
	trafficConns[1] = f.DescendantAdded:Connect(function(d)
		if not S.trafficOn then return end
		if S.trafficMode == "Destroy" then
			task.defer(function()
				local top = d
				while top.Parent and top.Parent ~= f do top = top.Parent end
				if top.Parent == f then pcall(top.Destroy, top) end
			end)
		else
			ghost(d)
		end
	end)
end
local function restoreTraffic()
	for inst, st in pairs(TrafficStore) do
		if inst.Parent then for p, v in pairs(st) do pcall(function() inst[p] = v end) end end
	end
	table.clear(TrafficStore)
end
local function setTraffic(on)
	S.trafficOn = on
	if on then
		hookTraffic(trafficFolder()); sweepTraffic()
		notify("Traffic cleared", S.trafficMode == "Ghost" and "Ghost mode, fully reversible" or "Destroyed until you rejoin", 2.5, "traffic-cone")
	else
		hookTraffic(nil); restoreTraffic()
		notify("Traffic restored", "Vehicles are back on the road", 2.5, "traffic-cone")
	end
end
connect(workspace.ChildAdded, function(c)
	if c.Name == "Traffic" and S.trafficOn then task.wait(); hookTraffic(c); sweepTraffic() end
end)

local FxColors = {
	Glowstone = rgb(255, 196, 71), Water = rgb(74, 157, 255), Zanite = rgb(150, 122, 255), ["Aether Grass"] = rgb(110, 220, 160),
}
local function fxColor(t)
	if S.fxMode == "Rainbow" then return Color3.fromHSV((t * .15) % 1, .6, 1) end
	if S.fxMode == "Custom" then return Color3.fromHSV(S.hue, .65, 1) end
	return FxColors[S.fxMode] or Theme.accent
end

local fx = {}
local function clearFX()
	for _, k in ipairs({ "att", "a1", "a2", "light", "sparks", "trail", "drift" }) do if fx[k] then pcall(fx[k].Destroy, fx[k]) end end
	fx = {}
end
local function buildFX(root)
	clearFX(); fx.root = root
	fx.att = new("Attachment", { Name = "AetherFX", Position = Vector3.new(0, -.6, 0) }, root)
	fx.light = new("PointLight", { Range = 22, Brightness = S.glow, Shadows = false, Enabled = S.glowOn }, root)
	fx.sparks = new("ParticleEmitter", {
		Texture = "rbxasset://textures/particles/sparkles_main.dds", Rate = 0, Lifetime = NumberRange.new(.6, 1.2),
		Speed = NumberRange.new(4, 14), SpreadAngle = Vector2.new(180, 180), LightEmission = 1, Drag = 2,
		Size = NumberSequence.new({ NumberSequenceKeypoint.new(0, .5), NumberSequenceKeypoint.new(1, 0) }),
		Transparency = NumberSequence.new({ NumberSequenceKeypoint.new(0, 0), NumberSequenceKeypoint.new(1, 1) }),
		RotSpeed = NumberRange.new(-180, 180), Enabled = S.sparks,
	}, fx.att)
	fx.drift = new("ParticleEmitter", {
		Texture = "rbxasset://textures/particles/sparkles_main.dds", Rate = 0, Lifetime = NumberRange.new(.8, 1.6),
		Speed = NumberRange.new(6, 18), SpreadAngle = Vector2.new(35, 35), LightEmission = .8, Drag = 3, Acceleration = Vector3.new(0, 6, 0),
		Size = NumberSequence.new({ NumberSequenceKeypoint.new(0, 1.2), NumberSequenceKeypoint.new(1, 0) }),
		Transparency = NumberSequence.new({ NumberSequenceKeypoint.new(0, .2), NumberSequenceKeypoint.new(1, 1) }),
	}, fx.att)
	fx.a1 = new("Attachment", { Position = Vector3.new(-2, -.6, 0) }, root)
	fx.a2 = new("Attachment", { Position = Vector3.new(2, -.6, 0) }, root)
	fx.trail = new("Trail", {
		Attachment0 = fx.a1, Attachment1 = fx.a2, Lifetime = .9, LightEmission = 1, MinLength = .1, FaceCamera = true, Enabled = S.trail,
		Transparency = NumberSequence.new({ NumberSequenceKeypoint.new(0, .15), NumberSequenceKeypoint.new(1, 1) }),
		WidthScale = NumberSequence.new({ NumberSequenceKeypoint.new(0, 1), NumberSequenceKeypoint.new(1, 0) }),
	}, root)
end

hud = new("Frame", { Name = "Speed", AnchorPoint = Vector2.new(.5, 1), Position = UDim2.new(.5, 0, 1, -130), Size = UDim2.fromOffset(150, 56), BackgroundColor3 = "@bg", BorderSizePixel = 0, Visible = false }, HudGui)
corner(hud, 6); stroke(hud, "@line", 1, 0)
local hudNum = text(hud, "0", 28, "@text", Enum.Font.BuilderSansExtraBold, Enum.TextXAlignment.Center); hudNum.Position = UDim2.fromOffset(0, 5); hudNum.Size = UDim2.new(1, 0, 0, 28)
local hudUnit = text(hud, "KM/H", 11, "@dim", Enum.Font.BuilderSansBold, Enum.TextXAlignment.Center); hudUnit.Position = UDim2.fromOffset(0, 33); hudUnit.Size = UDim2.new(1, 0, 0, 12)
local hudBar = new("Frame", { AnchorPoint = Vector2.new(.5, 1), Position = UDim2.new(.5, 0, 1, -5), Size = UDim2.new(1, -20, 0, 3), BackgroundColor3 = "@off", BorderSizePixel = 0 }, hud)
local hudFill = new("Frame", { Size = UDim2.fromScale(0, 1), BackgroundColor3 = "@accent", BorderSizePixel = 0 }, hudBar)
connect(hud.InputBegan, function(i)
	if i.UserInputType == Enum.UserInputType.MouseButton1 then hudDragStart, hudStartPos = i.Position, hud.Position end
end)

local wm = new("Frame", { AnchorPoint = Vector2.new(.5, 0), Position = UDim2.new(.5, 0, 0, 8), Size = UDim2.fromOffset(240, 24), BackgroundColor3 = "@bg", BorderSizePixel = 0 }, HudGui)
corner(wm, 5); stroke(wm, "@line", 1, 0)
new("Frame", { Position = UDim2.fromOffset(9, 9), Size = UDim2.fromOffset(6, 6), BackgroundColor3 = "@accent", BorderSizePixel = 0 }, wm)
local wmText = text(wm, "", 12, "@text", Enum.Font.BuilderSansBold); wmText.Position = UDim2.fromOffset(22, 0); wmText.Size = UDim2.new(1, -28, 1, 0)

local motePart = new("Part", { Name = "AetherHubMotes", Anchored = true, CanCollide = false, CanQuery = false, CanTouch = false, Transparency = 1, Size = Vector3.new(120, 1, 120) }, workspace)
local moteEm = new("ParticleEmitter", {
	Texture = "rbxasset://textures/particles/sparkles_main.dds", Rate = 28, Lifetime = NumberRange.new(7, 11),
	Speed = NumberRange.new(.5, 2.5), EmissionDirection = Enum.NormalId.Bottom, SpreadAngle = Vector2.new(35, 35), LightEmission = 1,
	Size = NumberSequence.new({ NumberSequenceKeypoint.new(0, 0), NumberSequenceKeypoint.new(.2, .35), NumberSequenceKeypoint.new(1, 0) }),
	Transparency = NumberSequence.new({ NumberSequenceKeypoint.new(0, 1), NumberSequenceKeypoint.new(.2, .1), NumberSequenceKeypoint.new(.8, .3), NumberSequenceKeypoint.new(1, 1) }),
	RotSpeed = NumberRange.new(-40, 40), Shape = Enum.ParticleEmitterShape.Box, ShapeStyle = Enum.ParticleEmitterShapeStyle.Volume,
}, motePart)
local moteOffset = 30
local MoteStyles = {
	Lumes = function() return { dir = Enum.NormalId.Bottom, rate = 28, speed = NumberRange.new(.5, 2.5), accel = Vector3.zero, size = .35, off = 30, color = ColorSequence.new(Theme.accent, Theme.accent2) } end,
	Snow = function() return { dir = Enum.NormalId.Bottom, rate = 70, speed = NumberRange.new(2, 5), accel = Vector3.new(0, -1, 0), size = .22, off = 30, color = ColorSequence.new(Color3.new(1, 1, 1), rgb(200, 225, 255)) } end,
	Embers = function() return { dir = Enum.NormalId.Top, rate = 24, speed = NumberRange.new(1, 3), accel = Vector3.new(0, 2, 0), size = .3, off = -5, color = ColorSequence.new(rgb(255, 214, 110), rgb(255, 120, 40)) } end,
}
local function applyMoteStyle(name)
	S.moteStyle = name
	local mk = MoteStyles[name]
	if not mk then moteEm.Enabled = false; return end
	local st = mk()
	moteEm.Enabled = true; moteEm.EmissionDirection = st.dir; moteEm.Rate = st.rate; moteEm.Speed = st.speed
	moteEm.Acceleration = st.accel; moteEm.Color = st.color; moteOffset = st.off
	moteEm.Size = NumberSequence.new({ NumberSequenceKeypoint.new(0, 0), NumberSequenceKeypoint.new(.2, st.size), NumberSequenceKeypoint.new(1, 0) })
end
reg(function() applyMoteStyle(S.moteStyle) end)

local Orig = {}
local function snap(inst, props)
	if not inst then return end
	Orig[inst] = Orig[inst] or {}
	for _, p in ipairs(props) do if Orig[inst][p] == nil then pcall(function() Orig[inst][p] = inst[p] end) end end
end
local atmos = Lighting:FindFirstChildOfClass("Atmosphere")
local clouds = workspace.Terrain:FindFirstChildOfClass("Clouds")
local sky = Lighting:FindFirstChildOfClass("Sky")
local LP = { "ClockTime", "Ambient", "OutdoorAmbient", "Brightness", "ColorShift_Top", "ExposureCompensation" }
local AP = { "Color", "Decay", "Density", "Offset", "Glare", "Haze" }
local CP = { "Color", "Cover", "Density" }
local SP = { "StarCount", "SunAngularSize", "MoonAngularSize" }
local cc = new("ColorCorrectionEffect", { Name = "AetherHubCC", Enabled = true }, Lighting)
local bl = new("BloomEffect", { Name = "AetherHubBloom", Intensity = 0, Size = 28, Threshold = .9, Enabled = true }, Lighting)

local Presets = {
	["Aether Day"] = { clock = 13, ambient = rgb(150, 175, 215), outdoor = rgb(170, 195, 235), bright = 3, shift = rgb(255, 250, 235), atm = { rgb(190, 225, 255), rgb(150, 205, 255), .28, .1, 0, 1.2 }, tint = rgb(255, 252, 246), cloud = { rgb(255, 255, 255), .7, .65 }, stars = 0 },
	["Skyroot Dawn"] = { clock = 6.1, ambient = rgb(140, 145, 185), outdoor = rgb(160, 155, 195), bright = 2.4, shift = rgb(255, 205, 175), atm = { rgb(255, 214, 190), rgb(255, 170, 150), .32, .25, .45, 1.8 }, tint = rgb(255, 238, 228), cloud = { rgb(255, 224, 205), .62, .6 }, stars = 0 },
	["Glowstone Dusk"] = { clock = 17.6, ambient = rgb(160, 125, 95), outdoor = rgb(190, 145, 95), bright = 3, shift = rgb(255, 196, 100), atm = { rgb(255, 200, 130), rgb(255, 130, 60), .3, .2, .6, 1.6 }, tint = rgb(255, 228, 188), cloud = { rgb(255, 205, 140), .5, .55 }, stars = 0 },
	["Cloud Sea"] = { clock = 11, ambient = rgb(165, 180, 205), outdoor = rgb(185, 198, 225), bright = 2.6, shift = rgb(255, 255, 255), atm = { rgb(235, 242, 255), rgb(215, 230, 250), .52, .05, 0, 2.6 }, tint = rgb(250, 252, 255), cloud = { rgb(255, 255, 255), 1, .9 }, stars = 0 },
	["Water Realm"] = { clock = 10, ambient = rgb(100, 150, 175), outdoor = rgb(120, 175, 200), bright = 2.4, shift = rgb(190, 245, 255), atm = { rgb(170, 235, 245), rgb(90, 190, 215), .46, .2, .2, 2.5 }, tint = rgb(214, 246, 255), cloud = { rgb(205, 245, 255), .6, .55 }, stars = 0 },
	["Zanite Night"] = { clock = 0, ambient = rgb(50, 52, 105), outdoor = rgb(62, 66, 130), bright = 1, shift = rgb(150, 140, 255), atm = { rgb(95, 90, 190), rgb(45, 40, 125), .36, .15, .1, 2 }, tint = rgb(215, 215, 255), cloud = { rgb(125, 120, 205), .55, .5 }, stars = 4000 },
}
local PresetNames = { "Game Default", "Aether Day", "Skyroot Dawn", "Glowstone Dusk", "Cloud Sea", "Water Realm", "Zanite Night" }
local activePreset
local function applyPreset(name)
	snap(Lighting, LP); snap(atmos, AP); snap(clouds, CP); snap(sky, SP)
	S.preset = name
	if name == "Game Default" then
		activePreset = nil
		for inst, props in pairs(Orig) do if inst.Parent then for p, v in pairs(props) do pcall(function() inst[p] = v end) end end end
		cc.TintColor = Color3.new(1, 1, 1)
		return
	end
	local p = Presets[name]; if not p then return end
	activePreset = p
	local function tw(inst, props) if inst then tween(inst, 1.2, props, Enum.EasingStyle.Sine) end end
	tw(Lighting, { ClockTime = p.clock, Ambient = p.ambient, OutdoorAmbient = p.outdoor, Brightness = p.bright, ColorShift_Top = p.shift })
	if atmos then tw(atmos, { Color = p.atm[1], Decay = p.atm[2], Density = p.atm[3], Offset = p.atm[4], Glare = p.atm[5], Haze = p.atm[6] }) end
	if clouds then tw(clouds, { Color = p.cloud[1], Cover = p.cloud[2], Density = p.cloud[3] }) end
	if sky then sky.StarCount = p.stars end
	tw(cc, { TintColor = p.tint })
	S.clock = p.clock
	if Objs.clock then Objs.clock.Set(p.clock, true) end
end

local enforceT = 0
local function enforce(dt)
	if S.cycle then
		Lighting.ClockTime = (Lighting.ClockTime + dt * S.cycleSpeed / 60) % 24
		S.clock = Lighting.ClockTime
	elseif S.lockTime then
		Lighting.ClockTime = S.clock
	end
	enforceT += dt
	if enforceT > .5 and activePreset then
		enforceT = 0
		local p = activePreset
		if atmos then pcall(function() atmos.Color = p.atm[1]; atmos.Decay = p.atm[2] end) end
		Lighting.Ambient = p.ambient; Lighting.OutdoorAmbient = p.outdoor
	end
	cc.Saturation = S.sat / 100; cc.Contrast = S.con / 100; bl.Intensity = S.bloom / 50
end

local savedCF
local function tpTo(pos)
	local m, r = getCar()
	if m and r then m:PivotTo(m:GetPivot() + (pos + Vector3.new(0, 4, 0) - r.Position)); return true end
	local ch = lp.Character
	if ch then ch:PivotTo(CFrame.new(pos + Vector3.new(0, 3, 0))); return true end
end
local function savePosition()
	local m = getCar()
	local t = m or lp.Character
	if t then savedCF = t:GetPivot(); notify("Position saved", "Use Teleport to Saved to return", 2.5, "map-pin") end
end
local function teleportSaved()
	if not savedCF then notify("Nothing saved", "Save a position first", 2.5, "map-pin"); return end
	local m, r = getCar()
	local t = m or lp.Character
	if t then
		t:PivotTo(savedCF)
		if r then r.AssemblyLinearVelocity = Vector3.zero; r.AssemblyAngularVelocity = Vector3.zero end
		notify("Teleported", "Back at your saved spot", 2.5, "map-pin")
	end
end

local fc = { cf = CFrame.new(), pitch = 0, yaw = 0 }
local function setFree(on)
	S.free = on
	cam = workspace.CurrentCamera
	if on then
		fc.cf = cam.CFrame
		local px, py = fc.cf:ToOrientation(); fc.pitch, fc.yaw = px, py
		cam.CameraType = Enum.CameraType.Scriptable
		CAS:BindActionAtPriority("AetherHubFree", function() return Enum.ContextActionResult.Sink end, false, 3000, Enum.KeyCode.W, Enum.KeyCode.A, Enum.KeyCode.S, Enum.KeyCode.D, Enum.KeyCode.Q, Enum.KeyCode.E)
	else
		CAS:UnbindAction("AetherHubFree")
		cam.CameraType = Enum.CameraType.Custom
		UIS.MouseBehavior = Enum.MouseBehavior.Default
	end
end

local clk, fpsAvg, uiTimer, flipT, hudSpd, twinkleT = 0, 60, 0, 0, 0, 0
local refreshStats = function() end
local lastSpeed = 0

connect(RunService.Heartbeat, function(dt)
	clk += dt
	fpsAvg += (1 / math.max(dt, .001) - fpsAvg) * math.min(1, dt * 3)
	for _, f in ipairs(Flecks) do
		f.y -= f.s * dt
		if f.y < -.05 then f.y = 1.05; f.x = math.random() end
		f.f.Position = UDim2.fromScale(f.x, f.y)
	end
	twinkleT += dt
	if twinkleT > .4 and #twinkle > 0 then
		twinkleT = 0
		local cell = twinkle[math.random(1, #twinkle)]
		tween(cell, .25, { BackgroundColor3 = LogoColors.L }).Completed:Connect(function() tween(cell, .5, { BackgroundColor3 = LogoColors.Y }) end)
	end
	enforce(dt)
	if S.trafficOn and clk % 1 < dt then sweepTraffic() end
	uiTimer += dt
	if uiTimer > .25 then uiTimer = 0; refreshStats() end

	local m, r, seat = getCar()
	if not r then
		hud.Visible = false; lastSpeed = 0
		if fx.root then clearFX() end
		return
	end
	if fx.root ~= r or not fx.att or not fx.att.Parent then buildFX(r) end
	local v = r.AssemblyLinearVelocity
	local spd = v.Magnitude
	local fwd = seat.CFrame.LookVector
	local accel = 0
	if S.assist > 0 and (UIS:IsKeyDown(Enum.KeyCode.W) or UIS:IsKeyDown(Enum.KeyCode.Up)) and v:Dot(fwd) > -3 then accel += S.assist end
	local boosting = S.nitroOn and S.nitroKey and UIS:IsKeyDown(S.nitroKey) and not UIS:GetFocusedTextBox()
	if boosting then accel += S.nitro end
	if accel > 0 then v += fwd * accel * dt end
	if S.limitOn then
		local cap = S.topSpeed / 1.008
		if v.Magnitude > cap then v = v.Unit * math.max(cap, v.Magnitude - 120 * dt) end
	end
	if accel > 0 or S.limitOn then r.AssemblyLinearVelocity = v end
	hudSpd += (spd - hudSpd) * math.min(1, dt * 10)
	lastSpeed = hudSpd * 1.008

	if S.autoflip then
		if r.CFrame.UpVector.Y < .25 and spd < 30 then flipT += dt else flipT = 0 end
		if flipT > 1.2 then
			flipT = 0
			local p, look = r.Position, r.CFrame.LookVector
			local yaw = Vector3.new(look.X, 0, look.Z)
			if yaw.Magnitude < .1 then yaw = Vector3.zAxis end
			local target = CFrame.lookAt(p + Vector3.new(0, 4, 0), p + Vector3.new(0, 4, 0) + yaw.Unit)
			m:PivotTo(target * r.CFrame:ToObjectSpace(m:GetPivot()))
			r.AssemblyLinearVelocity = Vector3.zero; r.AssemblyAngularVelocity = Vector3.zero
			notify("Auto flip", "Vehicle righted", 2, "rotate-ccw")
		end
	end

	hud.Visible = S.hud
	if S.hud then
		hudNum.Text = tostring(math.floor(lastSpeed + .5))
		hudFill.Size = UDim2.fromScale(math.clamp(lastSpeed / 450, 0, 1), 1)
	end

	local col = fxColor(clk)
	local col2 = col:Lerp(Color3.new(1, 1, 1), .5)
	if fx.light then fx.light.Enabled = S.glowOn; fx.light.Brightness = S.glow; fx.light.Color = col end
	if fx.sparks then
		fx.sparks.Enabled = S.sparks; fx.sparks.Color = ColorSequence.new(col, col2)
		fx.sparks.Rate = math.clamp(spd * .6, 0, 90) + (boosting and 120 or 0)
	end
	if fx.drift then
		local lat = math.abs(v:Dot(seat.CFrame.RightVector))
		fx.drift.Color = ColorSequence.new(col, col2)
		fx.drift.Rate = (S.drift and lat > 14) and math.clamp(lat * 3, 0, 160) or 0
	end
	if fx.trail then fx.trail.Enabled = S.trail and spd > 12; fx.trail.Color = ColorSequence.new(col, col2) end
end)

connect(RunService.RenderStepped, function(dt)
	cam = workspace.CurrentCamera
	if not cam then return end
	motePart.CFrame = CFrame.new(cam.CFrame.Position + Vector3.new(0, moteOffset, 0))
	if S.free then
		if UIS:IsMouseButtonPressed(Enum.UserInputType.MouseButton2) then
			UIS.MouseBehavior = Enum.MouseBehavior.LockCurrentPosition
			local d = UIS:GetMouseDelta()
			fc.yaw -= d.X * .0035; fc.pitch = math.clamp(fc.pitch - d.Y * .0035, -1.5, 1.5)
		else
			UIS.MouseBehavior = Enum.MouseBehavior.Default
		end
		local mv = Vector3.zero
		if not UIS:GetFocusedTextBox() then
			if UIS:IsKeyDown(Enum.KeyCode.W) then mv += Vector3.new(0, 0, -1) end
			if UIS:IsKeyDown(Enum.KeyCode.S) then mv += Vector3.new(0, 0, 1) end
			if UIS:IsKeyDown(Enum.KeyCode.A) then mv += Vector3.new(-1, 0, 0) end
			if UIS:IsKeyDown(Enum.KeyCode.D) then mv += Vector3.new(1, 0, 0) end
			if UIS:IsKeyDown(Enum.KeyCode.E) then mv += Vector3.new(0, 1, 0) end
			if UIS:IsKeyDown(Enum.KeyCode.Q) then mv += Vector3.new(0, -1, 0) end
		end
		local sp = S.freeSpeed * (UIS:IsKeyDown(Enum.KeyCode.LeftShift) and 3 or 1) * dt
		fc.cf = CFrame.new(fc.cf.Position) * CFrame.fromOrientation(fc.pitch, fc.yaw, 0) * CFrame.new(mv * sp)
		cam.CFrame = cam.CFrame:Lerp(fc.cf, math.min(1, dt * 14))
	elseif S.fovOn then
		local _, r = getCar()
		local bonus = (S.fovDyn and r) and math.clamp(r.AssemblyLinearVelocity.Magnitude / 6, 0, 25) or 0
		cam.FieldOfView += ((S.fov + bonus) - cam.FieldOfView) * math.min(1, dt * 6)
	end
end)

local function panic()
	for _, k in ipairs({ "traffic", "free", "gravOn", "fovOn", "limitOn", "glowOn" }) do
		local o = Objs[k]
		if o and o.Value then o.Set(false) end
	end
	if Objs.preset then Objs.preset.Set("Game Default") end
	setUI(false)
end

connect(UIS.InputBegan, function(i, gp)
	if listening and i.UserInputType == Enum.UserInputType.Keyboard then listening(i.KeyCode); return end
	if gp then return end
	if i.KeyCode == uiKey then setUI(not uiOpen)
	elseif i.KeyCode == panicKey then panic()
	elseif i.UserInputType == Enum.UserInputType.MouseButton1 and S.clickTp and UIS:IsKeyDown(Enum.KeyCode.LeftControl) and cam then
		local mp = UIS:GetMouseLocation()
		local ray = cam:ViewportPointToRay(mp.X, mp.Y)
		local rp = RaycastParams.new(); rp.FilterType = Enum.RaycastFilterType.Exclude
		rp.FilterDescendantsInstances = { lp.Character, (getCar()), motePart }
		local res = workspace:Raycast(ray.Origin, ray.Direction * 4000, rp)
		if res and tpTo(res.Position) then snd(SND_CLICK, 1.4, .45) end
	elseif i.KeyCode == S.hopKey and S.hopOn then
		local _, r = getCar()
		if r then r.AssemblyLinearVelocity += Vector3.new(0, S.hopPower, 0); snd(SND_CLICK, 1.6, .35) end
	end
end)

local VirtualUser = game:GetService("VirtualUser")
connect(lp.Idled, function()
	if not S.antiAfk then return end
	pcall(function() VirtualUser:CaptureController(); VirtualUser:ClickButton2(Vector2.new()) end)
end)

local ready = false
local loadProfile, fsOk, AUTO_FILE

do
local tHome = Window:Tab("Home", "layout-grid")
local h1 = tHome:Section("Live")
local tiles = h1:Tiles({ { "speed", "km/h" }, { "ping", "ping ms" }, { "fps", "fps" }, { "traffic", "traffic cars" } })
local h2 = tHome:Section("Quick actions")
h2:Button({ Name = "Toggle Traffic", Primary = true, Callback = function() Objs.traffic.Set(not Objs.traffic.Value) end })
h2:Button({ Name = "Save Position", Callback = savePosition })
h2:Button({ Name = "Teleport to Saved", Callback = teleportSaved })
h2:Button({ Name = "Panic - disable everything", Danger = true, Callback = panic })
local h3 = tHome:Section("Session")
h3:Info("Players in server", function() return #Players:GetPlayers() end)
h3:Info("Session time", function() local t = math.floor(os.clock() - startTime); return string.format("%02d:%02d:%02d", t // 3600, (t % 3600) // 60, t % 60) end)
h3:Info("Current car", function() local m = getCar(); return m and m.Name:gsub("^.-_", "") or "On foot" end)
local h4 = tHome:Section("Keybinds")
h4:Info("Show / hide hub", function() return uiKey.Name end)
h4:Info("Panic", function() return panicKey.Name end)
h4:Info("Nitro", function() return S.nitroKey and S.nitroKey.Name or "None" end)
h4:Info("Car hop", function() return S.hopKey and S.hopKey.Name or "None" end)
h4:Info("Teleport", function() return "Ctrl + Click" end)

refreshStats = function()
	local ping = 0
	pcall(function() ping = math.floor(Stats.Network.ServerStatsItem["Data Ping"]:GetValue() + .5) end)
	tiles.speed.Text = tostring(math.floor(lastSpeed + .5))
	tiles.ping.Text = tostring(ping)
	tiles.fps.Text = tostring(math.floor(fpsAvg + .5))
	tiles.traffic.Text = tostring(trafficCount())
	wm.Visible = S.watermark
	wmText.Text = string.format("Aether Hub   %d fps   %d ms", math.floor(fpsAvg + .5), ping)
	for _, fn in ipairs(infoRows) do fn() end
end

end
do
local tTraffic = Window:Tab("Traffic", "traffic-cone")
local t1 = tTraffic:Section("Traffic control")
t1:Toggle({ Name = "Clear Traffic", Desc = "Removes every ambient car so the road is yours", Flag = "traffic", Callback = setTraffic })
t1:Dropdown({ Name = "Mode", Options = { "Ghost", "Destroy" }, Default = "Ghost", Flag = "tmode", Callback = function(v)
	if S.trafficOn then restoreTraffic() end
	S.trafficMode = v
	if S.trafficOn then sweepTraffic() end
end })
local trafficLbl = t1:Label("Traffic vehicles in world: -")
local t2 = tTraffic:Section("About modes")
t2:Label("Ghost hides traffic and removes its collision. Reversible.")
t2:Label("Destroy deletes it for this server until you rejoin.")
task.spawn(function()
	while Gui.Parent do trafficLbl:Set("Traffic vehicles in world: " .. trafficCount()); task.wait(1) end
end)

end
do
local tCar = Window:Tab("Vehicle", "car")
local c1 = tCar:Section("Power")
c1:Slider({ Name = "Acceleration Assist", Min = 0, Max = 120, Default = 0, Suffix = " st/s2", Flag = "assist", Callback = function(v) S.assist = v end })
c1:Toggle({ Name = "Nitro", Desc = "Hold the nitro key to surge forward", Default = true, Flag = "nitroOn", Callback = function(v) S.nitroOn = v end })
c1:Slider({ Name = "Nitro Power", Min = 20, Max = 400, Default = 140, Suffix = " st/s2", Flag = "nitro", Callback = function(v) S.nitro = v end })
c1:Keybind({ Name = "Nitro Key", Default = Enum.KeyCode.LeftShift, Flag = "nitroKey", Callback = function(k) S.nitroKey = k end })
local c2 = tCar:Section("Limits and safety")
c2:Toggle({ Name = "Speed Limiter", Desc = "Cap your top speed", Flag = "limitOn", Callback = function(v) S.limitOn = v end })
c2:Slider({ Name = "Top Speed", Min = 60, Max = 900, Default = 400, Suffix = " km/h", Flag = "top", Callback = function(v) S.topSpeed = v end })
c2:Toggle({ Name = "Auto Flip", Desc = "Rights your car if it lands on its roof", Default = true, Flag = "autoflip", Callback = function(v) S.autoflip = v end })
c2:Toggle({ Name = "Speedometer", Desc = "Drag it anywhere on screen", Default = true, Flag = "hud", Callback = function(v) S.hud = v end })

end
do
local tVis = Window:Tab("Visuals", "sparkles")
local v1 = tVis:Section("Car effects")
v1:Dropdown({ Name = "Effect Color", Options = { "Glowstone", "Water", "Zanite", "Aether Grass", "Rainbow", "Custom" }, Default = "Glowstone", Flag = "fxMode", Callback = function(v) S.fxMode = v end })
v1:Slider({ Name = "Custom Hue", Min = 0, Max = 1, Default = .12, Decimals = 2, Rainbow = true, Flag = "hue", Callback = function(v) S.hue = v end })
v1:Toggle({ Name = "Underglow", Desc = "Soft light cast by your car", Flag = "glowOn", Callback = function(v) S.glowOn = v end })
v1:Slider({ Name = "Glow Intensity", Min = 0, Max = 10, Default = 3, Decimals = 1, Flag = "glow", Callback = function(v) S.glow = v end })
v1:Toggle({ Name = "Spark Particles", Default = true, Flag = "sparks", Callback = function(v) S.sparks = v end })
v1:Toggle({ Name = "Light Trail", Default = true, Flag = "trail", Callback = function(v) S.trail = v end })
v1:Toggle({ Name = "Drift Sparks", Desc = "Particles when you slide sideways", Default = true, Flag = "drift", Callback = function(v) S.drift = v end })
local v2 = tVis:Section("Camera and screen")
v2:Toggle({ Name = "Custom FOV", Flag = "fovOn", Callback = function(v) S.fovOn = v; if not v and cam then cam.FieldOfView = origFov end end })
v2:Slider({ Name = "Field of View", Min = 40, Max = 120, Default = 80, Suffix = " deg", Flag = "fov", Callback = function(v) S.fov = v end })
v2:Toggle({ Name = "Speed FOV", Desc = "Widens the view as you go faster", Default = true, Flag = "fovDyn", Callback = function(v) S.fovDyn = v end })
v2:Slider({ Name = "Saturation", Min = -100, Max = 100, Default = 0, Flag = "sat", Callback = function(v) S.sat = v end })
v2:Slider({ Name = "Contrast", Min = -100, Max = 100, Default = 0, Flag = "con", Callback = function(v) S.con = v end })
v2:Slider({ Name = "Bloom", Min = 0, Max = 100, Default = 0, Flag = "bloom", Callback = function(v) S.bloom = v end })
local v3 = tVis:Section("Ambient particles")
v3:Dropdown({ Name = "Style", Options = { "Lumes", "Snow", "Embers", "Off" }, Default = "Lumes", Flag = "moteStyle", Callback = applyMoteStyle })

end
do
local tSky = Window:Tab("Sky", "cloud-sun")
local k1 = tSky:Section("Sky studio")
k1:Dropdown({ Name = "Preset", Options = PresetNames, Default = "Game Default", Flag = "preset", Callback = function(v)
	applyPreset(v)
	if v ~= "Game Default" then notify("Sky changed", v, 2, "cloud-sun") end
end })
k1:Toggle({ Name = "Lock Time of Day", Flag = "lockTime", Callback = function(v) S.lockTime = v end })
k1:Slider({ Name = "Clock Time", Min = 0, Max = 24, Default = 14, Decimals = 1, Suffix = "h", Flag = "clock", Callback = function(v) S.clock = v; if S.lockTime then Lighting.ClockTime = v end end })
k1:Toggle({ Name = "Day Cycle", Desc = "Time keeps moving at your chosen speed", Flag = "cycle", Callback = function(v) S.cycle = v end })
k1:Slider({ Name = "Cycle Speed", Min = 1, Max = 120, Default = 6, Suffix = " h/min", Flag = "cycleSpeed", Callback = function(v) S.cycleSpeed = v end })
local k2 = tSky:Section("Clouds")
k2:Slider({ Name = "Cloud Cover", Min = 0, Max = 100, Default = 50, Flag = "cover", Callback = function(v) if clouds then snap(clouds, CP); clouds.Cover = v / 100 end end })
k2:Slider({ Name = "Cloud Density", Min = 0, Max = 100, Default = 50, Flag = "dens", Callback = function(v) if clouds then snap(clouds, CP); clouds.Density = v / 100 end end })

end
do
local tExtra = Window:Tab("Extras", "wand-sparkles")
local e1 = tExtra:Section("Movement")
e1:Toggle({ Name = "Car Hop", Desc = "Pop your car into the air with a key", Default = true, Flag = "hopOn", Callback = function(v) S.hopOn = v end })
e1:Keybind({ Name = "Hop Key", Default = Enum.KeyCode.H, Flag = "hopKey", Callback = function(k) S.hopKey = k end })
e1:Slider({ Name = "Hop Power", Min = 15, Max = 150, Default = 45, Flag = "hopPower", Callback = function(v) S.hopPower = v end })
e1:Toggle({ Name = "Low Gravity", Desc = "Floaty, moon-like physics", Flag = "gravOn", Callback = function(v) S.gravOn = v; workspace.Gravity = v and S.grav or origGravity end })
e1:Slider({ Name = "Gravity", Min = 20, Max = 196, Default = 100, Flag = "grav", Callback = function(v) S.grav = v; if S.gravOn then workspace.Gravity = v end end })
local e2 = tExtra:Section("Teleport")
e2:Toggle({ Name = "Ctrl + Click Teleport", Desc = "Hold Left Ctrl and click the world", Default = true, Flag = "clickTp", Callback = function(v) S.clickTp = v end })
e2:Button({ Name = "Save Current Position", Callback = savePosition })
e2:Button({ Name = "Teleport to Saved", Callback = teleportSaved })
local e3 = tExtra:Section("Photo mode")
e3:Toggle({ Name = "Free Camera", Desc = "Right mouse to look, WASD to move, Q and E for height", Flag = "free", Callback = setFree })
e3:Slider({ Name = "Camera Speed", Min = 10, Max = 300, Default = 60, Flag = "freeSpeed", Callback = function(v) S.freeSpeed = v end })

end
do
local tTheme = Window:Tab("Theme", "palette")
local m1 = tTheme:Section("Accent")
local accentDD
accentDD = m1:Dropdown({ Name = "Accent Preset", Options = { "Glowstone", "Water", "Zanite", "Aether Grass", "Custom" }, Default = "Glowstone", Flag = "accent", Callback = setAccent })
m1:Slider({ Name = "Primary Hue", Min = 0, Max = 1, Default = .12, Decimals = 2, Rainbow = true, Flag = "h1", Callback = function(v)
	Custom.h1 = v
	if ready then setAccent("Custom"); accentDD.Set("Custom", true) end
end })
m1:Slider({ Name = "Secondary Hue", Min = 0, Max = 1, Default = .58, Decimals = 2, Rainbow = true, Flag = "h2", Callback = function(v)
	Custom.h2 = v
	if ready then setAccent("Custom"); accentDD.Set("Custom", true) end
end })
local m2 = tTheme:Section("Window")
m2:Dropdown({ Name = "Background", Options = { "Holystone", "Night Sky", "Deep Water", "Zanite", "Warm Stone" }, Default = "Holystone", Flag = "bg", Callback = setBackground })
m2:Slider({ Name = "Opacity", Min = 40, Max = 100, Default = 100, Suffix = "%", Flag = "opacity", Callback = function(v) Main.BackgroundTransparency = (100 - v) / 100 end })
m2:Slider({ Name = "Corner Radius", Min = 0, Max = 24, Default = 8, Flag = "radius", Callback = function(v) MainCorner.CornerRadius = UDim.new(0, v) end })
m2:Slider({ Name = "UI Scale", Min = 70, Max = 130, Default = 100, Suffix = "%", Flag = "scale", Callback = function(v) g.AetherHubScale = v / 100; if uiOpen then tween(RootScale, .3, { Scale = v / 100 }) end end })
m2:Slider({ Name = "Animation Speed", Min = .5, Max = 2, Default = 1, Decimals = 2, Suffix = "x", Flag = "animspeed", Callback = function(v) Anim.speed = v end })
m2:Toggle({ Name = "Floating Specks", Desc = "Drifting pixels behind the window", Default = true, Flag = "specks", Callback = function(v) fleckLayer.Visible = v end })

end
do
local tSet = Window:Tab("Settings", "settings")
local s1 = tSet:Section("Interface")
s1:Keybind({ Name = "Show / Hide Hub", Default = DEFAULT_UI_KEY, Flag = "uiKey", Callback = function(k) uiKey = k or DEFAULT_UI_KEY end })
s1:Keybind({ Name = "Panic Key", Default = DEFAULT_PANIC_KEY, Flag = "panicKey", Callback = function(k) panicKey = k or DEFAULT_PANIC_KEY end })
s1:Toggle({ Name = "UI Sounds", Default = true, Flag = "sfx", Callback = function(v) Sfx.on = v end })
s1:Slider({ Name = "Sound Volume", Min = 0, Max = 100, Default = 60, Suffix = "%", Flag = "vol", Callback = function(v) Sfx.vol = v / 100 end })
s1:Toggle({ Name = "Notifications", Default = true, Flag = "notif", Callback = function(v) NotifOn = v end })
s1:Toggle({ Name = "Status Bar", Desc = "FPS and ping at the top of the screen", Default = true, Flag = "watermark", Callback = function(v) S.watermark = v; wm.Visible = v end })
local s2 = tSet:Section("Utility")
s2:Toggle({ Name = "Anti AFK", Desc = "Stops you being kicked for idling", Default = true, Flag = "antiAfk", Callback = function(v) S.antiAfk = v end })
s2:Slider({ Name = "FPS Cap", Min = 30, Max = 360, Default = 144, Flag = "fpscap", Callback = function(v) if setfpscap then pcall(setfpscap, v) end end })
s2:Button({ Name = "Rejoin Server", Callback = function() TeleportService:Teleport(game.PlaceId, lp) end })

local CFG_DIR = "AetherHub/profiles"
AUTO_FILE = "AetherHub/autoload.txt"
fsOk = writefile and readfile and listfiles and makefolder and isfolder and isfile and delfile
local function ensureDir()
	if not fsOk then return false end
	return pcall(function()
		if not isfolder("AetherHub") then makefolder("AetherHub") end
		if not isfolder(CFG_DIR) then makefolder(CFG_DIR) end
	end)
end
local function listProfiles()
	local out = {}
	if fsOk and ensureDir() then
		pcall(function()
			for _, f in ipairs(listfiles(CFG_DIR)) do
				local n = f:match("([^/\\]+)%.json$")
				if n then out[#out + 1] = n end
			end
		end)
	end
	table.sort(out)
	if #out == 0 then out = { "No profiles yet" } end
	return out
end
local function profilePath(name) return CFG_DIR .. "/" .. name .. ".json" end
local function snapshot()
	local data = {}
	for k, o in pairs(Objs) do
		local v = o.Value
		if typeof(v) == "EnumItem" then v = v.Name end
		if v ~= nil then data[k] = v end
	end
	return data
end
local function saveProfile(name)
	if not fsOk then return false, "Your executor has no file access" end
	ensureDir()
	local ok, err = pcall(function() writefile(profilePath(name), HttpService:JSONEncode(snapshot())) end)
	return ok, err
end
local lastApplied = { "preset", "accent", "bg" }
function loadProfile(name)
	if not fsOk then return false, "Your executor has no file access" end
	local ok, data = pcall(function() return HttpService:JSONDecode(readfile(profilePath(name))) end)
	if not ok then return false, "Could not read that profile" end
	local deferred = {}
	for _, k in ipairs(lastApplied) do deferred[k] = true end
	for k, v in pairs(data) do
		local o = Objs[k]
		if o and not deferred[k] then
			if k == "nitroKey" or k == "uiKey" or k == "panicKey" or k == "hopKey" then
				local okk, key = pcall(function() return Enum.KeyCode[v] end)
				v = okk and key or nil
			end
			pcall(o.Set, v)
		end
	end
	for _, k in ipairs(lastApplied) do
		if data[k] and Objs[k] then pcall(Objs[k].Set, data[k]) end
	end
	return true
end

local selectedName = ""
local p1 = tSet:Section("Profiles")
local profileDD
p1:TextBox({ Name = "Profile Name", Placeholder = "e.g. night cruise", Callback = function(t) selectedName = t end })
p1:Button({ Name = "Create Profile", Primary = true, Callback = function()
	local n = (selectedName:gsub("[^%w _%-]", "")):gsub("^%s+", ""):gsub("%s+$", "")
	if n == "" then notify("Name required", "Type a profile name first", 3, "save"); return end
	local ok, err = saveProfile(n)
	if ok then
		profileDD.Refresh(listProfiles()); profileDD.Set(n, true)
		notify("Profile created", n, 3, "save")
	else
		notify("Could not save", tostring(err), 4, "save")
	end
end })
profileDD = p1:Dropdown({ Name = "Saved Profiles", Options = listProfiles(), Default = listProfiles()[1] })
local function chosen()
	local n = profileDD.Value
	if not n or n == "No profiles yet" then notify("No profile selected", "Create one first", 3, "folder-open"); return end
	return n
end
p1:Button({ Name = "Load Selected", Callback = function()
	local n = chosen(); if not n then return end
	local ok, err = loadProfile(n)
	notify(ok and "Profile loaded" or "Could not load", ok and n or tostring(err), 3, "folder-open")
end })
p1:Button({ Name = "Overwrite Selected", Callback = function()
	local n = chosen(); if not n then return end
	local ok, err = saveProfile(n)
	notify(ok and "Profile updated" or "Could not save", ok and n or tostring(err), 3, "save")
end })
p1:Button({ Name = "Delete Selected", Danger = true, Callback = function()
	local n = chosen(); if not n then return end
	local ok = pcall(delfile, profilePath(n))
	profileDD.Refresh(listProfiles()); profileDD.Set(listProfiles()[1], true)
	notify(ok and "Profile deleted" or "Could not delete", n, 3, "trash-2")
end })
p1:Toggle({ Name = "Autoload Selected", Desc = "Applies this profile every time you launch", Callback = function(v)
	if not fsOk then notify("Unavailable", "Your executor has no file access", 3, "save"); return end
	ensureDir()
	if v then
		local n = chosen(); if not n then return end
		pcall(writefile, AUTO_FILE, n)
		notify("Autoload on", n, 3, "check")
	else
		pcall(delfile, AUTO_FILE)
		notify("Autoload off", "Hub starts with defaults", 3, "check")
	end
end })
local p2 = tSet:Section("Danger zone")
p2:Button({ Name = "Unload Aether Hub", Danger = true, Callback = function() if g.AetherHubUnload then g.AetherHubUnload() end end })

end

g.AetherHubScale = 1
g.AetherHubUnload = function()
	pcall(restoreTraffic)
	pcall(applyPreset, "Game Default")
	pcall(clearFX)
	pcall(function() if S.free then setFree(false) end end)
	pcall(function() workspace.Gravity = origGravity end)
	for _, c in ipairs(conns) do pcall(c.Disconnect, c) end
	for _, c in ipairs(trafficConns) do pcall(c.Disconnect, c) end
	if cam then pcall(function() cam.FieldOfView = origFov end) end
	for _, i in ipairs({ cc, bl, motePart, Gui, HudGui }) do pcall(i.Destroy, i) end
	g.AetherHubUnload = nil
end

local splash = new("CanvasGroup", { AnchorPoint = Vector2.new(.5, .5), Position = UDim2.fromScale(.5, .5), Size = UDim2.fromOffset(300, 190), BackgroundColor3 = "@bg", BorderSizePixel = 0, GroupTransparency = 1 }, Gui)
corner(splash, 8); stroke(splash, "@line", 1, 0)
makeLogo(splash, 5, UDim2.new(.5, 0, 0, 62))
local st = text(splash, "AETHER HUB", 20, "@text", Enum.Font.Arcade, Enum.TextXAlignment.Center); st.Position = UDim2.fromOffset(0, 104); st.Size = UDim2.new(1, 0, 0, 28)
local sb = new("Frame", { AnchorPoint = Vector2.new(.5, 0), Position = UDim2.new(.5, 0, 0, 150), Size = UDim2.fromOffset(160, 4), BackgroundColor3 = "@off", BorderSizePixel = 0 }, splash)
local sf = new("Frame", { Size = UDim2.fromScale(0, 1), BackgroundColor3 = "@accent", BorderSizePixel = 0 }, sb)
tween(splash, .5, { GroupTransparency = 0 })
snd(SND_CLICK, .6, .45)
tween(sf, 1.3, { Size = UDim2.fromScale(1, 1) }, Enum.EasingStyle.Sine, Enum.EasingDirection.InOut)
task.delay(1.5, function()
	tween(splash, .4, { GroupTransparency = 1 }).Completed:Wait()
	splash:Destroy()
	ready = true
	setUI(true)
	notify("Aether Hub loaded", "Press " .. uiKey.Name .. " to hide or show", 4, "check")
	if fsOk and pcall(function() return isfile(AUTO_FILE) end) and isfile(AUTO_FILE) then
		local ok, name = pcall(readfile, AUTO_FILE)
		if ok and name and name ~= "" then
			local good = loadProfile(name)
			if good then notify("Autoloaded", name, 3, "folder-open") end
		end
	end
end)
