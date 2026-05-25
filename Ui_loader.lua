if _G.NovaXLoaded then return _G.NovaXInstance end
_G.NovaXLoaded = true

if not game:IsLoaded() then game.Loaded:Wait() end

local NovaX = {}
NovaX.__index = NovaX

local Players           = game:GetService("Players")
local TweenService      = game:GetService("TweenService")
local UserInputService  = game:GetService("UserInputService")
local CoreGui           = game:GetService("CoreGui")
local RunService        = game:GetService("RunService")

local LocalPlayer = Players.LocalPlayer or Players:GetPropertyChangedSignal("LocalPlayer"):Wait() or Players.LocalPlayer

-- ═══════════════════════════════════════════════════════════════
-- SOLAR FLARE THEME
-- ═══════════════════════════════════════════════════════════════
local Theme = {
    Primary          = Color3.fromHex("0D0E12"),   -- Eclipse Dark
    Secondary        = Color3.fromHex("131418"),
    Card             = Color3.fromHex("1C1D24"),   -- Jet Stream
    CardHover        = Color3.fromHex("22232C"),
    CardBorder       = Color3.fromHex("2E2F3A"),
    Elevated         = Color3.fromHex("252630"),

    Accent           = Color3.fromHex("FF3E3E"),   -- Solar Flare
    AccentLight      = Color3.fromHex("FF6060"),
    AccentDark       = Color3.fromHex("CC2020"),
    AccentSurface    = Color3.fromHex("2A1010"),
    AccentSurfaceHover = Color3.fromHex("381515"),
    AccentGlow       = Color3.fromHex("FF3E3E"),

    Secondary2       = Color3.fromHex("FF9F00"),   -- Amber Glow
    TextPrimary      = Color3.fromHex("E2E4EC"),   -- Eclipse White
    TextSecondary    = Color3.fromHex("8A8C99"),
    TextTertiary     = Color3.fromHex("555666"),

    Success          = Color3.fromHex("3EFF8B"),
    Warning          = Color3.fromHex("FF9F00"),
    Error            = Color3.fromHex("FF3E3E"),
    Info             = Color3.fromHex("4DA6FF"),

    Border           = Color3.fromHex("2E2F3A"),

    FontBold         = Enum.Font.GothamBold,
    FontSemibold     = Enum.Font.GothamSemibold,
    FontMedium       = Enum.Font.GothamMedium,
    FontRegular      = Enum.Font.GothamMedium,

    CornerRadius     = 12,
    CornerRadiusSmall = 8,
    CornerRadiusXL   = 20,
    NormalSpeed      = 0.2,
    QuickSpeed       = 0.1,
    SpringSpeed      = 0.28,
}

-- ═══════════════════════════════════════════════════════════════
-- UTILITIES
-- ═══════════════════════════════════════════════════════════════
local Util = {}

function Util.Create(cls, props)
    local inst = Instance.new(cls)
    for k, v in pairs(props or {}) do
        if k ~= "Parent" then pcall(function() inst[k] = v end) end
    end
    if props and props.Parent then inst.Parent = props.Parent end
    return inst
end

function Util.Tween(obj, props, dur, style, dir)
    if not obj then return end
    TweenService:Create(obj, TweenInfo.new(dur or Theme.NormalSpeed, style or Enum.EasingStyle.Quint, dir or Enum.EasingDirection.Out), props):Play()
end

function Util.Spring(obj, props, spd)
    if not obj then return end
    TweenService:Create(obj, TweenInfo.new(spd or Theme.SpringSpeed, Enum.EasingStyle.Back, Enum.EasingDirection.Out), props):Play()
end

function Util.Corner(parent, r)
    return Util.Create("UICorner", {CornerRadius = UDim.new(0, r or Theme.CornerRadius), Parent = parent})
end

function Util.Stroke(parent, color, thickness)
    return Util.Create("UIStroke", {
        Color = color or Theme.Border, Thickness = thickness or 1,
        ApplyStrokeMode = Enum.ApplyStrokeMode.Border, Parent = parent
    })
end

