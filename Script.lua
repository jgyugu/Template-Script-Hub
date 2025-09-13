local scripts = {
    {
        name = "飞行脚本",
        url = "你的飞行脚本链接",
        desc = "经典飞行脚本（部分服务器拉回）",
        author = "未知",
        game = "通用"
    }
}

local introText = [[
欢迎来到 Delta Script Hub！
这里收集了你常用的 Roblox 脚本，点击左侧按钮即可查看详情并运行。
第一个按钮是本介绍，方便随时查看。
]]

local parentGui = game:GetService("CoreGui")
pcall(function()
    if typeof(gethui) == "function" then
        parentGui = gethui()
    end
end)

local ScreenGui = Instance.new("ScreenGui")
ScreenGui.Name = "DeltaScriptHub"
ScreenGui.Parent = parentGui
ScreenGui.ResetOnSpawn = false

local Frame = Instance.new("Frame", ScreenGui)
Frame.Size = UDim2.new(0, 500, 0, 350)
Frame.Position = UDim2.new(0.1, 0, 0.2, 0)
Frame.BackgroundColor3 = Color3.fromRGB(30, 30, 30)
Frame.BorderSizePixel = 0
Instance.new("UICorner", Frame).CornerRadius = UDim.new(0, 8)

local TitleBar = Instance.new("Frame", Frame)
TitleBar.Size = UDim2.new(1, 0, 0, 36)
TitleBar.BackgroundColor3 = Color3.fromRGB(40, 40, 40)
TitleBar.BorderSizePixel = 0

local Title = Instance.new("TextLabel", TitleBar)
Title.BackgroundTransparency = 1
Title.Position = UDim2.new(0, 12, 0, 0)
Title.Size = UDim2.new(1, -60, 1, 0)
Title.Text = "Delta Script Hub"
Title.TextColor3 = Color3.fromRGB(255, 255, 255)
Title.Font = Enum.Font.GothamSemibold
Title.TextSize = 16
Title.TextXAlignment = Enum.TextXAlignment.Left
local CloseBtn = Instance.new("TextButton", TitleBar)
CloseBtn.Size = UDim2.new(0, 28, 0, 28)
CloseBtn.Position = UDim2.new(1, -34, 0.5, -14)
CloseBtn.Text = "×"
CloseBtn.BackgroundColor3 = Color3.fromRGB(60, 60, 60)
CloseBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
CloseBtn.Font = Enum.Font.GothamBold
CloseBtn.TextSize = 16
Instance.new("UICorner", CloseBtn).CornerRadius = UDim.new(0, 6)
CloseBtn.MouseButton1Click:Connect(function()
    ScreenGui:Destroy()
end)

local MinBtn = Instance.new("TextButton", TitleBar)
MinBtn.Size = UDim2.new(0, 28, 0, 28)
MinBtn.Position = UDim2.new(1, -68, 0.5, -14)
MinBtn.Text = "-"
MinBtn.BackgroundColor3 = Color3.fromRGB(60, 60, 60)
MinBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
MinBtn.Font = Enum.Font.GothamBold
MinBtn.TextSize = 16
Instance.new("UICorner", MinBtn).CornerRadius = UDim.new(0, 6)

local Content = Instance.new("Frame", Frame)
Content.Size = UDim2.new(1, -10, 1, -46)
Content.Position = UDim2.new(0, 5, 0, 40)
Content.BackgroundTransparency = 1

local LeftPanel = Instance.new("ScrollingFrame", Content)
LeftPanel.Size = UDim2.new(0.4, -5, 1, 0)
LeftPanel.Position = UDim2.new(0, 0, 0, 0)
LeftPanel.BackgroundColor3 = Color3.fromRGB(35, 35, 35)
LeftPanel.BorderSizePixel = 0
LeftPanel.CanvasSize = UDim2.new(0, 0, 0, 0)
LeftPanel.ScrollBarThickness = 6
LeftPanel.VerticalScrollBarInset = Enum.ScrollBarInset.Always
Instance.new("UIListLayout", LeftPanel).Padding = UDim.new(0, 5)

local RightPanel = Instance.new("Frame", Content)
RightPanel.Size = UDim2.new(0.6, 0, 1, 0)
RightPanel.Position = UDim2.new(0.4, 5, 0, 0)
RightPanel.BackgroundColor3 = Color3.fromRGB(40, 40, 40)
RightPanel.BorderSizePixel = 0

local InfoLabel = Instance.new("TextLabel", RightPanel)
InfoLabel.Size = UDim2.new(1, -10, 0.7, -10)
InfoLabel.Position = UDim2.new(0, 5, 0, 5)
InfoLabel.BackgroundTransparency = 1
InfoLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
InfoLabel.Font = Enum.Font.Gotham
InfoLabel.TextSize = 14
InfoLabel.TextWrapped = true
InfoLabel.TextXAlignment = Enum.TextXAlignment.Left
InfoLabel.TextYAlignment = Enum.TextYAlignment.Top
InfoLabel.Text = introText

