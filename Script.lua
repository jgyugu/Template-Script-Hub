-- ===== 黑名单（UID） =====
local uidBlacklist = {}
local Players = game:GetService("Players")
local lp = Players.LocalPlayer

for _, uid in ipairs(uidBlacklist) do
    if lp.UserId == uid then
        lp:Kick("你已被禁止使用此脚本!")
        return
    end
end
-- ========================

-- ===== 云端获取 config.lua（版本号 + 公告） =====
local config = loadstring(game:HttpGet("https://raw.githubusercontent.com/jgyugu/Template-Script-Hub/refs/heads/main/config.lua"))()
local version = config.version or "v1.0"
local announcement = config.announcement or "公告获取失败"

-- ===== 加载 UI 库 =====
local OrionLib = loadstring(game:HttpGet("https://raw.githubusercontent.com/ChinaQY/-/Main/UI"))()

-- ===== 创建窗口（动态版本号） =====
local Window = OrionLib:MakeWindow({
    Name = "ethan脚本中心[" .. version .. "]",
    HidePremium = false,
    SaveConfig = true,
    ConfigFolder = "DeltaScriptHub",
    IntroEnabled = true,
    IntroText = "欢迎使用ethan脚本中心",
    Icon = "rbxassetid://4483345998"
})

-- ===== 公告标签页 =====
local NoticeTab = Window:MakeTab({
    Name = "公告",
    Icon = "rbxassetid://4483345998",
    PremiumOnly = false
})
NoticeTab:AddSection({ Name = "最新公告" })
NoticeTab:AddParagraph("公告内容", announcement)

-- 在公告页添加 时间 / FPS / Ping 段落
local timeParagraph = NoticeTab:AddParagraph("当前时间 / 性能信息", "加载中...")

task.spawn(function()
    local RunService = game:GetService("RunService")
    local Stats = game:GetService("Stats")
    while task.wait(1) do
        local now = os.date("*t")
        local timeStr = string.format("%04d-%02d-%02d %02d:%02d:%02d",
            now.year, now.month, now.day, now.hour, now.min, now.sec)
        local fps = math.floor(1 / RunService.RenderStepped:Wait())
        local ping = math.floor(Stats.Network.ServerStatsItem["Data Ping"]:GetValue())
        timeParagraph:Set(string.format(
            "时间: %s\nFPS: %d\nPing: %d ms",
            timeStr, fps, ping
        ))
    end
end)

-- ===== 通用功能标签页 =====
local CommonTab = Window:MakeTab({
    Name = "通用功能",
    Icon = "rbxassetid://4483345998",
    PremiumOnly = false
})
CommonTab:AddSection({ Name = "脚本列表" })

-- ===== 云端获取 scripts.lua（脚本列表） =====
local scripts = loadstring(game:HttpGet("https://raw.githubusercontent.com/jgyugu/Template-Script-Hub/refs/heads/main/scripts.lua"))()

if type(scripts) == "table" then
    for _, s in ipairs(scripts) do
        CommonTab:AddButton({
            Name = tostring(s.name or "未命名"),
            Callback = function()
                OrionLib:MakeNotification({
                    Name = "运行脚本",
                    Content = tostring(s.name or "未命名"),
                    Image = "rbxassetid://4483345998",
                    Time = 3
                })
                loadstring(game:HttpGet(s.url))()
            end
        })
    end
else
    CommonTab:AddParagraph("警告", "云端获取脚本失败")
end

-- ===== 玩家标签页 =====
local PlayerTab = Window:MakeTab({
    Name = "玩家",
    Icon = "rbxassetid://14250466898",
    PremiumOnly = false
})
PlayerTab:AddSection({ Name = "玩家属性设置" })

-- 玩家状态 Paragraph（实时刷新）
local playerStatusParagraph = PlayerTab:AddParagraph("玩家状态", "加载中...")

-- 辅助：获取玩家核心对象
local function getHumanoid()
    local char = lp.Character
    if not char then return nil end
    return char:FindFirstChildOfClass("Humanoid")
end
local function getHRP()
    local char = lp.Character
    if not char then return nil end
    return char:FindFirstChild("HumanoidRootPart")
end

-- 实时刷新玩家状态
task.spawn(function()
    while task.wait(0.5) do
        local hum = getHumanoid()
        local hrp = getHRP()

        if hum and hrp then
            local pos = hrp.Position
            local hp = math.floor(hum.Health)
            local maxhp = math.floor(hum.MaxHealth)
            local walkspeed = tonumber(hum.WalkSpeed) or 0
            local jumppower = tonumber(hum.JumpPower) or 0
            local gravity = tonumber(workspace.Gravity) or 196.2
            local state = hum:GetState()

            playerStatusParagraph:Set(string.format(
                "速度: %d\n跳跃力: %d\n重力: %g\n血量: %d / %d\n状态: %s\n位置: X=%.1f, Y=%.1f, Z=%.1f",
                walkspeed,
                jumppower,
                gravity,
                hp, maxhp,
                tostring(state),
                pos.X, pos.Y, pos.Z
            ))
        else
            playerStatusParagraph:Set("未检测到玩家角色（等待角色加载或重生）")
        end
    end
end)

