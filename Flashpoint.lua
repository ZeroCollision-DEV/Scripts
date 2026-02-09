local repo = 'https://raw.githubusercontent.com/violin-suzutsuki/LinoriaLib/main/'

local Library = loadstring(game:HttpGet(repo .. 'Library.lua'))()
local ThemeManager = loadstring(game:HttpGet(repo .. 'addons/ThemeManager.lua'))()
local SaveManager = loadstring(game:HttpGet(repo .. 'addons/SaveManager.lua'))()

local correctKey = "Jolly184"
local keyVerified = false
local keyScreenGui = nil
local keyTextBox = nil

local function createMainUI()

local Window = Library:CreateWindow({
    Title = "Flashpoint World's Collide Script | By Jolly",
    Center = true,
    AutoShow = true,
    TabPadding = 4,
    MenuFadeTime = 0.7,
    Size = UDim2.new(0, 600, 0, 600)
})

local Tabs = {
    Main = Window:AddTab("Main"),
    Teleport = Window:AddTab("Teleport"),
    Misc = Window:AddTab("Misc")
}

local MainGroup = Tabs.Main:AddLeftGroupbox("Stat Boosts")

local OriginalValues = {}
local function safeBackupStat(statName)
    local success, value = pcall(function()
        return game:GetService("Players").LocalPlayer.PlayerData.Upgrades[statName].Value
    end)
    if success then
        OriginalValues[statName] = value
    else
        OriginalValues[statName] = 0
    end
end

safeBackupStat("Speed")
safeBackupStat("Health") 
safeBackupStat("Flashtime Speed")
safeBackupStat("Damage")
safeBackupStat("Boost Speed")
safeBackupStat("Boost Duration")

local RebirthOriginalValues = {}
local function safeBackupRebirthStat(statName)
    local success, value = pcall(function()
        return game:GetService("Players").LocalPlayer.PlayerData.RebirthUpgrades[statName].Value
    end)
    if success then
        RebirthOriginalValues[statName] = value
    else
        RebirthOriginalValues[statName] = 0
    end
end

safeBackupRebirthStat("Speed")
safeBackupRebirthStat("Health") 
safeBackupRebirthStat("Flashtime Speed")
safeBackupRebirthStat("Damage")
safeBackupRebirthStat("Boost Speed")
safeBackupRebirthStat("Boost Duration")

MainGroup:AddToggle("EnableSpeed", {
    Text = "Enable Speed Boost",
    Default = false,
    Callback = function(State)
        if not State then
            pcall(function()
                game:GetService("Players").LocalPlayer.PlayerData.Upgrades.Speed.Value = OriginalValues.Speed
            end)
        end
    end
})

MainGroup:AddSlider("SpeedSlider", {
    Text = "Speed",
    Default = OriginalValues.Speed or 0,
    Min = 0,
    Max = 100000,
    Rounding = 0,
    Callback = function(Value)
        pcall(function()
            game:GetService("Players").LocalPlayer.PlayerData.Upgrades.Speed.Value = Value
        end)
    end
})

MainGroup:AddToggle("EnableHealth", {
    Text = "Enable Health Boost",
    Default = false,
    Callback = function(State)
        if not State then
            pcall(function()
                game:GetService("Players").LocalPlayer.PlayerData.Upgrades.Health.Value = OriginalValues.Health
            end)
        end
    end
})

MainGroup:AddSlider("HealthSlider", {
    Text = "Health",
    Default = OriginalValues.Health or 0,
    Min = 0,
    Max = 50,
    Rounding = 0,
    Callback = function(Value)
        pcall(function()
            game:GetService("Players").LocalPlayer.PlayerData.Upgrades.Health.Value = Value
        end)
    end
})

MainGroup:AddToggle("EnableFlashtimeSpeed", {
    Text = "Enable Flashtime Speed",
    Default = false,
    Callback = function(State)
        if not State then
            pcall(function()
                game:GetService("Players").LocalPlayer.PlayerData.Upgrades["Flashtime Speed"].Value = OriginalValues["Flashtime Speed"]
            end)
        end
    end
})

