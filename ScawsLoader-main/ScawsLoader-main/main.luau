local TweenService = game:GetService("TweenService")
local UserInputService = game:GetService("UserInputService")
local Players = game:GetService("Players")
local CoreGui = game:GetService("CoreGui")
local RunService = game:GetService("RunService")
local HttpService = game:GetService("HttpService")

local ScawsHub = {}
ScawsHub.__index = ScawsHub

local Config = {
    AnimationSpeed = 0.35,
    EasingStyle = Enum.EasingStyle.Quart,
    EasingDirection = Enum.EasingDirection.Out,

    Colors = {
        Background = Color3.fromRGB(0, 0, 0),
        Topbar = Color3.fromRGB(10, 10, 10),
        Sidebar = Color3.fromRGB(15, 15, 15),
        Main = Color3.fromRGB(20, 20, 20),
        Accent = Color3.fromRGB(200, 200, 200),
        AccentHover = Color3.fromRGB(180, 180, 180),
        Text = Color3.fromRGB(255, 255, 255),
        TextDark = Color3.fromRGB(150, 150, 150),
        Border = Color3.fromRGB(40, 40, 40),
        Success = Color3.fromRGB(34, 197, 94),
        Warning = Color3.fromRGB(250, 166, 26),
        Error = Color3.fromRGB(239, 68, 68),
    },

    WindowSize = UDim2.new(0, 520, 0, 380),
    SidebarWidth = 140,
    
    ConfigFolder = "ScawsHub",
    EnableSounds = false,
    EnableTooltips = true,
}

local SessionStartTime = tick()

-- Enhanced Utilities
local Utils = {}

function Utils:Tween(obj, properties, duration, callback)
    duration = duration or Config.AnimationSpeed
    local tween = TweenService:Create(
        obj,
        TweenInfo.new(duration, Enum.EasingStyle.Quart, Enum.EasingDirection.Out),
        properties
    )
    tween:Play()
    if callback then
        tween.Completed:Connect(callback)
    end
    return tween
end

function Utils:Spring(obj, properties, duration)
    duration = duration or 0.5
    local tween = TweenService:Create(
        obj,
        TweenInfo.new(duration, Enum.EasingStyle.Back, Enum.EasingDirection.Out),
        properties
    )
    tween:Play()
    return tween
end

function Utils:SmoothFade(obj, targetTransparency, duration)
    duration = duration or 0.25
    local tween = TweenService:Create(
        obj,
        TweenInfo.new(duration, Enum.EasingStyle.Quad, Enum.EasingDirection.InOut),
        {BackgroundTransparency = targetTransparency}
    )
    tween:Play()
    return tween
end

function Utils:IOSBounce(obj, properties, duration)
    duration = duration or 0.6
    local tween = TweenService:Create(
        obj,
        TweenInfo.new(duration, Enum.EasingStyle.Exponential, Enum.EasingDirection.Out),
        properties
    )
    tween:Play()
    return tween
end

function Utils:MakeDraggable(frame, handle)
    local dragging = false
    local dragInput, mousePos, framePos

    handle = handle or frame

    handle.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
            dragging = true
            mousePos = input.Position
            framePos = frame.Position
            
            input.Changed:Connect(function()
                if input.UserInputState == Enum.UserInputState.End then
                    dragging = false
                end
            end)
        end
    end)

    handle.InputChanged:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch then
            dragInput = input
        end
    end)

    UserInputService.InputChanged:Connect(function(input)
        if input == dragInput and dragging then
            local delta = input.Position - mousePos
            local tween = TweenService:Create(
                frame,
                TweenInfo.new(0.05, Enum.EasingStyle.Linear, Enum.EasingDirection.Out),
                {
                    Position = UDim2.new(
                        framePos.X.Scale,
                        framePos.X.Offset + delta.X,
                        framePos.Y.Scale,
                        framePos.Y.Offset + delta.Y
                    )
                }
            )
            tween:Play()
        end
    end)
end

function Utils:CreateCorner(parent, radius)
    local corner = Instance.new("UICorner")
    corner.CornerRadius = UDim.new(0, radius or 8)
    corner.Parent = parent
    return corner
end

function Utils:CreateStroke(parent, color, thickness)
    local stroke = Instance.new("UIStroke")
    stroke.Color = color or Config.Colors.Border
    stroke.Thickness = thickness or 1
    stroke.Transparency = 0.7
    stroke.ApplyStrokeMode = Enum.ApplyStrokeMode.Border
    stroke.Parent = parent
    return stroke
end

function Utils:FormatTime(seconds)
    local hours = math.floor(seconds / 3600)
    local mins = math.floor((seconds % 3600) / 60)
    local secs = math.floor(seconds % 60)
    return string.format("%02d:%02d:%02d", hours, mins, secs)
end

function Utils:PlaySound(soundId)
    if not Config.EnableSounds then return end
    local sound = Instance.new("Sound")
    sound.SoundId = soundId
    sound.Volume = 0.5
    sound.Parent = game:GetService("SoundService")
    sound:Play()
    sound.Ended:Connect(function()
        sound:Destroy()
    end)
end

function Utils:RGBToHex(color)
    return string.format("#%02X%02X%02X", 
        math.floor(color.R * 255),
        math.floor(color.G * 255),
        math.floor(color.B * 255)
    )
end

function Utils:HexToRGB(hex)
    hex = hex:gsub("#", "")
    return Color3.fromRGB(
        tonumber("0x"..hex:sub(1,2)),
        tonumber("0x"..hex:sub(3,4)),
        tonumber("0x"..hex:sub(5,6))
    )
end

-- FPS Counter
local FPSTracker = {
    lastUpdate = tick(),
    frameCount = 0,
    currentFPS = 60
}

RunService.RenderStepped:Connect(function()
    FPSTracker.frameCount = FPSTracker.frameCount + 1
    local now = tick()
    if now - FPSTracker.lastUpdate >= 1 then
        FPSTracker.currentFPS = FPSTracker.frameCount
        FPSTracker.frameCount = 0
        FPSTracker.lastUpdate = now
    end
end)

-- Ping Tracker
local PingTracker = {
    currentPing = 0
}

task.spawn(function()
    while true do
        local success, ping = pcall(function()
            return game:GetService("Stats").Network.ServerStatsItem["Data Ping"]:GetValue()
        end)
        if success then
            PingTracker.currentPing = math.floor(ping)
        end
        task.wait(1)
    end
end)

-- Tooltip System
local TooltipSystem = {}

function TooltipSystem:Create(parent)
    if not Config.EnableTooltips then return end
    
    local tooltip = parent:GetAttribute("Tooltip")
    if not tooltip then return end
    
    local TooltipGui = Instance.new("ScreenGui")
    TooltipGui.Name = "Tooltip"
    TooltipGui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
    TooltipGui.IgnoreGuiInset = true
    TooltipGui.DisplayOrder = 999
    
    if gethui then
        TooltipGui.Parent = gethui()
    else
        TooltipGui.Parent = CoreGui
    end
    
    local TooltipFrame = Instance.new("Frame")
    TooltipFrame.Size = UDim2.new(0, 0, 0, 0)
    TooltipFrame.BackgroundColor3 = Config.Colors.Background
    TooltipFrame.BackgroundTransparency = 0.1
    TooltipFrame.BorderSizePixel = 0
    TooltipFrame.Parent = TooltipGui
    Utils:CreateCorner(TooltipFrame, 6)
    Utils:CreateStroke(TooltipFrame, Config.Colors.Accent, 1)
    
    local TooltipText = Instance.new("TextLabel")
    TooltipText.Size = UDim2.new(1, -16, 1, -8)
    TooltipText.Position = UDim2.new(0, 8, 0, 4)
    TooltipText.BackgroundTransparency = 1
    TooltipText.Font = Enum.Font.Gotham
    TooltipText.Text = tooltip
    TooltipText.TextColor3 = Config.Colors.Text
    TooltipText.TextSize = 11
    TooltipText.TextXAlignment = Enum.TextXAlignment.Left
    TooltipText.Parent = TooltipFrame
    
    local textSize = game:GetService("TextService"):GetTextSize(
        tooltip, 11, Enum.Font.Gotham, Vector2.new(200, 1000)
    )
    
    local showing = false
    
    parent.MouseEnter:Connect(function()
        showing = true
        task.wait(0.5)
        if not showing then return end
        
        TooltipFrame.Size = UDim2.new(0, textSize.X + 16, 0, textSize.Y + 8)
        TooltipFrame.Position = UDim2.new(0, parent.AbsolutePosition.X, 0, parent.AbsolutePosition.Y + parent.AbsoluteSize.Y + 8)
        Utils:Spring(TooltipFrame, {BackgroundTransparency = 0.1}, 0.2)
    end)
    
    parent.MouseLeave:Connect(function()
        showing = false
        Utils:Tween(TooltipFrame, {BackgroundTransparency = 1, Size = UDim2.new(0, 0, 0, 0)}, 0.2)
    end)
    
    parent.MouseMoved:Connect(function(x, y)
        if showing then
            TooltipFrame.Position = UDim2.new(0, x + 15, 0, y + 15)
        end
    end)
end

-- Config Manager
local ConfigManager = {}

function ConfigManager:Save(name, data)
    local success, err = pcall(function()
        if not isfolder(Config.ConfigFolder) then
            makefolder(Config.ConfigFolder)
        end
        
        local json = HttpService:JSONEncode(data)
        writefile(Config.ConfigFolder .. "/" .. name .. ".json", json)
    end)
    
    return success
end

function ConfigManager:Load(name)
    local success, result = pcall(function()
        local path = Config.ConfigFolder .. "/" .. name .. ".json"
        if isfile(path) then
            local json = readfile(path)
            return HttpService:JSONDecode(json)
        end
        return nil
    end)
    
    return success and result or nil
end

function ConfigManager:Delete(name)
    local success = pcall(function()
        local path = Config.ConfigFolder .. "/" .. name .. ".json"
        if isfile(path) then
            delfile(path)
        end
    end)
    return success
end

function ConfigManager:List()
    local success, files = pcall(function()
        if not isfolder(Config.ConfigFolder) then
            return {}
        end
        return listfiles(Config.ConfigFolder)
    end)
    
    if success then
        local configs = {}
        for _, file in ipairs(files) do
            local name = file:match("([^/]+)%.json$")
            if name then
                table.insert(configs, name)
            end
        end
        return configs
    end
    
    return {}
end

-- Watermark
function ScawsHub:CreateWatermark(settings)
    settings = settings or {}
    local text = settings.Text or "ScawsHub | FPS: 60 | Ping: 0ms"
    local position = settings.Position or UDim2.new(0, 10, 0, 10)
    
    local WatermarkGui = Instance.new("ScreenGui")
    WatermarkGui.Name = "ScawsHub_Watermark"
    WatermarkGui.ResetOnSpawn = false
    WatermarkGui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
    WatermarkGui.IgnoreGuiInset = true
    WatermarkGui.DisplayOrder = 100
    
    if gethui then
        WatermarkGui.Parent = gethui()
    else
        WatermarkGui.Parent = CoreGui
    end
    
    local WatermarkFrame = Instance.new("Frame")
    WatermarkFrame.Size = UDim2.new(0, 200, 0, 32)
    WatermarkFrame.Position = position
    WatermarkFrame.BackgroundColor3 = Config.Colors.Background
    WatermarkFrame.BackgroundTransparency = 0.2
    WatermarkFrame.BorderSizePixel = 0
    WatermarkFrame.Parent = WatermarkGui
    Utils:CreateCorner(WatermarkFrame, 8)
    Utils:CreateStroke(WatermarkFrame, Config.Colors.Border, 1)
    
    local WatermarkText = Instance.new("TextLabel")
    WatermarkText.Size = UDim2.new(1, -16, 1, 0)
    WatermarkText.Position = UDim2.new(0, 8, 0, 0)
    WatermarkText.BackgroundTransparency = 1
    WatermarkText.Font = Enum.Font.GothamMedium
    WatermarkText.Text = text
    WatermarkText.TextColor3 = Config.Colors.Text
    WatermarkText.TextSize = 11
    WatermarkText.TextXAlignment = Enum.TextXAlignment.Left
    WatermarkText.Parent = WatermarkFrame
    
    Utils:MakeDraggable(WatermarkFrame)
    
    if settings.Dynamic then
        RunService.RenderStepped:Connect(function()
            local sessionTime = Utils:FormatTime(tick() - SessionStartTime)
            WatermarkText.Text = string.format(
                "ScawsHub | %s | FPS: %d | Ping: %dms",
                sessionTime,
                FPSTracker.currentFPS,
                PingTracker.currentPing
            )
            
            local textSize = game:GetService("TextService"):GetTextSize(
                WatermarkText.Text, 11, Enum.Font.GothamMedium, Vector2.new(1000, 32)
            )
            WatermarkFrame.Size = UDim2.new(0, textSize.X + 16, 0, 32)
        end)
    end
    
    return {
        Frame = WatermarkFrame,
        UpdateText = function(newText)
            WatermarkText.Text = newText
        end,
        Destroy = function()
            WatermarkGui:Destroy()
        end
    }
