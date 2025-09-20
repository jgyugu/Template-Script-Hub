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
local uidBlacklist = config.blacklist

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

-- ===== 标签页缓存表 =====
local tabs = {}
-- ===== 创建通用功能标签页 =====
local CommonTab = Window:MakeTab({
    Name = "通用功能",
    Icon = "rbxassetid://4483345998",
    PremiumOnly = false
})
CommonTab:AddSection({ Name = "脚本列表:" })
tabs["通用"] = CommonTab -- 缓存通用标签页

-- ===== 云端获取 scripts.lua（脚本列表） =====
local scripts = loadstring(game:HttpGet(
    "https://raw.githubusercontent.com/jgyugu/Template-Script-Hub/refs/heads/main/scripts.lua"
))()

if type(scripts) == "table" then
    for _, s in ipairs(scripts) do
        local scriptType = tostring(s.type or "通用")

        -- 如果标签页不存在则创建（非通用类型）
        if not tabs[scriptType] then
            local newTab = Window:MakeTab({
                Name = scriptType,
                Icon = "rbxassetid://4483345998",
                PremiumOnly = false
            })
            newTab:AddSection({ Name = "脚本列表:" })
            tabs[scriptType] = newTab
        end

        -- 添加按钮（点击时检查游戏 ID）
        tabs[scriptType]:AddButton({
            Name = tostring(s.name or "未命名"),
            Callback = function()
                -- 非通用脚本检查 ID
                if scriptType ~= "通用" then
                    if not s.id or s.id ~= game.GameId then
                        OrionLib:MakeNotification({
                            Name = "错误",
                            Content = "请在对应游戏运行！",
                            Image = "rbxassetid://14250466898",
                            Time = 3
                        })
                        return
                    end
                end

                -- 运行脚本
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
    Icon = "rbxassetid://4483345998",
    PremiumOnly = false
})

-- 状态/连接/资源跟踪，用于销毁时清理
local infiniteJumpConnection
local noclipConnection
local airwalkPart
local airwalkConnection
local airwalkCharAddedConn
local visionLoop = nil
local highlightFolder = Instance.new("Folder")
highlightFolder.Name = "ESP_Highlights"
highlightFolder.Parent = game:GetService("CoreGui")
local espConnections = {} -- { PlayerAdded = conn }
local espCharacterAddedConnections = {} -- 每个玩家的 CharacterAdded 连接
local tpConnection
local dropdownPlayerAddedConn
local dropdownPlayerRemovingConn
local statusCharAddedConn
local statusLoopRunning = true
local aboutLoopRunning = true

-- ===== 新增：玩家属性循环保持（速度/跳跃力） =====
local attrLoopConn
local targetWalkSpeed = nil
local targetJumpPower = nil

attrLoopConn = game:GetService("RunService").RenderStepped:Connect(function()
    local hum = lp.Character and lp.Character:FindFirstChildOfClass("Humanoid")
    if hum then
        if targetWalkSpeed then
            hum.WalkSpeed = targetWalkSpeed
        end
        if targetJumpPower then
            hum.UseJumpPower = true
            hum.JumpPower = targetJumpPower
        end
    end
end)