MainGroup:AddSlider("FlashtimeSpeedSlider", {
    Text = "Flashtime Speed",
    Default = OriginalValues["Flashtime Speed"] or 0,
    Min = 0,
    Max = 100000,
    Rounding = 0,
    Callback = function(Value)
        pcall(function()
            game:GetService("Players").LocalPlayer.PlayerData.Upgrades["Flashtime Speed"].Value = Value
        end)
    end
})

MainGroup:AddToggle("EnableDamage", {
    Text = "Enable Damage Boost",
    Default = false,
    Callback = function(State)
        if not State then
            pcall(function()
                game:GetService("Players").LocalPlayer.PlayerData.Upgrades.Damage.Value = OriginalValues.Damage
            end)
        end
    end
})

MainGroup:AddSlider("DamageSlider", {
    Text = "Damage",
    Default = OriginalValues.Damage or 0,
    Min = 0,
    Max = 100000,
    Rounding = 0,
    Callback = function(Value)
        pcall(function()
            game:GetService("Players").LocalPlayer.PlayerData.Upgrades.Damage.Value = Value
        end)
    end
})

MainGroup:AddToggle("EnableBoostSpeed", {
    Text = "Enable Boost Speed",
    Default = false,
    Callback = function(State)
        if not State then
            pcall(function()
                game:GetService("Players").LocalPlayer.PlayerData.Upgrades["Boost Speed"].Value = OriginalValues["Boost Speed"]
            end)
        end
    end
})

MainGroup:AddSlider("BoostSpeedSlider", {
    Text = "Boost Speed",
    Default = OriginalValues["Boost Speed"] or 0,
    Min = 0,
    Max = 100000,
    Rounding = 0,
    Callback = function(Value)
        pcall(function()
            game:GetService("Players").LocalPlayer.PlayerData.Upgrades["Boost Speed"].Value = Value
        end)
    end
})

MainGroup:AddToggle("EnableBoostDur", {
    Text = "Enable Boost Duration",
    Default = false,
    Callback = function(State)
        if not State then
            pcall(function()
                game:GetService("Players").LocalPlayer.PlayerData.Upgrades["Boost Duration"].Value = OriginalValues["Boost Duration"]
            end)
        end
    end
})

MainGroup:AddSlider("BoostDurSlider", {
    Text = "Boost Duration",
    Default = OriginalValues["Boost Duration"] or 0,
    Min = 0,
    Max = 100000,
    Rounding = 0,
    Callback = function(Value)
        pcall(function()
            game:GetService("Players").LocalPlayer.PlayerData.Upgrades["Boost Duration"].Value = Value
        end)
    end
})

local AbilitiesGroup = Tabs.Main:AddLeftGroupbox("Abilities")

AbilitiesGroup:AddToggle("ArmTornado", {
    Text = "Arm Tornado",
    Default = false,
    Callback = function(State)
        pcall(function()
            if State then
                game:GetService("Players").LocalPlayer.PlayerData.Abilities.ArmTornado.Value = 3
            else
                game:GetService("Players").LocalPlayer.PlayerData.Abilities.ArmTornado.Value = 0
            end
        end)
    end
})

AbilitiesGroup:AddToggle("LightningThrow", {
    Text = "Lightning Throw",
    Default = false,
    Callback = function(State)
        pcall(function()
            if State then
                game:GetService("Players").LocalPlayer.PlayerData.Abilities.LightningThrow.Value = 3
            else
                game:GetService("Players").LocalPlayer.PlayerData.Abilities.LightningThrow.Value = 0
            end
        end)
    end
})

local RebirthGroup = Tabs.Main:AddRightGroupbox("Rebirth Upgrades")

