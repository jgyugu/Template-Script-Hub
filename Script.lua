-- ===== 黑名单（UID） =====
local uidBlacklist = {}

local Players = game:GetService("Players")
local lp = Players.LocalPlayer

for _, uid in ipairs(uidBlacklist) do
    if lp.UserId == uid then
        lp:Kick("你已被禁止使用此脚本")
        return
    end
end
-- ========================

-- ===== 配置区 =====
local scripts = {
    {
        name = "飞行脚本",
        url = "https://raw.githubusercontent.com/jgyugu/Template-Script-Hub/refs/heads/main/fly_Script",
        desc = "经典飞行脚本（部分服务器拉回）",
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
AboutTab:AddSection({ Name = "脚本中心:" })
AboutTab:AddParagraph("欢迎", "欢迎来到 ethan脚本中心！\n这是一个收集可用脚本的脚本中心方便开g。\n此脚本完全免费请勿倒卖!")

-- 第 2 个标签页：通用
local CommonTab = Window:MakeTab({
    Name = "通用",
    Icon = "rbxassetid://4483345998",
    PremiumOnly = false
})
CommonTab:AddSection({ Name = "通用功能" })

-- 生成功能按钮
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
    CommonTab:AddParagraph("简介", string.format("作者：%s\n适用游戏：%s\n简介：%s", s.author, s.game, s.desc))
end

-- 初始化 UI
OrionLib:Init()
