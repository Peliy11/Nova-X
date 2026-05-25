local TweenService = game:GetService("TweenService")
local HttpService = game:GetService("HttpService")
local CoreGui = game:GetService("CoreGui")
local Players = game:GetService("Players")

local httprequest = request or http_request or (http and http.request)
local Module = {}

local function safeRequest(options)
    if type(httprequest) ~= "function" then
        warn("[Discord] HTTP request function not available")
        return nil
    end
    local ok, result = pcall(function()
        return httprequest(options)
    end)
    if not ok then
        warn("[Discord] request error:", tostring(result))
        return nil
    end
    return result
end

local function GetInviteData(invite)
    if type(invite) ~= "string" then
        return nil
    end

    local code = invite:match("([^/]+)$") or invite
    local response = safeRequest({
        Url = "https://ptb.discord.com/api/invites/" .. code,
        Method = "GET",
        Headers = { ["Content-Type"] = "application/json" }
    })

    if not response or not response.Body then
        return nil
    end

    local ok, data = pcall(function()
        return HttpService:JSONDecode(response.Body)
    end)

    if not ok then
        warn("[Discord] Failed to decode invite data")
        return nil
    end

    return data
end

local function CreatePromptGui()
    local screenGui = Instance.new("ScreenGui")
    screenGui.Name = "NovaXDiscordPrompt"
    screenGui.ResetOnSpawn = false
    screenGui.IgnoreGuiInset = true
    pcall(function()
        if syn and syn.protect_gui then
            syn.protect_gui(screenGui)
            screenGui.Parent = CoreGui
        elseif gethui then
            screenGui.Parent = gethui()
        else
            screenGui.Parent = CoreGui
        end
    end)

    local holder = Instance.new("Frame")
    holder.Name = "Holder"
    holder.AnchorPoint = Vector2.new(0.5, 0.5)
    holder.Position = UDim2.new(0.5, 0.5, 0.5, 0)
    holder.Size = UDim2.new(0, 0, 0, 0)
    holder.BackgroundColor3 = Color3.fromRGB(20, 20, 25)
    holder.BorderSizePixel = 0
    holder.Parent = screenGui

    local holderCorner = Instance.new("UICorner")
    holderCorner.CornerRadius = UDim.new(0, 16)
    holderCorner.Parent = holder

    local title = Instance.new("TextLabel")
    title.Name = "Title"
    title.Size = UDim2.new(1, -32, 0, 30)
    title.Position = UDim2.new(0, 16, 0, 16)
    title.BackgroundTransparency = 1
    title.Font = Enum.Font.GothamBold
    title.TextSize = 18
    title.TextColor3 = Color3.fromRGB(255, 255, 255)
    title.TextXAlignment = Enum.TextXAlignment.Left
    title.Text = "Join the Discord"
    title.Parent = holder

    local message = Instance.new("TextLabel")
    message.Name = "Message"
    message.Size = UDim2.new(1, -32, 0, 44)
    message.Position = UDim2.new(0, 16, 0, 54)
    message.BackgroundTransparency = 1
    message.Font = Enum.Font.Gotham
    message.TextSize = 14
    message.TextColor3 = Color3.fromRGB(190, 190, 190)
    message.TextXAlignment = Enum.TextXAlignment.Left
    message.TextWrapped = true
    message.Text = "Join the Nova X Discord for updates, support, and new releases."
    message.Parent = holder

    local buttons = Instance.new("Frame")
    buttons.Name = "Buttons"
    buttons.Size = UDim2.new(1, -32, 0, 34)
    buttons.Position = UDim2.new(0, 16, 1, -50)
    buttons.BackgroundTransparency = 1
    buttons.Parent = holder

    local accept = Instance.new("TextButton")
    accept.Name = "Accept"
    accept.Size = UDim2.new(0.5, -8, 1, 0)
    accept.Position = UDim2.new(0, 0, 0, 0)
    accept.BackgroundColor3 = Color3.fromRGB(85, 100, 255)
    accept.Font = Enum.Font.GothamSemibold
    accept.TextSize = 14
    accept.TextColor3 = Color3.fromRGB(255, 255, 255)
    accept.Text = "Join Discord"
    accept.AutoButtonColor = false
    accept.Parent = buttons

    local ignore = Instance.new("TextButton")
    ignore.Name = "Ignore"
    ignore.Size = UDim2.new(0.5, -8, 1, 0)
    ignore.Position = UDim2.new(0.5, 16, 0, 0)
    ignore.BackgroundColor3 = Color3.fromRGB(50, 50, 55)
    ignore.Font = Enum.Font.GothamSemibold
    ignore.TextSize = 14
    ignore.TextColor3 = Color3.fromRGB(255, 255, 255)
    ignore.Text = "Maybe Later"
    ignore.AutoButtonColor = false
    ignore.Parent = buttons

    return screenGui