RebirthGroup:AddToggle("EnableRebirthSpeed", {
    Text = "Enable Rebirth Speed",
    Default = false,
    Callback = function(State)
        if not State then
            pcall(function()
                game:GetService("Players").LocalPlayer.PlayerData.RebirthUpgrades.Speed.Value = RebirthOriginalValues.Speed
            end)
        end
    end
})

RebirthGroup:AddSlider("RebirthSpeedSlider", {
    Text = "Rebirth Speed",
    Default = RebirthOriginalValues.Speed or 0,
    Min = 0,
    Max = 100000,
    Rounding = 0,
    Callback = function(Value)
        pcall(function()
            game:GetService("Players").LocalPlayer.PlayerData.RebirthUpgrades.Speed.Value = Value
        end)
    end
})

RebirthGroup:AddToggle("EnableRebirthHealth", {
    Text = "Enable Rebirth Health",
    Default = false,
    Callback = function(State)
        if not State then
            pcall(function()
                game:GetService("Players").LocalPlayer.PlayerData.RebirthUpgrades.Health.Value = RebirthOriginalValues.Health
            end)
        end
    end
})

RebirthGroup:AddSlider("RebirthHealthSlider", {
    Text = "Rebirth Health",
    Default = RebirthOriginalValues.Health or 0,
    Min = 0,
    Max = 100000,
    Rounding = 0,
    Callback = function(Value)
        pcall(function()
            game:GetService("Players").LocalPlayer.PlayerData.RebirthUpgrades.Health.Value = Value
        end)
    end
})

RebirthGroup:AddToggle("EnableRebirthFlashtimeSpeed", {
    Text = "Enable Rebirth Flashtime Speed",
    Default = false,
    Callback = function(State)
        if not State then
            pcall(function()
                game:GetService("Players").LocalPlayer.PlayerData.RebirthUpgrades["Flashtime Speed"].Value = RebirthOriginalValues["Flashtime Speed"]
            end)
        end
    end
})

RebirthGroup:AddSlider("RebirthFlashtimeSpeedSlider", {
    Text = "Rebirth Flashtime Speed",
    Default = RebirthOriginalValues["Flashtime Speed"] or 0,
    Min = 0,
    Max = 100000,
    Rounding = 0,
    Callback = function(Value)
        pcall(function()
            game:GetService("Players").LocalPlayer.PlayerData.RebirthUpgrades["Flashtime Speed"].Value = Value
        end)
    end
})

RebirthGroup:AddToggle("EnableRebirthDamage", {
    Text = "Enable Rebirth Damage",
    Default = false,
    Callback = function(State)
        if not State then
            pcall(function()
                game:GetService("Players").LocalPlayer.PlayerData.RebirthUpgrades.Damage.Value = RebirthOriginalValues.Damage
            end)
        end
    end
})

RebirthGroup:AddSlider("RebirthDamageSlider", {
    Text = "Rebirth Damage",
    Default = RebirthOriginalValues.Damage or 0,
    Min = 0,
    Max = 100000,
    Rounding = 0,
    Callback = function(Value)
        pcall(function()
            game:GetService("Players").LocalPlayer.PlayerData.RebirthUpgrades.Damage.Value = Value
        end)
    end
})

RebirthGroup:AddToggle("EnableRebirthBoostSpeed", {
    Text = "Enable Rebirth Boost Speed",
    Default = false,
    Callback = function(State)
        if not State then
            pcall(function()
                game:GetService("Players").LocalPlayer.PlayerData.RebirthUpgrades["Boost Speed"].Value = RebirthOriginalValues["Boost Speed"]
            end)
        end
    end
})

RebirthGroup:AddSlider("RebirthBoostSpeedSlider", {
    Text = "Rebirth Boost Speed",
    Default = RebirthOriginalValues["Boost Speed"] or 0,
    Min = 0,
    Max = 100000,
    Rounding = 0,
    Callback = function(Value)
        pcall(function()
            game:GetService("Players").LocalPlayer.PlayerData.RebirthUpgrades["Boost Speed"].Value = Value
        end)
    end
})