-- 玩家状态 Paragraph（实时刷新） 
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
    while statusLoopRunning and task.wait(0.5) do
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
statusCharAddedConn = lp.CharacterAdded:Connect(function()
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

PlayerTab:AddSection({ Name = "玩家属性设置(部分服务器没用)" })

-- 输入框：设置跳跃力（循环保持）
PlayerTab:AddTextbox({
    Name = "设置跳跃",
    Default = "",
    TextDisappear = true,
    Callback = function(Value)
        local num = tonumber(Value)
        if num then
            targetJumpPower = num
            local hum = lp.Character and lp.Character:FindFirstChildOfClass("Humanoid")
            if hum then
                hum.UseJumpPower = true
                hum.JumpPower = num
            end
        else
            OrionLib:MakeNotification({
                Name = "输入错误",
                Content = "请输入数字！",
                Image = "rbxassetid://14250466898",
                Time = 2
            })
        end
    end
})

-- 输入框：设置移动速度（循环保持）
PlayerTab:AddTextbox({
    Name = "设置速度",
    Default = "",
    TextDisappear = true,
    Callback = function(Value)
        local num = tonumber(Value)
        if num then
            targetWalkSpeed = num
            local hum = lp.Character and lp.Character:FindFirstChildOfClass("Humanoid")
            if hum then
                hum.WalkSpeed = num
            end
        else
            OrionLib:MakeNotification({
                Name = "输入错误",
                Content = "请输入数字！",
                Image = "rbxassetid://14250466898",
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
                Image = "rbxassetid://14250466898",
                Time = 2
            })
        end
    end
})

-- 按钮：恢复默认值（并停止循环保持）
PlayerTab:AddButton({
    Name = "恢复默认 重力/速度/跳跃力",
    Callback = function()
        workspace.Gravity = 196.2
        targetWalkSpeed = nil
        targetJumpPower = nil
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
local lastY = nil -- 记录平台当前高度
local tolerance = 0.4 -- 容差，允许下沉的距离（studs）

-- 销毁平台
local function destroyAirwalkPart()
    if airwalkPart then
        airwalkPart:Destroy()
        airwalkPart = nil
    end
end

-- 创建平台
local function createAirwalkPart()
    destroyAirwalkPart() -- 创建前先清理旧的
    airwalkPart = Instance.new("Part")
    airwalkPart.Size = Vector3.new(6, 5, 6) -- 厚度 5
    airwalkPart.Anchored = true
    airwalkPart.Transparency = 1 -- 调试可见（调试完成可改为 1 隐形）
    airwalkPart.CanCollide = true
    airwalkPart.Massless = true
    airwalkPart.Name = "AirWalkPart"
    airwalkPart.Parent = workspace
end

-- 启动踏空
local function startAirwalk()
    createAirwalkPart()
    lastY = nil

    if airwalkConnection then
        airwalkConnection:Disconnect()
    end

    airwalkConnection = game:GetService("RunService").RenderStepped:Connect(function()
        if lp.Character and lp.Character:FindFirstChild("HumanoidRootPart") then
            local hrp = lp.Character.HumanoidRootPart
            local pos = hrp.Position
            local halfHeight = airwalkPart.Size.Y / 2
            local targetY = pos.Y - 3.5 - halfHeight -- 顶面对齐脚底

            -- 初始化高度
            if not lastY then
                lastY = targetY
            end

            -- 只允许上升
            if targetY > lastY then
                lastY = targetY
            end

            -- 更新平台位置
            airwalkPart.Position = Vector3.new(pos.X, lastY, pos.Z)

            -- 防 NoClip 托举（带容差）：只调整 Y 轴，不改朝向
            if pos.Y < lastY + halfHeight - tolerance then
                local cf = hrp.CFrame
                hrp.CFrame = CFrame.fromMatrix(
                    Vector3.new(cf.Position.X, lastY + halfHeight, cf.Position.Z),
                    cf.RightVector,
                    cf.UpVector
                )
            end
        end
    end)
end

-- UI 开关
CommonTab:AddToggle({
    Name = "踏空而行",
    Default = false,
    Callback = function(state)
        if state then
            startAirwalk()
            -- 重生后继续运行，不销毁
            if airwalkCharAddedConn then
                airwalkCharAddedConn:Disconnect()
                airwalkCharAddedConn = nil
            end
            airwalkCharAddedConn = lp.CharacterAdded:Connect(function()
                task.wait(1)
                startAirwalk()
            end)
        else
            if airwalkConnection then
                airwalkConnection:Disconnect()
                airwalkConnection = nil
            end
            if airwalkCharAddedConn then
                airwalkCharAddedConn:Disconnect()
                airwalkCharAddedConn = nil
            end
            destroyAirwalkPart() -- 关掉时才清理
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

-- 控制循环的变量
CommonTab:AddToggle({
    Name = "一键视觉增强（夜视+去雾）",
    Default = false,
    Callback = function(state)
        if state then
            -- 开启循环刷新
            if visionLoop then visionLoop:Disconnect() end
            visionLoop = game:GetService("RunService").RenderStepped:Connect(function()
                lighting.Brightness = 5
                lighting.Ambient = Color3.new(1, 1, 1)
                lighting.OutdoorAmbient = Color3.new(1, 1, 1)
                lighting.FogEnd = 1e6
                lighting.FogStart = 0
                lighting.FogColor = Color3.fromRGB(255, 255, 255)
            end)
        else
            -- 停止循环并恢复原设置
            if visionLoop then
                visionLoop:Disconnect()
                visionLoop = nil
            end
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

        -- 监听角色刷新（存储以便清理）
        local c = player.CharacterAdded:Connect(function(char)
            attachHighlight(char)
        end)
        espCharacterAddedConnections[player] = c
    end
end

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
            -- 断开已有玩家的 CharacterAdded 监听
            for plr, conn in pairs(espCharacterAddedConnections) do
                if conn then conn:Disconnect() end
                espCharacterAddedConnections[plr] = nil
            end
        end
    end
})

-- ===== 传送到玩家（多位面：背后/正对面/头上/左边/右边） =====
local selectedTarget = nil
local selectedMode = "背后"
local H_DIST = 4
local EXTRA_Y = 1

-- 获取玩家列表
local function getPlayerList()
    local names = {}
    for _, plr in ipairs(Players:GetPlayers()) do
        if plr ~= lp then
            table.insert(names, plr.Name)
        end
    end
    table.sort(names)
    return names
end

-- 下拉列表：选择目标
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

-- 下拉列表：选择位置
local modeDropdown = PlayerTab:AddDropdown({
    Name = "选择传送位置",
    Default = "背后",
    Options = {"背后","正对面","头上","左边","右边"},
    Callback = function(value)
        selectedMode = value
    end
})

-- 玩家列表动态刷新
dropdownPlayerAddedConn = Players.PlayerAdded:Connect(function(plr)
    if plr ~= lp then
        tpDropdown:Refresh(getPlayerList(), true)
    end
end)
dropdownPlayerRemovingConn = Players.PlayerRemoving:Connect(function(plr)
    if plr ~= lp then
        tpDropdown:Refresh(getPlayerList(), true)
        if plr.Name == selectedTarget then
            selectedTarget = nil
        end
    end
end)

-- 辅助：设置本地玩家碰撞
local function setLocalCollision(state)
    if lp.Character then
        for _, part in ipairs(lp.Character:GetDescendants()) do
            if part:IsA("BasePart") then
                part.CanCollide = state
            end
        end
    end
end

-- 偏移计算
local function getOffsetCFrame(targetHRP)
    if selectedMode == "背后" then
        return CFrame.new(0, 0, -H_DIST)
    elseif selectedMode == "正对面" then
        return CFrame.new(0, 0, H_DIST)
    elseif selectedMode == "左边" then
        return CFrame.new(-H_DIST, 0, 0)
    elseif selectedMode == "右边" then
        return CFrame.new(H_DIST, 0, 0)
    elseif selectedMode == "头上" then
        local targetHum = targetHRP.Parent:FindFirstChildOfClass("Humanoid")
        local myHum = lp.Character and lp.Character:FindFirstChildOfClass("Humanoid")
        local targetHRPSizeY = targetHRP.Size.Y / 2
        local myHRP = lp.Character and lp.Character:FindFirstChild("HumanoidRootPart")
        local myHRPSizeY = myHRP and myHRP.Size.Y/2 or 1
    
        local targetHeight = (targetHum and targetHum.HipHeight or 2) + targetHRPSizeY
        local myHeight = (myHum and myHum.HipHeight or 2) + myHRPSizeY
    
        local y = targetHeight + myHeight + 1 -- +1 是额外缓冲
        return CFrame.new(0, y, 0)
    else
        return CFrame.new()
    end
end

-- 持续传送
PlayerTab:AddToggle({
    Name = "持续传送到玩家",
    Default = false,
    Callback = function(state)
        local myHum = lp.Character and lp.Character:FindFirstChildOfClass("Humanoid")
        if state then
            if not selectedTarget then
                OrionLib:MakeNotification({
                    Name = "未选择目标",
                    Content = "请先在下拉列表选择一个玩家！",
                    Image = "rbxassetid://14250466898",
                    Time = 2
                })
                return
            end
            setLocalCollision(false)
            tpConnection = game:GetService("RunService").RenderStepped:Connect(function()
                local targetPlayer = Players:FindFirstChild(selectedTarget)
                if not (targetPlayer and targetPlayer.Character) then return end
                local targetHRP = targetPlayer.Character:FindFirstChild("HumanoidRootPart")
                local myChar = lp.Character
                local myHRP = myChar and myChar:FindFirstChild("HumanoidRootPart")
                if targetHRP and myHRP then
                    myHRP.CFrame = targetHRP.CFrame * getOffsetCFrame(targetHRP)
                    -- 如果是头上模式，设置坐下
                    if selectedMode == "头上" and myHum then
                        myHum.Sit = true
                    end
                end
            end)
        else
            if tpConnection then
                tpConnection:Disconnect()
                tpConnection = nil
            end
            setLocalCollision(true)
            -- 恢复站立
            if myHum then
                myHum.Sit = false
            end
        end
    end
})

-- 一次性传送
PlayerTab:AddButton({
    Name = "一次性传送到玩家",
    Callback = function()
        if not selectedTarget then
            OrionLib:MakeNotification({
                Name = "未选择目标",
                Content = "请先在下拉列表选择一个玩家！",
                Image = "rbxassetid://14250466898",
                Time = 2
            })
            return
        end
        local targetPlayer = Players:FindFirstChild(selectedTarget)
        if targetPlayer and targetPlayer.Character then
            local targetHRP = targetPlayer.Character:FindFirstChild("HumanoidRootPart")
            local myChar = lp.Character
            local myHRP = myChar and myChar:FindFirstChild("HumanoidRootPart")
            if targetHRP and myHRP then
                setLocalCollision(false)
                myHRP.CFrame = targetHRP.CFrame * getOffsetCFrame(targetHRP)
                setLocalCollision(true)
                OrionLib:MakeNotification({
                    Name = "传送成功",
                    Content = ("已传送到 %s 的 %s"):format(selectedTarget, selectedMode),
                    Image = "rbxassetid://4483345998",
                    Time = 2
                })
            end
        end
    end
})

-- ===== 甩飞玩家（基于物理旋转的碰撞甩飞） =====
local flingConnection
local flingCharAddedConn
local flingAttachment
local flingConstraint

local function stopFling()
    if flingConnection then
        flingConnection:Disconnect()
        flingConnection = nil
    end
    if flingCharAddedConn then
        flingCharAddedConn:Disconnect()
        flingCharAddedConn = nil
    end
    local myChar = lp.Character
    local myHRP = myChar and myChar:FindFirstChild("HumanoidRootPart")
    if flingConstraint then
        flingConstraint:Destroy()
        flingConstraint = nil
    end
    if flingAttachment then
        flingAttachment:Destroy()
        flingAttachment = nil
    end
    if myHRP then
        myHRP.AssemblyAngularVelocity = Vector3.new(0, 0, 0)
        -- 确保碰撞恢复为可碰撞（由其他功能可能改变，这里不强制设置全身）
        myHRP.CanCollide = true
    end
end

local function startFling()
    stopFling()

    local myChar = lp.Character
    local myHRP = myChar and myChar:FindFirstChild("HumanoidRootPart")
    if not myHRP then return end

    -- 创建附件与角速度约束（新物理组件比 BodyAngularVelocity 更稳定）
    flingAttachment = Instance.new("Attachment")
    flingAttachment.Name = "FlingAttachment"
    flingAttachment.Parent = myHRP

    flingConstraint = Instance.new("AngularVelocity")
    flingConstraint.Name = "FlingAngular"
    flingConstraint.Attachment0 = flingAttachment
    flingConstraint.RelativeTo = Enum.ActuatorRelativeTo.Attachment0
    flingConstraint.AngularVelocity = Vector3.new(0, 10000, 0) -- 高速旋转
    flingConstraint.MaxTorque = math.huge
    flingConstraint.Enabled = true
    flingConstraint.Parent = myHRP

    -- 确保有碰撞去打到对方
    for _, part in ipairs(myChar:GetDescendants()) do
        if part:IsA("BasePart") then
            part.CanCollide = true
            part.Massless = false
        end
    end

    -- 重生时重建甩飞
    flingCharAddedConn = lp.CharacterAdded:Connect(function()
        task.wait(1)
        startFling()
    end)

    -- 持续靠近目标并保持高速旋转
    flingConnection = game:GetService("RunService").RenderStepped:Connect(function()
        if not selectedTarget then return end
        local targetPlayer = Players:FindFirstChild(selectedTarget)
        if not (targetPlayer and targetPlayer.Character) then return end
        local targetHRP = targetPlayer.Character:FindFirstChild("HumanoidRootPart")
        if not (myHRP and targetHRP) then return end

        -- 贴近目标（稍微偏移，避免卡进身体中心）
        local offset = CFrame.new(0, 0, 1.5)
        myHRP.CFrame = targetHRP.CFrame * offset

        -- 给目标一个向上的线速度冲击（接触时更容易被抛飞）
        myHRP.AssemblyLinearVelocity = Vector3.new(0, 200, 0)
    end)
end

PlayerTab:AddToggle({
    Name = "甩飞玩家（需选择目标）",
    Default = false,
    Callback = function(state)
        if state then
            if not selectedTarget then
                OrionLib:MakeNotification({
                    Name = "未选择目标",
                    Content = "请先在上方选择一个目标玩家！",
                    Image = "rbxassetid://14250466898",
                    Time = 2
                })
                return
            end
            startFling()
            OrionLib:MakeNotification({
                Name = "甩飞已开启",
                Content = "正在尝试甩飞：" .. tostring(selectedTarget),
                Image = "rbxassetid://4483345998",
                Time = 2
            })
        else
            stopFling()
            OrionLib:MakeNotification({
                Name = "甩飞已关闭",
                Content = "甩飞功能已停止并清理。",
                Image = "rbxassetid://4483345998",
                Time = 2
            })
        end
    end
})

-- ===== 自毁按钮 =====
PlayerTab:AddButton({
    Name = "自毁",
    Callback = function()
        local StarterGui = game:GetService("StarterGui")
        local Players = game:GetService("Players")
        local lp = Players.LocalPlayer

        -- 创建回调函数
        local confirmFunc = Instance.new("BindableFunction")
        function confirmFunc.OnInvoke(choice)
            if choice == "是" then
                local char = lp.Character
                if char then
                    local hum = char:FindFirstChildOfClass("Humanoid")
                    if hum then
                        hum.Health = 0
                    end
                end
            end
        end

        -- 弹出系统通知
        StarterGui:SetCore("SendNotification", {
            Title = "确认自毁？",
            Text = "你确定要自毁吗？",
            Duration = 3,
            Callback = confirmFunc,
            Button1 = "是",
            Button2 = "否"
        })
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
    Name = "作者QQ:635681310(点击复制)",
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

-- 获取当前 GameId
local currentGameId = tostring(game.GameId)
-- 创建按钮（显示 + 点击复制）
AboutTab:AddButton({
    Name = "当前游戏ID: " .. currentGameId .. "（点击复制）",
    Callback = function()
        if setclipboard then
            setclipboard(currentGameId)
            OrionLib:MakeNotification({
                Name = "复制成功",
                Content = "当前GameId已复制到剪贴板",
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
    while aboutLoopRunning and task.wait(1) do
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

-- ===== 销毁/清理函数（在销毁 GUI 时调用） =====
local function cleanupAll()
    -- 停止状态循环
    statusLoopRunning = false
    aboutLoopRunning = false

    -- 断开玩家状态 CharacterAdded
    if statusCharAddedConn then
        statusCharAddedConn:Disconnect()
        statusCharAddedConn = nil
    end

    -- 无限跳
    if infiniteJumpConnection then
        infiniteJumpConnection:Disconnect()
        infiniteJumpConnection = nil
    end

    -- 穿墙：恢复碰撞并断开
    if lp.Character then
        for _, part in ipairs(lp.Character:GetDescendants()) do
            if part:IsA("BasePart") then
                part.CanCollide = true
            end
        end
    end
    if noclipConnection then
        noclipConnection:Disconnect()
        noclipConnection = nil
    end

    -- 踏空：断开连接与重生监听并销毁平台
    if airwalkConnection then
        airwalkConnection:Disconnect()
        airwalkConnection = nil
    end
    if airwalkCharAddedConn then
        airwalkCharAddedConn:Disconnect()
        airwalkCharAddedConn = nil
    end
    destroyAirwalkPart()

    -- 视觉增强：断开并恢复原设置
    if visionLoop then
        visionLoop:Disconnect()
        visionLoop = nil
    end
    pcall(function()
        lighting.Brightness = oldBrightness
        lighting.Ambient = oldAmbient
        lighting.OutdoorAmbient = oldOutdoorAmbient
        lighting.FogEnd = oldFogEnd
        lighting.FogStart = oldFogStart
        lighting.FogColor = oldFogColor
    end)

    -- 透视：移除高亮，断开新玩家与角色监听
    for _, h in ipairs(highlightFolder:GetChildren()) do
        h:Destroy()
    end
    if espConnections.PlayerAdded then
        espConnections.PlayerAdded:Disconnect()
        espConnections.PlayerAdded = nil
    end
    for plr, conn in pairs(espCharacterAddedConnections) do
        if conn then conn:Disconnect() end
        espCharacterAddedConnections[plr] = nil
    end
    if highlightFolder and highlightFolder.Parent then
        highlightFolder:Destroy()
    end

    -- 传送：断开连接并恢复站立/碰撞
    if tpConnection then
        tpConnection:Disconnect()
        tpConnection = nil
    end
    local hum = lp.Character and lp.Character:FindFirstChildOfClass("Humanoid")
    if hum then
        hum.Sit = false
    end
    setLocalCollision(true)

    -- 下拉列表刷新监听断开
    if dropdownPlayerAddedConn then
        dropdownPlayerAddedConn:Disconnect()
        dropdownPlayerAddedConn = nil
    end
    if dropdownPlayerRemovingConn then
        dropdownPlayerRemovingConn:Disconnect()
        dropdownPlayerRemovingConn = nil
    end

    -- 停止属性保持循环并恢复默认
    targetWalkSpeed = nil
    targetJumpPower = nil
    if attrLoopConn then
        attrLoopConn:Disconnect()
        attrLoopConn = nil
    end
    workspace.Gravity = 196.2
    if hum then
        hum.WalkSpeed = 16
        hum.UseJumpPower = true
        hum.JumpPower = 50
    end

    -- 停止甩飞并清理
    stopFling()
end

-- ===== 销毁界面按钮 =====
AboutTab:AddButton({
    Name = "销毁界面",
    Callback = function()
        local StarterGui = game:GetService("StarterGui")

        -- 创建回调函数
        local confirmFunc = Instance.new("BindableFunction")
        function confirmFunc.OnInvoke(choice)
            if choice == "是" then
                -- 清理与恢复
                pcall(cleanupAll)

                StarterGui:SetCore("SendNotification", {
                    Title = "Ethan 脚本中心",
                    Text = "期待您下次使用",
                    Duration = 2.5
                })
                task.wait(1)
                OrionLib:Destroy()
            end
        end

        -- 弹出系统通知
        StarterGui:SetCore("SendNotification", {
            Title = "确认？",
            Text = "你确定要销毁界面吗？",
            Duration = 3,
            Callback = confirmFunc,
            Button1 = "是",
            Button2 = "否"
        })
    end
})

-- ===== 初始化 UI =====
OrionLib:Init()
