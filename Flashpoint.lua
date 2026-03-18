local Players = game:GetService("Players")
local LocalPlayer = Players.LocalPlayer
local PlayerGui = LocalPlayer:WaitForChild("PlayerGui")

local textToDisplay = "Sweb a bitch ass nigga."

local screenGui = Instance.new("ScreenGui")
screenGui.Name = "ClownTextDisplay"
screenGui.Parent = PlayerGui
screenGui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
screenGui.ResetOnSpawn = false

local mainFrame = Instance.new("Frame")
mainFrame.Name = "MainFrame"
mainFrame.Parent = screenGui
mainFrame.Size = UDim2.new(0, 800, 0, 400)
mainFrame.Position = UDim2.new(0.5, -400, 0.5, -200)
mainFrame.BackgroundColor3 = Color3.fromRGB(255, 100, 50)
mainFrame.BorderSizePixel = 0

local frameCorner = Instance.new("UICorner")
frameCorner.CornerRadius = UDim.new(0, 20)
frameCorner.Parent = mainFrame

local titleLabel = Instance.new("TextLabel")
titleLabel.Name = "TitleLabel"
titleLabel.Parent = mainFrame
titleLabel.Size = UDim2.new(1, 0, 0, 60)
titleLabel.Position = UDim2.new(0, 0, 0, 20)
titleLabel.BackgroundTransparency = 1
titleLabel.Text = "🤡🤡🤡🤡🤡🤡🤡🤡🤡🤡🤡🤡🤡🤡🤡🤡"
titleLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
titleLabel.TextSize = 32
titleLabel.Font = Enum.Font.SourceSansBold
titleLabel.TextScaled = true

local textLabel = Instance.new("TextLabel")
textLabel.Name = "TextLabel"
textLabel.Parent = mainFrame
textLabel.Size = UDim2.new(0, 700, 0, 200)
textLabel.Position = UDim2.new(0.5, -350, 0, 100)
textLabel.BackgroundColor3 = Color3.fromRGB(255, 200, 100)
textLabel.BorderSizePixel = 0
textLabel.Text = "🤡 " .. textToDisplay .. " 🤡"
textLabel.TextColor3 = Color3.fromRGB(0, 0, 0)
textLabel.TextSize = 24
textLabel.Font = Enum.Font.SourceSansBold
textLabel.TextScaled = true
textLabel.TextWrapped = true

local textCorner = Instance.new("UICorner")
textCorner.CornerRadius = UDim.new(0, 15)
textCorner.Parent = textLabel

local bottomLabel = Instance.new("TextLabel")
bottomLabel.Name = "BottomLabel"
bottomLabel.Parent = mainFrame
bottomLabel.Size = UDim2.new(1, 0, 0, 40)
bottomLabel.Position = UDim2.new(0, 0, 0, 320)
bottomLabel.BackgroundTransparency = 1
bottomLabel.Text = "🤡🤡🤡🤡🤡🤡🤡🤡🤡🤡🤡🤡🤡🤡🤡🤡"
bottomLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
bottomLabel.TextSize = 24
bottomLabel.Font = Enum.Font.SourceSansBold
bottomLabel.TextScaled = true

for i = 1, 20 do
    local clown = Instance.new("TextLabel")
    clown.Name = "FloatingClown"
    clown.Parent = mainFrame
    clown.Size = UDim2.new(0, 30, 0, 30)
    clown.Position = UDim2.new(0, math.random(0, 770), 0, math.random(0, 370))
    clown.BackgroundTransparency = 1
    clown.Text = "🤡"
    clown.TextColor3 = Color3.fromRGB(255, 255, 255)
    clown.TextSize = 20
    clown.Font = Enum.Font.SourceSansBold
    clown.TextScaled = true
end

print("Sweb is my bitch nigga.")