RebirthGroup:AddToggle("EnableRebirthBoostDur", {
    Text = "Enable Rebirth Boost Duration",
    Default = false,
    Callback = function(State)
        if not State then
            pcall(function()
                game:GetService("Players").LocalPlayer.PlayerData.RebirthUpgrades["Boost Duration"].Value = RebirthOriginalValues["Boost Duration"]
            end)
        end
    end
})

RebirthGroup:AddSlider("RebirthBoostDurSlider", {
    Text = "Rebirth Boost Duration",
    Default = RebirthOriginalValues["Boost Duration"] or 0,
    Min = 0,
    Max = 100000,
    Rounding = 0,
    Callback = function(Value)
        pcall(function()
            game:GetService("Players").LocalPlayer.PlayerData.RebirthUpgrades["Boost Duration"].Value = Value
        end)
    end
})

local MiscMainGroup = Tabs.Main:AddLeftGroupbox("Misc")

MiscMainGroup:AddToggle("SuitBypass", {
    Text = "Unlock All",
    Default = false,
    Callback = function(State)
        pcall(function()
            game:GetService("Players").LocalPlayer.PlayerData.Misc.SuitBypass.Value = State
        end)
    end
})

local GamepassesGroup = Tabs.Main:AddLeftGroupbox("Gamepasses")

GamepassesGroup:AddToggle("Gamepass2XSkillPoints", {
    Text = "2X SKILLPOINTS",
    Default = false,
    Callback = function(State)
        if State then
            pcall(function()
                local intValue = Instance.new("IntValue")
                intValue.Name = "2X SKILLPOINTS"
                intValue.Value = 912780880
                intValue.Parent = game:GetService("Players").LocalPlayer.PlayerData.GamepassesBought
            end)
        else
            pcall(function()
                if game:GetService("Players").LocalPlayer.PlayerData.GamepassesBought:FindFirstChild("2X SKILLPOINTS") then
                    game:GetService("Players").LocalPlayer.PlayerData.GamepassesBought["2X SKILLPOINTS"]:Destroy()
                end
            end)
        end
    end
})

GamepassesGroup:AddToggle("GamepassTrailCustomization", {
    Text = "Trail Customization",
    Default = false,
    Callback = function(State)
        if State then
            pcall(function()
                local intValue = Instance.new("IntValue")
                intValue.Name = "Trail Customization"
                intValue.Value = 943911201
                intValue.Parent = game:GetService("Players").LocalPlayer.PlayerData.GamepassesBought
            end)
        else
            pcall(function()
                if game:GetService("Players").LocalPlayer.PlayerData.GamepassesBought:FindFirstChild("Trail Customization") then
                    game:GetService("Players").LocalPlayer.PlayerData.GamepassesBought["Trail Customization"]:Destroy()
                end
            end)
        end
    end
})

GamepassesGroup:AddToggle("Gamepass2XEXP", {
    Text = "2X EXP",
    Default = false,
    Callback = function(State)
        if State then
            pcall(function()
                local intValue = Instance.new("IntValue")
                intValue.Name = "2X EXP"
                intValue.Value = 910843611
                intValue.Parent = game:GetService("Players").LocalPlayer.PlayerData.GamepassesBought
            end)
        else
            pcall(function()
                if game:GetService("Players").LocalPlayer.PlayerData.GamepassesBought:FindFirstChild("2X EXP") then
                    game:GetService("Players").LocalPlayer.PlayerData.GamepassesBought["2X EXP"]:Destroy()
                end
            end)
        end
    end
})

