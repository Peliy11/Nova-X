local TweenService = game:GetService("TweenService")
local UserInputService = game:GetService("UserInputService")
local Players = game:GetService("Players")
local CoreGui = game:GetService("CoreGui")
local RunService = game:GetService("RunService")
local TeleportService = game:GetService("TeleportService")

local ScawsHub = {}
ScawsHub.__index = ScawsHub

local Config = {
    AnimationSpeed = 0.35,
    EasingStyle = Enum.EasingStyle.Quart,
    EasingDirection = Enum.EasingDirection.Out,

    Colors = {
        Background = Color3.fromRGB(25, 30, 28),
        Topbar = Color3.fromRGB(28, 35, 32),
        Sidebar = Color3.fromRGB(28, 35, 32),
        Main = Color3.fromRGB(30, 38, 34),
        Accent = Color3.fromRGB(67, 181, 129),
        AccentHover = Color3.fromRGB(87, 201, 149),
        Text = Color3.fromRGB(255, 255, 255),
        TextDark = Color3.fromRGB(160, 170, 165),
        Border = Color3.fromRGB(45, 58, 50),
        Success = Color3.fromRGB(67, 181, 129),
        Warning = Color3.fromRGB(250, 166, 26),
        Error = Color3.fromRGB(240, 71, 71),
    },

    WindowSize = UDim2.new(0, 550, 0, 400),
    SidebarWidth = 150,
}

local SessionStartTime = tick()

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
    stroke.Transparency = 0.3
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

