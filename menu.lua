-- ===== 云端获取 config.lua（带重试机制，失败则销毁 UI） =====
local config
local maxRetries = 3
local success = false

for attempt = 1, maxRetries do
    local ok, result = pcall(function()
        return loadstring(game:HttpGet(
            "https://raw.githubusercontent.com/jgyugu/Template-Script-Hub/refs/heads/main/config.lua"
        ))()
    end)

    if ok and type(result) == "table" then
        config = result
        success = true
        break
    else
        warn(string.format("[EthanHub] 获取配置失败（第 %d 次），正在重试...", attempt))
        task.wait(1) -- 等待 1 秒再重试
    end
end

if not success then
    -- 提示用户
    game.StarterGui:SetCore("SendNotification", {
        Title = "Ethan 脚本中心",
        Text = "无法获取配置，请检查你的网络连接！",
        Duration = 5
    })

    -- 如果 UI 已经存在则销毁
    local coreGui = game:GetService("CoreGui")
    local oldUI = coreGui:FindFirstChild("Orion") -- OrionLib 默认 UI 名
    if oldUI then
        oldUI:Destroy()
    end

    return -- 停止脚本
end

-- ===== 读取配置 =====
local version = config.version or "v1.0"
local announcement = config.announcement or "公告获取失败"
local correctKey = config.key or "default-key"
local uidBlacklist = config.blacklist or {}

-- ===== 黑名单检测 =====
local Players = game:GetService("Players")
local lp = Players.LocalPlayer
for _, uid in ipairs(uidBlacklist) do
    if lp.UserId == uid then
        lp:Kick("你已被禁止使用此脚本!")
        return
    end
end
-- ===== 加载 UI 库 =====
local OrionLib = loadstring(game:HttpGet("https://raw.githubusercontent.com/jgyugu/Template-Script-Hub/refs/heads/main/UI"))()

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

-- ===== 关于公告标签页 =====
local NoticeTab = Window:MakeTab({
    Name = "公告",
    Icon = "rbxassetid://4483345998",
    PremiumOnly = false
})
NoticeTab:AddSection({ Name = "最新公告:" })
NoticeTab:AddParagraph("公告内容:", announcement)



-- ===== 通用功能标签页 =====
local CommonTab = Window:MakeTab({
    Name = "通用功能",
    Icon = "rbxassetid://4483345998",
    PremiumOnly = false
})
CommonTab:AddSection({ Name = "脚本列表:" })

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

CommonTab:AddSection({ Name = "功能:" })

-- ===== 玩家标签页 =====
local PlayerTab = Window:MakeTab({
    Name = "玩家",
    Icon = "rbxassetid://14250466898",
    PremiumOnly = false
})

-- 玩家状态 Paragraph（实时刷新） → 移到关于此脚本标签页
local playerStatusParagraph = PlayerTab:AddParagraph("玩家状态:", "加载中...")

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

PlayerTab:AddSection({ Name = "玩家属性设置(部分服务器没用)" })