GamepassesGroup:AddToggle("Gamepass2XCash", {
    Text = "2X CASH",
    Default = false,
    Callback = function(State)
        if State then
            pcall(function()
                local intValue = Instance.new("IntValue")
                intValue.Name = "2X CASH"
                intValue.Value = 912593565
                intValue.Parent = game:GetService("Players").LocalPlayer.PlayerData.GamepassesBought
            end)
        else
            pcall(function()
                if game:GetService("Players").LocalPlayer.PlayerData.GamepassesBought:FindFirstChild("2X CASH") then
                    game:GetService("Players").LocalPlayer.PlayerData.GamepassesBought["2X CASH"]:Destroy()
                end
            end)
        end
    end
})

GamepassesGroup:AddToggle("GamepassInstantSpin", {
    Text = "Instant Spin",
    Default = false,
    Callback = function(State)
        if State then
            pcall(function()
                local intValue = Instance.new("IntValue")
                intValue.Name = "Instant Spin"
                intValue.Value = 1420990597
                intValue.Parent = game:GetService("Players").LocalPlayer.PlayerData.GamepassesBought
            end)
        else
            pcall(function()
                if game:GetService("Players").LocalPlayer.PlayerData.GamepassesBought:FindFirstChild("Instant Spin") then
                    game:GetService("Players").LocalPlayer.PlayerData.GamepassesBought["Instant Spin"]:Destroy()
                end
            end)
        end
    end
})

GamepassesGroup:AddToggle("GamepassMissionSelector", {
    Text = "Mission Selector",
    Default = false,
    Callback = function(State)
        if State then
            pcall(function()
                local intValue = Instance.new("IntValue")
                intValue.Name = "Mission Selector"
                intValue.Value = 1412163280
                intValue.Parent = game:GetService("Players").LocalPlayer.PlayerData.GamepassesBought
            end)
        else
            pcall(function()
                if game:GetService("Players").LocalPlayer.PlayerData.GamepassesBought:FindFirstChild("Mission Selector") then
                    game:GetService("Players").LocalPlayer.PlayerData.GamepassesBought["Mission Selector"]:Destroy()
                end
            end)
        end
    end
})

local RightGroup = Tabs.Main:AddRightGroupbox("Controls")


RightGroup:AddLabel("UI Toggle: RightShift")

local MiscGroup = Tabs.Misc:AddLeftGroupbox("Miscellaneous")

MiscGroup:AddButton("Clear Console", function()
    print("Console cleared")
end)

local PlayerList = {}
local SelectedPlayer = nil
local CameraLocked = false
local Camera = workspace.CurrentCamera
local LocalPlayer = game:GetService("Players").LocalPlayer
local RunService = game:GetService("RunService")

local PlayerDropdown = MiscGroup:AddDropdown("PlayerSelect", {
    Title = "Select Player",
    Values = {},
    Default = "None",
    Callback = function(Value)
        if Value ~= "None" then
            SelectedPlayer = game:GetService("Players"):FindFirstChild(Value)
        else
            SelectedPlayer = nil
        end
    end
})

MiscGroup:AddButton("Lock Camera", function()
    if SelectedPlayer and SelectedPlayer.Character then
        CameraLocked = true
        Library:Notify("Camera locked on " .. SelectedPlayer.Name, 3)
    else
        Library:Notify("Please select a player first!", 3)
    end
end)

MiscGroup:AddButton("Unlock Camera", function()
    CameraLocked = false
    Camera.CameraSubject = LocalPlayer.Character
    Library:Notify("Camera unlocked", 3)
end)

local function UpdatePlayerList()
    local Players = game:GetService("Players"):GetPlayers()
    local PlayerNames = {"None"}
    
    for _, Player in ipairs(Players) do
        if Player ~= LocalPlayer then
            table.insert(PlayerNames, Player.Name)
        end
    end
    
    PlayerDropdown:SetValues(PlayerNames)
end

local LastUpdateTime = 0
local TargetFPS = 60