end

function ScawsHub:CreateLoadingScreen(settings)
    settings = settings or {}
    local imageId = "rbxassetid://119216623675384"
    local duration = settings.Duration or 3

    local LoadingGui = Instance.new("ScreenGui")
    LoadingGui.Name = "ScawsHub_Loading"
    LoadingGui.ResetOnSpawn = false
    LoadingGui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
    LoadingGui.IgnoreGuiInset = true

    if gethui then
        LoadingGui.Parent = gethui()
    elseif syn and syn.protect_gui then
        syn.protect_gui(LoadingGui)
        LoadingGui.Parent = CoreGui
    else
        LoadingGui.Parent = CoreGui
    end

    local Container = Instance.new("Frame")
    Container.Name = "Container"
    Container.Size = UDim2.new(1, 0, 1, 0)
    Container.BackgroundTransparency = 1
    Container.BorderSizePixel = 0
    Container.Parent = LoadingGui

    local ImageLabel = Instance.new("ImageLabel")
    ImageLabel.Name = "Logo"
    ImageLabel.AnchorPoint = Vector2.new(0.5, 0.5)
    ImageLabel.Position = UDim2.new(0.5, 0, 0.5, 0)
    ImageLabel.Size = UDim2.new(0, 250, 0, 250)
    ImageLabel.BackgroundTransparency = 1
    ImageLabel.Image = imageId
    ImageLabel.ImageTransparency = 1
    ImageLabel.ScaleType = Enum.ScaleType.Fit
    ImageLabel.Parent = Container

    Utils:IOSBounce(ImageLabel, {ImageTransparency = 0, Size = UDim2.new(0, 350, 0, 350)}, 1)

    task.wait(duration)

    Utils:Tween(ImageLabel, {ImageTransparency = 1, Size = UDim2.new(0, 400, 0, 400)}, 0.5, function()
        task.wait(0.1)
        LoadingGui:Destroy()
    end)
end

