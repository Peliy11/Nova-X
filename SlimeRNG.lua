if _G.NovaXLoaded and _G.NovaXInstance and _G.NovaXInstance.SlimeRNGLoaded then return _G.NovaXInstance end

local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")
local TweenService = game:GetService("TweenService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local HttpService = game:GetService("HttpService")

local LocalPlayer = Players.LocalPlayer or Players:GetPropertyChangedSignal("LocalPlayer"):Wait()

-- ═══════════════════════════════════════════════════════════════
-- DYNAMIC SCAWSHUB LOADER
-- ═══════════════════════════════════════════════════════════════
local ScawsHub
do
    local function safeReadFile(path)
        if type(readfile) == "function" then
            local ok, content = pcall(readfile, path)
            if ok and type(content) == "string" then
                return content
            end
        end
        return nil
    end

    -- 1. Try local load for development
    local localSrc = safeReadFile("ScawsLoader-main/ScawsLoader-main/main.luau")
    if localSrc then
        local fn = loadstring(localSrc)
        if fn then
            local ok, res = pcall(fn)
            if ok then ScawsHub = res end
        end
    end

    -- 2. Fall back to raw GitHub URL for players
    if not ScawsHub then
        local url = "https://raw.githubusercontent.com/Peliy11/Nova-X/main/ScawsLoader-main/ScawsLoader-main/main.luau"
        local ok, onlineSrc = pcall(game.HttpGet, game, url)
        if ok and type(onlineSrc) == "string" and #onlineSrc > 0 then
            local fn = loadstring(onlineSrc)
            if fn then
                local ok2, res = pcall(fn)
                if ok2 then ScawsHub = res end
            end
        end
    end
end

if not ScawsHub then
    warn("[Nova X] Critical Error: Failed to load ScawsHub UI library.")
    return nil
end

-- ═══════════════════════════════════════════════════════════════
-- SETTINGS CONFIGURATION
-- ═══════════════════════════════════════════════════════════════
local Settings = {
    AutoRoll = false,
    AutoEquipBest = false,
    AutoUpgrade = false,
    AutoBuyZones = false,
    AutoRebirth = false,
    AutoCollectItems = false,
    AutoCollectIndexRewards = false,
    AutoCollectOfflineRewards = false,

    AutoUseBoosts = false,
    AutoUseFood = false,
    AutoUsePacks = false,

    AutoUnlockRecipe = false,
    AutoCraft = false,
    XPTransfer = false,

    AutoRedeemCodes = false,
    FPSBoost = false,
    TeleportToZones = false,
    WalkSpeed = 16,
    Fly = false,
    FlySpeed = 50,
    Noclip = false,

    WebhookEnabled = false,
    WebhookUrl = "",
    WebhookInterval = 60,
    WebhookShowPlayerName = true,
    WebhookShowCoins = true,
    WebhookShowGoop = true,
    WebhookShowSessionTime = true,
    WebhookShowNewItems = true,
    WebhookTimestamp = true,
}

-- ═══════════════════════════════════════════════════════════════
-- DYNAMIC REMOTE EVENT FINDER
-- ═══════════════════════════════════════════════════════════════
local cachedRemotes = {}

local function findRemote(className, possibleNames)
    local cacheKey = className .. "_" .. table.concat(possibleNames, ",")
    if cachedRemotes[cacheKey] and cachedRemotes[cacheKey].Parent then
        return cachedRemotes[cacheKey]
    end

    for _, obj in ipairs(ReplicatedStorage:GetDescendants()) do
        if obj:IsA(className) then
            local nameLower = obj.Name:lower()
            for _, possible in ipairs(possibleNames) do
                if nameLower:find(possible:lower()) then
                    cachedRemotes[cacheKey] = obj
                    return obj
                end
            end
        end
    end
    return nil
end

local function getRemote(name)
    if name == "Roll" then
        return findRemote("RemoteEvent", {"roll", "spin"})
    elseif name == "Rebirth" then
        return findRemote("RemoteEvent", {"rebirth", "ascend"})
    elseif name == "Craft" then
        return findRemote("RemoteEvent", {"craft", "make"})
    elseif name == "Upgrade" then
        return findRemote("RemoteEvent", {"upgrade", "buyupgrade"})
    elseif name == "Equip" then
        return findRemote("RemoteEvent", {"equip", "equipbest", "equip_best"})
    elseif name == "Zone" then
        return findRemote("RemoteEvent", {"zone", "unlockzone", "buyzone"})
    elseif name == "Index" then
        return findRemote("RemoteEvent", {"index", "claimindex", "reward"})
    elseif name == "Offline" then
        return findRemote("RemoteEvent", {"offline", "claimoffline", "offline_reward"})
    end
    return nil
end

-- ═══════════════════════════════════════════════════════════════
-- CHEAT FEATURES IMPLEMENTATION
-- ═══════════════════════════════════════════════════════════════
local function applyWalkSpeed()
    pcall(function()
        local character = LocalPlayer.Character
        local humanoid = character and character:FindFirstChild("Humanoid")
        if humanoid then
            humanoid.WalkSpeed = Settings.WalkSpeed
        end
    end)
end

local function applyNoclip()
    pcall(function()
        local character = LocalPlayer.Character
        if not character then return end
        for _, part in ipairs(character:GetDescendants()) do
            if part:IsA("BasePart") and part.Name ~= "HumanoidRootPart" then
                part.CanCollide = not Settings.Noclip
            end
        end
    end)
end

local flyConnection
local function updateFlyState()
    local character = LocalPlayer.Character
    local hrp = character and character:FindFirstChild("HumanoidRootPart")
    local humanoid = character and character:FindFirstChild("Humanoid")
    if not hrp or not humanoid then return end

    if not Settings.Fly then
        if flyConnection then
            flyConnection:Disconnect()
            flyConnection = nil
        end
        humanoid.PlatformStand = false
        hrp.Velocity = Vector3.zero
        return
    end

    humanoid.PlatformStand = true
    local camera = workspace.CurrentCamera

    flyConnection = RunService.Heartbeat:Connect(function(dt)
        local char = LocalPlayer.Character
        local root = char and char:FindFirstChild("HumanoidRootPart")
        if not root then return end

        local look = camera.CFrame.LookVector
        local right = camera.CFrame.RightVector
        local dir = Vector3.new(0, 0, 0)

        if UserInputService:IsKeyDown(Enum.KeyCode.W) then dir = dir + look end
        if UserInputService:IsKeyDown(Enum.KeyCode.S) then dir = dir - look end
        if UserInputService:IsKeyDown(Enum.KeyCode.A) then dir = dir - right end
        if UserInputService:IsKeyDown(Enum.KeyCode.D) then dir = dir + right end
        if UserInputService:IsKeyDown(Enum.KeyCode.Space) then dir = dir + Vector3.new(0, 1, 0) end
        if UserInputService:IsKeyDown(Enum.KeyCode.LeftShift) then dir = dir - Vector3.new(0, 1, 0) end

        root.Velocity = Vector3.new(0, 0, 0)
        if dir.Magnitude > 0 then
            root.CFrame = root.CFrame + (dir.Unit * Settings.FlySpeed * dt * 10)
        end
    end)
end

local function applyFPSBoost(enabled)
    if not enabled then return end
    pcall(function()
        for _, v in ipairs(workspace:GetDescendants()) do
            if v:IsA("Decal") or v:IsA("Texture") then
                v.Transparency = 1
            elseif v:IsA("ParticleEmitter") or v:IsA("Trail") then
                v.Enabled = false
            elseif v:IsA("PostEffect") then
                v.Enabled = false
            end
        end
    end)
end

local function collectItems()
    pcall(function()
        local character = LocalPlayer.Character
        local hrp = character and character:FindFirstChild("HumanoidRootPart")
        if not hrp then return end

        for _, v in ipairs(workspace:GetDescendants()) do
            if v:IsA("BasePart") and (v.Name:lower():find("coin") or v.Name:lower():find("goop") or v.Name:lower():find("item") or v.Name:lower():find("crystal") or v.Name:lower():find("gift")) then
                local touch = v:FindFirstChildOfClass("TouchTransmitter") or v:FindFirstChild("TouchInterest")
                if touch then
                    pcall(function()
                        firetouchinterest(hrp, v, 0)
                        firetouchinterest(hrp, v, 1)
                    end)
                else
                    local prompt = v:FindFirstChildOfClass("ProximityPrompt") or v.Parent:FindFirstChildOfClass("ProximityPrompt")
                    if prompt then
                        pcall(function() fireproximityprompt(prompt) end)
                    end
                end
            end
        end
    end)
end

-- ═══════════════════════════════════════════════════════════════
-- WEBHOOK STAT NOTIFIER
-- ═══════════════════════════════════════════════════════════════
local function sendWebhook()
    if not Settings.WebhookEnabled or not Settings.WebhookUrl or Settings.WebhookUrl == "" then return end

    local fields = {}
    if Settings.WebhookShowPlayerName then
        table.insert(fields, {
            name = "Player",
            value = LocalPlayer.Name .. " (" .. tostring(LocalPlayer.UserId) .. ")",
            inline = true
        })
    end

    local leaderstats = LocalPlayer:FindFirstChild("leaderstats")
    local coins = leaderstats and (leaderstats:FindFirstChild("Coins") or leaderstats:FindFirstChild("Gold") or leaderstats:FindFirstChild("Money"))
    local rebirths = leaderstats and (leaderstats:FindFirstChild("Rebirths") or leaderstats:FindFirstChild("Ascensions"))

    if Settings.WebhookShowCoins and coins then
        table.insert(fields, {
            name = "Coins",
            value = tostring(coins.Value),
            inline = true
        })
    end

    if rebirths then
        table.insert(fields, {
            name = "Rebirths",
            value = tostring(rebirths.Value),
            inline = true
        })
    end

    local embed = {
        title = "Nova X - Slime RNG Stat Update",
        color = 16727614, -- Hex #FF3E3E
        fields = fields,
        footer = {
            text = "Nova X Slime RNG Script"
        }
    }

    if Settings.WebhookTimestamp then
        embed.timestamp = os.date("!%Y-%m-%dT%H:%M:%SZ")
    end

    local payload = {
        embeds = { embed }
    }

    local httprequest = request or http_request or (http and http.request) or (syn and syn.request)
    if type(httprequest) == "function" then
        pcall(httprequest, {
            Url = Settings.WebhookUrl,
            Method = "POST",
            Headers = {
                ["Content-Type"] = "application/json"
            },
            Body = HttpService:JSONEncode(payload)
        })
    end
end

-- ═══════════════════════════════════════════════════════════════
-- AUTOMATION THREADS (BACKGROUND LOOPS)
-- ═══════════════════════════════════════════════════════════════
task.spawn(function()
    while true do
        task.wait(0.1)
        if Settings.AutoRoll then
            local remote = getRemote("Roll")
            if remote then pcall(function() remote:FireServer() end) end
        end
    end
end)

task.spawn(function()
    while true do
        task.wait(1)
        if Settings.AutoEquipBest then
            local remote = getRemote("Equip")
            if remote then pcall(function() remote:FireServer() end) end
        end
        if Settings.AutoUpgrade then
            local remote = getRemote("Upgrade")
            if remote then pcall(function() remote:FireServer() end) end
        end
        if Settings.AutoBuyZones then
            local remote = getRemote("Zone")
            if remote then pcall(function() remote:FireServer() end) end
        end
        if Settings.AutoRebirth then
            local remote = getRemote("Rebirth")
            if remote then pcall(function() remote:FireServer() end) end
        end
    end
end)

task.spawn(function()
    while true do
        task.wait(1)
        if Settings.AutoCollectItems then
            collectItems()
        end
        if Settings.AutoCollectIndexRewards then
            local remote = getRemote("Index")
            if remote then pcall(function() remote:FireServer() end) end
        end
        if Settings.AutoCollectOfflineRewards then
            local remote = getRemote("Offline")
            if remote then pcall(function() remote:FireServer() end) end
        end
    end
end)

task.spawn(function()
    while true do
        task.wait(2)
        if Settings.AutoCraft then
            local remote = getRemote("Craft")
            if remote then pcall(function() remote:FireServer() end) end
        end
    end
end)

task.spawn(function()
    while true do
        task.wait(1)
        if Settings.WebhookEnabled then
            sendWebhook()
            task.wait(math.clamp(Settings.WebhookInterval, 5, 600))
        end
    end
end)

-- ═══════════════════════════════════════════════════════════════
-- SLIMERNG MAIN LOAD
-- ═══════════════════════════════════════════════════════════════
local SlimeRNG = {}

function SlimeRNG.Load()
    -- Create the window
    local Window = ScawsHub:CreateWindow({
        Name = "Nova X | Slime RNG",
        ShowLoading = true,
        LoadingDuration = 2
    })

    -- 1. Main Tab
    local MainTab = Window:CreateTab("Main")
    MainTab:CreateSection("Auto Progression")
    MainTab:CreateToggle({
        Name = "Auto Roll",
        Default = Settings.AutoRoll,
        Callback = function(v) Settings.AutoRoll = v end
    })
    MainTab:CreateToggle({
        Name = "Auto Equip Best",
        Default = Settings.AutoEquipBest,
        Callback = function(v) Settings.AutoEquipBest = v end
    })
    MainTab:CreateToggle({
        Name = "Auto Upgrade",
        Default = Settings.AutoUpgrade,
        Callback = function(v) Settings.AutoUpgrade = v end
    })
    MainTab:CreateToggle({
        Name = "Auto Buy Zones",
        Default = Settings.AutoBuyZones,
        Callback = function(v) Settings.AutoBuyZones = v end
    })
    MainTab:CreateToggle({
        Name = "Auto Rebirth",
        Default = Settings.AutoRebirth,
        Callback = function(v) Settings.AutoRebirth = v end
    })
    MainTab:CreateDivider()
    MainTab:CreateSection("Rewards & Collection")
    MainTab:CreateToggle({
        Name = "Auto Collect Items",
        Default = Settings.AutoCollectItems,
        Callback = function(v) Settings.AutoCollectItems = v end
    })
    MainTab:CreateToggle({
        Name = "Auto Claim Index Rewards",
        Default = Settings.AutoCollectIndexRewards,
        Callback = function(v) Settings.AutoCollectIndexRewards = v end
    })
    MainTab:CreateToggle({
        Name = "Auto Claim Offline Rewards",
        Default = Settings.AutoCollectOfflineRewards,
        Callback = function(v) Settings.AutoCollectOfflineRewards = v end
    })

    -- 2. Items Tab
    local ItemsTab = Window:CreateTab("Items")
    ItemsTab:CreateSection("Boosters & Consumables")
    ItemsTab:CreateToggle({
        Name = "Auto Use Boosts",
        Default = Settings.AutoUseBoosts,
        Callback = function(v) Settings.AutoUseBoosts = v end
    })
    ItemsTab:CreateToggle({
        Name = "Auto Use Food",
        Default = Settings.AutoUseFood,
        Callback = function(v) Settings.AutoUseFood = v end
    })
    ItemsTab:CreateToggle({
        Name = "Auto Use Packs",
        Default = Settings.AutoUsePacks,
        Callback = function(v) Settings.AutoUsePacks = v end
    })

    -- 3. Workshop Tab
    local WorkshopTab = Window:CreateTab("Workshop")
    WorkshopTab:CreateSection("Crafting & Workshop Helpers")
    WorkshopTab:CreateToggle({
        Name = "Auto Unlock Recipe",
        Default = Settings.AutoUnlockRecipe,
        Callback = function(v) Settings.AutoUnlockRecipe = v end
    })
    WorkshopTab:CreateToggle({
        Name = "Auto Craft",
        Default = Settings.AutoCraft,
        Callback = function(v) Settings.AutoCraft = v end
    })
    WorkshopTab:CreateToggle({
        Name = "XP Transfer Helper",
        Default = Settings.XPTransfer,
        Callback = function(v) Settings.XPTransfer = v end
    })

    -- 4. Movement Tab
    local MovementTab = Window:CreateTab("Movement")
    MovementTab:CreateSection("Stat Modifiers")
    MovementTab:CreateSlider({
        Name = "WalkSpeed",
        Min = 16,
        Max = 500,
        Default = Settings.WalkSpeed,
        Increment = 1,
        Callback = function(v) Settings.WalkSpeed = v end
    })
    MovementTab:CreateDivider()
    MovementTab:CreateSection("Flying Options")
    MovementTab:CreateToggle({
        Name = "Fly Enabled",
        Default = Settings.Fly,
        Callback = function(v)
            Settings.Fly = v
            updateFlyState()
        end
    })
    MovementTab:CreateSlider({
        Name = "Fly Speed",
        Min = 10,
        Max = 500,
        Default = Settings.FlySpeed,
        Increment = 1,
        Callback = function(v) Settings.FlySpeed = v end
    })
    MovementTab:CreateDivider()
    MovementTab:CreateSection("Other Utilities")
    MovementTab:CreateToggle({
        Name = "Noclip",
        Default = Settings.Noclip,
        Callback = function(v) Settings.Noclip = v end
    })
    MovementTab:CreateToggle({
        Name = "FPS Boost",
        Default = Settings.FPSBoost,
        Callback = function(v)
            Settings.FPSBoost = v
            applyFPSBoost(v)
        end
    })
    MovementTab:CreateToggle({
        Name = "Auto Redeem Codes",
        Default = Settings.AutoRedeemCodes,
        Callback = function(v) Settings.AutoRedeemCodes = v end
    })

    -- 5. Webhook Tab
    local WebhookTab = Window:CreateTab("Webhook")
    WebhookTab:CreateSection("Settings")
    WebhookTab:CreateToggle({
        Name = "Enable Webhook",
        Default = Settings.WebhookEnabled,
        Callback = function(v) Settings.WebhookEnabled = v end
    })
    WebhookTab:CreateInput({
        Name = "Webhook URL",
        Placeholder = "Enter Discord Webhook URL...",
        Default = Settings.WebhookUrl,
        Callback = function(v) Settings.WebhookUrl = v end
    })
    WebhookTab:CreateSlider({
        Name = "Send Interval (seconds)",
        Min = 10,
        Max = 600,
        Default = Settings.WebhookInterval,
        Increment = 5,
        Callback = function(v) Settings.WebhookInterval = v end
    })
    WebhookTab:CreateDivider()
    WebhookTab:CreateSection("Notification Details")
    WebhookTab:CreateToggle({
        Name = "Show Player Name",
        Default = Settings.WebhookShowPlayerName,
        Callback = function(v) Settings.WebhookShowPlayerName = v end
    })
    WebhookTab:CreateToggle({
        Name = "Show Coins",
        Default = Settings.WebhookShowCoins,
        Callback = function(v) Settings.WebhookShowCoins = v end
    })
    WebhookTab:CreateToggle({
        Name = "Show Goop",
        Default = Settings.WebhookShowGoop,
        Callback = function(v) Settings.WebhookShowGoop = v end
    })
    WebhookTab:CreateToggle({
        Name = "Show Session Time",
        Default = Settings.WebhookShowSessionTime,
        Callback = function(v) Settings.WebhookShowSessionTime = v end
    })
    WebhookTab:CreateToggle({
        Name = "Show New Items & Slimes",
        Default = Settings.WebhookShowNewItems,
        Callback = function(v) Settings.WebhookShowNewItems = v end
    })
    WebhookTab:CreateToggle({
        Name = "Include Timestamp",
        Default = Settings.WebhookTimestamp,
        Callback = function(v) Settings.WebhookTimestamp = v end
    })

    -- Heartbeat updates for WalkSpeed and Noclip
    RunService.Heartbeat:Connect(function()
        applyWalkSpeed()
        applyNoclip()
    end)

    _G.NovaXInstance = _G.NovaXInstance or {}
    _G.NovaXInstance.SlimeRNGLoaded = true
end

return SlimeRNG