RunService.Heartbeat:Connect(function()
    if CameraLocked and SelectedPlayer and SelectedPlayer.Character then
        local targetPart = SelectedPlayer.Character:FindFirstChild("HumanoidRootPart")
        
        if targetPart then
            local currentCameraSubject = Camera.CameraSubject
            if currentCameraSubject ~= SelectedPlayer.Character then
                Camera.CameraSubject = SelectedPlayer.Character
            end
            
            local currentTime = tick()
            local deltaTime = currentTime - LastUpdateTime
            local targetDeltaTime = 1 / TargetFPS
            
            if deltaTime >= targetDeltaTime then
                local offsetDistance = 5 
                local cameraOffset = targetPart.CFrame:ToWorldSpace(CFrame.new(0, 0, -offsetDistance).Position)
                
                Camera.CFrame = CFrame.new(cameraOffset, targetPart.Position)
                LastUpdateTime = currentTime
            end
        end
    end
end)

game:GetService("Players").PlayerAdded:Connect(function()
    UpdatePlayerList()
end)

game:GetService("Players").PlayerRemoving:Connect(function()
    UpdatePlayerList()
    if SelectedPlayer and not game:GetService("Players"):FindFirstChild(SelectedPlayer.Name) then
        SelectedPlayer = nil
        CameraLocked = false
        Camera.CameraSubject = LocalPlayer.Character
    end
end)

UpdatePlayerList()

local function restoreAllValues()
    print("Restoring all values to original backups...")
    
    local regularStats = {"Speed", "Health", "Flashtime Speed", "Damage", "Boost Speed", "Boost Duration"}
    for _, statName in ipairs(regularStats) do
        pcall(function()
            game:GetService("Players").LocalPlayer.PlayerData.Upgrades[statName].Value = OriginalValues[statName] or 0
            print("Restored", statName, "to", OriginalValues[statName] or 0)
        end)
    end
    
    -- Restore Rebirth Upgrades
    local rebirthStats = {"Speed", "Health", "Flashtime Speed", "Damage", "Boost Speed", "Boost Duration"}
    for _, statName in ipairs(rebirthStats) do
        pcall(function()
            game:GetService("Players").LocalPlayer.PlayerData.RebirthUpgrades[statName].Value = RebirthOriginalValues[statName] or 0
            print("Restored Rebirth", statName, "to", RebirthOriginalValues[statName] or 0)
        end)
    end
    
    -- Restore Abilities
    pcall(function()
        game:GetService("Players").LocalPlayer.PlayerData.Abilities.ArmTornado.Value = 0
        game:GetService("Players").LocalPlayer.PlayerData.Abilities.LightningThrow.Value = 0
        print("Restored Abilities to 0")
    end)
    
    print("All values restored successfully!")
end

local MiscRight = Tabs.Misc:AddRightGroupbox("Info")

MiscRight:AddLabel("Version: 1.0.0")
MiscRight:AddLabel("Library: Linoria")
MiscRight:AddDivider()
MiscRight:AddButton("Unload Script", function()
    restoreAllValues()
    Library:Notify("All values restored! Unloading script...", 3)
    wait(1)
    Library:Unload()
end)

print("Misc tab completed")

local TeleportGroup = Tabs.Teleport:AddLeftGroupbox("Locations")

TeleportGroup:AddButton("Jitters TP", function()
    pcall(function()
        game:GetService("Players").LocalPlayer.Character.HumanoidRootPart.CFrame = workspace.Teleports["Jitters TP"]["City into Jitters"]["City into Jitters"]["Exit 1"].CFrame
    end)
end)

TeleportGroup:AddButton("Star Labs TP", function()
    pcall(function()
        game:GetService("Players").LocalPlayer.Character.HumanoidRootPart.CFrame = workspace.Teleports["Star Labs TP"]["City into StarLabs"]["StarLabs into City"]["Entrance 2"].CFrame
    end)
end)

TeleportGroup:AddButton("GCPD TP", function()
    pcall(function()
        game:GetService("Players").LocalPlayer.Character.HumanoidRootPart.CFrame = workspace.Teleports["GCPD TP"]["City into GCPD"]["Exit 1"].CFrame
    end)
end)

