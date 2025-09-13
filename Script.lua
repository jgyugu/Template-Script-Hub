-- Roblox Delta Script Hub 左右分栏版
-- 作者：Copilot
-- 功能：左右分栏（左功能按钮 / 右信息区）+ 标题栏拖动（鼠标 & 触屏）+ 最小化 + 关闭
-- ⚠ 请确保脚本来源安全

-- ====== 配置区 ======
local scripts = {
    {name = "脚本", url = "你的脚本链接"},
    {name = "脚本", url = "你的脚本链接"},
    {name = "脚本", url = "你的脚本链接"},
    {name = "脚本", url = "你的脚本链接"},
    {name = "脚本", url = "你的脚本链接"},
    {name = "脚本", url = "你的脚本链接"},
    {name = "脚本", url = "你的脚本链接"},
}
-- ====================

-- 安全挂载到 UI 容器
local parentGui = game:GetService("CoreGui")
pcall(function()
    if typeof(gethui) == "function" then
        parentGui = gethui()
    end
end)

-- 创建 ScreenGui
local ScreenGui = Instance.new("ScreenGui")
ScreenGui.Name = "DeltaScriptHub"
ScreenGui.Parent = parentGui
ScreenGui.ResetOnSpawn = false

-- 主窗口
local Frame = Instance.new("Frame")
Frame.Name = "MainWindow"
Frame.Parent = ScreenGui
Frame.Size = UDim2.new(0, 500, 0, 350)
Frame.Position = UDim2.new(0.1, 0, 0.2, 0)
Frame.BackgroundColor3 = Color3.fromRGB(30, 30, 30)
Frame.BorderSizePixel = 0
Instance.new("UICorner", Frame).CornerRadius = UDim.new(0, 8)

-- 标题栏
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

-- 关闭按钮
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

-- 最小化按钮
local MinBtn = Instance.new("TextButton", TitleBar)
MinBtn.Size = UDim2.new(0, 28, 0, 28)
MinBtn.Position = UDim2.new(1, -68, 0.5, -14)
MinBtn.Text = "-"
MinBtn.BackgroundColor3 = Color3.fromRGB(60, 60, 60)
MinBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
MinBtn.Font = Enum.Font.GothamBold
MinBtn.TextSize = 16
Instance.new("UICorner", MinBtn).CornerRadius = UDim.new(0, 6)

-- 内容区（左右分栏）
local Content = Instance.new("Frame", Frame)
Content.Size = UDim2.new(1, -10, 1, -46)
Content.Position = UDim2.new(0, 5, 0, 40)
Content.BackgroundTransparency = 1

-- 左边功能栏
local LeftPanel = Instance.new("ScrollingFrame", Content)
LeftPanel.Size = UDim2.new(0.4, -5, 1, 0)
LeftPanel.Position = UDim2.new(0, 0, 0, 0)
LeftPanel.BackgroundColor3 = Color3.fromRGB(35, 35, 35)
LeftPanel.BorderSizePixel = 0
LeftPanel.CanvasSize = UDim2.new(0, 0, 0, 0)
Instance.new("UIListLayout", LeftPanel).Padding = UDim.new(0, 5)

-- 右边信息栏
local RightPanel = Instance.new("Frame", Content)
RightPanel.Size = UDim2.new(0.6, 0, 1, 0)
RightPanel.Position = UDim2.new(0.4, 5, 0, 0)
RightPanel.BackgroundColor3 = Color3.fromRGB(40, 40, 40)
RightPanel.BorderSizePixel = 0

local InfoLabel = Instance.new("TextLabel", RightPanel)
InfoLabel.Size = UDim2.new(1, -10, 1, -10)
InfoLabel.Position = UDim2.new(0, 5, 0, 5)
InfoLabel.BackgroundTransparency = 1
InfoLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
InfoLabel.Font = Enum.Font.Gotham
InfoLabel.TextSize = 14
InfoLabel.TextWrapped = true
InfoLabel.TextXAlignment = Enum.TextXAlignment.Left
InfoLabel.TextYAlignment = Enum.TextYAlignment.Top
InfoLabel.Text = [[
欢迎来到 Delta Script Hub！
左边是功能按钮，点击即可执行脚本。
右边显示脚本中心的说明、提示和作者信息。

作者：小唐
版本：分栏布局 v1.0
]]

-- 生成功能按钮
for _, s in ipairs(scripts) do
    local btn = Instance.new("TextButton", LeftPanel)
    btn.Size = UDim2.new(1, -5, 0, 30)
    btn.BackgroundColor3 = Color3.fromRGB(70, 70, 70)
    btn.TextColor3 = Color3.fromRGB(255, 255, 255)
    btn.Text = s.name
    btn.MouseButton1Click:Connect(function()
        loadstring(game:HttpGet(s.url))()
    end)
end
LeftPanel.CanvasSize = UDim2.new(0, 0, 0, #scripts * 35)

-- 拖动逻辑（鼠标 + 触屏）
local UIS = game:GetService("UserInputService")
local dragging, dragStart, startPos
local function updateDrag(input)
    local delta = input.Position - dragStart
    Frame.Position = UDim2.new(startPos.X.Scale, startPos.X.Offset + delta.X, startPos.Y.Scale, startPos.Y.Offset + delta.Y)
end
TitleBar.InputBegan:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
        dragging = true
        dragStart = input.Position
        startPos = Frame.Position
    end
end)
TitleBar.InputEnded:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
        dragging = false
    end
end)
UIS.InputChanged:Connect(function(input)
    if dragging and (input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch) then
        updateDrag(input)
    end
end)

-- 最小化功能
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