-- 角色重生时提示并快速刷新一次
lp.CharacterAdded:Connect(function()
    playerStatusParagraph:Set("检测到角色重生，加载中...")
    task.delay(1, function()
        local hum = getHumanoid()
        local hrp = getHRP()
        if hum and hrp then
            local pos = hrp.Position
            playerStatusParagraph:Set(string.format(
                "速度: %d\n跳跃力: %d\n重力: %g\n血量: %d / %d\n位置: X=%.1f, Y=%.1f, Z=%.1f",
                hum.WalkSpeed, hum.JumpPower, workspace.Gravity,
                math.floor(hum.Health), math.floor(hum.MaxHealth),
                pos.X, pos.Y, pos.Z
            ))
        end
    end)
end)
-- 输入框：设置跳跃力
PlayerTab:AddTextbox({
    Name = "设置跳跃力",
    Default = "",
    TextDisappear = true,
    Callback = function(Value)
        local num = tonumber(Value)
        if num then
            local hum = lp.Character and lp.Character:FindFirstChildOfClass("Humanoid")
            if hum then
                hum.UseJumpPower = true
                hum.JumpPower = num
            end
        else
            OrionLib:MakeNotification({
                Name = "输入错误",
                Content = "请输入数字！",
                Image = "rbxassetid://4483345998",
                Time = 2
            })
        end
    end
})

-- 输入框：设置移动速度
PlayerTab:AddTextbox({
    Name = "设置移动速度",
    Default = "",
    TextDisappear = true,
    Callback = function(Value)
        local num = tonumber(Value)
        if num then
            local hum = lp.Character and lp.Character:FindFirstChildOfClass("Humanoid")
            if hum then
                hum.WalkSpeed = num
            end
        else
            OrionLib:MakeNotification({
                Name = "输入错误",
                Content = "请输入数字！",
                Image = "rbxassetid://4483345998",
                Time = 2
            })
        end
    end
})

-- 输入框：设置重力
PlayerTab:AddTextbox({
    Name = "设置重力",
    Default = "",
    TextDisappear = true,
    Callback = function(Value)
        local num = tonumber(Value)
        if num then
            workspace.Gravity = num
        else
            OrionLib:MakeNotification({
                Name = "输入错误",
                Content = "请输入数字！",
                Image = "rbxassetid://4483345998",
                Time = 2
            })
        end
    end
})

-- 按钮：恢复默认值
PlayerTab:AddButton({
    Name = "恢复默认 重力/速度/跳跃力",
    Callback = function()
        workspace.Gravity = 196.2
        local hum = lp.Character and lp.Character:FindFirstChildOfClass("Humanoid")
        if hum then
            hum.WalkSpeed = 16
            hum.UseJumpPower = true
            hum.JumpPower = 50
        end
        OrionLib:MakeNotification({
            Name = "已恢复默认值",
            Content = "重力、速度、跳跃力已恢复默认",
            Image = "rbxassetid://4483345998",
            Time = 3
        })
    end
})

-- 开关：无限跳
local infiniteJumpConnection
CommonTab:AddToggle({
    Name = "开启无限跳",
    Default = false,
    Callback = function(state)
        if state then
            infiniteJumpConnection = game:GetService("UserInputService").JumpRequest:Connect(function()
                local hum = lp.Character and lp.Character:FindFirstChildOfClass("Humanoid")
                if hum then
                    hum:ChangeState(Enum.HumanoidStateType.Jumping)
                end
            end)
        else
            if infiniteJumpConnection then
                infiniteJumpConnection:Disconnect()
                infiniteJumpConnection = nil
            end
        end
    end
})

-- 开关：穿墙功能
local noclipConnection
CommonTab:AddToggle({
    Name = "开启穿墙",
    Default = false,
    Callback = function(state)
        if state then
            noclipConnection = game:GetService("RunService").Stepped:Connect(function()
                if lp.Character then
                    for _, part in pairs(lp.Character:GetDescendants()) do
                        if part:IsA("BasePart") then
                            part.CanCollide = false
                        end
                    end
                end
            end)
        else
            if noclipConnection then
                noclipConnection:Disconnect()
                noclipConnection = nil
            end
            if lp.Character then
                for _, part in pairs(lp.Character:GetDescendants()) do
                    if part:IsA("BasePart") then
                        part.CanCollide = true
                    end
                end
            end
        end
    end
})

