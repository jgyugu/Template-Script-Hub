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

-- ===== 配置区 =====
local scripts = {
    {
        name = "飞行脚本",
        url = "https://raw.githubusercontent.com/jgyugu/Template-Script-Hub/refs/heads/main/fly_Script",
        author = "未知",
        game = "通用"
    }
}
-- =================

-- 加载改版 ChinaQY UI
local OrionLib = loadstring(game:HttpGet("https://raw.githubusercontent.com/ChinaQY/-/Main/UI"))()

-- 创建窗口
local Window = OrionLib:MakeWindow({
    Name = "ethan脚本中心v1.1",
    HidePremium = false,
    SaveConfig = true,
    ConfigFolder = "DeltaScriptHub",
    IntroEnabled = true,
    IntroText = "欢迎使用ethan脚本中心",
    Icon = "rbxassetid://4483345998"
})

-- 第 1 个标签页：关于此脚本
local AboutTab = Window:MakeTab({
    Name = "关于此脚本",
    Icon = "rbxassetid://4483345998",
    PremiumOnly = false
})
AboutTab:AddSection({ Name = "脚本中心" })
AboutTab:AddParagraph("欢迎", "欢迎来到 ethan脚本中心！\n这是一个收集可用 Roblox 脚本的中心，方便快速运行。\n此脚本完全免费，请勿倒卖！")

-- 第 2 个标签页：通用功能
local CommonTab = Window:MakeTab({
    Name = "通用",
    Icon = "rbxassetid://4483345998",
    PremiumOnly = false
})
CommonTab:AddSection({ Name = "通用功能" })

-- 第 3 个标签页：玩家
local PlayerTab = Window:MakeTab({
    Name = "玩家",
    Icon = "rbxassetid://14250466898",
    PremiumOnly = false
})
PlayerTab:AddSection({ Name = "玩家属性设置" })

-- 玩家状态 Paragraph（实时刷新）
local playerStatusParagraph = PlayerTab:AddParagraph("玩家状态", "加载中...")

-- 每 0.5 秒刷新一次信息
task.spawn(function()
    while task.wait(0.5) do
        if lp.Character and lp.Character:FindFirstChildOfClass("Humanoid") and lp.Character:FindFirstChild("HumanoidRootPart") then
            local hum = lp.Character:FindFirstChildOfClass("Humanoid")
            local pos = lp.Character.HumanoidRootPart.Position

            -- 获取 FPS
            local fps = math.floor(1 / game:GetService("RunService").RenderStepped:Wait())

            -- 获取 Ping（毫秒）
            local ping = math.floor(game:GetService("Stats")
                .Network.ServerStatsItem["Data Ping"]:GetValue())

            playerStatusParagraph:Set(string.format(
                "速度: %s\n跳跃力: %s\n重力: %s\n血量: %s / %s\n位置: X=%.1f, Y=%.1f, Z=%.1f\nFPS: %d\nPing: %d ms",
                hum.WalkSpeed,
                hum.JumpPower,
                workspace.Gravity,
                math.floor(hum.Health),
                math.floor(hum.MaxHealth),
                pos.X, pos.Y, pos.Z,
                fps,
                ping
            ))
        else
            playerStatusParagraph:Set("未检测到玩家角色")
        end
    end
end)

-- 输入框：设置跳跃力
PlayerTab:AddTextbox({
    Name = "设置跳跃力",
    Default = "",
    TextDisappear = true,
    Callback = function(Value)
        local num = tonumber(Value)
        if num then
            if lp.Character and lp.Character:FindFirstChildOfClass("Humanoid") then
                lp.Character:FindFirstChildOfClass("Humanoid").UseJumpPower = true
                lp.Character:FindFirstChildOfClass("Humanoid").JumpPower = num
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
            if lp.Character and lp.Character:FindFirstChildOfClass("Humanoid") then
                lp.Character:FindFirstChildOfClass("Humanoid").WalkSpeed = num
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
        if lp.Character and lp.Character:FindFirstChildOfClass("Humanoid") then
            local hum = lp.Character:FindFirstChildOfClass("Humanoid")
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

-- 生成功能按钮（无简介）
for _, s in ipairs(scripts) do
    CommonTab:AddButton({
        Name = s.name,
        Callback = function()
            OrionLib:MakeNotification({
                Name = "运行脚本",
                Content = s.name,
                Image = "rbxassetid://4483345998",
                Time = 3
            })
            loadstring(game:HttpGet(s.url))()
        end
    })
end

-- 开关：无限跳
local infiniteJumpConnection
CommonTab:AddToggle({
    Name = "开启无限跳",
    Default = false,
    Callback = function(state)
        if state then
            infiniteJumpConnection = game:GetService("UserInputService").JumpRequest:Connect(function()
                if lp.Character and lp.Character:FindFirstChildOfClass("Humanoid") then
                    lp.Character:FindFirstChildOfClass("Humanoid"):ChangeState(Enum.HumanoidStateType.Jumping)
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
            -- 创建方块
            airwalkPart = Instance.new("Part")
            airwalkPart.Size = Vector3.new(6, 1, 6)
            airwalkPart.Anchored = true
            airwalkPart.Transparency = 0.5
            airwalkPart.Color = Color3.fromRGB(0, 255, 0)
            airwalkPart.Name = "AirWalkPart"
            airwalkPart.Parent = workspace

            -- 持续跟随玩家脚下（位置调低）
            airwalkConnection = game:GetService("RunService").RenderStepped:Connect(function()
                if lp.Character and lp.Character:FindFirstChild("HumanoidRootPart") then
                    local pos = lp.Character.HumanoidRootPart.Position
                    -- 调低到脚底下，避免顶起玩家
                    airwalkPart.Position = Vector3.new(pos.X, pos.Y - 3.5, pos.Z)
                end
            end)
        else
            -- 关闭时销毁方块
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

-- 开关：夜视功能
local lighting = game:GetService("Lighting")
local oldBrightness = lighting.Brightness
local oldAmbient = lighting.Ambient
local oldOutdoorAmbient = lighting.OutdoorAmbient

CommonTab:AddToggle({
    Name = "开启夜视",
    Default = false,
    Callback = function(state)
        if state then
            -- 开启夜视
            lighting.Brightness = 5
            lighting.Ambient = Color3.new(1, 1, 1)
            lighting.OutdoorAmbient = Color3.new(1, 1, 1)
        else
            -- 恢复原设置
            lighting.Brightness = oldBrightness
            lighting.Ambient = oldAmbient
            lighting.OutdoorAmbient = oldOutdoorAmbient
        end
    end
})

-- 开关：去雾功能
local oldFogEnd = lighting.FogEnd
local oldFogStart = lighting.FogStart
local oldFogColor = lighting.FogColor

CommonTab:AddToggle({
    Name = "去雾",
    Default = false,
    Callback = function(state)
        if state then
            -- 移除雾
            lighting.FogEnd = 1e6
            lighting.FogStart = 0
            lighting.FogColor = Color3.fromRGB(255, 255, 255)
        else
            -- 恢复原雾效果
            lighting.FogEnd = oldFogEnd
            lighting.FogStart = oldFogStart
            lighting.FogColor = oldFogColor
        end
    end
})

-- 初始化 UI
OrionLib:Init()