function Util.Shadow(parent, offset, trans)
    return Util.Create("ImageLabel", {
        Name = "Shadow", AnchorPoint = Vector2.new(0.5, 0.5),
        Position = UDim2.new(0.5, 0, 0.5, offset or 6),
        Size = UDim2.new(1, 47, 1, 47), BackgroundTransparency = 1,
        Image = "rbxassetid://5554236805", ImageColor3 = Color3.new(0,0,0),
        ImageTransparency = trans or 0.4, ScaleType = Enum.ScaleType.Slice,
        SliceCenter = Rect.new(23, 23, 277, 277), ZIndex = -1, Parent = parent
    })
end

function Util.Glow(parent, color, size, trans)
    return Util.Create("ImageLabel", {
        Name = "Glow", AnchorPoint = Vector2.new(0.5, 0.5),
        Position = UDim2.new(0.5, 0, 0.5, 0),
        Size = UDim2.new(1, size or 30, 1, size or 30),
        BackgroundTransparency = 1, Image = "rbxassetid://5554236805",
        ImageColor3 = color or Theme.AccentGlow,
        ImageTransparency = trans or 0.82,
        ScaleType = Enum.ScaleType.Slice,
        SliceCenter = Rect.new(23, 23, 277, 277), ZIndex = -1, Parent = parent
    })
end

function Util.Ripple(btn)
    local r = Util.Create("Frame", {
        AnchorPoint = Vector2.new(0.5, 0.5),
        Position = UDim2.new(0.5, 0, 0.5, 0), Size = UDim2.new(0, 0, 0, 0),
        BackgroundColor3 = Color3.fromRGB(255,255,255), BackgroundTransparency = 0.85,
        ZIndex = btn.ZIndex + 1, Parent = btn
    })
    Util.Corner(r, 100)
    local mx = math.max(btn.AbsoluteSize.X, btn.AbsoluteSize.Y) * 2.5
    Util.Tween(r, {Size = UDim2.new(0, mx, 0, mx), BackgroundTransparency = 1}, 0.5, Enum.EasingStyle.Quad)
    task.delay(0.5, function() if r and r.Parent then r:Destroy() end end)
end

local function FadeAllChildren(frame, dur)
    for _, c in ipairs(frame:GetDescendants()) do
        if c:IsA("TextLabel") or c:IsA("TextButton") or c:IsA("TextBox") then
            Util.Tween(c, {TextTransparency = 1}, dur)
        end
        if c:IsA("Frame") and c.BackgroundTransparency < 1 then
            Util.Tween(c, {BackgroundTransparency = 1}, dur)
        end
        if c:IsA("ImageLabel") then Util.Tween(c, {ImageTransparency = 1}, dur) end
        if c:IsA("UIStroke") then Util.Tween(c, {Transparency = 1}, dur) end
    end
end

-- ═══════════════════════════════════════════════════════════════
-- JUNKIE KEY SYSTEM
-- ═══════════════════════════════════════════════════════════════
local JunkieSDK = {}

function JunkieSDK.new(config)
    local self = setmetatable({}, {__index = JunkieSDK})
    self.ApiKey   = config.ApiKey or ""
    self.Service  = config.Service or ""
    self.Provider = config.Provider or ""
    self.SDK      = nil
    local ok, res = pcall(function()
        return loadstring(game:HttpGet("https://junkie-development.de/sdk/JunkieKeySystem.lua"))()
    end)
    if ok and res then self.SDK = res end
    return self
end

function JunkieSDK:VerifyKey(key)
    if not self.SDK then return false, "Junkie SDK not loaded" end
    if not key or key == "" then return false, "Please enter a key" end
    key = key:gsub("%s+", "")
    local ok, r = pcall(function() return self.SDK.verifyKey(self.ApiKey, key, self.Service) end)
    if ok and r == true then return true, "Key verified!" end
    return false, "Invalid key. Please try again."
end

function JunkieSDK:CopyLink()
    if not self.SDK then return false, "Junkie SDK not loaded" end
    local ok, l = pcall(function() return self.SDK.getLink(self.ApiKey, self.Provider, self.Service) end)
    if ok and l then
        pcall(function() (setclipboard or toclipboard or function()end)(l) end)
        return true, "Link copied to clipboard!"
    end
    return false, "Failed to get key link"
end