-- 输入框：设置跳跃力
PlayerTab:AddTextbox({
    Name = "设置跳跃",
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
    Name = "设置速度",
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
PlayerTab:AddSection({ Name = "玩家功能类:" })
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

-- 开关：踏空而行（隐形无碰撞版）
local airwalkPart
local airwalkConnection

local function createAirwalkPart()
    if not airwalkPart then
        airwalkPart = Instance.new("Part")
        airwalkPart.Size = Vector3.new(6, 1, 6)
        airwalkPart.Anchored = true
        airwalkPart.Transparency = 1 -- 完全透明
        airwalkPart.CanCollide = false -- 不挡住任何人
        airwalkPart.Massless = true
        airwalkPart.Name = "AirWalkPart"
        airwalkPart.Parent = workspace
    end
end

CommonTab:AddToggle({
    Name = "踏空而行",
    Default = false,
    Callback = function(state)
        if state then
            createAirwalkPart()

            airwalkConnection = game:GetService("RunService").RenderStepped:Connect(function()
                if lp.Character and lp.Character:FindFirstChild("HumanoidRootPart") then
                    local pos = lp.Character.HumanoidRootPart.Position
                    airwalkPart.Position = Vector3.new(pos.X, pos.Y - 3.5, pos.Z)
                end
            end)

            -- 角色重生时重新创建方块
            lp.CharacterAdded:Connect(function()
                task.wait(1)
                createAirwalkPart()
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

-- 开关：透视玩家（稳固版）
local highlightFolder = Instance.new("Folder")
highlightFolder.Name = "ESP_Highlights"
highlightFolder.Parent = game:GetService("CoreGui")

local function addHighlightToPlayer(player)
    if player ~= lp then
        local function attachHighlight(char)
            -- 移除旧的
            local old = highlightFolder:FindFirstChild(player.Name)
            if old then old:Destroy() end

            -- 创建新的
            local highlight = Instance.new("Highlight")
            highlight.Name = player.Name
            highlight.Adornee = char
            highlight.FillColor = Color3.fromRGB(255, 0, 0)
            highlight.OutlineColor = Color3.fromRGB(255, 255, 255)
            highlight.FillTransparency = 0.5
            highlight.OutlineTransparency = 0
            highlight.Parent = highlightFolder
        end

        -- 如果角色已存在，立即绑定
        if player.Character then
            attachHighlight(player.Character)
        end

        -- 监听角色刷新
        player.CharacterAdded:Connect(function(char)
            attachHighlight(char)
        end)
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
                addHighlightToPlayer(plr)
            end)
        else
            -- 关闭透视，移除所有高亮
            for _, h in ipairs(highlightFolder:GetChildren()) do
                h:Destroy()
            end
            -- 断开监听
            if espConnections.PlayerAdded then
                espConnections.PlayerAdded:Disconnect()
                espConnections.PlayerAdded = nil
            end
        end
    end
})

-- ===== 传送到玩家背后功能（带碰撞关闭） =====
local selectedTarget = nil

-- 获取玩家列表（排除自己）
local function getPlayerList()
    local names = {}
    for _, plr in ipairs(Players:GetPlayers()) do
        if plr ~= lp then
            table.insert(names, plr.Name)
        end
    end
    return names
end

-- 下拉列表：选择传送目标玩家
local tpDropdown = PlayerTab:AddDropdown({
    Name = "选择传送目标玩家",
    Default = "未选择",
    Options = getPlayerList(),
    Callback = function(value)
        selectedTarget = value
        OrionLib:MakeNotification({
            Name = "目标已选择",
            Content = "已选择传送目标：" .. value,
            Image = "rbxassetid://4483345998",
            Time = 2
        })
    end
})

-- 更新下拉列表
Players.PlayerAdded:Connect(function(plr)
    if plr ~= lp then
        tpDropdown:Refresh(getPlayerList(), true)
    end
end)
Players.PlayerRemoving:Connect(function(plr)
    if plr ~= lp then
        tpDropdown:Refresh(getPlayerList(), true)
        if plr.Name == selectedTarget then
            selectedTarget = nil
        end
    end
end)

-- 辅助函数：设置本地玩家碰撞
local function setLocalCollision(state)
    if lp.Character then
        for _, part in ipairs(lp.Character:GetDescendants()) do
            if part:IsA("BasePart") then
                part.CanCollide = state
            end
        end
    end
end

-- 开关：持续传送到玩家背后
local tpConnection
PlayerTab:AddToggle({
    Name = "持续传送到玩家背后",
    Default = false,
    Callback = function(state)
        if state then
            if not selectedTarget then
                OrionLib:MakeNotification({
                    Name = "未选择目标",
                    Content = "请先在下拉列表选择一个玩家！",
                    Image = "rbxassetid://4483345998",
                    Time = 2
                })
                return
            end

            -- 关闭本地玩家碰撞
            setLocalCollision(false)

            tpConnection = game:GetService("RunService").RenderStepped:Connect(function()
                local targetPlayer = Players:FindFirstChild(selectedTarget)
                if targetPlayer 
                and targetPlayer.Character 
                and targetPlayer.Character:FindFirstChild("HumanoidRootPart") 
                and lp.Character 
                and lp.Character:FindFirstChild("HumanoidRootPart") then
                    
                    local targetHRP = targetPlayer.Character.HumanoidRootPart
                    local myHRP = lp.Character.HumanoidRootPart

                    local backOffset = -targetHRP.CFrame.LookVector * 4
                    myHRP.CFrame = CFrame.new(targetHRP.Position + backOffset, targetHRP.Position)
                end
            end)
        else
            if tpConnection then
                tpConnection:Disconnect()
                tpConnection = nil
            end
            -- 恢复本地玩家碰撞
            setLocalCollision(true)
        end
    end
})

-- 按钮：一次性传送到玩家背后
PlayerTab:AddButton({
    Name = "一次性传送到玩家背后",
    Callback = function()
        if not selectedTarget then
            OrionLib:MakeNotification({
                Name = "未选择目标",
                Content = "请先在下拉列表选择一个玩家！",
                Image = "rbxassetid://4483345998",
                Time = 2
            })
            return
        end

        local targetPlayer = Players:FindFirstChild(selectedTarget)
        if targetPlayer 
        and targetPlayer.Character 
        and targetPlayer.Character:FindFirstChild("HumanoidRootPart") 
        and lp.Character 
        and lp.Character:FindFirstChild("HumanoidRootPart") then
            
            -- 临时关闭碰撞
            setLocalCollision(false)

            local targetHRP = targetPlayer.Character.HumanoidRootPart
            local myHRP = lp.Character.HumanoidRootPart

            local backOffset = -targetHRP.CFrame.LookVector * 4
            myHRP.CFrame = CFrame.new(targetHRP.Position + backOffset, targetHRP.Position)

            -- 恢复碰撞
            setLocalCollision(true)

            OrionLib:MakeNotification({
                Name = "传送成功",
                Content = "已传送到 " .. selectedTarget .. " 背后",
                Image = "rbxassetid://4483345998",
                Time = 2
            })
        else
            OrionLib:MakeNotification({
                Name = "传送失败",
                Content = "目标玩家不可用或未加载角色",
                Image = "rbxassetid://4483345998",
                Time = 2
            })
        end
    end
})

-- 创建“关于此脚本”标签页
local AboutTab = Window:MakeTab({
    Name = "关于此脚本",
    Icon = "rbxassetid://4483345998",
    PremiumOnly = false
})

-- 按钮：复制作者 QQ
AboutTab:AddButton({
    Name = "复制作者QQ",
    Callback = function()
        if setclipboard then
            setclipboard("635681310")
            OrionLib:MakeNotification({
                Name = "复制成功",
                Content = "作者QQ已复制到剪贴板",
                Image = "rbxassetid://4483345998",
                Time = 2
            })
        else
            OrionLib:MakeNotification({
                Name = "复制失败",
                Content = "当前环境不支持复制到剪贴板",
                Image = "rbxassetid://4483345998",
                Time = 2
            })
        end
    end
})



-- 在关于此脚本页添加 时间 / FPS / Ping 段落
local timeParagraph = AboutTab:AddParagraph("游戏状态:", "加载中...")

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

-- ===== 初始化 UI =====
OrionLib:Init()