TeleportGroup:AddButton("Barry's Apartment TP", function()
    pcall(function()
        game:GetService("Players").LocalPlayer.Character.HumanoidRootPart.CFrame = workspace.Teleports["Barry's Apartment TP"]["Apartment into City"]["Entrance 2"].CFrame
    end)
end)

TeleportGroup:AddButton("Spawn", function()
    pcall(function()
        game:GetService("Players").LocalPlayer.Character.HumanoidRootPart.CFrame = workspace.SpawnLocation.CFrame
    end)
end)

-- Theme Manager Setup
ThemeManager:SetLibrary(Library)
ThemeManager:SetFolder("MyScriptName")
ThemeManager:ApplyToGroupbox(Tabs.Misc:AddLeftGroupbox("Themes"))

end

local function createKeyUI()
    local Players = game:GetService("Players")
    local LocalPlayer = Players.LocalPlayer
    local PlayerGui = LocalPlayer:WaitForChild("PlayerGui")
    
    keyScreenGui = Instance.new("ScreenGui")
    keyScreenGui.Name = "KeyAuthGUI"
    keyScreenGui.Parent = PlayerGui
    keyScreenGui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
    
    local mainFrame = Instance.new("Frame")
    mainFrame.Name = "MainFrame"
    mainFrame.Parent = keyScreenGui
    mainFrame.Size = UDim2.new(0, 400, 0, 300)
    mainFrame.Position = UDim2.new(0.5, -200, 0.5, -150)
    mainFrame.BackgroundColor3 = Color3.fromRGB(30, 30, 30)
    mainFrame.BorderSizePixel = 0
    mainFrame.Active = true
    mainFrame.Draggable = true
    
    local corner = Instance.new("UICorner")
    corner.CornerRadius = UDim.new(0, 10)
    corner.Parent = mainFrame
    
    local titleLabel = Instance.new("TextLabel")
    titleLabel.Name = "TitleLabel"
    titleLabel.Parent = mainFrame
    titleLabel.Size = UDim2.new(1, 0, 0, 40)
    titleLabel.Position = UDim2.new(0, 0, 0, 20)
    titleLabel.BackgroundTransparency = 1
    titleLabel.Text = "Key Authentication"
    titleLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
    titleLabel.TextSize = 24
    titleLabel.Font = Enum.Font.SourceSansBold
    titleLabel.TextScaled = true
    
    local subtitleLabel = Instance.new("TextLabel")
    subtitleLabel.Name = "SubtitleLabel"
    subtitleLabel.Parent = mainFrame
    subtitleLabel.Size = UDim2.new(1, 0, 0, 30)
    subtitleLabel.Position = UDim2.new(0, 0, 0, 70)
    subtitleLabel.BackgroundTransparency = 1
    subtitleLabel.Text = "Get key from discord"
    subtitleLabel.TextColor3 = Color3.fromRGB(200, 200, 200)
    subtitleLabel.TextSize = 16
    subtitleLabel.Font = Enum.Font.SourceSans
    
    keyTextBox = Instance.new("TextBox")
    keyTextBox.Name = "KeyTextBox"
    keyTextBox.Parent = mainFrame
    keyTextBox.Size = UDim2.new(0, 300, 0, 40)
    keyTextBox.Position = UDim2.new(0.5, -150, 0, 120)
    keyTextBox.BackgroundColor3 = Color3.fromRGB(50, 50, 50)
    keyTextBox.BorderSizePixel = 0
    keyTextBox.PlaceholderText = "Enter Key"
    keyTextBox.Text = ""
    keyTextBox.TextColor3 = Color3.fromRGB(255, 255, 255)
    keyTextBox.TextSize = 16
    keyTextBox.Font = Enum.Font.SourceSans
    
    local textBoxCorner = Instance.new("UICorner")
    textBoxCorner.CornerRadius = UDim.new(0, 5)
    textBoxCorner.Parent = keyTextBox
    
    local loadButton = Instance.new("TextButton")
    loadButton.Name = "LoadButton"
    loadButton.Parent = mainFrame
    loadButton.Size = UDim2.new(0, 130, 0, 40)
    loadButton.Position = UDim2.new(0, 35, 0, 180)
    loadButton.BackgroundColor3 = Color3.fromRGB(0, 150, 0)
    loadButton.BorderSizePixel = 0
    loadButton.Text = "Load Script"
    loadButton.TextColor3 = Color3.fromRGB(255, 255, 255)
    loadButton.TextSize = 16
    loadButton.Font = Enum.Font.SourceSansBold
    
    local loadButtonCorner = Instance.new("UICorner")
    loadButtonCorner.CornerRadius = UDim.new(0, 5)
    loadButtonCorner.Parent = loadButton
    
    local discordButton = Instance.new("TextButton")
    discordButton.Name = "DiscordButton"
    discordButton.Parent = mainFrame
    discordButton.Size = UDim2.new(0, 130, 0, 40)
    discordButton.Position = UDim2.new(0, 235, 0, 180)
    discordButton.BackgroundColor3 = Color3.fromRGB(88, 101, 242)
    discordButton.BorderSizePixel = 0
    discordButton.Text = "Join Discord"
    discordButton.TextColor3 = Color3.fromRGB(255, 255, 255)
    discordButton.TextSize = 16
    discordButton.Font = Enum.Font.SourceSansBold
    
    local discordButtonCorner = Instance.new("UICorner")
    discordButtonCorner.CornerRadius = UDim.new(0, 5)
    discordButtonCorner.Parent = discordButton
    
    local function createNotification(text, duration)
        local notification = Instance.new("TextLabel")
        notification.Name = "Notification"
        notification.Parent = keyScreenGui
        notification.Size = UDim2.new(0, 300, 0, 50)
        notification.Position = UDim2.new(0.5, -150, 0, 50)
        notification.BackgroundColor3 = Color3.fromRGB(40, 40, 40)
        notification.BorderSizePixel = 0
        notification.Text = text
        notification.TextColor3 = Color3.fromRGB(255, 255, 255)
        notification.TextSize = 16
        notification.Font = Enum.Font.SourceSans
        notification.TextWrapped = true
        
        local notificationCorner = Instance.new("UICorner")
        notificationCorner.CornerRadius = UDim.new(0, 5)
        notificationCorner.Parent = notification
        
        spawn(function()
            wait(duration)
            if notification then
                notification:Destroy()
            end
        end)
    end
    
    loadButton.MouseButton1Click:Connect(function()
        local enteredKey = keyTextBox.Text
        if enteredKey:lower() == correctKey:lower() then
            keyVerified = true
            createNotification("Key verified! Loading script...", 3)
            wait(1)
            keyScreenGui:Destroy()
            createMainUI()
        else
            createNotification("Invalid key! Please try again.", 3)
        end
    end)
    
    discordButton.MouseButton1Click:Connect(function()
        local discordLink = "discord.gg/swebware"
        if setclipboard then
            setclipboard(discordLink)
            createNotification("Discord invite link copied to clipboard!", 3)
        else
            createNotification("Could not copy link. Manual copy: " .. discordLink, 5)
        end
    end)
    
    loadButton.MouseEnter:Connect(function()
        loadButton.BackgroundColor3 = Color3.fromRGB(0, 200, 0)
    end)
    
    loadButton.MouseLeave:Connect(function()
        loadButton.BackgroundColor3 = Color3.fromRGB(0, 150, 0)
    end)
    
    discordButton.MouseEnter:Connect(function()
        discordButton.BackgroundColor3 = Color3.fromRGB(108, 121, 255)
    end)
    
    discordButton.MouseLeave:Connect(function()
        discordButton.BackgroundColor3 = Color3.fromRGB(88, 101, 242)
    end)
end

createKeyUI()