function ScawsHub:CreateWindow(settings)
    settings = settings or {}
    local windowTitle = settings.Name or "ScawsHUB"
    local showLoading = settings.ShowLoading ~= false
    local configSupport = settings.ConfigSupport ~= false

    if showLoading then
        self:CreateLoadingScreen({
            Duration = settings.LoadingDuration or 3
        })
    end

    local MainGui = Instance.new("ScreenGui")
    MainGui.Name = "ScawsHub_Main"
    MainGui.ResetOnSpawn = false
    MainGui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
    MainGui.IgnoreGuiInset = true

    if gethui then
        MainGui.Parent = gethui()
    elseif syn and syn.protect_gui then
        syn.protect_gui(MainGui)
        MainGui.Parent = CoreGui
    else
        MainGui.Parent = CoreGui
    end

    local Main = Instance.new("Frame")
    Main.Name = "Main"
    Main.AnchorPoint = Vector2.new(0.5, 0.5)
    Main.Position = UDim2.new(0.5, 0, 0.5, 0)
    Main.Size = UDim2.new(0, 0, 0, 0)
    Main.BackgroundColor3 = Config.Colors.Background
    Main.BackgroundTransparency = 0.15
    Main.BorderSizePixel = 0
    Main.ClipsDescendants = true
    Main.Parent = MainGui
    Utils:CreateCorner(Main, 14)
    Utils:CreateStroke(Main, Config.Colors.Border, 1)

    Utils:IOSBounce(Main, {Size = Config.WindowSize}, 0.7)

    local Shadow = Instance.new("ImageLabel")
    Shadow.Name = "Shadow"
    Shadow.AnchorPoint = Vector2.new(0.5, 0.5)
    Shadow.Position = UDim2.new(0.5, 0, 0.5, 0)
    Shadow.Size = UDim2.new(1, 50, 1, 50)
    Shadow.BackgroundTransparency = 1
    Shadow.Image = "rbxassetid://5554236805"
    Shadow.ImageColor3 = Color3.fromRGB(0, 0, 0)
    Shadow.ImageTransparency = 0.3
    Shadow.ZIndex = 0
    Shadow.Parent = Main

    local Topbar = Instance.new("Frame")
    Topbar.Name = "Topbar"
    Topbar.Size = UDim2.new(1, 0, 0, 45)
    Topbar.BackgroundColor3 = Config.Colors.Topbar
    Topbar.BackgroundTransparency = 0.15
    Topbar.BorderSizePixel = 0
    Topbar.Parent = Main
    
    local TopbarCorner = Instance.new("UICorner")
    TopbarCorner.CornerRadius = UDim.new(0, 14)
    TopbarCorner.Parent = Topbar

    local TopbarGradient = Instance.new("Frame")
    TopbarGradient.Size = UDim2.new(1, 0, 1, 0)
    TopbarGradient.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
    TopbarGradient.BackgroundTransparency = 0.95
    TopbarGradient.BorderSizePixel = 0
    TopbarGradient.Parent = Topbar
    
    local TopbarGradientCorner = Instance.new("UICorner")
    TopbarGradientCorner.CornerRadius = UDim.new(0, 14)
    TopbarGradientCorner.Parent = TopbarGradient
    
    local TopbarGradientEffect = Instance.new("UIGradient")
    TopbarGradientEffect.Rotation = 90
    TopbarGradientEffect.Transparency = NumberSequence.new({
        NumberSequenceKeypoint.new(0, 0.9),
        NumberSequenceKeypoint.new(0.5, 0.95),
        NumberSequenceKeypoint.new(1, 1)
    })
    TopbarGradientEffect.Parent = TopbarGradient

    local TitleLabel = Instance.new("TextLabel")
    TitleLabel.Name = "Title"
    TitleLabel.Size = UDim2.new(0, 180, 1, -5)
    TitleLabel.Position = UDim2.new(0, 16, 0, -5)
    TitleLabel.BackgroundTransparency = 1
    TitleLabel.Font = Enum.Font.GothamBold
    TitleLabel.Text = windowTitle
    TitleLabel.TextColor3 = Config.Colors.Text
    TitleLabel.TextSize = 16
    TitleLabel.TextXAlignment = Enum.TextXAlignment.Left
    TitleLabel.ZIndex = 2
    TitleLabel.Parent = Topbar

    local CreditsLabel = Instance.new("TextLabel")
    CreditsLabel.Name = "Credits"
    CreditsLabel.Size = UDim2.new(0, 100, 1, 0)
    CreditsLabel.Position = UDim2.new(0, 16, 0, 13)
    CreditsLabel.BackgroundTransparency = 1
    CreditsLabel.Font = Enum.Font.Gotham
    CreditsLabel.Text = "by ScawsHub"
    CreditsLabel.TextColor3 = Config.Colors.TextDark
    CreditsLabel.TextSize = 9
    CreditsLabel.TextXAlignment = Enum.TextXAlignment.Left
    CreditsLabel.TextTransparency = 0.3
    CreditsLabel.ZIndex = 2
    CreditsLabel.Parent = Topbar

    local CloseButton = Instance.new("TextButton")
    CloseButton.Name = "CloseButton"
    CloseButton.AnchorPoint = Vector2.new(1, 0.5)
    CloseButton.Position = UDim2.new(1, -8, 0.5, 0)
    CloseButton.Size = UDim2.new(0, 28, 0, 28)
    CloseButton.BackgroundColor3 = Config.Colors.Border
    CloseButton.BackgroundTransparency = 0.3
    CloseButton.BorderSizePixel = 0
    CloseButton.Font = Enum.Font.GothamBold
    CloseButton.Text = "×"
    CloseButton.TextColor3 = Config.Colors.Text
    CloseButton.TextSize = 18
    CloseButton.ZIndex = 2
    CloseButton.Parent = Topbar
    Utils:CreateCorner(CloseButton, 14)

    local MinimizeButton = Instance.new("TextButton")
    MinimizeButton.Name = "MinimizeButton"
    MinimizeButton.AnchorPoint = Vector2.new(1, 0.5)
    MinimizeButton.Position = UDim2.new(1, -40, 0.5, 0)
    MinimizeButton.Size = UDim2.new(0, 28, 0, 28)
    MinimizeButton.BackgroundColor3 = Config.Colors.Border
    MinimizeButton.BackgroundTransparency = 0.3
    MinimizeButton.BorderSizePixel = 0
    MinimizeButton.Font = Enum.Font.GothamBold
    MinimizeButton.Text = "−"
    MinimizeButton.TextColor3 = Config.Colors.Text
    MinimizeButton.TextSize = 16
    MinimizeButton.ZIndex = 2
    MinimizeButton.Parent = Topbar
    Utils:CreateCorner(MinimizeButton, 14)

    local player = Players.LocalPlayer
    local AvatarButton = Instance.new("ImageButton")
    AvatarButton.Name = "AvatarButton"
    AvatarButton.AnchorPoint = Vector2.new(1, 0.5)
    AvatarButton.Position = UDim2.new(1, -72, 0.5, 0)
    AvatarButton.Size = UDim2.new(0, 28, 0, 28)
    AvatarButton.BackgroundColor3 = Config.Colors.Border
    AvatarButton.BackgroundTransparency = 0.3
    AvatarButton.BorderSizePixel = 0
    AvatarButton.Image = "rbxthumb://type=AvatarHeadShot&id=" .. player.UserId .. "&w=150&h=150"
    AvatarButton.ZIndex = 2
    AvatarButton.Parent = Topbar
    Utils:CreateCorner(AvatarButton, 14)

    local PlayerInfoFrame = Instance.new("Frame")
    PlayerInfoFrame.Name = "PlayerInfo"
    PlayerInfoFrame.Size = UDim2.new(0, 0, 0, 0)
    PlayerInfoFrame.BackgroundColor3 = Config.Colors.Background
    PlayerInfoFrame.BackgroundTransparency = 1
    PlayerInfoFrame.BorderSizePixel = 0
    PlayerInfoFrame.Visible = false
    PlayerInfoFrame.ZIndex = 1000
    PlayerInfoFrame.ClipsDescendants = true
    PlayerInfoFrame.Parent = MainGui
    Utils:CreateCorner(PlayerInfoFrame, 12)
    
    local InfoStroke = Utils:CreateStroke(PlayerInfoFrame, Config.Colors.Accent, 1)
    InfoStroke.Transparency = 1

    local PlayerInfoLayout = Instance.new("UIPadding")
    PlayerInfoLayout.PaddingLeft = UDim.new(0, 14)
    PlayerInfoLayout.PaddingRight = UDim.new(0, 14)
    PlayerInfoLayout.PaddingTop = UDim.new(0, 12)
    PlayerInfoLayout.PaddingBottom = UDim.new(0, 12)
    PlayerInfoLayout.Parent = PlayerInfoFrame

    local InfoHeader = Instance.new("TextLabel")
    InfoHeader.Size = UDim2.new(1, 0, 0, 18)
    InfoHeader.Position = UDim2.new(0, 0, 0, 0)
    InfoHeader.BackgroundTransparency = 1
    InfoHeader.Font = Enum.Font.GothamBold
    InfoHeader.Text = "PLAYER INFO"
    InfoHeader.TextColor3 = Config.Colors.Accent
    InfoHeader.TextSize = 11
    InfoHeader.TextXAlignment = Enum.TextXAlignment.Left
    InfoHeader.TextTransparency = 1
    InfoHeader.Parent = PlayerInfoFrame

    local Divider = Instance.new("Frame")
    Divider.Size = UDim2.new(1, 0, 0, 1)
    Divider.Position = UDim2.new(0, 0, 0, 22)
    Divider.BackgroundColor3 = Config.Colors.Border
    Divider.BackgroundTransparency = 1
    Divider.BorderSizePixel = 0
    Divider.Parent = PlayerInfoFrame

    local UsernameLabel = Instance.new("TextLabel")
    UsernameLabel.Size = UDim2.new(1, 0, 0, 14)
    UsernameLabel.Position = UDim2.new(0, 0, 0, 28)
    UsernameLabel.BackgroundTransparency = 1
    UsernameLabel.Font = Enum.Font.GothamBold
    UsernameLabel.Text = "Username: " .. player.Name
    UsernameLabel.TextColor3 = Config.Colors.Text
    UsernameLabel.TextSize = 11
    UsernameLabel.TextXAlignment = Enum.TextXAlignment.Left
    UsernameLabel.TextTransparency = 1
    UsernameLabel.Parent = PlayerInfoFrame

    local OwnerLabel = Instance.new("TextLabel")
    OwnerLabel.Size = UDim2.new(1, 0, 0, 12)
    OwnerLabel.Position = UDim2.new(0, 0, 0, 44)
    OwnerLabel.BackgroundTransparency = 1
    OwnerLabel.Font = Enum.Font.GothamMedium
    OwnerLabel.Text = ""
    OwnerLabel.TextColor3 = Config.Colors.Accent
    OwnerLabel.TextSize = 9
    OwnerLabel.TextXAlignment = Enum.TextXAlignment.Left
    OwnerLabel.TextTransparency = 1
    OwnerLabel.Parent = PlayerInfoFrame
    
    if player.Name == "6r5lo" then
        OwnerLabel.Text = "Owner of ScawsHub"
    end

    local UserIdLabel = Instance.new("TextLabel")
    UserIdLabel.Size = UDim2.new(1, 0, 0, 14)
    UserIdLabel.Position = UDim2.new(0, 0, 0, 62)
    UserIdLabel.BackgroundTransparency = 1
    UserIdLabel.Font = Enum.Font.Gotham
    UserIdLabel.Text = "User ID: " .. player.UserId
    UserIdLabel.TextColor3 = Config.Colors.TextDark
    UserIdLabel.TextSize = 10
    UserIdLabel.TextXAlignment = Enum.TextXAlignment.Left
    UserIdLabel.TextTransparency = 1
    UserIdLabel.Parent = PlayerInfoFrame

    local AccountAgeLabel = Instance.new("TextLabel")
    AccountAgeLabel.Size = UDim2.new(1, 0, 0, 14)
    AccountAgeLabel.Position = UDim2.new(0, 0, 0, 78)
    AccountAgeLabel.BackgroundTransparency = 1
    AccountAgeLabel.Font = Enum.Font.Gotham
    AccountAgeLabel.Text = "Account Age: " .. player.AccountAge .. " days"
    AccountAgeLabel.TextColor3 = Config.Colors.TextDark
    AccountAgeLabel.TextSize = 10
    AccountAgeLabel.TextXAlignment = Enum.TextXAlignment.Left
    AccountAgeLabel.TextTransparency = 1
    AccountAgeLabel.Parent = PlayerInfoFrame

    local JobIdLabel = Instance.new("TextLabel")
    JobIdLabel.Size = UDim2.new(1, 0, 0, 14)
    JobIdLabel.Position = UDim2.new(0, 0, 0, 94)
    JobIdLabel.BackgroundTransparency = 1
    JobIdLabel.Font = Enum.Font.Gotham
    JobIdLabel.Text = "Job ID: " .. game.JobId:sub(1, 8) .. "..."
    JobIdLabel.TextColor3 = Config.Colors.TextDark
    JobIdLabel.TextSize = 10
    JobIdLabel.TextXAlignment = Enum.TextXAlignment.Left
    JobIdLabel.TextTransparency = 1
    JobIdLabel.Parent = PlayerInfoFrame

    local SessionLabel = Instance.new("TextLabel")
    SessionLabel.Size = UDim2.new(1, 0, 0, 14)
    SessionLabel.Position = UDim2.new(0, 0, 0, 110)
    SessionLabel.BackgroundTransparency = 1
    SessionLabel.Font = Enum.Font.Gotham
    SessionLabel.Text = "Session Time: 00:00:00"
    SessionLabel.TextColor3 = Config.Colors.TextDark
    SessionLabel.TextSize = 10
    SessionLabel.TextXAlignment = Enum.TextXAlignment.Left
    SessionLabel.TextTransparency = 1
    SessionLabel.Parent = PlayerInfoFrame

    local PingLabel = Instance.new("TextLabel")
    PingLabel.Size = UDim2.new(0.5, -5, 0, 14)
    PingLabel.Position = UDim2.new(0, 0, 0, 126)
    PingLabel.BackgroundTransparency = 1
    PingLabel.Font = Enum.Font.Gotham
    PingLabel.Text = "Ping: " .. PingTracker.currentPing .. "ms"
    PingLabel.TextColor3 = Config.Colors.Warning
    PingLabel.TextSize = 10
    PingLabel.TextXAlignment = Enum.TextXAlignment.Left
    PingLabel.TextTransparency = 1
    PingLabel.Parent = PlayerInfoFrame

    local FPSLabel = Instance.new("TextLabel")
    FPSLabel.Size = UDim2.new(0.5, -5, 0, 14)
    FPSLabel.Position = UDim2.new(0.5, 5, 0, 126)
    FPSLabel.BackgroundTransparency = 1
    FPSLabel.Font = Enum.Font.Gotham
    FPSLabel.Text = "FPS: " .. FPSTracker.currentFPS
    FPSLabel.TextColor3 = Config.Colors.Success
    FPSLabel.TextSize = 10
    FPSLabel.TextXAlignment = Enum.TextXAlignment.Left
    FPSLabel.TextTransparency = 1
    FPSLabel.Parent = PlayerInfoFrame

    local statsConnection
    local allInfoLabels = {
        InfoHeader, UsernameLabel, OwnerLabel, UserIdLabel, 
        AccountAgeLabel, JobIdLabel, SessionLabel, PingLabel, FPSLabel
    }

    local function FadeInInfo()
        PlayerInfoFrame.Visible = true
        Utils:Spring(PlayerInfoFrame, {
            BackgroundTransparency = 0.1, 
            Size = UDim2.new(0, 220, 0, 155)
        }, 0.35)
        Utils:Tween(InfoStroke, {Transparency = 0.3}, 0.35)
        Utils:Tween(Divider, {BackgroundTransparency = 0.7}, 0.35)
        
        for i, label in ipairs(allInfoLabels) do
            task.spawn(function()
                task.wait(i * 0.03)
                Utils:Tween(label, {TextTransparency = 0}, 0.25)
            end)
        end
    end

    local function FadeOutInfo()
        for _, label in ipairs(allInfoLabels) do
            Utils:Tween(label, {TextTransparency = 1}, 0.2)
        end
        
        Utils:Tween(InfoStroke, {Transparency = 1}, 0.2)
        Utils:Tween(Divider, {BackgroundTransparency = 1}, 0.2)
        Utils:Spring(PlayerInfoFrame, {
            BackgroundTransparency = 1, 
            Size = UDim2.new(0, 220, 0, 0)
        }, 0.3)
        
        task.wait(0.35)
        PlayerInfoFrame.Visible = false
    end

    AvatarButton.MouseEnter:Connect(function()
        FadeInInfo()
        Utils:SmoothFade(AvatarButton, 0.1, 0.2)
        
        statsConnection = RunService.RenderStepped:Connect(function()
            local sessionTime = tick() - SessionStartTime
            SessionLabel.Text = "Session Time: " .. Utils:FormatTime(sessionTime)
            FPSLabel.Text = "FPS: " .. FPSTracker.currentFPS
            PingLabel.Text = "Ping: " .. PingTracker.currentPing .. "ms"
            
            if FPSTracker.currentFPS >= 60 then
                FPSLabel.TextColor3 = Config.Colors.Success
            elseif FPSTracker.currentFPS >= 30 then
                FPSLabel.TextColor3 = Config.Colors.Warning
            else
                FPSLabel.TextColor3 = Config.Colors.Error
            end
            
            if PingTracker.currentPing <= 100 then
                PingLabel.TextColor3 = Config.Colors.Success
            elseif PingTracker.currentPing <= 200 then
                PingLabel.TextColor3 = Config.Colors.Warning
            else
                PingLabel.TextColor3 = Config.Colors.Error
            end
        end)
    end)

    AvatarButton.MouseLeave:Connect(function()
        FadeOutInfo()
        Utils:SmoothFade(AvatarButton, 0.3, 0.2)
        
        if statsConnection then
            statsConnection:Disconnect()
            statsConnection = nil
        end
    end)

    AvatarButton.MouseMoved:Connect(function(x, y)
        if PlayerInfoFrame.Visible then
            PlayerInfoFrame.Position = UDim2.new(0, x - PlayerInfoFrame.AbsoluteSize.X - 15, 0, y - 80)
        end
    end)

    local Sidebar = Instance.new("Frame")
    Sidebar.Name = "Sidebar"
    Sidebar.Position = UDim2.new(0, 0, 0, 45)
    Sidebar.Size = UDim2.new(0, Config.SidebarWidth, 1, -45)
    Sidebar.BackgroundColor3 = Config.Colors.Sidebar
    Sidebar.BackgroundTransparency = 0.15
    Sidebar.BorderSizePixel = 0
    Sidebar.ClipsDescendants = true
    Sidebar.Parent = Main
    
    local SidebarCorner = Instance.new("UICorner")
    SidebarCorner.CornerRadius = UDim.new(0, 14)
    SidebarCorner.Parent = Sidebar
    
    local SidebarTopCover = Instance.new("Frame")
    SidebarTopCover.Size = UDim2.new(1, 0, 0, 14)
    SidebarTopCover.Position = UDim2.new(0, 0, 0, 0)
    SidebarTopCover.BackgroundColor3 = Config.Colors.Sidebar
    SidebarTopCover.BackgroundTransparency = 0.15
    SidebarTopCover.BorderSizePixel = 0
    SidebarTopCover.Parent = Sidebar

    local Separator = Instance.new("Frame")
    Separator.Name = "Separator"
    Separator.Position = UDim2.new(1, 0, 0, 0)
    Separator.Size = UDim2.new(0, 1, 1, 0)
    Separator.BackgroundColor3 = Config.Colors.Border
    Separator.BackgroundTransparency = 0.5
    Separator.BorderSizePixel = 0
    Separator.Parent = Sidebar

    local TabContainer = Instance.new("ScrollingFrame")
    TabContainer.Name = "TabContainer"
    TabContainer.Size = UDim2.new(1, -10, 1, -14)
    TabContainer.Position = UDim2.new(0, 5, 0, 7)
    TabContainer.BackgroundTransparency = 1
    TabContainer.BorderSizePixel = 0
    TabContainer.ScrollBarThickness = 3
    TabContainer.ScrollBarImageColor3 = Config.Colors.Accent
    TabContainer.ScrollBarImageTransparency = 0.5
    TabContainer.CanvasSize = UDim2.new(0, 0, 0, 0)
    TabContainer.Parent = Sidebar

    local TabLayout = Instance.new("UIListLayout")
    TabLayout.SortOrder = Enum.SortOrder.LayoutOrder
    TabLayout.Padding = UDim.new(0, 6)
    TabLayout.Parent = TabContainer

    TabLayout:GetPropertyChangedSignal("AbsoluteContentSize"):Connect(function()
        TabContainer.CanvasSize = UDim2.new(0, 0, 0, TabLayout.AbsoluteContentSize.Y + 10)
    end)

    local ContentArea = Instance.new("Frame")
    ContentArea.Name = "ContentArea"
    ContentArea.Position = UDim2.new(0, Config.SidebarWidth, 0, 45)
    ContentArea.Size = UDim2.new(1, -Config.SidebarWidth, 1, -45)
    ContentArea.BackgroundColor3 = Config.Colors.Main
    ContentArea.BackgroundTransparency = 0.15
    ContentArea.BorderSizePixel = 0
    ContentArea.ClipsDescendants = true
    ContentArea.Parent = Main
    
    local ContentCorner = Instance.new("UICorner")
    ContentCorner.CornerRadius = UDim.new(0, 14)
    ContentCorner.Parent = ContentArea
    
    local ContentTopCover = Instance.new("Frame")
    ContentTopCover.Size = UDim2.new(0, 14, 0, 14)
    ContentTopCover.Position = UDim2.new(0, 0, 0, 0)
    ContentTopCover.BackgroundColor3 = Config.Colors.Main
    ContentTopCover.BackgroundTransparency = 0.15
    ContentTopCover.BorderSizePixel = 0
    ContentTopCover.Parent = ContentArea
    
    local ContentTopRightCover = Instance.new("Frame")
    ContentTopRightCover.Size = UDim2.new(0, 14, 0, 14)
    ContentTopRightCover.Position = UDim2.new(1, -14, 0, 0)
    ContentTopRightCover.BackgroundColor3 = Config.Colors.Main
    ContentTopRightCover.BackgroundTransparency = 0.15
    ContentTopRightCover.BorderSizePixel = 0
    ContentTopRightCover.Parent = ContentArea

    Utils:MakeDraggable(Main, Topbar)

    local Window = {
        Gui = MainGui,
        Main = Main,
        Topbar = Topbar,
        Sidebar = Sidebar,
        TabContainer = TabContainer,
        ContentArea = ContentArea,
        Tabs = {},
        CurrentTab = nil,
        Visible = true,
        Minimized = false,
        IsTransitioning = false,
        ConfigData = {},
    }

    CloseButton.MouseButton1Click:Connect(function()
        Utils:Spring(CloseButton, {Size = UDim2.new(0, 24, 0, 24)}, 0.1)
        task.wait(0.06)
        Utils:Spring(CloseButton, {Size = UDim2.new(0, 28, 0, 28)}, 0.15)
        
        local closeTween = TweenService:Create(
            Main,
            TweenInfo.new(0.5, Enum.EasingStyle.Back, Enum.EasingDirection.In),
            {Size = UDim2.new(0, 0, 0, 0)}
        )
        closeTween:Play()
        closeTween.Completed:Connect(function()
            MainGui:Destroy()
        end)
    end)

    MinimizeButton.MouseButton1Click:Connect(function()
        Utils:Spring(MinimizeButton, {Size = UDim2.new(0, 24, 0, 24)}, 0.1)
        task.wait(0.06)
        Utils:Spring(MinimizeButton, {Size = UDim2.new(0, 28, 0, 28)}, 0.15)
        
        Window.Minimized = not Window.Minimized
        if Window.Minimized then
            MinimizeButton.Text = "+"
            local minTween = TweenService:Create(
                Main,
                TweenInfo.new(0.4, Enum.EasingStyle.Exponential, Enum.EasingDirection.Out),
                {Size = UDim2.new(0, Config.WindowSize.X.Offset, 0, 45)}
            )
            minTween:Play()
        else
            MinimizeButton.Text = "−"
            local maxTween = TweenService:Create(
                Main,
                TweenInfo.new(0.4, Enum.EasingStyle.Exponential, Enum.EasingDirection.Out),
                {Size = Config.WindowSize}
            )
            maxTween:Play()
        end
    end)

    CloseButton.MouseEnter:Connect(function()
        Utils:SmoothFade(CloseButton, 0.1, 0.2)
    end)
    CloseButton.MouseLeave:Connect(function()
        Utils:SmoothFade(CloseButton, 0.3, 0.2)
    end)

    MinimizeButton.MouseEnter:Connect(function()
        Utils:SmoothFade(MinimizeButton, 0.1, 0.2)
    end)
    MinimizeButton.MouseLeave:Connect(function()
        Utils:SmoothFade(MinimizeButton, 0.3, 0.2)
    end)

    function Window:CreateTab(name, icon)
        local Tab = {}
        Tab.Name = name
        Tab.Button = nil
        Tab.Content = nil
        Tab.Elements = {}
        
        local TabButton = Instance.new("TextButton")
        TabButton.Name = name
        TabButton.Size = UDim2.new(1, -10, 0, 34)
        TabButton.BackgroundColor3 = Config.Colors.Accent
        TabButton.BackgroundTransparency = 1
        TabButton.BorderSizePixel = 0
        TabButton.Font = Enum.Font.GothamSemibold
        TabButton.Text = "  " .. name
        TabButton.TextColor3 = Config.Colors.TextDark
        TabButton.TextSize = 13
        TabButton.TextXAlignment = Enum.TextXAlignment.Left
        TabButton.ZIndex = 2
        TabButton.Parent = TabContainer
        
        Tab.Button = TabButton
        
        local TabContent = Instance.new("ScrollingFrame")
        TabContent.Name = name .. "_Content"
        TabContent.Size = UDim2.new(1, -20, 1, -20)
        TabContent.Position = UDim2.new(0, 10, 0, 10)
        TabContent.BackgroundTransparency = 1
        TabContent.BorderSizePixel = 0
        TabContent.ScrollBarThickness = 3
        TabContent.ScrollBarImageColor3 = Config.Colors.Accent
        TabContent.ScrollBarImageTransparency = 0.5
        TabContent.CanvasSize = UDim2.new(0, 0, 0, 0)
        TabContent.Visible = false
        TabContent.Parent = ContentArea
        
        local ContentLayout = Instance.new("UIListLayout")
        ContentLayout.SortOrder = Enum.SortOrder.LayoutOrder
        ContentLayout.Padding = UDim.new(0, 8)
        ContentLayout.Parent = TabContent
        
        ContentLayout:GetPropertyChangedSignal("AbsoluteContentSize"):Connect(function()
            TabContent.CanvasSize = UDim2.new(0, 0, 0, ContentLayout.AbsoluteContentSize.Y + 16)
        end)
        
        Tab.Content = TabContent
        
        TabButton.MouseButton1Click:Connect(function()
            Window:SelectTab(Tab)
        end)
        
        TabButton.MouseEnter:Connect(function()
            if Window.CurrentTab ~= Tab then
                Utils:SmoothFade(TabButton, 0.8, 0.2)
            end
        end)
        
        TabButton.MouseLeave:Connect(function()
            if Window.CurrentTab ~= Tab then
                Utils:SmoothFade(TabButton, 1, 0.2)
            end
        end)
        
        table.insert(Window.Tabs, Tab)
        
        if #Window.Tabs == 1 then
            Window:SelectTab(Tab)
        end
        
        function Tab:CreateSection(name)
            local SectionFrame = Instance.new("Frame")
            SectionFrame.Size = UDim2.new(1, -6, 0, 30)
            SectionFrame.BackgroundTransparency = 1
            SectionFrame.Parent = TabContent
            
            local SectionLine = Instance.new("Frame")
            SectionLine.Size = UDim2.new(0, 3, 1, -8)
            SectionLine.Position = UDim2.new(0, 0, 0, 4)
            SectionLine.BackgroundColor3 = Config.Colors.Accent
            SectionLine.BorderSizePixel = 0
            SectionLine.Parent = SectionFrame
            Utils:CreateCorner(SectionLine, 2)
            
            local SectionLabel = Instance.new("TextLabel")
            SectionLabel.Size = UDim2.new(1, -12, 1, 0)
            SectionLabel.Position = UDim2.new(0, 12, 0, 0)
            SectionLabel.BackgroundTransparency = 1
            SectionLabel.Font = Enum.Font.GothamBold
            SectionLabel.Text = name
            SectionLabel.TextColor3 = Config.Colors.Text
            SectionLabel.TextSize = 14
            SectionLabel.TextXAlignment = Enum.TextXAlignment.Left
            SectionLabel.Parent = SectionFrame
            
            return SectionFrame
        end
        
        function Tab:CreateDivider()
            local DividerFrame = Instance.new("Frame")
            DividerFrame.Size = UDim2.new(1, -6, 0, 8)
            DividerFrame.BackgroundTransparency = 1
            DividerFrame.Parent = TabContent
            
            local Line = Instance.new("Frame")
            Line.Size = UDim2.new(1, -20, 0, 1)
            Line.Position = UDim2.new(0, 10, 0.5, 0)
            Line.BackgroundColor3 = Config.Colors.Border
            Line.BackgroundTransparency = 0.5
            Line.BorderSizePixel = 0
            Line.Parent = DividerFrame
            
            return DividerFrame
        end
        
        function Tab:CreateButton(settings)
            settings = settings or {}
            local buttonName = settings.Name or "Button"
            local callback = settings.Callback or function() end
            
            local ButtonFrame = Instance.new("Frame")
            ButtonFrame.Name = buttonName
            ButtonFrame.Size = UDim2.new(1, -6, 0, 38)
            ButtonFrame.BackgroundColor3 = Config.Colors.Background
            ButtonFrame.BackgroundTransparency = 0.6
            ButtonFrame.BorderSizePixel = 0
            ButtonFrame.Parent = TabContent
            Utils:CreateCorner(ButtonFrame, 8)
            Utils:CreateStroke(ButtonFrame, Config.Colors.Border, 1)
            
            if settings.Tooltip then
                ButtonFrame:SetAttribute("Tooltip", settings.Tooltip)
                TooltipSystem:Create(ButtonFrame)
            end
            
            local Button = Instance.new("TextButton")
            Button.Size = UDim2.new(1, -16, 1, -6)
            Button.Position = UDim2.new(0, 8, 0, 3)
            Button.BackgroundTransparency = 1
            Button.Font = Enum.Font.GothamSemibold
            Button.Text = buttonName
            Button.TextColor3 = Config.Colors.Text
            Button.TextSize = 13
            Button.TextXAlignment = Enum.TextXAlignment.Left
            Button.Parent = ButtonFrame
            
            Button.MouseButton1Click:Connect(function()
                Utils:Spring(ButtonFrame, {BackgroundColor3 = Config.Colors.Accent, BackgroundTransparency = 0.2}, 0.1)
                task.wait(0.08)
                Utils:Spring(ButtonFrame, {BackgroundColor3 = Config.Colors.Background, BackgroundTransparency = 0.6}, 0.15)
                callback()
            end)
            
            Button.MouseEnter:Connect(function()
                Utils:SmoothFade(ButtonFrame, 0.4, 0.2)
            end)
            
            Button.MouseLeave:Connect(function()
                Utils:SmoothFade(ButtonFrame, 0.6, 0.2)
            end)
            
            return ButtonFrame
        end
        
        function Tab:CreateToggle(settings)
            settings = settings or {}
            local toggleName = settings.Name or "Toggle"
            local default = settings.Default or false
            local callback = settings.Callback or function() end
            
            local ToggleFrame = Instance.new("Frame")
            ToggleFrame.Name = toggleName
            ToggleFrame.Size = UDim2.new(1, -6, 0, 38)
            ToggleFrame.BackgroundColor3 = Config.Colors.Background
            ToggleFrame.BackgroundTransparency = 0.6
            ToggleFrame.BorderSizePixel = 0
            ToggleFrame.Parent = TabContent
            Utils:CreateCorner(ToggleFrame, 8)
            Utils:CreateStroke(ToggleFrame, Config.Colors.Border, 1)
            
            if settings.Tooltip then
                ToggleFrame:SetAttribute("Tooltip", settings.Tooltip)
                TooltipSystem:Create(ToggleFrame)
            end
            
            local Label = Instance.new("TextLabel")
            Label.Size = UDim2.new(1, -60, 1, 0)
            Label.Position = UDim2.new(0, 12, 0, 0)
            Label.BackgroundTransparency = 1
            Label.Font = Enum.Font.GothamSemibold
            Label.Text = toggleName
            Label.TextColor3 = Config.Colors.Text
            Label.TextSize = 13
            Label.TextXAlignment = Enum.TextXAlignment.Left
            Label.Parent = ToggleFrame
            
            local ToggleButton = Instance.new("TextButton")
            ToggleButton.AnchorPoint = Vector2.new(1, 0.5)
            ToggleButton.Position = UDim2.new(1, -12, 0.5, 0)
            ToggleButton.Size = UDim2.new(0, 42, 0, 22)
            ToggleButton.BackgroundColor3 = Config.Colors.Border
            ToggleButton.BackgroundTransparency = 0.2
            ToggleButton.BorderSizePixel = 0
            ToggleButton.Text = ""
            ToggleButton.Parent = ToggleFrame
            Utils:CreateCorner(ToggleButton, 11)
            
            local ToggleIndicator = Instance.new("Frame")
            ToggleIndicator.Size = UDim2.new(0, 16, 0, 16)
            ToggleIndicator.Position = UDim2.new(0, 3, 0.5, -8)
            ToggleIndicator.BackgroundColor3 = Config.Colors.TextDark
            ToggleIndicator.BorderSizePixel = 0
            ToggleIndicator.Parent = ToggleButton
            Utils:CreateCorner(ToggleIndicator, 8)
            
            local toggled = default
            
            local function UpdateToggle()
                if toggled then
                    Utils:Spring(ToggleButton, {BackgroundColor3 = Color3.fromRGB(120, 120, 120), BackgroundTransparency = 0}, 0.25)
                    Utils:Spring(ToggleIndicator, {Position = UDim2.new(1, -19, 0.5, -8), BackgroundColor3 = Config.Colors.Text}, 0.25)
                else
                    Utils:Spring(ToggleButton, {BackgroundColor3 = Config.Colors.Border, BackgroundTransparency = 0.2}, 0.25)
                    Utils:Spring(ToggleIndicator, {Position = UDim2.new(0, 3, 0.5, -8), BackgroundColor3 = Config.Colors.TextDark}, 0.25)
                end
                callback(toggled)
                Window.ConfigData[toggleName] = toggled
            end
            
            ToggleButton.MouseButton1Click:Connect(function()
                toggled = not toggled
                UpdateToggle()
            end)
            
            UpdateToggle()
            
            return {
                Frame = ToggleFrame,
                SetValue = function(value)
                    toggled = value
                    UpdateToggle()
                end,
                GetValue = function()
                    return toggled
                end
            }
        end
        
        function Tab:CreateSlider(settings)
            settings = settings or {}
            local sliderName = settings.Name or "Slider"
            local min = settings.Min or 0
            local max = settings.Max or 100
            local default = settings.Default or min
            local increment = settings.Increment or 1
            local callback = settings.Callback or function() end
            
            local SliderFrame = Instance.new("Frame")
            SliderFrame.Name = sliderName
            SliderFrame.Size = UDim2.new(1, -6, 0, 56)
            SliderFrame.BackgroundColor3 = Config.Colors.Background
            SliderFrame.BackgroundTransparency = 0.6
            SliderFrame.BorderSizePixel = 0
            SliderFrame.Parent = TabContent
            Utils:CreateCorner(SliderFrame, 8)
            Utils:CreateStroke(SliderFrame, Config.Colors.Border, 1)
            
            if settings.Tooltip then
                SliderFrame:SetAttribute("Tooltip", settings.Tooltip)
                TooltipSystem:Create(SliderFrame)
            end
            
            local Label = Instance.new("TextLabel")
            Label.Size = UDim2.new(1, -20, 0, 20)
            Label.Position = UDim2.new(0, 12, 0, 6)
            Label.BackgroundTransparency = 1
            Label.Font = Enum.Font.GothamSemibold
            Label.Text = sliderName
            Label.TextColor3 = Config.Colors.Text
            Label.TextSize = 13
            Label.TextXAlignment = Enum.TextXAlignment.Left
            Label.Parent = SliderFrame
            
            local ValueLabel = Instance.new("TextLabel")
            ValueLabel.AnchorPoint = Vector2.new(1, 0)
            ValueLabel.Size = UDim2.new(0, 50, 0, 20)
            ValueLabel.Position = UDim2.new(1, -12, 0, 6)
            ValueLabel.BackgroundTransparency = 1
            ValueLabel.Font = Enum.Font.GothamBold
            ValueLabel.Text = tostring(default)
            ValueLabel.TextColor3 = Config.Colors.Accent
            ValueLabel.TextSize = 13
            ValueLabel.TextXAlignment = Enum.TextXAlignment.Right
            ValueLabel.Parent = SliderFrame
            
            local SliderBG = Instance.new("Frame")
            SliderBG.Size = UDim2.new(1, -24, 0, 5)
            SliderBG.Position = UDim2.new(0, 12, 0, 38)
            SliderBG.BackgroundColor3 = Config.Colors.Border
            SliderBG.BackgroundTransparency = 0.3
            SliderBG.BorderSizePixel = 0
            SliderBG.Parent = SliderFrame
            Utils:CreateCorner(SliderBG, 2)
            
            local SliderFill = Instance.new("Frame")
            SliderFill.Size = UDim2.new((default - min) / (max - min), 0, 1, 0)
            SliderFill.BackgroundColor3 = Config.Colors.Accent
            SliderFill.BorderSizePixel = 0
            SliderFill.Parent = SliderBG
            Utils:CreateCorner(SliderFill, 2)
            
            local SliderButton = Instance.new("TextButton")
            SliderButton.Size = UDim2.new(1, 0, 1, 16)
            SliderButton.Position = UDim2.new(0, 0, 0, -8)
            SliderButton.BackgroundTransparency = 1
            SliderButton.Text = ""
            SliderButton.Parent = SliderBG
            
            local dragging = false
            local currentValue = default
            
            local function UpdateSlider(input)
                local pos = math.clamp((input.Position.X - SliderBG.AbsolutePosition.X) / SliderBG.AbsoluteSize.X, 0, 1)
                local value = math.floor((min + (max - min) * pos) / increment + 0.5) * increment
                value = math.clamp(value, min, max)
                
                currentValue = value
                ValueLabel.Text = tostring(value)
                Utils:Spring(SliderFill, {Size = UDim2.new((value - min) / (max - min), 0, 1, 0)}, 0.15)
                callback(value)
                Window.ConfigData[sliderName] = value
            end
            
            SliderButton.InputBegan:Connect(function(input)
                if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
                    dragging = true
                    UpdateSlider(input)
                end
            end)
            
            SliderButton.InputEnded:Connect(function(input)
                if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
                    dragging = false
                end
            end)
            
            UserInputService.InputChanged:Connect(function(input)
                if dragging and (input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch) then
                    UpdateSlider(input)
                end
            end)
            
            return {
                Frame = SliderFrame,
                SetValue = function(value)
                    currentValue = math.clamp(value, min, max)
                    ValueLabel.Text = tostring(currentValue)
                    Utils:Spring(SliderFill, {Size = UDim2.new((currentValue - min) / (max - min), 0, 1, 0)}, 0.15)
                    Window.ConfigData[sliderName] = currentValue
                end,
                GetValue = function()
                    return currentValue
                end
            }
        end
        
        function Tab:CreateDropdown(settings)
            settings = settings or {}
            local dropdownName = settings.Name or "Dropdown"
            local options = settings.Options or {}
            local default = settings.Default or (options[1] or "None")
            local callback = settings.Callback or function() end
            
            local DropdownFrame = Instance.new("Frame")
            DropdownFrame.Name = dropdownName
            DropdownFrame.Size = UDim2.new(1, -6, 0, 38)
            DropdownFrame.BackgroundTransparency = 1
            DropdownFrame.BorderSizePixel = 0
            DropdownFrame.Parent = TabContent
            DropdownFrame.ClipsDescendants = true
            DropdownFrame.ZIndex = 10
            
            local DropdownHeader = Instance.new("Frame")
            DropdownHeader.Name = "Header"
            DropdownHeader.Size = UDim2.new(1, 0, 0, 38)
            DropdownHeader.Position = UDim2.new(0, 0, 0, 0)
            DropdownHeader.BackgroundColor3 = Config.Colors.Background
            DropdownHeader.BackgroundTransparency = 0.6
            DropdownHeader.BorderSizePixel = 0
            DropdownHeader.Parent = DropdownFrame
            Utils:CreateCorner(DropdownHeader, 8)
            Utils:CreateStroke(DropdownHeader, Config.Colors.Border, 1)
            
            if settings.Tooltip then
                DropdownHeader:SetAttribute("Tooltip", settings.Tooltip)
                TooltipSystem:Create(DropdownHeader)
            end
            
            local Label = Instance.new("TextLabel")
            Label.Size = UDim2.new(1, -38, 0, 38)
            Label.Position = UDim2.new(0, 12, 0, 0)
            Label.BackgroundTransparency = 1
            Label.Font = Enum.Font.GothamSemibold
            Label.Text = dropdownName .. ": " .. default
            Label.TextColor3 = Config.Colors.Text
            Label.TextSize = 13
            Label.TextXAlignment = Enum.TextXAlignment.Left
            Label.Parent = DropdownHeader
            
            local Arrow = Instance.new("TextLabel")
            Arrow.AnchorPoint = Vector2.new(1, 0.5)
            Arrow.Size = UDim2.new(0, 16, 0, 16)
            Arrow.Position = UDim2.new(1, -12, 0, 19)
            Arrow.BackgroundTransparency = 1
            Arrow.Font = Enum.Font.GothamBold
            Arrow.Text = "›"
            Arrow.TextColor3 = Config.Colors.TextDark
            Arrow.TextSize = 14
            Arrow.Rotation = 90
            Arrow.Parent = DropdownHeader
            
            local OptionsContainer = Instance.new("Frame")
            OptionsContainer.Size = UDim2.new(1, -10, 0, #options * 32)
            OptionsContainer.Position = UDim2.new(0, 5, 0, 43)
            OptionsContainer.BackgroundTransparency = 1
            OptionsContainer.BorderSizePixel = 0
            OptionsContainer.Parent = DropdownFrame
            
            local OptionsLayout = Instance.new("UIListLayout")
            OptionsLayout.SortOrder = Enum.SortOrder.LayoutOrder
            OptionsLayout.Padding = UDim.new(0, 3)
            OptionsLayout.Parent = OptionsContainer
            
            local isOpen = false
            local currentValue = default
            
            local function ToggleDropdown()
                isOpen = not isOpen
                if isOpen then
                    Utils:IOSBounce(DropdownFrame, {Size = UDim2.new(1, -6, 0, 43 + #options * 32 + 6)}, 0.3)
                    Utils:IOSBounce(Arrow, {Rotation = 270}, 0.3)
                else
                    Utils:IOSBounce(DropdownFrame, {Size = UDim2.new(1, -6, 0, 38)}, 0.3)
                    Utils:IOSBounce(Arrow, {Rotation = 90}, 0.3)
                end
            end
            
            local DropdownButton = Instance.new("TextButton")
            DropdownButton.Size = UDim2.new(1, 0, 0, 38)
            DropdownButton.BackgroundTransparency = 1
            DropdownButton.Text = ""
            DropdownButton.ZIndex = 2
            DropdownButton.Parent = DropdownHeader
            
            DropdownButton.MouseButton1Click:Connect(ToggleDropdown)
            
            for _, option in ipairs(options) do
                local OptionButton = Instance.new("TextButton")
                OptionButton.Size = UDim2.new(1, 0, 0, 28)
                OptionButton.BackgroundColor3 = Config.Colors.Background
                OptionButton.BackgroundTransparency = 0.4
                OptionButton.BorderSizePixel = 0
                OptionButton.Font = Enum.Font.Gotham
                OptionButton.Text = "  " .. option
                OptionButton.TextColor3 = Config.Colors.Text
                OptionButton.TextSize = 12
                OptionButton.TextXAlignment = Enum.TextXAlignment.Left
                OptionButton.Parent = OptionsContainer
                Utils:CreateCorner(OptionButton, 6)
                
                OptionButton.MouseButton1Click:Connect(function()
                    currentValue = option
                    Label.Text = dropdownName .. ": " .. option
                    ToggleDropdown()
                    callback(option)
                    Window.ConfigData[dropdownName] = option
                end)
                
                OptionButton.MouseEnter:Connect(function()
                    Utils:SmoothFade(OptionButton, 0.2, 0.2)
                end)
                
                OptionButton.MouseLeave:Connect(function()
                    Utils:SmoothFade(OptionButton, 0.4, 0.2)
                end)
            end
            
            return {
                Frame = DropdownFrame,
                SetValue = function(value)
                    currentValue = value
                    Label.Text = dropdownName .. ": " .. value
                    Window.ConfigData[dropdownName] = value
                end,
                GetValue = function()
                    return currentValue
                end
            }
        end
        
        function Tab:CreateInput(settings)
            settings = settings or {}
            local inputName = settings.Name or "Input"
            local placeholder = settings.Placeholder or "Enter text..."
            local default = settings.Default or ""
            local callback = settings.Callback or function() end
            
            local InputFrame = Instance.new("Frame")
            InputFrame.Name = inputName
            InputFrame.Size = UDim2.new(1, -6, 0, 62)
            InputFrame.BackgroundColor3 = Config.Colors.Background
            InputFrame.BackgroundTransparency = 0.6
            InputFrame.BorderSizePixel = 0
            InputFrame.Parent = TabContent
            Utils:CreateCorner(InputFrame, 8)
            Utils:CreateStroke(InputFrame, Config.Colors.Border, 1)
            
            if settings.Tooltip then
                InputFrame:SetAttribute("Tooltip", settings.Tooltip)
                TooltipSystem:Create(InputFrame)
            end
            
            local Label = Instance.new("TextLabel")
            Label.Size = UDim2.new(1, -20, 0, 20)
            Label.Position = UDim2.new(0, 12, 0, 6)
            Label.BackgroundTransparency = 1
            Label.Font = Enum.Font.GothamSemibold
            Label.Text = inputName
            Label.TextColor3 = Config.Colors.Text
            Label.TextSize = 13
            Label.TextXAlignment = Enum.TextXAlignment.Left
            Label.Parent = InputFrame
            
            local InputBox = Instance.new("TextBox")
            InputBox.Size = UDim2.new(1, -24, 0, 26)
            InputBox.Position = UDim2.new(0, 12, 0, 28)
            InputBox.BackgroundColor3 = Config.Colors.Border
            InputBox.BackgroundTransparency = 0.3
            InputBox.BorderSizePixel = 0
            InputBox.Font = Enum.Font.Gotham
            InputBox.PlaceholderText = placeholder
            InputBox.PlaceholderColor3 = Config.Colors.TextDark
            InputBox.Text = default
            InputBox.TextColor3 = Config.Colors.Text
            InputBox.TextSize = 12
            InputBox.TextXAlignment = Enum.TextXAlignment.Left
            InputBox.ClearTextOnFocus = false
            InputBox.Parent = InputFrame
            Utils:CreateCorner(InputBox, 6)
            
            local InputPadding = Instance.new("UIPadding")
            InputPadding.PaddingLeft = UDim.new(0, 8)
            InputPadding.PaddingRight = UDim.new(0, 8)
            InputPadding.Parent = InputBox
            
            InputBox.Focused:Connect(function()
                Utils:Tween(InputBox, {BackgroundColor3 = Config.Colors.Accent, BackgroundTransparency = 0.2}, 0.2)
            end)
            
            InputBox.FocusLost:Connect(function(enterPressed)
                Utils:Tween(InputBox, {BackgroundColor3 = Config.Colors.Border, BackgroundTransparency = 0.3}, 0.2)
                if enterPressed or settings.OnChange then
                    callback(InputBox.Text)
                    Window.ConfigData[inputName] = InputBox.Text
                end
            end)
            
            if settings.OnChange then
                InputBox:GetPropertyChangedSignal("Text"):Connect(function()
                    callback(InputBox.Text)
                    Window.ConfigData[inputName] = InputBox.Text
                end)
            end
            
            return {
                Frame = InputFrame,
                SetValue = function(value)
                    InputBox.Text = value
                    Window.ConfigData[inputName] = value
                end,
                GetValue = function()
                    return InputBox.Text
                end
            }
        end
        
        function Tab:CreateKeybind(settings)
            settings = settings or {}
            local keybindName = settings.Name or "Keybind"
            local default = settings.Default or Enum.KeyCode.E
            local callback = settings.Callback or function() end
            
            local KeybindFrame = Instance.new("Frame")
            KeybindFrame.Name = keybindName
            KeybindFrame.Size = UDim2.new(1, -6, 0, 38)
            KeybindFrame.BackgroundColor3 = Config.Colors.Background
            KeybindFrame.BackgroundTransparency = 0.6
            KeybindFrame.BorderSizePixel = 0
            KeybindFrame.Parent = TabContent
            Utils:CreateCorner(KeybindFrame, 8)
            Utils:CreateStroke(KeybindFrame, Config.Colors.Border, 1)
            
            if settings.Tooltip then
                KeybindFrame:SetAttribute("Tooltip", settings.Tooltip)
                TooltipSystem:Create(KeybindFrame)
            end
            
            local Label = Instance.new("TextLabel")
            Label.Size = UDim2.new(1, -100, 1, 0)
            Label.Position = UDim2.new(0, 12, 0, 0)
            Label.BackgroundTransparency = 1
            Label.Font = Enum.Font.GothamSemibold
            Label.Text = keybindName
            Label.TextColor3 = Config.Colors.Text
            Label.TextSize = 13
            Label.TextXAlignment = Enum.TextXAlignment.Left
            Label.Parent = KeybindFrame
            
            local KeybindButton = Instance.new("TextButton")
            KeybindButton.AnchorPoint = Vector2.new(1, 0.5)
            KeybindButton.Position = UDim2.new(1, -12, 0.5, 0)
            KeybindButton.Size = UDim2.new(0, 70, 0, 26)
            KeybindButton.BackgroundColor3 = Config.Colors.Border
            KeybindButton.BackgroundTransparency = 0.2
            KeybindButton.BorderSizePixel = 0
            KeybindButton.Font = Enum.Font.GothamBold
            KeybindButton.Text = default.Name
            KeybindButton.TextColor3 = Config.Colors.Text
            KeybindButton.TextSize = 11
            KeybindButton.Parent = KeybindFrame
            Utils:CreateCorner(KeybindButton, 6)
            
            local currentKey = default
            local binding = false
            
            KeybindButton.MouseButton1Click:Connect(function()
                binding = true
                KeybindButton.Text = "..."
                Utils:Tween(KeybindButton, {BackgroundColor3 = Config.Colors.Accent}, 0.2)
            end)
            
            UserInputService.InputBegan:Connect(function(input, gameProcessed)
                if binding then
                    if input.UserInputType == Enum.UserInputType.Keyboard then
                        currentKey = input.KeyCode
                        KeybindButton.Text = input.KeyCode.Name
                        binding = false
                        Utils:Tween(KeybindButton, {BackgroundColor3 = Config.Colors.Border}, 0.2)
                        Window.ConfigData[keybindName] = input.KeyCode.Name
                    end
                elseif input.KeyCode == currentKey and not gameProcessed then
                    callback()
                end
            end)
            
            return {
                Frame = KeybindFrame,
                SetKey = function(key)
                    currentKey = key
                    KeybindButton.Text = key.Name
                    Window.ConfigData[keybindName] = key.Name
                end,
                GetKey = function()
                    return currentKey
                end
            }
        end
        
        function Tab:CreateColorPicker(settings)
            settings = settings or {}
            local colorName = settings.Name or "Color Picker"
            local default = settings.Default or Color3.fromRGB(255, 255, 255)
            local callback = settings.Callback or function() end
            
            local ColorFrame = Instance.new("Frame")
            ColorFrame.Name = colorName
            ColorFrame.Size = UDim2.new(1, -6, 0, 38)
            ColorFrame.BackgroundColor3 = Config.Colors.Background
            ColorFrame.BackgroundTransparency = 0.6
            ColorFrame.BorderSizePixel = 0
            ColorFrame.Parent = TabContent
            Utils:CreateCorner(ColorFrame, 8)
            Utils:CreateStroke(ColorFrame, Config.Colors.Border, 1)
            
            if settings.Tooltip then
                ColorFrame:SetAttribute("Tooltip", settings.Tooltip)
                TooltipSystem:Create(ColorFrame)
            end
            
            local Label = Instance.new("TextLabel")
            Label.Size = UDim2.new(1, -60, 1, 0)
            Label.Position = UDim2.new(0, 12, 0, 0)
            Label.BackgroundTransparency = 1
            Label.Font = Enum.Font.GothamSemibold
            Label.Text = colorName
            Label.TextColor3 = Config.Colors.Text
            Label.TextSize = 13
            Label.TextXAlignment = Enum.TextXAlignment.Left
            Label.Parent = ColorFrame
            
            local ColorDisplay = Instance.new("TextButton")
            ColorDisplay.AnchorPoint = Vector2.new(1, 0.5)
            ColorDisplay.Position = UDim2.new(1, -12, 0.5, 0)
            ColorDisplay.Size = UDim2.new(0, 36, 0, 22)
            ColorDisplay.BackgroundColor3 = default
            ColorDisplay.BorderSizePixel = 0
            ColorDisplay.Text = ""
            ColorDisplay.Parent = ColorFrame
            Utils:CreateCorner(ColorDisplay, 6)
            Utils:CreateStroke(ColorDisplay, Config.Colors.Border, 1)
            
            local currentColor = default
            
            ColorDisplay.MouseButton1Click:Connect(function()
                -- Simple RGB input dialog
                local r = math.floor(currentColor.R * 255)
                local g = math.floor(currentColor.G * 255)
                local b = math.floor(currentColor.B * 255)
                
                -- This is a basic implementation - you could expand this with a full color picker UI
                ScawsHub:CreateNotification({
                    Title = "Color Picker",
                    Content = string.format("Current: RGB(%d, %d, %d)\nClick to randomize", r, g, b),
                    Duration = 3,
                    Type = "Info"
                })
                
                -- For now, just cycle through some preset colors
                local presets = {
                    Color3.fromRGB(255, 0, 0),
                    Color3.fromRGB(0, 255, 0),
                    Color3.fromRGB(0, 0, 255),
                    Color3.fromRGB(255, 255, 0),
                    Color3.fromRGB(255, 0, 255),
                    Color3.fromRGB(0, 255, 255),
                    Color3.fromRGB(255, 255, 255),
                }
                
                local currentIndex = 1
                for i, color in ipairs(presets) do
                    if color == currentColor then
                        currentIndex = i
                        break
                    end
                end
                
                currentColor = presets[(currentIndex % #presets) + 1]
                Utils:Tween(ColorDisplay, {BackgroundColor3 = currentColor}, 0.3)
                callback(currentColor)
                Window.ConfigData[colorName] = Utils:RGBToHex(currentColor)
            end)
            
            ColorDisplay.MouseEnter:Connect(function()
                Utils:Tween(ColorDisplay, {Size = UDim2.new(0, 38, 0, 24)}, 0.2)
            end)
            
            ColorDisplay.MouseLeave:Connect(function()
                Utils:Tween(ColorDisplay, {Size = UDim2.new(0, 36, 0, 22)}, 0.2)
            end)
            
            return {
                Frame = ColorFrame,
                SetColor = function(color)
                    currentColor = color
                    ColorDisplay.BackgroundColor3 = color
                    Window.ConfigData[colorName] = Utils:RGBToHex(color)
                end,
                GetColor = function()
                    return currentColor
                end
            }
        end
        
        function Tab:CreateLabel(text)
            local LabelFrame = Instance.new("Frame")
            LabelFrame.Size = UDim2.new(1, -6, 0, 26)
            LabelFrame.BackgroundTransparency = 1
            LabelFrame.Parent = TabContent
            
            local Label = Instance.new("TextLabel")
            Label.Size = UDim2.new(1, -24, 1, 0)
            Label.Position = UDim2.new(0, 12, 0, 0)
            Label.BackgroundTransparency = 1
            Label.Font = Enum.Font.Gotham
            Label.Text = text
            Label.TextColor3 = Config.Colors.TextDark
            Label.TextSize = 12
            Label.TextXAlignment = Enum.TextXAlignment.Left
            Label.TextWrapped = true
            Label.Parent = LabelFrame
            
            return {
                Frame = LabelFrame,
                UpdateText = function(newText)
                    Label.Text = newText
                end
            }
        end
        
        function Tab:CreateParagraph(settings)
            settings = settings or {}
            local title = settings.Title or "Paragraph"
            local content = settings.Content or ""
            
            local textSize = game:GetService("TextService"):GetTextSize(
                content, 11, Enum.Font.Gotham, Vector2.new(330, 1000)
            )
            
            local ParagraphFrame = Instance.new("Frame")
            ParagraphFrame.Size = UDim2.new(1, -6, 0, textSize.Y + 36)
            ParagraphFrame.BackgroundColor3 = Config.Colors.Background
            ParagraphFrame.BackgroundTransparency = 0.6
            ParagraphFrame.BorderSizePixel = 0
            ParagraphFrame.Parent = TabContent
            Utils:CreateCorner(ParagraphFrame, 8)
            Utils:CreateStroke(ParagraphFrame, Config.Colors.Border, 1)
            
            local TitleLabel = Instance.new("TextLabel")
            TitleLabel.Size = UDim2.new(1, -24, 0, 18)
            TitleLabel.Position = UDim2.new(0, 12, 0, 8)
            TitleLabel.BackgroundTransparency = 1
            TitleLabel.Font = Enum.Font.GothamBold
            TitleLabel.Text = title
            TitleLabel.TextColor3 = Config.Colors.Text
            TitleLabel.TextSize = 13
            TitleLabel.TextXAlignment = Enum.TextXAlignment.Left
            TitleLabel.Parent = ParagraphFrame
            
            local ContentLabel = Instance.new("TextLabel")
            ContentLabel.Size = UDim2.new(1, -24, 0, textSize.Y)
            ContentLabel.Position = UDim2.new(0, 12, 0, 28)
            ContentLabel.BackgroundTransparency = 1
            ContentLabel.Font = Enum.Font.Gotham
            ContentLabel.Text = content
            ContentLabel.TextColor3 = Config.Colors.TextDark
            ContentLabel.TextSize = 11
            ContentLabel.TextXAlignment = Enum.TextXAlignment.Left
            ContentLabel.TextYAlignment = Enum.TextYAlignment.Top
            ContentLabel.TextWrapped = true
            ContentLabel.Parent = ParagraphFrame
            
            return {
                Frame = ParagraphFrame,
                UpdateContent = function(newTitle, newContent)
                    TitleLabel.Text = newTitle
                    ContentLabel.Text = newContent
                end
            }
        end
        
        return Tab
    end

    function Window:SelectTab(tab)
        if self.IsTransitioning then return end
        if self.CurrentTab == tab then return end
        
        self.IsTransitioning = true
        
        for _, t in ipairs(self.Tabs) do
            if t == tab then
                Utils:SmoothFade(t.Button, 0.6, 0.3)
                Utils:Tween(t.Button, {BackgroundColor3 = Color3.fromRGB(25, 25, 25)}, 0.3)
                Utils:Tween(t.Button, {TextColor3 = Config.Colors.Text}, 0.3)
                
                if self.CurrentTab and self.CurrentTab.Content.Visible then
                    for _, element in ipairs(self.CurrentTab.Content:GetChildren()) do
                        if element:IsA("GuiObject") and not element:IsA("UIListLayout") then
                            local fadeOutTween = TweenService:Create(
                                element,
                                TweenInfo.new(0.15, Enum.EasingStyle.Quad, Enum.EasingDirection.In),
                                {
                                    Position = UDim2.new(element.Position.X.Scale, element.Position.X.Offset - 15, element.Position.Y.Scale, element.Position.Y.Offset),
                                    BackgroundTransparency = 1
                                }
                            )
                            fadeOutTween:Play()
                            
                            if element:IsA("TextLabel") or element:IsA("TextButton") then
                                Utils:Tween(element, {TextTransparency = 1}, 0.15)
                            end
                            
                            for _, child in ipairs(element:GetChildren()) do
                                if child:IsA("TextLabel") or child:IsA("TextButton") then
                                    Utils:Tween(child, {TextTransparency = 1}, 0.15)
                                elseif child:IsA("Frame") and child.Name ~= "UICorner" and child.Name ~= "UIStroke" and child.Name ~= "Header" then
                                    Utils:Tween(child, {BackgroundTransparency = 1}, 0.15)
                                end
                            end
                        end
                    end
                end
                
                task.wait(0.18)
                
                if self.CurrentTab then
                    self.CurrentTab.Content.Visible = false
                end
                
                t.Content.Visible = true
                
                for i, element in ipairs(t.Content:GetChildren()) do
                    if element:IsA("GuiObject") and not element:IsA("UIListLayout") then
                        local originalBgTrans = element.BackgroundTransparency
                        local originalPos = element.Position
                        
                        element.Position = UDim2.new(originalPos.X.Scale, originalPos.X.Offset + 15, originalPos.Y.Scale, originalPos.Y.Offset)
                        element.BackgroundTransparency = 1
                        
                        if element:IsA("TextLabel") or element:IsA("TextButton") then
                            element.TextTransparency = 1
                        end
                        
                        for _, child in ipairs(element:GetChildren()) do
                            if child:IsA("TextLabel") or child:IsA("TextButton") then
                                child.TextTransparency = 1
                            elseif child:IsA("Frame") and child.Name ~= "UICorner" and child.Name ~= "UIStroke" and child.Name ~= "Header" then
                                child.BackgroundTransparency = 1
                            end
                        end
                        
                        task.spawn(function()
                            task.wait(i * 0.025)
                            
                            local fadeInTween = TweenService:Create(
                                element,
                                TweenInfo.new(0.4, Enum.EasingStyle.Exponential, Enum.EasingDirection.Out),
                                {Position = originalPos, BackgroundTransparency = originalBgTrans}
                            )
                            fadeInTween:Play()
                            
                            if element:IsA("TextLabel") or element:IsA("TextButton") then
                                Utils:Tween(element, {TextTransparency = 0}, 0.4)
                            end
                            
                            for _, child in ipairs(element:GetChildren()) do
                                if child:IsA("TextLabel") or child:IsA("TextButton") then
                                    Utils:Tween(child, {TextTransparency = 0}, 0.4)
                                elseif child:IsA("Frame") and child.Name ~= "UICorner" and child.Name ~= "UIStroke" and child.Name ~= "Header" then
                                    local origTrans = child:GetAttribute("OriginalTransparency") or 0.6
                                    Utils:Tween(child, {BackgroundTransparency = origTrans}, 0.4)
                                end
                            end
                        end)
                    end
                end
            else
                Utils:SmoothFade(t.Button, 1, 0.3)
                Utils:Tween(t.Button, {BackgroundColor3 = Config.Colors.Accent}, 0.3)
                Utils:Tween(t.Button, {TextColor3 = Config.Colors.TextDark}, 0.3)
            end
        end
        
        self.CurrentTab = tab
        
        task.delay(0.5, function()
            self.IsTransitioning = false
        end)
    end
    
    function Window:SaveConfig(name)
        if ConfigManager:Save(name, self.ConfigData) then
            ScawsHub:CreateNotification({
                Title = "Config Saved",
                Content = "Configuration '" .. name .. "' has been saved successfully.",
                Duration = 3,
                Type = "Success"
            })
            return true
        else
            ScawsHub:CreateNotification({
                Title = "Save Failed",
                Content = "Failed to save configuration '" .. name .. "'.",
                Duration = 3,
                Type = "Error"
            })
            return false
        end
    end
    
    function Window:LoadConfig(name)
        local config = ConfigManager:Load(name)
        if config then
            self.ConfigData = config
            ScawsHub:CreateNotification({
                Title = "Config Loaded",
                Content = "Configuration '" .. name .. "' has been loaded successfully.",
                Duration = 3,
                Type = "Success"
            })
            return true
        else
            ScawsHub:CreateNotification({
                Title = "Load Failed",
                Content = "Failed to load configuration '" .. name .. "'.",
                Duration = 3,
                Type = "Error"
            })
            return false
        end
    end
    
    function Window:DeleteConfig(name)
        if ConfigManager:Delete(name) then
            ScawsHub:CreateNotification({
                Title = "Config Deleted",
                Content = "Configuration '" .. name .. "' has been deleted.",
                Duration = 3,
                Type = "Success"
            })
            return true
        else
            return false
        end
    end
    
    function Window:ListConfigs()
        return ConfigManager:List()
    end

    return Window
end

function ScawsHub:CreateNotification(settings)
    settings = settings or {}
    local title = settings.Title or "Notification"
    local content = settings.Content or ""
    local duration = settings.Duration or 5
    local type = settings.Type or "Info"

    local notifGui = game:GetService("CoreGui"):FindFirstChild("ScawsHub_Notifications")
    if not notifGui then
        notifGui = Instance.new("ScreenGui")
        notifGui.Name = "ScawsHub_Notifications"
        notifGui.ResetOnSpawn = false
        notifGui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
        notifGui.IgnoreGuiInset = true
        
        if gethui then
            notifGui.Parent = gethui()
        else
            notifGui.Parent = CoreGui
        end
        
        local NotifContainer = Instance.new("Frame")
        NotifContainer.Name = "NotifContainer"
        NotifContainer.AnchorPoint = Vector2.new(1, 1)
        NotifContainer.Position = UDim2.new(1, -20, 1, -20)
        NotifContainer.Size = UDim2.new(0, 300, 1, -40)
        NotifContainer.BackgroundTransparency = 1
        NotifContainer.Parent = notifGui
        
        local NotifLayout = Instance.new("UIListLayout")
        NotifLayout.SortOrder = Enum.SortOrder.LayoutOrder
        NotifLayout.Padding = UDim.new(0, 8)
        NotifLayout.VerticalAlignment = Enum.VerticalAlignment.Bottom
        NotifLayout.HorizontalAlignment = Enum.HorizontalAlignment.Right
        NotifLayout.Parent = NotifContainer
    end

    local NotifContainer = notifGui:FindFirstChild("NotifContainer")

    local Notification = Instance.new("Frame")
    Notification.Size = UDim2.new(0, 280, 0, 75)
    Notification.Position = UDim2.new(1, 300, 0, 0)
    Notification.BackgroundColor3 = Config.Colors.Background
    Notification.BackgroundTransparency = 1
    Notification.BorderSizePixel = 0
    Notification.Parent = NotifContainer
    Utils:CreateCorner(Notification, 10)

    local colorMap = {
        Info = Config.Colors.Accent,
        Success = Config.Colors.Success,
        Warning = Config.Colors.Warning,
        Error = Config.Colors.Error
    }

    local NotifStroke = Utils:CreateStroke(Notification, colorMap[type] or Config.Colors.Accent, 1)
    NotifStroke.Transparency = 1

    local Indicator = Instance.new("Frame")
    Indicator.Size = UDim2.new(0, 3, 1, -16)
    Indicator.Position = UDim2.new(0, 8, 0, 8)
    Indicator.BackgroundColor3 = colorMap[type] or Config.Colors.Accent
    Indicator.BackgroundTransparency = 1
    Indicator.BorderSizePixel = 0
    Indicator.ZIndex = 2
    Indicator.Parent = Notification
    Utils:CreateCorner(Indicator, 1)

    local IconLabel = Instance.new("TextLabel")
    IconLabel.Size = UDim2.new(0, 20, 0, 20)
    IconLabel.Position = UDim2.new(0, 18, 0, 12)
    IconLabel.BackgroundTransparency = 1
    IconLabel.Font = Enum.Font.GothamBold
    IconLabel.TextSize = 16
    IconLabel.TextColor3 = colorMap[type] or Config.Colors.Accent
    IconLabel.TextTransparency = 1
    IconLabel.ZIndex = 2
    
    local iconMap = {
        Info = "i",
        Success = "✓",
        Warning = "!",
        Error = "✕"
    }
    IconLabel.Text = iconMap[type] or "i"
    IconLabel.Parent = Notification

    local Title = Instance.new("TextLabel")
    Title.Size = UDim2.new(1, -54, 0, 20)
    Title.Position = UDim2.new(0, 44, 0, 12)
    Title.BackgroundTransparency = 1
    Title.Font = Enum.Font.GothamBold
    Title.Text = title
    Title.TextColor3 = Config.Colors.Text
    Title.TextSize = 13
    Title.TextXAlignment = Enum.TextXAlignment.Left
    Title.TextTransparency = 1
    Title.ZIndex = 2
    Title.Parent = Notification

    local Content = Instance.new("TextLabel")
    Content.Size = UDim2.new(1, -54, 0, 32)
    Content.Position = UDim2.new(0, 44, 0, 32)
    Content.BackgroundTransparency = 1
    Content.Font = Enum.Font.Gotham
    Content.Text = content
    Content.TextColor3 = Config.Colors.TextDark
    Content.TextSize = 11
    Content.TextXAlignment = Enum.TextXAlignment.Left
    Content.TextYAlignment = Enum.TextYAlignment.Top
    Content.TextWrapped = true
    Content.TextTransparency = 1
    Content.ZIndex = 2
    Content.Parent = Notification

    local ProgressBar = Instance.new("Frame")
    ProgressBar.Size = UDim2.new(1, -16, 0, 2)
    ProgressBar.Position = UDim2.new(0, 8, 1, -6)
    ProgressBar.BackgroundColor3 = colorMap[type] or Config.Colors.Accent
    ProgressBar.BackgroundTransparency = 1
    ProgressBar.BorderSizePixel = 0
    ProgressBar.ZIndex = 2
    ProgressBar.Parent = Notification
    Utils:CreateCorner(ProgressBar, 1)

    Utils:Tween(Notification, {BackgroundTransparency = 0.1}, 0.3)
    Utils:Tween(NotifStroke, {Transparency = 0.5}, 0.3)
    Utils:Tween(Indicator, {BackgroundTransparency = 0}, 0.3)
    Utils:Tween(IconLabel, {TextTransparency = 0}, 0.3)
    Utils:Tween(Title, {TextTransparency = 0}, 0.3)
    Utils:Tween(Content, {TextTransparency = 0}, 0.3)
    Utils:Tween(ProgressBar, {BackgroundTransparency = 0}, 0.3)

    local slideInTween = TweenService:Create(
        Notification,
        TweenInfo.new(0.5, Enum.EasingStyle.Back, Enum.EasingDirection.Out),
        {Position = UDim2.new(0, 0, 0, 0)}
    )
    slideInTween:Play()

    local progressTween = TweenService:Create(
        ProgressBar,
        TweenInfo.new(duration, Enum.EasingStyle.Linear, Enum.EasingDirection.InOut),
        {Size = UDim2.new(0, 0, 0, 2)}
    )
    
    task.wait(0.5)
    progressTween:Play()

    task.delay(duration, function()
        Utils:Tween(Notification, {BackgroundTransparency = 1}, 0.4)
        Utils:Tween(NotifStroke, {Transparency = 1}, 0.4)
        Utils:Tween(Indicator, {BackgroundTransparency = 1}, 0.4)
        Utils:Tween(IconLabel, {TextTransparency = 1}, 0.4)
        Utils:Tween(Title, {TextTransparency = 1}, 0.4)
        Utils:Tween(Content, {TextTransparency = 1}, 0.4)
        Utils:Tween(ProgressBar, {BackgroundTransparency = 1}, 0.4)
        
        local slideOutTween = TweenService:Create(
            Notification,
            TweenInfo.new(0.4, Enum.EasingStyle.Back, Enum.EasingDirection.In),
            {Position = UDim2.new(1, 300, 0, 0)}
        )
        slideOutTween:Play()
        
        task.wait(0.5)
        Notification:Destroy()
    end)
end
-- Key System (runs automatically before anything loads)
local function RunKeySystem()
    local correctKey = "SH25"
    local discordLink = "https://discord.gg/7CA2QGEfzP"
    
    local KeyGui = Instance.new("ScreenGui")
    KeyGui.Name = "ScawsHub_KeySystem"
    KeyGui.ResetOnSpawn = false
    KeyGui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
    KeyGui.IgnoreGuiInset = true
    
    if gethui then
        KeyGui.Parent = gethui()
    elseif syn and syn.protect_gui then
        syn.protect_gui(KeyGui)
        KeyGui.Parent = CoreGui
    else
        KeyGui.Parent = CoreGui
    end
    
    local KeyMain = Instance.new("Frame")
    KeyMain.Name = "KeyMain"
    KeyMain.AnchorPoint = Vector2.new(0.5, 0.5)
    KeyMain.Position = UDim2.new(0.5, 0, 0.5, 0)
    KeyMain.Size = UDim2.new(0, 0, 0, 0)
    KeyMain.BackgroundColor3 = Config.Colors.Background
    KeyMain.BackgroundTransparency = 0.15
    KeyMain.BorderSizePixel = 0
    KeyMain.ClipsDescendants = true
    KeyMain.Parent = KeyGui
    Utils:CreateCorner(KeyMain, 14)
    Utils:CreateStroke(KeyMain, Config.Colors.Border, 1)
    
    Utils:IOSBounce(KeyMain, {Size = UDim2.new(0, 320, 0, 220)}, 0.7)
    
    local KeyTopbar = Instance.new("Frame")
    KeyTopbar.Name = "Topbar"
    KeyTopbar.Size = UDim2.new(1, 0, 0, 40)
    KeyTopbar.BackgroundColor3 = Config.Colors.Topbar
    KeyTopbar.BackgroundTransparency = 0.15
    KeyTopbar.BorderSizePixel = 0
    KeyTopbar.Parent = KeyMain
    
    local TopbarCorner = Instance.new("UICorner")
    TopbarCorner.CornerRadius = UDim.new(0, 14)
    TopbarCorner.Parent = KeyTopbar
    
    local KeyTitle = Instance.new("TextLabel")
    KeyTitle.Size = UDim2.new(1, -24, 1, 0)
    KeyTitle.Position = UDim2.new(0, 12, 0, 0)
    KeyTitle.BackgroundTransparency = 1
    KeyTitle.Font = Enum.Font.GothamBold
    KeyTitle.Text = "ScawsHUB - Key System"
    KeyTitle.TextColor3 = Config.Colors.Text
    KeyTitle.TextSize = 14
    KeyTitle.TextXAlignment = Enum.TextXAlignment.Left
    KeyTitle.Parent = KeyTopbar
    
    local ContentFrame = Instance.new("Frame")
    ContentFrame.Size = UDim2.new(1, -24, 1, -52)
    ContentFrame.Position = UDim2.new(0, 12, 0, 46)
    ContentFrame.BackgroundTransparency = 1
    ContentFrame.Parent = KeyMain
    
    local KeyLabel = Instance.new("TextLabel")
    KeyLabel.Size = UDim2.new(1, 0, 0, 18)
    KeyLabel.Position = UDim2.new(0, 0, 0, 0)
    KeyLabel.BackgroundTransparency = 1
    KeyLabel.Font = Enum.Font.GothamSemibold
    KeyLabel.Text = "Enter your key to continue"
    KeyLabel.TextColor3 = Config.Colors.TextDark
    KeyLabel.TextSize = 12
    KeyLabel.TextXAlignment = Enum.TextXAlignment.Left
    KeyLabel.Parent = ContentFrame
    
    local KeyInput = Instance.new("TextBox")
    KeyInput.Size = UDim2.new(1, 0, 0, 36)
    KeyInput.Position = UDim2.new(0, 0, 0, 24)
    KeyInput.BackgroundColor3 = Config.Colors.Border
    KeyInput.BackgroundTransparency = 0.3
    KeyInput.BorderSizePixel = 0
    KeyInput.Font = Enum.Font.Gotham
    KeyInput.PlaceholderText = "Enter key here..."
    KeyInput.PlaceholderColor3 = Config.Colors.TextDark
    KeyInput.Text = ""
    KeyInput.TextColor3 = Config.Colors.Text
    KeyInput.TextSize = 13
    KeyInput.ClearTextOnFocus = false
    KeyInput.Parent = ContentFrame
    Utils:CreateCorner(KeyInput, 8)
    
    local InputPadding = Instance.new("UIPadding")
    InputPadding.PaddingLeft = UDim.new(0, 10)
    InputPadding.PaddingRight = UDim.new(0, 10)
    InputPadding.Parent = KeyInput
    
    local StatusLabel = Instance.new("TextLabel")
    StatusLabel.Size = UDim2.new(1, 0, 0, 16)
    StatusLabel.Position = UDim2.new(0, 0, 0, 64)
    StatusLabel.BackgroundTransparency = 1
    StatusLabel.Font = Enum.Font.Gotham
    StatusLabel.Text = ""
    StatusLabel.TextColor3 = Config.Colors.Error
    StatusLabel.TextSize = 11
    StatusLabel.TextXAlignment = Enum.TextXAlignment.Left
    StatusLabel.Parent = ContentFrame
    
    local SubmitButton = Instance.new("TextButton")
    SubmitButton.Size = UDim2.new(1, 0, 0, 34)
    SubmitButton.Position = UDim2.new(0, 0, 0, 86)
    SubmitButton.BackgroundColor3 = Config.Colors.Accent
    SubmitButton.BackgroundTransparency = 0.3
    SubmitButton.BorderSizePixel = 0
    SubmitButton.Font = Enum.Font.GothamBold
    SubmitButton.Text = "Submit Key"
    SubmitButton.TextColor3 = Config.Colors.Text
    SubmitButton.TextSize = 13
    SubmitButton.Parent = ContentFrame
    Utils:CreateCorner(SubmitButton, 8)
    
    local DiscordButton = Instance.new("TextButton")
    DiscordButton.Size = UDim2.new(1, 0, 0, 34)
    DiscordButton.Position = UDim2.new(0, 0, 0, 126)
    DiscordButton.BackgroundColor3 = Color3.fromRGB(88, 101, 242)
    DiscordButton.BackgroundTransparency = 0.3
    DiscordButton.BorderSizePixel = 0
    DiscordButton.Font = Enum.Font.GothamSemibold
    DiscordButton.Text = "No key? Join our Discord"
    DiscordButton.TextColor3 = Config.Colors.Text
    DiscordButton.TextSize = 12
    DiscordButton.Parent = ContentFrame
    Utils:CreateCorner(DiscordButton, 8)
    
    SubmitButton.MouseEnter:Connect(function()
        Utils:SmoothFade(SubmitButton, 0.1, 0.2)
    end)
    SubmitButton.MouseLeave:Connect(function()
        Utils:SmoothFade(SubmitButton, 0.3, 0.2)
    end)
    
    DiscordButton.MouseEnter:Connect(function()
        Utils:SmoothFade(DiscordButton, 0.1, 0.2)
    end)
    DiscordButton.MouseLeave:Connect(function()
        Utils:SmoothFade(DiscordButton, 0.3, 0.2)
    end)
    
    KeyInput.Focused:Connect(function()
        Utils:Tween(KeyInput, {BackgroundColor3 = Config.Colors.Accent, BackgroundTransparency = 0.2}, 0.2)
    end)
    
    KeyInput.FocusLost:Connect(function()
        Utils:Tween(KeyInput, {BackgroundColor3 = Config.Colors.Border, BackgroundTransparency = 0.3}, 0.2)
    end)
    
    local keyValidated = false
    
    local function ValidateKey()
        if KeyInput.Text == correctKey then
            keyValidated = true
            StatusLabel.TextColor3 = Config.Colors.Success
            StatusLabel.Text = "Key accepted! Loading..."
            Utils:Spring(SubmitButton, {BackgroundColor3 = Config.Colors.Success}, 0.3)
            
            task.wait(0.5)
            Utils:Tween(KeyMain, {Size = UDim2.new(0, 0, 0, 0), BackgroundTransparency = 1}, 0.4)
            task.wait(0.5)
            KeyGui:Destroy()
        else
            StatusLabel.TextColor3 = Config.Colors.Error
            StatusLabel.Text = "Invalid key. Please try again."
            Utils:Spring(KeyMain, {Position = UDim2.new(0.5, 10, 0.5, 0)}, 0.1)
            task.wait(0.1)
            Utils:Spring(KeyMain, {Position = UDim2.new(0.5, -10, 0.5, 0)}, 0.1)
            task.wait(0.1)
            Utils:Spring(KeyMain, {Position = UDim2.new(0.5, 0, 0.5, 0)}, 0.1)
        end
    end
    
    SubmitButton.MouseButton1Click:Connect(ValidateKey)
    
    KeyInput.FocusLost:Connect(function(enterPressed)
        if enterPressed then
            ValidateKey()
        end
    end)
    
    DiscordButton.MouseButton1Click:Connect(function()
        if setclipboard then
            setclipboard(discordLink)
            StatusLabel.TextColor3 = Config.Colors.Success
            StatusLabel.Text = "Discord link has been copied to your clipboard!"
        else
            StatusLabel.TextColor3 = Config.Colors.Warning
            StatusLabel.Text = discordLink
        end
    end)
    
    repeat task.wait() until keyValidated
end

RunKeySystem()

return ScawsHub