-- ═══════════════════════════════════════════════════════════════
-- KEY SYSTEM UI
-- ═══════════════════════════════════════════════════════════════
function NovaX:CreateKeyUI(config)
    config = config or {}

    local handler    = JunkieSDK.new({ApiKey = config.ApiKey or "", Service = config.Service or "", Provider = config.Provider or ""})
    local title      = config.Title or "NOVA X"
    local subtitle   = config.Subtitle or "Key Verification"
    local onSuccess  = config.OnSuccess or function() end
    local onFailed   = config.OnFailed or function() end

    -- Auto-verify saved key
    local saved = getgenv().NOVAX_SAVED_KEY
    if saved and saved ~= "" then
        local ok, _ = handler:VerifyKey(saved)
        if ok then
            getgenv().SCRIPT_KEY = saved
            task.defer(onSuccess)
            return { Destroy = function() end, SetStatus = function() end }
        else
            getgenv().NOVAX_SAVED_KEY = nil
        end
    end

    getgenv().SCRIPT_KEY = nil

    local ScreenGui = Util.Create("ScreenGui", {
        Name = "NovaXKeySystem", ResetOnSpawn = false,
        ZIndexBehavior = Enum.ZIndexBehavior.Sibling, IgnoreGuiInset = true
    })
    pcall(function()
        if syn and syn.protect_gui then syn.protect_gui(ScreenGui); ScreenGui.Parent = CoreGui
        elseif gethui then ScreenGui.Parent = gethui()
        else ScreenGui.Parent = CoreGui end
    end)

    -- Dim overlay
    local Overlay = Util.Create("Frame", {
        Size = UDim2.new(1,0,1,0), BackgroundColor3 = Color3.new(0,0,0),
        BackgroundTransparency = 1, ZIndex = 0, Parent = ScreenGui
    })
    Util.Tween(Overlay, {BackgroundTransparency = 0.45}, 0.4)

    -- Main card
    local MainFrame = Util.Create("Frame", {
        Name = "Main", AnchorPoint = Vector2.new(0.5, 0.5),
        Position = UDim2.new(0.5, 0, 0.55, 0),
        Size = UDim2.new(0, 420, 0, 400),
        BackgroundColor3 = Theme.Primary,
        BackgroundTransparency = 1,
        ClipsDescendants = true, Parent = ScreenGui
    })
    Util.Corner(MainFrame, Theme.CornerRadiusXL)
    local MainStroke = Util.Stroke(MainFrame, Theme.CardBorder, 1)
    local MainShadow = Util.Shadow(MainFrame, 10, 0.3)
    local MainGlow   = Util.Glow(MainFrame, Theme.AccentGlow, 50, 0.93)

    -- Entry animation
    task.defer(function()
        Util.Tween(MainFrame, {BackgroundTransparency = 0, Position = UDim2.new(0.5,0,0.5,0)}, 0.45, Enum.EasingStyle.Quart)
    end)

    -- Header area (also drag handle)
    local Header = Util.Create("Frame", {
        Size = UDim2.new(1,0,0,130), BackgroundTransparency = 1, Parent = MainFrame
    })

    -- Drag pill
    Util.Corner(Util.Create("Frame", {
        AnchorPoint = Vector2.new(0.5, 0), Size = UDim2.new(0,36,0,4),
        Position = UDim2.new(0.5,0,0,10), BackgroundColor3 = Theme.Elevated, Parent = MainFrame
    }), 2)

    -- Logo box
    local LogoFrame = Util.Create("Frame", {
        AnchorPoint = Vector2.new(0.5, 0), Size = UDim2.new(0,54,0,54),
        Position = UDim2.new(0.5,0,0,22), BackgroundColor3 = Theme.Accent, Parent = Header
    })
    Util.Corner(LogoFrame, 14)
    Util.Glow(LogoFrame, Theme.AccentGlow, 24, 0.7)
    Util.Shadow(LogoFrame, 4, 0.5)

    -- Icon inside logo box (replace asset id with yours)
    Util.Create("ImageLabel", {
        Size = UDim2.new(1,-12,1,-12), Position = UDim2.new(0,6,0,6),
        BackgroundTransparency = 1, Image = "rbxassetid://0",  -- << YOUR ICON
        ScaleType = Enum.ScaleType.Fit, ZIndex = 2, Parent = LogoFrame
    })

    -- Title
    Util.Create("TextLabel", {
        AnchorPoint = Vector2.new(0.5,0), Size = UDim2.new(1,-40,0,22),
        Position = UDim2.new(0.5,0,0,82), BackgroundTransparency = 1,
        Font = Theme.FontBold, Text = title,
        TextColor3 = Theme.TextPrimary, TextSize = 20, Parent = Header
    })

    -- Subtitle
    Util.Create("TextLabel", {
        AnchorPoint = Vector2.new(0.5,0), Size = UDim2.new(1,-40,0,16),
        Position = UDim2.new(0.5,0,0,106), BackgroundTransparency = 1,
        Font = Theme.FontRegular, Text = subtitle,
        TextColor3 = Theme.TextTertiary, TextSize = 12, Parent = Header
    })

    -- Content area
    local Content = Util.Create("Frame", {
        Size = UDim2.new(1,-48,0,240), Position = UDim2.new(0,24,0,134),
        BackgroundTransparency = 1, Parent = MainFrame
    })

    -- Key input
    local InputFrame = Util.Create("Frame", {
        Size = UDim2.new(1,0,0,44), BackgroundColor3 = Theme.Card, Parent = Content
    })
    Util.Corner(InputFrame, Theme.CornerRadius)
    local InputStroke = Util.Stroke(InputFrame, Theme.CardBorder, 1)

    local KeyInput = Util.Create("TextBox", {
        Size = UDim2.new(1,-28,1,0), Position = UDim2.new(0,14,0,0),
        BackgroundTransparency = 1, Font = Theme.FontRegular,
        PlaceholderText = "Enter your key here...",
        PlaceholderColor3 = Theme.TextTertiary, Text = "",
        TextColor3 = Theme.TextPrimary, TextSize = 13,
        TextXAlignment = Enum.TextXAlignment.Left,
        ClearTextOnFocus = false, Parent = InputFrame
    })

    -- Status
    local StatusLabel = Util.Create("TextLabel", {
        Size = UDim2.new(1,0,0,18), Position = UDim2.new(0,0,0,50),
        BackgroundTransparency = 1, Font = Theme.FontMedium,
        Text = "", TextColor3 = Theme.TextSecondary, TextSize = 11, Parent = Content
    })

    -- Verify button
    local VerifyBtn = Util.Create("TextButton", {
        Size = UDim2.new(1,0,0,44), Position = UDim2.new(0,0,0,74),
        BackgroundColor3 = Theme.Accent, Font = Theme.FontSemibold,
        Text = "Verify Key", TextColor3 = Color3.fromRGB(255,255,255),
        TextSize = 14, AutoButtonColor = false, ClipsDescendants = true, Parent = Content
    })
    Util.Corner(VerifyBtn, Theme.CornerRadius)
    Util.Shadow(VerifyBtn, 4, 0.6)

    -- Get Key button
    local GetKeyBtn = Util.Create("TextButton", {
        Size = UDim2.new(1,0,0,44), Position = UDim2.new(0,0,0,126),
        BackgroundColor3 = Theme.Card, Font = Theme.FontSemibold,
        Text = "Get Key", TextColor3 = Theme.Accent,
        TextSize = 14, AutoButtonColor = false, ClipsDescendants = true, Parent = Content
    })
    Util.Corner(GetKeyBtn, Theme.CornerRadius)
    Util.Stroke(GetKeyBtn, Theme.CardBorder, 1)

    -- Discord row
    local DiscordRow = Util.Create("Frame", {
        Size = UDim2.new(1,0,0,44), Position = UDim2.new(0,0,0,182),
        BackgroundColor3 = Theme.Card, Parent = Content
    })
    Util.Corner(DiscordRow, Theme.CornerRadius)
    Util.Stroke(DiscordRow, Theme.CardBorder, 1)

    Util.Create("TextLabel", {
        Size = UDim2.new(0,24,1,0), Position = UDim2.new(0,14,0,0),
        BackgroundTransparency = 1, Font = Theme.FontBold,
        Text = "💬", TextSize = 14, Parent = DiscordRow
    })
    Util.Create("TextLabel", {
        Size = UDim2.new(0,80,1,0), Position = UDim2.new(0,42,0,0),
        BackgroundTransparency = 1, Font = Theme.FontMedium,
        Text = "Need help?", TextColor3 = Theme.TextSecondary,
        TextSize = 12, TextXAlignment = Enum.TextXAlignment.Left, Parent = DiscordRow
    })
    local DiscordBtn = Util.Create("TextButton", {
        AnchorPoint = Vector2.new(1, 0.5),
        Size = UDim2.new(0,100,0,30), Position = UDim2.new(1,-10,0.5,0),
        BackgroundColor3 = Theme.AccentSurface, Font = Theme.FontSemibold,
        Text = "Join Discord", TextColor3 = Theme.Accent,
        TextSize = 11, AutoButtonColor = false, Parent = DiscordRow
    })
    Util.Corner(DiscordBtn, Theme.CornerRadiusSmall)

    -- Footer
    Util.Create("TextLabel", {
        AnchorPoint = Vector2.new(0.5, 0), Size = UDim2.new(1,0,0,14),
        Position = UDim2.new(0.5,0,0,232), BackgroundTransparency = 1,
        Font = Theme.FontRegular, Text = "Powered by Junkie Key System",
        TextColor3 = Theme.TextTertiary, TextSize = 9, Parent = Content
    })

    -- ─── Dragging ───
    local Connections = {}
    local dragging, dragStart, startPos = false, nil, nil
    local targetPos = MainFrame.Position

    table.insert(Connections, Header.InputBegan:Connect(function(i)
        if i.UserInputType == Enum.UserInputType.MouseButton1 then
            dragging = true; dragStart = i.Position; startPos = MainFrame.Position
        end
    end))
    table.insert(Connections, Header.InputEnded:Connect(function(i)
        if i.UserInputType == Enum.UserInputType.MouseButton1 then dragging = false end
    end))
    table.insert(Connections, UserInputService.InputChanged:Connect(function(i)
        if dragging and i.UserInputType == Enum.UserInputType.MouseMovement then
            local d = i.Position - dragStart
            targetPos = UDim2.new(startPos.X.Scale, startPos.X.Offset + d.X, startPos.Y.Scale, startPos.Y.Offset + d.Y)
        end
    end))
    table.insert(Connections, RunService.RenderStepped:Connect(function()
        if dragging then MainFrame.Position = MainFrame.Position:Lerp(targetPos, 0.15) end
    end))

    -- ─── Focus effects ───
    table.insert(Connections, KeyInput.Focused:Connect(function()
        Util.Tween(InputFrame, {BackgroundColor3 = Theme.CardHover}, 0.08)
        Util.Tween(InputStroke, {Color = Theme.Accent}, 0.08)
    end))
    table.insert(Connections, KeyInput.FocusLost:Connect(function()
        Util.Tween(InputFrame, {BackgroundColor3 = Theme.Card}, 0.12)
        Util.Tween(InputStroke, {Color = Theme.CardBorder}, 0.12)
    end))

    -- ─── Button hovers ───
    local function Hover(btn, base, hov, press)
        table.insert(Connections, btn.MouseEnter:Connect(function() Util.Tween(btn, {BackgroundColor3 = hov}, 0.08) end))
        table.insert(Connections, btn.MouseLeave:Connect(function() Util.Tween(btn, {BackgroundColor3 = base}, 0.1) end))
        table.insert(Connections, btn.MouseButton1Down:Connect(function() Util.Tween(btn, {BackgroundColor3 = press}, 0.04) end))
        table.insert(Connections, btn.MouseButton1Up:Connect(function() Util.Tween(btn, {BackgroundColor3 = hov}, 0.06) end))
    end
    Hover(VerifyBtn, Theme.Accent, Theme.AccentLight, Theme.AccentDark)
    Hover(GetKeyBtn, Theme.Card, Theme.CardHover, Theme.Elevated)
    Hover(DiscordBtn, Theme.AccentSurface, Theme.AccentSurfaceHover, Theme.AccentSurface)

    local function SetStatus(text, color)
        StatusLabel.Text = text
        StatusLabel.TextColor3 = color or Theme.TextSecondary
    end

    local function Close()
        for _, c in ipairs(Connections) do c:Disconnect() end
        Util.Tween(Overlay, {BackgroundTransparency = 1}, 0.2)
        Util.Tween(MainGlow, {ImageTransparency = 1}, 0.1)
        Util.Tween(MainShadow, {ImageTransparency = 1}, 0.1)
        Util.Tween(MainStroke, {Transparency = 1}, 0.1)
        FadeAllChildren(MainFrame, Theme.QuickSpeed)
        Util.Tween(MainFrame, {BackgroundTransparency = 1, Position = UDim2.new(0.5,0,0.55,0)}, 0.25, Enum.EasingStyle.Quart, Enum.EasingDirection.In)
        task.delay(0.3, function() ScreenGui:Destroy() end)
    end

    -- ─── Verify click ───
    table.insert(Connections, VerifyBtn.MouseButton1Click:Connect(function()
        Util.Ripple(VerifyBtn)
        local key = KeyInput.Text
        if key == "" then SetStatus("Please enter a key", Theme.Warning); return end
        SetStatus("Validating...", Theme.Info)
        VerifyBtn.Text = "•••"
        task.spawn(function()
            local ok, msg = handler:VerifyKey(key)
            if ok then
                SetStatus("✓ " .. msg, Theme.Success)
                VerifyBtn.Text = "✓ Verified"
                Util.Tween(VerifyBtn, {BackgroundColor3 = Theme.Success}, 0.12)
                getgenv().SCRIPT_KEY = key
                getgenv().NOVAX_SAVED_KEY = key
                task.delay(1.2, function() Close(); task.delay(0.35, onSuccess) end)
            else
                SetStatus("✕ " .. msg, Theme.Error)
                VerifyBtn.Text = "Verify Key"
                Util.Tween(VerifyBtn, {BackgroundColor3 = Theme.Error}, 0.1)
                task.delay(1.5, function() Util.Tween(VerifyBtn, {BackgroundColor3 = Theme.Accent}, 0.2) end)
                onFailed(msg)
            end
        end)
    end))

    -- Enter key shortcut
    table.insert(Connections, KeyInput.FocusLost:Connect(function(enter)
        if enter then VerifyBtn.MouseButton1Click:Fire() end
    end))

    -- ─── Get Key click ───
    table.insert(Connections, GetKeyBtn.MouseButton1Click:Connect(function()
        Util.Ripple(GetKeyBtn)
        SetStatus("Getting link...", Theme.Info)
        task.spawn(function()
            local ok, m = handler:CopyLink()
            if ok then
                SetStatus("✓ " .. m, Theme.Success)
                GetKeyBtn.Text = "✓ Copied!"
                task.delay(2, function() GetKeyBtn.Text = "Get Key"; SetStatus("") end)
            else
                SetStatus("✕ " .. (m or "Failed"), Theme.Error)
            end
        end)
    end))

    -- ─── Discord click ───
    table.insert(Connections, DiscordBtn.MouseButton1Click:Connect(function()
        local link = config.Discord or ""
        pcall(function() (setclipboard or toclipboard or function()end)(link) end)
        DiscordBtn.Text = "✓ Copied!"
        SetStatus("Discord invite copied!", Theme.Success)
        task.delay(1.5, function() DiscordBtn.Text = "Join Discord" end)
    end))

    -- ─── Stagger entry ───
    task.delay(0.15, function()
        for i, el in ipairs({InputFrame, StatusLabel, VerifyBtn, GetKeyBtn, DiscordRow}) do
            if el and el.Parent then
                local orig = el.Position
                el.Position = UDim2.new(orig.X.Scale, orig.X.Offset, orig.Y.Scale, orig.Y.Offset + 20)
                task.delay(i * 0.05, function()
                    Util.Tween(el, {Position = orig}, 0.38, Enum.EasingStyle.Quart)
                end)
            end
        end
    end)

    return { Destroy = function() Close() end, SetStatus = SetStatus }
end

NovaX.Theme = Theme
NovaX.Util  = Util
_G.NovaXInstance = NovaX

return NovaX