function Utils:GenerateRandomString(length)
    local chars = "ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789!@#$%^&*()_+-=[]{}|;:,.<>?"
    local str = ""
    for i = 1, length do
        local rand = math.random(1, #chars)
        str = str .. chars:sub(rand, rand)
    end
    return str
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

function ScawsHub:CreateLoadingScreen(settings)
    settings = settings or {}
    local imageId = "rbxassetid://110576456793971"
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
    Container.BackgroundColor3 = Color3.fromRGB(15, 20, 18)
    Container.BorderSizePixel = 0
    Container.Parent = LoadingGui

    -- Matrix-style code rain effect
    local StringsFrame = Instance.new("Frame")
    StringsFrame.Name = "StringsFrame"
    StringsFrame.Size = UDim2.new(1, 0, 1, 0)
    StringsFrame.BackgroundTransparency = 1
    StringsFrame.BorderSizePixel = 0
    StringsFrame.Parent = Container

    local ImageLabel = Instance.new("ImageLabel")
    ImageLabel.Name = "Logo"
    ImageLabel.AnchorPoint = Vector2.new(0.5, 0.5)
    ImageLabel.Position = UDim2.new(0.5, 0, 0.5, 0)
    ImageLabel.Size = UDim2.new(0, 250, 0, 250)
    ImageLabel.BackgroundTransparency = 1
    ImageLabel.Image = imageId
    ImageLabel.ImageTransparency = 1
    ImageLabel.ScaleType = Enum.ScaleType.Fit
    ImageLabel.ZIndex = 2
    ImageLabel.Parent = Container

    local DevVersionLabel = Instance.new("TextLabel")
    DevVersionLabel.Name = "DevVersion"
    DevVersionLabel.AnchorPoint = Vector2.new(0.5, 0)
    DevVersionLabel.Position = UDim2.new(0.5, 0, 0.5, 140)
    DevVersionLabel.Size = UDim2.new(0, 200, 0, 30)
    DevVersionLabel.BackgroundTransparency = 1
    DevVersionLabel.Font = Enum.Font.GothamBold
    DevVersionLabel.Text = "DevVersion"
    DevVersionLabel.TextColor3 = Config.Colors.Accent
    DevVersionLabel.TextSize = 16
    DevVersionLabel.TextTransparency = 1
    DevVersionLabel.ZIndex = 2
    DevVersionLabel.Parent = Container

    print("[ScawsHUB] Loading image:", imageId)

    -- Create random strings appearing from top-left to bottom-right
    local screenSize = workspace.CurrentCamera.ViewportSize
    local rows = 20
    local cols = 30
    local totalCells = rows * cols
    local stringLabels = {}

    for i = 1, totalCells do
        local row = math.floor((i - 1) / cols)
        local col = (i - 1) % cols
        
        local stringLabel = Instance.new("TextLabel")
        stringLabel.Size = UDim2.new(1 / cols, 0, 1 / rows, 0)
        stringLabel.Position = UDim2.new(col / cols, 0, row / rows, 0)
        stringLabel.BackgroundTransparency = 1
        stringLabel.Font = Enum.Font.Code
        stringLabel.Text = ""
        stringLabel.TextColor3 = Config.Colors.Accent
        stringLabel.TextSize = 10
        stringLabel.TextTransparency = 0
        stringLabel.TextXAlignment = Enum.TextXAlignment.Center
        stringLabel.TextYAlignment = Enum.TextYAlignment.Center
        stringLabel.Parent = StringsFrame
        
        table.insert(stringLabels, stringLabel)
    end

    -- Animate strings appearing
    task.spawn(function()
        local delay = (duration * 0.6) / totalCells
        for i, label in ipairs(stringLabels) do
            task.spawn(function()
                task.wait((i - 1) * delay)
                
                -- Random string animation
                for j = 1, 3 do
                    label.Text = Utils:GenerateRandomString(math.random(1, 3))
                    task.wait(0.03)
                end
                
                -- Fade out after appearing
                task.wait(0.1)
                Utils:Tween(label, {TextTransparency = 0.8}, 0.3)
            end)
        end
    end)

    -- Show logo after strings start
    task.wait(duration * 0.3)
    Utils:IOSBounce(ImageLabel, {ImageTransparency = 0, Size = UDim2.new(0, 350, 0, 350)}, 0.8)
    Utils:Tween(DevVersionLabel, {TextTransparency = 0}, 0.5)

    task.wait(duration * 0.7)

    -- Fade everything out
    Utils:Tween(Container, {BackgroundTransparency = 1}, 0.5)
    Utils:Tween(ImageLabel, {ImageTransparency = 1, Size = UDim2.new(0, 400, 0, 400)}, 0.5)
    Utils:Tween(DevVersionLabel, {TextTransparency = 1}, 0.5)
    
    for _, label in ipairs(stringLabels) do
        Utils:Tween(label, {TextTransparency = 1}, 0.5)
    end
    
    task.wait(0.6)
    LoadingGui:Destroy()
end

function ScawsHub:CreateWindow(settings)
    settings = settings or {}
    local windowTitle = settings.Name or "ScawsHUB"
    local showLoading = settings.ShowLoading ~= false

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
    Main.ClipsDescendants = false
    Main.Parent = MainGui
    Utils:CreateCorner(Main, 16)
    Utils:CreateStroke(Main, Config.Colors.Border, 1)

    local MainInner = Instance.new("Frame")
    MainInner.Name = "MainInner"
    MainInner.Size = UDim2.new(1, 0, 1, 0)
    MainInner.Position = UDim2.new(0, 0, 0, 0)
    MainInner.BackgroundTransparency = 1
    MainInner.ClipsDescendants = true
    MainInner.BorderSizePixel = 0
    MainInner.Parent = Main
    Utils:CreateCorner(MainInner, 16)

    Utils:IOSBounce(Main, {Size = Config.WindowSize}, 0.7)

    local Shadow = Instance.new("ImageLabel")
    Shadow.Name = "Shadow"
    Shadow.AnchorPoint = Vector2.new(0.5, 0.5)
    Shadow.Position = UDim2.new(0.5, 0, 0.5, 0)
    Shadow.Size = UDim2.new(1, 45, 1, 45)
    Shadow.BackgroundTransparency = 1
    Shadow.Image = "rbxassetid://5554236805"
    Shadow.ImageColor3 = Color3.fromRGB(0, 0, 0)
    Shadow.ImageTransparency = 0.2
    Shadow.ZIndex = 0
    Shadow.Parent = Main

    local Topbar = Instance.new("Frame")
    Topbar.Name = "Topbar"
    Topbar.Size = UDim2.new(1, 0, 0, 45)
    Topbar.BackgroundColor3 = Config.Colors.Topbar
    Topbar.BackgroundTransparency = 0.15
    Topbar.BorderSizePixel = 0
    Topbar.ClipsDescendants = true
    Topbar.Parent = MainInner
    Utils:CreateCorner(Topbar, 16)

    local TopbarFix = Instance.new("Frame")
    TopbarFix.Size = UDim2.new(1, 0, 0, 20)
    TopbarFix.Position = UDim2.new(0, 0, 1, -20)
    TopbarFix.BackgroundColor3 = Config.Colors.Topbar
    TopbarFix.BackgroundTransparency = 0.15
    TopbarFix.BorderSizePixel = 0
    TopbarFix.Parent = Topbar

    local TitleLabel = Instance.new("TextLabel")
    TitleLabel.Name = "Title"
    TitleLabel.Size = UDim2.new(0, 200, 1, 0)
    TitleLabel.Position = UDim2.new(0, 18, 0, -8)
    TitleLabel.BackgroundTransparency = 1
    TitleLabel.Font = Enum.Font.GothamBold
    TitleLabel.Text = windowTitle
    TitleLabel.TextColor3 = Config.Colors.Text
    TitleLabel.TextSize = 16
    TitleLabel.TextXAlignment = Enum.TextXAlignment.Left
    TitleLabel.Parent = Topbar

    local CreditsLabel = Instance.new("TextLabel")
    CreditsLabel.Name = "Credits"
    CreditsLabel.Size = UDim2.new(0, 150, 1, 0)
    CreditsLabel.Position = UDim2.new(0, 18, 0, 10)
    CreditsLabel.BackgroundTransparency = 1
    CreditsLabel.Font = Enum.Font.Gotham
    CreditsLabel.Text = "by ScawsHub • DevVersion"
    CreditsLabel.TextColor3 = Config.Colors.Accent
    CreditsLabel.TextSize = 9
    CreditsLabel.TextXAlignment = Enum.TextXAlignment.Left
    CreditsLabel.TextTransparency = 0.4
    CreditsLabel.Parent = Topbar

    local CloseButton = Instance.new("TextButton")
    CloseButton.Name = "CloseButton"
    CloseButton.AnchorPoint = Vector2.new(1, 0.5)
    CloseButton.Position = UDim2.new(1, -8, 0.5, 0)
    CloseButton.Size = UDim2.new(0, 30, 0, 30)
    CloseButton.BackgroundColor3 = Config.Colors.Border
    CloseButton.BackgroundTransparency = 0.6
    CloseButton.BorderSizePixel = 0
    CloseButton.Font = Enum.Font.GothamBold
    CloseButton.Text = "×"
    CloseButton.TextColor3 = Config.Colors.Text
    CloseButton.TextSize = 18
    CloseButton.Parent = Topbar
    Utils:CreateCorner(CloseButton, 15)

    local MinimizeButton = Instance.new("TextButton")
    MinimizeButton.Name = "MinimizeButton"
    MinimizeButton.AnchorPoint = Vector2.new(1, 0.5)
    MinimizeButton.Position = UDim2.new(1, -43, 0.5, 0)
    MinimizeButton.Size = UDim2.new(0, 30, 0, 30)
    MinimizeButton.BackgroundColor3 = Config.Colors.Border
    MinimizeButton.BackgroundTransparency = 0.6
    MinimizeButton.BorderSizePixel = 0
    MinimizeButton.Font = Enum.Font.GothamBold
    MinimizeButton.Text = "−"
    MinimizeButton.TextColor3 = Config.Colors.Text
    MinimizeButton.TextSize = 16
    MinimizeButton.Parent = Topbar
    Utils:CreateCorner(MinimizeButton, 15)

    -- Player Avatar Button
    local player = Players.LocalPlayer
    local AvatarButton = Instance.new("ImageButton")
    AvatarButton.Name = "AvatarButton"
    AvatarButton.AnchorPoint = Vector2.new(1, 0.5)
    AvatarButton.Position = UDim2.new(1, -78, 0.5, 0)
    AvatarButton.Size = UDim2.new(0, 30, 0, 30)
    AvatarButton.BackgroundColor3 = Config.Colors.Border
    AvatarButton.BackgroundTransparency = 0.6
    AvatarButton.BorderSizePixel = 0
    AvatarButton.Image = "rbxthumb://type=AvatarHeadShot&id=" .. player.UserId .. "&w=150&h=150"
    AvatarButton.Parent = Topbar
    Utils:CreateCorner(AvatarButton, 15)

    -- Player Info Hover Frame (Enhanced)
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
    
    local InfoStroke = Utils:CreateStroke(PlayerInfoFrame, Config.Colors.Accent, 2)
    InfoStroke.Transparency = 1

    local PlayerInfoLayout = Instance.new("UIPadding")
    PlayerInfoLayout.PaddingLeft = UDim.new(0, 14)
    PlayerInfoLayout.PaddingRight = UDim.new(0, 14)
    PlayerInfoLayout.PaddingTop = UDim.new(0, 12)
    PlayerInfoLayout.PaddingBottom = UDim.new(0, 12)
    PlayerInfoLayout.Parent = PlayerInfoFrame

    -- Title Header
    local InfoHeader = Instance.new("TextLabel")
    InfoHeader.Size = UDim2.new(1, 0, 0, 20)
    InfoHeader.Position = UDim2.new(0, 0, 0, 0)
    InfoHeader.BackgroundTransparency = 1
    InfoHeader.Font = Enum.Font.GothamBold
    InfoHeader.Text = "PLAYER INFO"
    InfoHeader.TextColor3 = Config.Colors.Accent
    InfoHeader.TextSize = 13
    InfoHeader.TextXAlignment = Enum.TextXAlignment.Left
    InfoHeader.TextTransparency = 1
    InfoHeader.Parent = PlayerInfoFrame

    local Divider = Instance.new("Frame")
    Divider.Size = UDim2.new(1, 0, 0, 1)
    Divider.Position = UDim2.new(0, 0, 0, 24)
    Divider.BackgroundColor3 = Config.Colors.Border
    Divider.BackgroundTransparency = 1
    Divider.BorderSizePixel = 0
    Divider.Parent = PlayerInfoFrame

    local UsernameLabel = Instance.new("TextLabel")
    UsernameLabel.Size = UDim2.new(1, 0, 0, 16)
    UsernameLabel.Position = UDim2.new(0, 0, 0, 30)
    UsernameLabel.BackgroundTransparency = 1
    UsernameLabel.Font = Enum.Font.GothamBold
    UsernameLabel.Text = "Username: " .. player.Name
    UsernameLabel.TextColor3 = Config.Colors.Text
    UsernameLabel.TextSize = 12
    UsernameLabel.TextXAlignment = Enum.TextXAlignment.Left
    UsernameLabel.TextTransparency = 1
    UsernameLabel.Parent = PlayerInfoFrame

    local OwnerLabel = Instance.new("TextLabel")
    OwnerLabel.Size = UDim2.new(1, 0, 0, 14)
    OwnerLabel.Position = UDim2.new(0, 0, 0, 48)
    OwnerLabel.BackgroundTransparency = 1
    OwnerLabel.Font = Enum.Font.GothamMedium
    OwnerLabel.Text = "Owner of ScawsHub"
    OwnerLabel.TextColor3 = Config.Colors.Accent
    OwnerLabel.TextSize = 10
    OwnerLabel.TextXAlignment = Enum.TextXAlignment.Left
    OwnerLabel.TextTransparency = 1
    OwnerLabel.Parent = PlayerInfoFrame

    local UserIdLabel = Instance.new("TextLabel")
    UserIdLabel.Size = UDim2.new(1, 0, 0, 16)
    UserIdLabel.Position = UDim2.new(0, 0, 0, 68)
    UserIdLabel.BackgroundTransparency = 1
    UserIdLabel.Font = Enum.Font.Gotham
    UserIdLabel.Text = "User ID: " .. player.UserId
    UserIdLabel.TextColor3 = Config.Colors.TextDark
    UserIdLabel.TextSize = 11
    UserIdLabel.TextXAlignment = Enum.TextXAlignment.Left
    UserIdLabel.TextTransparency = 1
    UserIdLabel.Parent = PlayerInfoFrame

    local AccountAgeLabel = Instance.new("TextLabel")
    AccountAgeLabel.Size = UDim2.new(1, 0, 0, 16)
    AccountAgeLabel.Position = UDim2.new(0, 0, 0, 86)
    AccountAgeLabel.BackgroundTransparency = 1
    AccountAgeLabel.Font = Enum.Font.Gotham
    AccountAgeLabel.Text = "Account Age: " .. player.AccountAge .. " days"
    AccountAgeLabel.TextColor3 = Config.Colors.TextDark
    AccountAgeLabel.TextSize = 11
    AccountAgeLabel.TextXAlignment = Enum.TextXAlignment.Left
    AccountAgeLabel.TextTransparency = 1
    AccountAgeLabel.Parent = PlayerInfoFrame

    local JobIdLabel = Instance.new("TextLabel")
    JobIdLabel.Size = UDim2.new(1, 0, 0, 16)
    JobIdLabel.Position = UDim2.new(0, 0, 0, 104)
    JobIdLabel.BackgroundTransparency = 1
    JobIdLabel.Font = Enum.Font.Gotham
    JobIdLabel.Text = "Job ID: " .. game.JobId:sub(1, 8) .. "..."
    JobIdLabel.TextColor3 = Config.Colors.TextDark
    JobIdLabel.TextSize = 11
    JobIdLabel.TextXAlignment = Enum.TextXAlignment.Left
    JobIdLabel.TextTransparency = 1
    JobIdLabel.Parent = PlayerInfoFrame

    local SessionLabel = Instance.new("TextLabel")
    SessionLabel.Size = UDim2.new(1, 0, 0, 16)
    SessionLabel.Position = UDim2.new(0, 0, 0, 122)
    SessionLabel.BackgroundTransparency = 1
    SessionLabel.Font = Enum.Font.Gotham
    SessionLabel.Text = "Session Time: 00:00:00"
    SessionLabel.TextColor3 = Config.Colors.TextDark
    SessionLabel.TextSize = 11
    SessionLabel.TextXAlignment = Enum.TextXAlignment.Left
    SessionLabel.TextTransparency = 1
    SessionLabel.Parent = PlayerInfoFrame

    local PingLabel = Instance.new("TextLabel")
    PingLabel.Size = UDim2.new(0.5, -5, 0, 16)
    PingLabel.Position = UDim2.new(0, 0, 0, 140)
    PingLabel.BackgroundTransparency = 1
    PingLabel.Font = Enum.Font.Gotham
    PingLabel.Text = "Ping: " .. PingTracker.currentPing .. "ms"
    PingLabel.TextColor3 = Config.Colors.Warning
    PingLabel.TextSize = 11
    PingLabel.TextXAlignment = Enum.TextXAlignment.Left
    PingLabel.TextTransparency = 1
    PingLabel.Parent = PlayerInfoFrame

    local FPSLabel = Instance.new("TextLabel")
    FPSLabel.Size = UDim2.new(0.5, -5, 0, 16)
    FPSLabel.Position = UDim2.new(0.5, 5, 0, 140)
    FPSLabel.BackgroundTransparency = 1
    FPSLabel.Font = Enum.Font.Gotham
    FPSLabel.Text = "FPS: " .. FPSTracker.currentFPS
    FPSLabel.TextColor3 = Config.Colors.Success
    FPSLabel.TextSize = 11
    FPSLabel.TextXAlignment = Enum.TextXAlignment.Left
    FPSLabel.TextTransparency = 1
    FPSLabel.Parent = PlayerInfoFrame

    -- Update stats in real-time when visible
    local statsConnection
    local allInfoLabels = {
        InfoHeader, UsernameLabel, OwnerLabel, UserIdLabel, 
        AccountAgeLabel, JobIdLabel, SessionLabel, PingLabel, FPSLabel
    }

    local function FadeInInfo()
        PlayerInfoFrame.Visible = true
        Utils:Spring(PlayerInfoFrame, {
            BackgroundTransparency = 0.05, 
            Size = UDim2.new(0, 230, 0, 170)
        }, 0.35)
        Utils:Tween(InfoStroke, {Transparency = 0.1}, 0.35)
        Utils:Tween(Divider, {BackgroundTransparency = 0.5}, 0.35)
        
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
            Size = UDim2.new(0, 230, 0, 0)
        }, 0.3)
        
        task.wait(0.35)
        PlayerInfoFrame.Visible = false
    end

    AvatarButton.MouseEnter:Connect(function()
        FadeInInfo()
        Utils:SmoothFade(AvatarButton, 0.3, 0.2)
        
        statsConnection = RunService.RenderStepped:Connect(function()
            local sessionTime = tick() - SessionStartTime
            SessionLabel.Text = "Session Time: " .. Utils:FormatTime(sessionTime)
            FPSLabel.Text = "FPS: " .. FPSTracker.currentFPS
            PingLabel.Text = "Ping: " .. PingTracker.currentPing .. "ms"
            
            -- Color code FPS
            if FPSTracker.currentFPS >= 60 then
                FPSLabel.TextColor3 = Config.Colors.Success
            elseif FPSTracker.currentFPS >= 30 then
                FPSLabel.TextColor3 = Config.Colors.Warning
            else
                FPSLabel.TextColor3 = Config.Colors.Error
            end
            
            -- Color code Ping
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
        Utils:SmoothFade(AvatarButton, 0.6, 0.2)
        
        if statsConnection then
            statsConnection:Disconnect()
            statsConnection = nil
        end
    end)

    AvatarButton.MouseMoved:Connect(function(x, y)
        if PlayerInfoFrame.Visible then
            -- Position frame to the left of the avatar button
            PlayerInfoFrame.Position = UDim2.new(0, x - PlayerInfoFrame.AbsoluteSize.X - 15, 0, y - 85)
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
    Sidebar.Parent = MainInner

    local SidebarBottomFix = Instance.new("Frame")
    SidebarBottomFix.Name = "BottomFix"
    SidebarBottomFix.Size = UDim2.new(1, 2, 0, 20)
    SidebarBottomFix.Position = UDim2.new(0, -1, 1, -20)
    SidebarBottomFix.BackgroundColor3 = Config.Colors.Sidebar
    SidebarBottomFix.BackgroundTransparency = 0.15
    SidebarBottomFix.BorderSizePixel = 0
    SidebarBottomFix.Parent = Sidebar

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
    TabContainer.Size = UDim2.new(1, -10, 1, -10)
    TabContainer.Position = UDim2.new(0, 5, 0, 5)
    TabContainer.BackgroundTransparency = 1
    TabContainer.BorderSizePixel = 0
    TabContainer.ScrollBarThickness = 4
    TabContainer.ScrollBarImageColor3 = Config.Colors.Accent
    TabContainer.ScrollBarImageTransparency = 0.3
    TabContainer.CanvasSize = UDim2.new(0, 0, 0, 0)
    TabContainer.Parent = Sidebar

    local TabLayout = Instance.new("UIListLayout")
    TabLayout.SortOrder = Enum.SortOrder.LayoutOrder
    TabLayout.Padding = UDim.new(0, 8)
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
    ContentArea.Parent = MainInner

    local ContentBottomFix = Instance.new("Frame")
    ContentBottomFix.Name = "BottomFix"
    ContentBottomFix.Size = UDim2.new(1, 1, 0, 20)
    ContentBottomFix.Position = UDim2.new(0, 0, 1, -20)
    ContentBottomFix.BackgroundColor3 = Config.Colors.Main
    ContentBottomFix.BackgroundTransparency = 0.15
    ContentBottomFix.BorderSizePixel = 0
    ContentBottomFix.Parent = ContentArea

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
    }

    CloseButton.MouseButton1Click:Connect(function()
        local tween = TweenService:Create(
            CloseButton,
            TweenInfo.new(0.1, Enum.EasingStyle.Quad, Enum.EasingDirection.Out),
            {BackgroundTransparency = 0.3, Size = UDim2.new(0, 26, 0, 26)}
        )
        tween:Play()
        task.wait(0.06)
        local tween2 = TweenService:Create(
            CloseButton,
            TweenInfo.new(0.15, Enum.EasingStyle.Back, Enum.EasingDirection.Out),
            {BackgroundTransparency = 0.6, Size = UDim2.new(0, 30, 0, 30)}
        )
        tween2:Play()
        
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
        local tween = TweenService:Create(
            MinimizeButton,
            TweenInfo.new(0.1, Enum.EasingStyle.Quad, Enum.EasingDirection.Out),
            {BackgroundTransparency = 0.3, Size = UDim2.new(0, 26, 0, 26)}
        )
        tween:Play()
        task.wait(0.06)
        local tween2 = TweenService:Create(
            MinimizeButton,
            TweenInfo.new(0.15, Enum.EasingStyle.Back, Enum.EasingDirection.Out),
            {BackgroundTransparency = 0.6, Size = UDim2.new(0, 30, 0, 30)}
        )
        tween2:Play()
        
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
        Utils:SmoothFade(CloseButton, 0.3, 0.2)
    end)
    CloseButton.MouseLeave:Connect(function()
        Utils:SmoothFade(CloseButton, 0.6, 0.2)
    end)

    MinimizeButton.MouseEnter:Connect(function()
        Utils:SmoothFade(MinimizeButton, 0.3, 0.2)
    end)
    MinimizeButton.MouseLeave:Connect(function()
        Utils:SmoothFade(MinimizeButton, 0.6, 0.2)
    end)

    function Window:CreateTab(name, icon)
        local Tab = {}
        Tab.Name = name
        Tab.Button = nil
        Tab.Content = nil
        Tab.Elements = {}
        
        local TabButton = Instance.new("TextButton")
        TabButton.Name = name
        TabButton.Size = UDim2.new(1, -10, 0, 36)
        TabButton.BackgroundColor3 = Config.Colors.Accent
        TabButton.BackgroundTransparency = 1
        TabButton.BorderSizePixel = 0
        TabButton.Font = Enum.Font.GothamSemibold
        TabButton.Text = "  " .. name
        TabButton.TextColor3 = Config.Colors.TextDark
        TabButton.TextSize = 14
        TabButton.TextXAlignment = Enum.TextXAlignment.Left
        TabButton.ZIndex = 2
        TabButton.Parent = TabContainer
        Utils:CreateCorner(TabButton, 10)
        
        Tab.Button = TabButton
        
        local TabContent = Instance.new("ScrollingFrame")
        TabContent.Name = name .. "_Content"
        TabContent.Size = UDim2.new(1, -20, 1, -20)
        TabContent.Position = UDim2.new(0, 10, 0, 10)
        TabContent.BackgroundTransparency = 1
        TabContent.BorderSizePixel = 0
        TabContent.ScrollBarThickness = 3
        TabContent.ScrollBarImageColor3 = Config.Colors.Accent
        TabContent.ScrollBarImageTransparency = 0.3
        TabContent.CanvasSize = UDim2.new(0, 0, 0, 0)
        TabContent.Visible = false
        TabContent.Parent = ContentArea
        
        local ContentLayout = Instance.new("UIListLayout")
        ContentLayout.SortOrder = Enum.SortOrder.LayoutOrder
        ContentLayout.Padding = UDim.new(0, 10)
        ContentLayout.Parent = TabContent
        
        ContentLayout:GetPropertyChangedSignal("AbsoluteContentSize"):Connect(function()
            TabContent.CanvasSize = UDim2.new(0, 0, 0, ContentLayout.AbsoluteContentSize.Y + 20)
        end)
        
        Tab.Content = TabContent
        
        TabButton.MouseButton1Click:Connect(function()
            Window:SelectTab(Tab)
        end)
        
        TabButton.MouseEnter:Connect(function()
            if Window.CurrentTab ~= Tab then
                Utils:SmoothFade(TabButton, 0.85, 0.2)
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
        
        function Tab:CreateButton(settings)
            settings = settings or {}
            local buttonName = settings.Name or "Button"
            local callback = settings.Callback or function() end
            
            local ButtonFrame = Instance.new("Frame")
            ButtonFrame.Name = buttonName
            ButtonFrame.Size = UDim2.new(1, -6, 0, 40)
            ButtonFrame.BackgroundColor3 = Config.Colors.Background
            ButtonFrame.BackgroundTransparency = 0.2
            ButtonFrame.BorderSizePixel = 0
            ButtonFrame.Parent = TabContent
            Utils:CreateCorner(ButtonFrame, 10)
            Utils:CreateStroke(ButtonFrame, Config.Colors.Border, 1)
            
            local Button = Instance.new("TextButton")
            Button.Size = UDim2.new(1, -20, 1, -8)
            Button.Position = UDim2.new(0, 10, 0, 4)
            Button.BackgroundTransparency = 1
            Button.Font = Enum.Font.GothamSemibold
            Button.Text = buttonName
            Button.TextColor3 = Config.Colors.Text
            Button.TextSize = 14
            Button.TextXAlignment = Enum.TextXAlignment.Left
            Button.Parent = ButtonFrame
            
            Button.MouseButton1Click:Connect(function()
                Utils:Spring(ButtonFrame, {BackgroundColor3 = Config.Colors.Accent, BackgroundTransparency = 0}, 0.1)
                task.wait(0.08)
                Utils:Spring(ButtonFrame, {BackgroundColor3 = Config.Colors.Background, BackgroundTransparency = 0.2}, 0.15)
                callback()
            end)
            
            Button.MouseEnter:Connect(function()
                Utils:SmoothFade(ButtonFrame, 0.1, 0.2)
            end)
            
            Button.MouseLeave:Connect(function()
                Utils:SmoothFade(ButtonFrame, 0.2, 0.2)
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
            ToggleFrame.Size = UDim2.new(1, -6, 0, 40)
            ToggleFrame.BackgroundColor3 = Config.Colors.Background
            ToggleFrame.BackgroundTransparency = 0.2
            ToggleFrame.BorderSizePixel = 0
            ToggleFrame.Parent = TabContent
            Utils:CreateCorner(ToggleFrame, 10)
            Utils:CreateStroke(ToggleFrame, Config.Colors.Border, 1)
            
            local Label = Instance.new("TextLabel")
            Label.Size = UDim2.new(1, -65, 1, 0)
            Label.Position = UDim2.new(0, 12, 0, 0)
            Label.BackgroundTransparency = 1
            Label.Font = Enum.Font.GothamSemibold
            Label.Text = toggleName
            Label.TextColor3 = Config.Colors.Text
            Label.TextSize = 14
            Label.TextXAlignment = Enum.TextXAlignment.Left
            Label.Parent = ToggleFrame
            
            local ToggleButton = Instance.new("TextButton")
            ToggleButton.AnchorPoint = Vector2.new(1, 0.5)
            ToggleButton.Position = UDim2.new(1, -12, 0.5, 0)
            ToggleButton.Size = UDim2.new(0, 44, 0, 24)
            ToggleButton.BackgroundColor3 = Config.Colors.Border
            ToggleButton.BackgroundTransparency = 0.2
            ToggleButton.BorderSizePixel = 0
            ToggleButton.Text = ""
            ToggleButton.Parent = ToggleFrame
            Utils:CreateCorner(ToggleButton, 12)
            
            local ToggleIndicator = Instance.new("Frame")
            ToggleIndicator.Size = UDim2.new(0, 18, 0, 18)
            ToggleIndicator.Position = UDim2.new(0, 3, 0.5, -9)
            ToggleIndicator.BackgroundColor3 = Config.Colors.TextDark
            ToggleIndicator.BorderSizePixel = 0
            ToggleIndicator.Parent = ToggleButton
            Utils:CreateCorner(ToggleIndicator, 9)
            
            local toggled = default
            
            local function UpdateToggle()
                if toggled then
                    Utils:Spring(ToggleButton, {BackgroundColor3 = Config.Colors.Accent, BackgroundTransparency = 0}, 0.25)
                    Utils:Spring(ToggleIndicator, {Position = UDim2.new(1, -21, 0.5, -9), BackgroundColor3 = Config.Colors.Text}, 0.25)
                else
                    Utils:Spring(ToggleButton, {BackgroundColor3 = Config.Colors.Border, BackgroundTransparency = 0.2}, 0.25)
                    Utils:Spring(ToggleIndicator, {Position = UDim2.new(0, 3, 0.5, -9), BackgroundColor3 = Config.Colors.TextDark}, 0.25)
                end
                callback(toggled)
            end
            
            ToggleButton.MouseButton1Click:Connect(function()
                toggled = not toggled
                UpdateToggle()
            end)
            
            UpdateToggle()
            
            return ToggleFrame
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
            SliderFrame.Size = UDim2.new(1, -6, 0, 58)
            SliderFrame.BackgroundColor3 = Config.Colors.Background
            SliderFrame.BackgroundTransparency = 0.2
            SliderFrame.BorderSizePixel = 0
            SliderFrame.Parent = TabContent
            Utils:CreateCorner(SliderFrame, 10)
            Utils:CreateStroke(SliderFrame, Config.Colors.Border, 1)
            
            local Label = Instance.new("TextLabel")
            Label.Size = UDim2.new(1, -20, 0, 20)
            Label.Position = UDim2.new(0, 12, 0, 6)
            Label.BackgroundTransparency = 1
            Label.Font = Enum.Font.GothamSemibold
            Label.Text = sliderName
            Label.TextColor3 = Config.Colors.Text
            Label.TextSize = 14
            Label.TextXAlignment = Enum.TextXAlignment.Left
            Label.Parent = SliderFrame
            
            local ValueLabel = Instance.new("TextLabel")
            ValueLabel.AnchorPoint = Vector2.new(1, 0)
            ValueLabel.Size = UDim2.new(0, 60, 0, 20)
            ValueLabel.Position = UDim2.new(1, -12, 0, 6)
            ValueLabel.BackgroundTransparency = 1
            ValueLabel.Font = Enum.Font.GothamBold
            ValueLabel.Text = tostring(default)
            ValueLabel.TextColor3 = Config.Colors.Accent
            ValueLabel.TextSize = 14
            ValueLabel.TextXAlignment = Enum.TextXAlignment.Right
            ValueLabel.Parent = SliderFrame
            
            local SliderBG = Instance.new("Frame")
            SliderBG.Size = UDim2.new(1, -24, 0, 6)
            SliderBG.Position = UDim2.new(0, 12, 0, 36)
            SliderBG.BackgroundColor3 = Config.Colors.Border
            SliderBG.BackgroundTransparency = 0.3
            SliderBG.BorderSizePixel = 0
            SliderBG.Parent = SliderFrame
            Utils:CreateCorner(SliderBG, 3)
            
            local SliderFill = Instance.new("Frame")
            SliderFill.Size = UDim2.new((default - min) / (max - min), 0, 1, 0)
            SliderFill.BackgroundColor3 = Config.Colors.Accent
            SliderFill.BorderSizePixel = 0
            SliderFill.Parent = SliderBG
            Utils:CreateCorner(SliderFill, 3)
            
            local SliderButton = Instance.new("TextButton")
            SliderButton.Size = UDim2.new(1, 0, 1, 20)
            SliderButton.Position = UDim2.new(0, 0, 0, -10)
            SliderButton.BackgroundTransparency = 1
            SliderButton.Text = ""
            SliderButton.Parent = SliderBG
            
            local dragging = false
            
            local function UpdateSlider(input)
                local pos = math.clamp((input.Position.X - SliderBG.AbsolutePosition.X) / SliderBG.AbsoluteSize.X, 0, 1)
                local value = math.floor((min + (max - min) * pos) / increment + 0.5) * increment
                value = math.clamp(value, min, max)
                
                ValueLabel.Text = tostring(value)
                Utils:Spring(SliderFill, {Size = UDim2.new((value - min) / (max - min), 0, 1, 0)}, 0.15)
                callback(value)
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
            
            return SliderFrame
        end
        
        function Tab:CreateDropdown(settings)
            settings = settings or {}
            local dropdownName = settings.Name or "Dropdown"
            local options = settings.Options or {}
            local default = settings.Default or (options[1] or "None")
            local callback = settings.Callback or function() end
            
            -- Main container with NO background
            local DropdownFrame = Instance.new("Frame")
            DropdownFrame.Name = dropdownName
            DropdownFrame.Size = UDim2.new(1, -6, 0, 40)
            DropdownFrame.BackgroundTransparency = 1
            DropdownFrame.BorderSizePixel = 0
            DropdownFrame.Parent = TabContent
            DropdownFrame.ClipsDescendants = true
            DropdownFrame.ZIndex = 10
            
            -- Header background (the clickable part with actual background)
            local DropdownHeader = Instance.new("Frame")
            DropdownHeader.Name = "Header"
            DropdownHeader.Size = UDim2.new(1, 0, 0, 40)
            DropdownHeader.Position = UDim2.new(0, 0, 0, 0)
            DropdownHeader.BackgroundColor3 = Config.Colors.Background
            DropdownHeader.BackgroundTransparency = 0.2
            DropdownHeader.BorderSizePixel = 0
            DropdownHeader.Parent = DropdownFrame
            Utils:CreateCorner(DropdownHeader, 10)
            Utils:CreateStroke(DropdownHeader, Config.Colors.Border, 1)
            
            local Label = Instance.new("TextLabel")
            Label.Size = UDim2.new(1, -40, 0, 40)
            Label.Position = UDim2.new(0, 12, 0, 0)
            Label.BackgroundTransparency = 1
            Label.Font = Enum.Font.GothamSemibold
            Label.Text = dropdownName .. ": " .. default
            Label.TextColor3 = Config.Colors.Text
            Label.TextSize = 14
            Label.TextXAlignment = Enum.TextXAlignment.Left
            Label.Parent = DropdownHeader
            
            local Arrow = Instance.new("TextLabel")
            Arrow.AnchorPoint = Vector2.new(1, 0.5)
            Arrow.Size = UDim2.new(0, 20, 0, 20)
            Arrow.Position = UDim2.new(1, -12, 0, 20)
            Arrow.BackgroundTransparency = 1
            Arrow.Font = Enum.Font.GothamBold
            Arrow.Text = "›"
            Arrow.TextColor3 = Config.Colors.TextDark
            Arrow.TextSize = 16
            Arrow.Rotation = 90
            Arrow.Parent = DropdownHeader
            
            local OptionsContainer = Instance.new("Frame")
            OptionsContainer.Size = UDim2.new(1, -12, 0, #options * 34)
            OptionsContainer.Position = UDim2.new(0, 6, 0, 46)
            OptionsContainer.BackgroundTransparency = 1
            OptionsContainer.BorderSizePixel = 0
            OptionsContainer.Parent = DropdownFrame
            
            local OptionsLayout = Instance.new("UIListLayout")
            OptionsLayout.SortOrder = Enum.SortOrder.LayoutOrder
            OptionsLayout.Padding = UDim.new(0, 2)
            OptionsLayout.Parent = OptionsContainer
            
            local isOpen = false
            local currentValue = default
            
            local function ToggleDropdown()
                isOpen = not isOpen
                if isOpen then
                    Utils:IOSBounce(DropdownFrame, {Size = UDim2.new(1, -6, 0, 46 + #options * 34 + 6)}, 0.3)
                    Utils:IOSBounce(Arrow, {Rotation = 270}, 0.3)
                else
                    Utils:IOSBounce(DropdownFrame, {Size = UDim2.new(1, -6, 0, 40)}, 0.3)
                    Utils:IOSBounce(Arrow, {Rotation = 90}, 0.3)
                end
            end
            
            local DropdownButton = Instance.new("TextButton")
            DropdownButton.Size = UDim2.new(1, 0, 0, 40)
            DropdownButton.BackgroundTransparency = 1
            DropdownButton.Text = ""
            DropdownButton.ZIndex = 2
            DropdownButton.Parent = DropdownHeader
            
            DropdownButton.MouseButton1Click:Connect(ToggleDropdown)
            
            for _, option in ipairs(options) do
                local OptionButton = Instance.new("TextButton")
                OptionButton.Size = UDim2.new(1, 0, 0, 32)
                OptionButton.BackgroundColor3 = Config.Colors.Background
                OptionButton.BackgroundTransparency = 0.3
                OptionButton.BorderSizePixel = 0
                OptionButton.Font = Enum.Font.Gotham
                OptionButton.Text = "  " .. option
                OptionButton.TextColor3 = Config.Colors.Text
                OptionButton.TextSize = 13
                OptionButton.TextXAlignment = Enum.TextXAlignment.Left
                OptionButton.Parent = OptionsContainer
                Utils:CreateCorner(OptionButton, 8)
                
                OptionButton.MouseButton1Click:Connect(function()
                    currentValue = option
                    Label.Text = dropdownName .. ": " .. option
                    ToggleDropdown()
                    callback(option)
                end)
                
                OptionButton.MouseEnter:Connect(function()
                    Utils:SmoothFade(OptionButton, 0.15, 0.2)
                end)
                
                OptionButton.MouseLeave:Connect(function()
                    Utils:SmoothFade(OptionButton, 0.3, 0.2)
                end)
            end
            
            return DropdownFrame
        end
        
        function Tab:CreateLabel(text)
            local LabelFrame = Instance.new("Frame")
            LabelFrame.Size = UDim2.new(1, -6, 0, 28)
            LabelFrame.BackgroundTransparency = 1
            LabelFrame.Parent = TabContent
            
            local Label = Instance.new("TextLabel")
            Label.Size = UDim2.new(1, -24, 1, 0)
            Label.Position = UDim2.new(0, 12, 0, 0)
            Label.BackgroundTransparency = 1
            Label.Font = Enum.Font.Gotham
            Label.Text = text
            Label.TextColor3 = Config.Colors.TextDark
            Label.TextSize = 13
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
        
        return Tab
    end

    function Window:SelectTab(tab)
        if self.IsTransitioning then return end
        if self.CurrentTab == tab then return end
        
        self.IsTransitioning = true
        
        for _, t in ipairs(self.Tabs) do
            if t == tab then
                Utils:SmoothFade(t.Button, 0.8, 0.3)
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
                                    local origTrans = child:GetAttribute("OriginalTransparency") or 0.2
                                    Utils:Tween(child, {BackgroundTransparency = origTrans}, 0.4)
                                end
                            end
                        end)
                    end
                end
            else
                Utils:SmoothFade(t.Button, 1, 0.3)
                Utils:Tween(t.Button, {TextColor3 = Config.Colors.TextDark}, 0.3)
            end
        end
        
        self.CurrentTab = tab
        
        task.delay(0.5, function()
            self.IsTransitioning = false
        end)
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
        NotifContainer.Size = UDim2.new(0, 340, 1, -40)
        NotifContainer.BackgroundTransparency = 1
        NotifContainer.Parent = notifGui
        
        local NotifLayout = Instance.new("UIListLayout")
        NotifLayout.SortOrder = Enum.SortOrder.LayoutOrder
        NotifLayout.Padding = UDim.new(0, 10)
        NotifLayout.VerticalAlignment = Enum.VerticalAlignment.Bottom
        NotifLayout.HorizontalAlignment = Enum.HorizontalAlignment.Right
        NotifLayout.Parent = NotifContainer
    end

    local NotifContainer = notifGui:FindFirstChild("NotifContainer")

    local Notification = Instance.new("Frame")
    Notification.Size = UDim2.new(0, 320, 0, 80)
    Notification.Position = UDim2.new(1, 340, 0, 0)
    Notification.BackgroundColor3 = Config.Colors.Background
    Notification.BackgroundTransparency = 0.05
    Notification.BorderSizePixel = 0
    Notification.Parent = NotifContainer
    Utils:CreateCorner(Notification, 12)

    local colorMap = {
        Info = Config.Colors.Accent,
        Success = Config.Colors.Success,
        Warning = Config.Colors.Warning,
        Error = Config.Colors.Error
    }

    local NotifStroke = Utils:CreateStroke(Notification, colorMap[type] or Config.Colors.Accent, 2)
    NotifStroke.Transparency = 0.1

    local Indicator = Instance.new("Frame")
    Indicator.Size = UDim2.new(0, 4, 1, -20)
    Indicator.Position = UDim2.new(0, 10, 0, 10)
    Indicator.BackgroundColor3 = colorMap[type] or Config.Colors.Accent
    Indicator.BorderSizePixel = 0
    Indicator.ZIndex = 2
    Indicator.Parent = Notification
    Utils:CreateCorner(Indicator, 2)

    local IconLabel = Instance.new("TextLabel")
    IconLabel.Size = UDim2.new(0, 24, 0, 24)
    IconLabel.Position = UDim2.new(0, 20, 0, 12)
    IconLabel.BackgroundTransparency = 1
    IconLabel.Font = Enum.Font.GothamBold
    IconLabel.TextSize = 18
    IconLabel.TextColor3 = colorMap[type] or Config.Colors.Accent
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
    Title.Size = UDim2.new(1, -60, 0, 22)
    Title.Position = UDim2.new(0, 50, 0, 12)
    Title.BackgroundTransparency = 1
    Title.Font = Enum.Font.GothamBold
    Title.Text = title
    Title.TextColor3 = Config.Colors.Text
    Title.TextSize = 14
    Title.TextXAlignment = Enum.TextXAlignment.Left
    Title.ZIndex = 2
    Title.Parent = Notification

    local Content = Instance.new("TextLabel")
    Content.Size = UDim2.new(1, -60, 0, 36)
    Content.Position = UDim2.new(0, 50, 0, 34)
    Content.BackgroundTransparency = 1
    Content.Font = Enum.Font.Gotham
    Content.Text = content
    Content.TextColor3 = Config.Colors.TextDark
    Content.TextSize = 12
    Content.TextXAlignment = Enum.TextXAlignment.Left
    Content.TextYAlignment = Enum.TextYAlignment.Top
    Content.TextWrapped = true
    Content.ZIndex = 2
    Content.Parent = Notification

    local ProgressBar = Instance.new("Frame")
    ProgressBar.Size = UDim2.new(1, -20, 0, 2)
    ProgressBar.Position = UDim2.new(0, 10, 1, -6)
    ProgressBar.BackgroundColor3 = colorMap[type] or Config.Colors.Accent
    ProgressBar.BorderSizePixel = 0
    ProgressBar.ZIndex = 2
    ProgressBar.Parent = Notification
    Utils:CreateCorner(ProgressBar, 1)

    local slideInTween = TweenService:Create(
        Notification,
        TweenInfo.new(0.6, Enum.EasingStyle.Back, Enum.EasingDirection.Out),
        {Position = UDim2.new(0, 0, 0, 0)}
    )
    slideInTween:Play()

    local progressTween = TweenService:Create(
        ProgressBar,
        TweenInfo.new(duration, Enum.EasingStyle.Linear, Enum.EasingDirection.InOut),
        {Size = UDim2.new(0, 0, 0, 2)}
    )
    
    task.wait(0.6)
    progressTween:Play()

    task.delay(duration, function()
        local slideOutTween = TweenService:Create(
            Notification,
            TweenInfo.new(0.5, Enum.EasingStyle.Back, Enum.EasingDirection.In),
            {Position = UDim2.new(1, 340, 0, 0)}
        )
        slideOutTween:Play()
        
        Utils:Tween(Notification, {BackgroundTransparency = 1}, 0.4)
        Utils:Tween(NotifStroke, {Transparency = 1}, 0.4)
        Utils:Tween(Indicator, {BackgroundTransparency = 1}, 0.4)
        Utils:Tween(IconLabel, {TextTransparency = 1}, 0.4)
        Utils:Tween(Title, {TextTransparency = 1}, 0.4)
        Utils:Tween(Content, {TextTransparency = 1}, 0.4)
        Utils:Tween(ProgressBar, {BackgroundTransparency = 1}, 0.4)
        
        task.wait(0.55)
        Notification:Destroy()
    end)
end

return ScawsHub