end

local function AnimatePrompt(promptGui, visible)
    local holder = promptGui:FindFirstChild("Holder")
    if not holder then
        return
    end

    if visible then
        holder.Visible = true
        TweenService:Create(holder, TweenInfo.new(0.35, Enum.EasingStyle.Quint, Enum.EasingDirection.Out), {Size = UDim2.new(0, 340, 0, 180)}):Play()
    else
        TweenService:Create(holder, TweenInfo.new(0.25, Enum.EasingStyle.Quint, Enum.EasingDirection.In), {Size = UDim2.new(0, 0, 0, 0)}):Play()
        task.delay(0.3, function()
            if promptGui and promptGui.Parent then
                promptGui:Destroy()
            end
        end)
    end
end

function Module:Join(invite)
    if type(invite) ~= "string" then
        return false
    end

    local data = GetInviteData(invite)
    if not data or not data.code then
        return false
    end

    local ok = pcall(function()
        safeRequest({
            Url = "http://127.0.0.1:6463/rpc?v=1",
            Method = "POST",
            Headers = {
                ["Content-Type"] = "application/json",
                ["Origin"] = "https://discord.com"
            },
            Body = HttpService:JSONEncode({
                cmd = "INVITE_BROWSER",
                args = { code = data.code },
                nonce = HttpService:GenerateGUID(false)
            })
        })
    end)

    if ok then
        getgenv().NOVA_DISCORD_JOINED = true
        return true
    end

    return false
end

function Module:Prompt(data)
    assert(typeof(data) == "table", "Data must be a table")
    assert(typeof(data.name) == "string", "Name must be a string")
    assert(typeof(data.invite) == "string", "Invite must be a string")

    if getgenv().NOVA_DISCORD_JOINED then
        return true
    end

    local inviteData = GetInviteData(data.invite)
    if not inviteData then
        warn("[Discord] Invalid invite or failed to fetch data")
        return false
    end

    local promptGui = CreatePromptGui()
    local holder = promptGui:WaitForChild("Holder")
    local title = holder:WaitForChild("Title")
    local message = holder:WaitForChild("Message")
    local buttons = holder:WaitForChild("Buttons")
    local accept = buttons:WaitForChild("Accept")
    local ignore = buttons:WaitForChild("Ignore")

    title.Text = "Join " .. data.name
    message.Text = "You are not currently connected to the " .. data.name .. " Discord server. Click join to open the invite in Discord."

    AnimatePrompt(promptGui, true)

    local connections = {}
    local function cleanup()
        for _, c in pairs(connections) do
            if c and c.Disconnect then
                c:Disconnect()
            end
        end
    end

    connections[#connections + 1] = accept.Activated:Connect(function()
        local joined = self:Join(data.invite)
        cleanup()
        AnimatePrompt(promptGui, false)
        if not joined then
            warn("[Discord] Could not open Discord invite. Make sure Discord is running.")
        end
    end)

    connections[#connections + 1] = ignore.Activated:Connect(function()
        cleanup()
        AnimatePrompt(promptGui, false)
    end)

    return true
end

function Module:CheckAndPrompt(data)
    if getgenv().NOVA_DISCORD_JOINED then
        return true
    end
    return self:Prompt(data)
end

function Module:IsJoined()
    return getgenv().NOVA_DISCORD_JOINED == true
end

return Module