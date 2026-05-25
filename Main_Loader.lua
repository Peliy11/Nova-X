repeat task.wait() until game:IsLoaded()

local TweenService = game:GetService("TweenService")
local UserInputService = game:GetService("UserInputService")
local CoreGui = game:GetService("CoreGui")
local Players = game:GetService("Players")

local LocalPlayer = Players.LocalPlayer or Players:GetPropertyChangedSignal("LocalPlayer"):Wait()

if _G.NovaXLoaded then
    return _G.NovaXInstance
end
_G.NovaXLoaded = true

local function create_instance(instance_type, properties, children)
    local instance = Instance.new(instance_type)
    for key, value in pairs(properties or {}) do
        instance[key] = value
    end
    if children then
        for _, child in pairs(children) do
            if child then
                child.Parent = instance
            end
        end
    end
    return instance
end

local function create_tween(instance, properties, duration, easing_style, easing_direction)
    local info = TweenInfo.new(
        duration or 0.3,
        easing_style or Enum.EasingStyle.Quart,
        easing_direction or Enum.EasingDirection.Out
    )
    local tween = TweenService:Create(instance, info, properties)
    tween:Play()
    return tween
end

local function create_bounce_tween(instance, properties, duration)
    local info = TweenInfo.new(
        duration or 0.5,
        Enum.EasingStyle.Back,
        Enum.EasingDirection.Out
    )
    local tween = TweenService:Create(instance, info, properties)
    tween:Play()
    return tween
end

local function create_smooth_tween(instance, properties, duration)
    local info = TweenInfo.new(
        duration or 0.4,
        Enum.EasingStyle.Exponential,
        Enum.EasingDirection.Out
    )
    local tween = TweenService:Create(instance, info, properties)
    tween:Play()
    return tween
end

local function safeReadFile(path)
    if type(readfile) == "function" then
        local ok, content = pcall(readfile, path)
        if ok and type(content) == "string" then
            return content
        end
    end
    return nil
end

local function loadScript(path)
    -- 1. Try local file first (for dev/testing)
    local localSource = safeReadFile(path)
    if localSource then
        local fn, err = loadstring(localSource)
        if not fn then
            warn("[Nova X] Failed to parse local script:", path, err)
            return nil
        end
        local ok, result = pcall(fn)
        if not ok then
            warn("[Nova X] Failed to run local script:", path, result)
            return nil
        end
        return result
    end

    if type(dofile) == "function" then
        local ok, result = pcall(dofile, path)
        if ok then
            return result
        end
    end

    -- 2. Try loading from GitHub raw URL
    local githubUrl = "https://raw.githubusercontent.com/Peliy11/Nova-X/main/" .. path
    local ok, onlineSource = pcall(game.HttpGet, game, githubUrl)
    if ok and type(onlineSource) == "string" and #onlineSource > 0 then
        local fn, err = loadstring(onlineSource)
        if not fn then
            warn("[Nova X] Failed to parse script from GitHub:", path, err)
            return nil
        end
        local ok2, result = pcall(fn)
        if not ok2 then
            warn("[Nova X] Failed to run script from GitHub:", path, result)
            return nil
        end
        return result
    end

    warn("[Nova X] Failed to load script:", path)
    return nil
end

local GAME_SCRIPTS = {
    SlimeRNG = "SlimeRNG.lua",
    Default = "SlimeRNG.lua"
}

local GAME_PLACE_MAP = {
    [92416421522960] = "SlimeRNG", -- Slime RNG place ID
}

local function get_script_key()
    local pid = game.PlaceId
    if GAME_PLACE_MAP[pid] then
        return GAME_PLACE_MAP[pid]
    end

    local name = tostring(game.Name or ""):lower()
    if name:find("slime") and name:find("rng") then
        return "SlimeRNG"
    end

    return "Default"
end

local function load_game_script(game_key)
    local path = GAME_SCRIPTS[game_key] or GAME_SCRIPTS.Default
    if not path then
        warn("[Nova X] No game script available for detected game:", tostring(game_key))
        return
    end

    local scriptModule = loadScript(path)
    if type(scriptModule) == "table" and type(scriptModule.Load) == "function" then
        pcall(scriptModule.Load)
        return
    end

    warn("[Nova X] Failed to load game module from", tostring(path))
end

local function ensureDiscordPrompt()
    local discordModule = loadScript("Discord.lua")
    if type(discordModule) == "table" and type(discordModule.CheckAndPrompt) == "function" then
        pcall(function()
            discordModule:CheckAndPrompt({
                name = "Nova X Discord",
                invite = "t28aPzKQrY",
            })
        end)
        return discordModule
    end

    warn("[Nova X] Discord module failed to load or does not support CheckAndPrompt")
    return nil
end

local function launchKeyUI()
    local uiModule = loadScript("Ui_loader.lua")
    if type(uiModule) ~= "table" or type(uiModule.CreateKeyUI) ~= "function" then
        warn("[Nova X] UI loader failed to initialize")
        return
    end

    uiModule:CreateKeyUI({
        ApiKey = "234f7b3d-7db1-477d-a9ad-0b5551d35354",
        Service = "Nova x",
        Provider = "Nova X",
        Discord = "https://discord.gg/t28aPzKQrY",
        OnSuccess = function()
            local gameKey = get_script_key()
            load_game_script(gameKey)
        end,
        OnFailed = function(msg)
            warn("[Nova X] Key verification failed:", tostring(msg))
        end,
    })
end

ensureDiscordPrompt()
launchKeyUI()

_G.NovaXInstance = true
return _G.NovaXInstance