local RunBtn = Instance.new("TextButton", RightPanel)
RunBtn.Size = UDim2.new(1, -10, 0, 35)
RunBtn.Position = UDim2.new(0, 5, 1, -40)
RunBtn.Text = "运行脚本"
RunBtn.BackgroundColor3 = Color3.fromRGB(60, 60, 60)
RunBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
RunBtn.Font = Enum.Font.GothamBold
RunBtn.TextSize = 16
Instance.new("UICorner", RunBtn).CornerRadius = UDim.new(0, 6)
RunBtn.Visible = false
-- 提示消息函数
local function showNotification(msg)
    local note = Instance.new("TextLabel", ScreenGui)
    note.AnchorPoint = Vector2.new(0, 1)
    note.Position = UDim2.new(0, 10, 1, -10)
    note.Size = UDim2.new(0, 300, 0, 30)
    note.BackgroundColor3 = Color3.fromRGB(0, 0, 0)
    note.BackgroundTransparency = 0.3
    note.TextColor3 = Color3.fromRGB(255, 255, 255)
    note.Font = Enum.Font.GothamBold
    note.TextSize = 14
    note.TextXAlignment = Enum.TextXAlignment.Left
    note.Text = "  " .. msg
    Instance.new("UICorner", note).CornerRadius = UDim.new(0, 6)
    game:GetService("TweenService"):Create(note, TweenInfo.new(0.5), {BackgroundTransparency = 0.3, TextTransparency = 0}):Play()
    task.delay(2, function()
        game:GetService("TweenService"):Create(note, TweenInfo.new(0.5), {BackgroundTransparency = 1, TextTransparency = 1}):Play()
        task.delay(0.5, function()
            note:Destroy()
        end)
    end)
end

-- 左侧第一个按钮：介绍
local introBtn = Instance.new("TextButton", LeftPanel)
introBtn.Size = UDim2.new(1, -5, 0, 30)
introBtn.BackgroundColor3 = Color3.fromRGB(70, 70, 70)
introBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
introBtn.Text = "脚本中心介绍"
introBtn.MouseButton1Click:Connect(function()
    InfoLabel.Text = introText
    RunBtn.Visible = false
end)

-- 生成功能按钮
for _, s in ipairs(scripts) do
    local btn = Instance.new("TextButton", LeftPanel)
    btn.Size = UDim2.new(1, -5, 0, 30)
    btn.BackgroundColor3 = Color3.fromRGB(70, 70, 70)
    btn.TextColor3 = Color3.fromRGB(255, 255, 255)
    btn.Text = s.name
    btn.MouseButton1Click:Connect(function()
        InfoLabel.Text = string.format(
            "名称：%s\n作者：%s\n适用游戏：%s\n\n简介：%s",
            s.name, s.author, s.game, s.desc
        )
        RunBtn.Visible = true
        RunBtn.MouseButton1Click:Connect(function()
            showNotification("正在运行脚本：" .. s.name)
            loadstring(game:HttpGet(s.url))()
        end)
    end)
end
LeftPanel.CanvasSize = UDim2.new(0, 0, 0, (#scripts + 1) * 35)
local UIS = game:GetService("UserInputService")
local dragging, dragStart, startPos

local function updateDrag(input)
    local delta = input.Position - dragStart
    Frame.Position = UDim2.new(
        startPos.X.Scale,
        startPos.X.Offset + delta.X,
        startPos.Y.Scale,
        startPos.Y.Offset + delta.Y
    )
end

TitleBar.InputBegan:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.MouseButton1
    or input.UserInputType == Enum.UserInputType.Touch then
        dragging = true
        dragStart = input.Position
        startPos = Frame.Position
    end
end)

TitleBar.InputEnded:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.MouseButton1
    or input.UserInputType == Enum.UserInputType.Touch then
        dragging = false
    end
end)

UIS.InputChanged:Connect(function(input)
    if dragging and (input.UserInputType == Enum.UserInputType.MouseMovement
    or input.UserInputType == Enum.UserInputType.Touch) then
        updateDrag(input)
    end
end)

local minimized = false
MinBtn.MouseButton1Click:Connect(function()
    minimized = not minimized
    Content.Visible = not minimized
    if minimized then
        Frame.Size = UDim2.new(0, 500, 0, 36)
        MinBtn.Text = "+"
    else
        Frame.Size = UDim2.new(0, 500, 0, 350)
        MinBtn.Text = "-"
    end
end)