-- 开关：踏空而行
local airwalkPart
local airwalkConnection
CommonTab:AddToggle({
    Name = "踏空而行",
    Default = false,
    Callback = function(state)
        if state then
            airwalkPart = Instance.new("Part")
            airwalkPart.Size = Vector3.new(6, 1, 6)
            airwalkPart.Anchored = true
            airwalkPart.Transparency = 0.5
            airwalkPart.Color = Color3.fromRGB(0, 255, 0)
            airwalkPart.Name = "AirWalkPart"
            airwalkPart.Parent = workspace

            airwalkConnection = game:GetService("RunService").RenderStepped:Connect(function()
                if lp.Character and lp.Character:FindFirstChild("HumanoidRootPart") then
                    local pos = lp.Character.HumanoidRootPart.Position
                    airwalkPart.Position = Vector3.new(pos.X, pos.Y - 3.5, pos.Z)
                end
            end)
        else
            if airwalkConnection then
                airwalkConnection:Disconnect()
                airwalkConnection = nil
            end
            if airwalkPart then
                airwalkPart:Destroy()
                airwalkPart = nil
            end
        end
    end
})

-- ===== 一键视觉增强（夜视 + 去雾） =====
local lighting = game:GetService("Lighting")

-- 保存初始环境参数
local oldBrightness = lighting.Brightness
local oldAmbient = lighting.Ambient
local oldOutdoorAmbient = lighting.OutdoorAmbient
local oldFogEnd = lighting.FogEnd
local oldFogStart = lighting.FogStart
local oldFogColor = lighting.FogColor

CommonTab:AddToggle({
    Name = "一键视觉增强（夜视+去雾）",
    Default = false,
    Callback = function(state)
        if state then
            -- 开启夜视
            lighting.Brightness = 5
            lighting.Ambient = Color3.new(1, 1, 1)
            lighting.OutdoorAmbient = Color3.new(1, 1, 1)
            -- 去雾
            lighting.FogEnd = 1e6
            lighting.FogStart = 0
            lighting.FogColor = Color3.fromRGB(255, 255, 255)
        else
            -- 恢复原设置
            lighting.Brightness = oldBrightness
            lighting.Ambient = oldAmbient
            lighting.OutdoorAmbient = oldOutdoorAmbient
            lighting.FogEnd = oldFogEnd
            lighting.FogStart = oldFogStart
            lighting.FogColor = oldFogColor
        end
    end
})

-- 开关：透视玩家
local highlightFolder = Instance.new("Folder")
highlightFolder.Name = "ESP_Highlights"
highlightFolder.Parent = game:GetService("CoreGui")

local function addHighlightToPlayer(player)
    if player ~= lp and player.Character and not highlightFolder:FindFirstChild(player.Name) then
        local highlight = Instance.new("Highlight")
        highlight.Name = player.Name
        highlight.Adornee = player.Character
        highlight.FillColor = Color3.fromRGB(255, 0, 0) -- 红色高亮
        highlight.OutlineColor = Color3.fromRGB(255, 255, 255)
        highlight.FillTransparency = 0.5
        highlight.OutlineTransparency = 0
        highlight.Parent = highlightFolder
    end
end

local function removeHighlightFromPlayer(player)
    local h = highlightFolder:FindFirstChild(player.Name)
    if h then
        h:Destroy()
    end
end

local espConnections = {}

PlayerTab:AddToggle({
    Name = "透视玩家",
    Default = false,
    Callback = function(state)
        if state then
            -- 给当前所有其他玩家加高亮
            for _, plr in ipairs(Players:GetPlayers()) do
                addHighlightToPlayer(plr)
            end
            -- 监听新玩家加入
            espConnections.PlayerAdded = Players.PlayerAdded:Connect(function(plr)
                if plr ~= lp then
                    plr.CharacterAdded:Connect(function()
                        addHighlightToPlayer(plr)
                    end)
                end
            end)
            -- 监听玩家角色刷新
            espConnections.CharacterAdded = {}
            for _, plr in ipairs(Players:GetPlayers()) do
                if plr ~= lp then
                    espConnections.CharacterAdded[plr.Name] = plr.CharacterAdded:Connect(function()
                        addHighlightToPlayer(plr)
                    end)
                end
            end
        else
            -- 关闭透视，移除所有高亮
            for _, h in ipairs(highlightFolder:GetChildren()) do
                h:Destroy()
            end
            -- 断开所有连接
            if espConnections.PlayerAdded then
                espConnections.PlayerAdded:Disconnect()
                espConnections.PlayerAdded = nil
            end
            if espConnections.CharacterAdded then
                for _, conn in pairs(espConnections.CharacterAdded) do
                    conn:Disconnect()
                end
                espConnections.CharacterAdded = {}
            end
        end
    end
})

-- ===== 初始化 UI =====
OrionLib:Init()
