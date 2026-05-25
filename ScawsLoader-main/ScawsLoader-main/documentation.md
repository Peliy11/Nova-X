ScawsHub UI Library - Quick Documentation
🚀 Basic Setup
lualocal ScawsHub = loadstring(game:HttpGet("your-url-here"))()

-- Create Window (with loading screen)
local Window = ScawsHub:CreateWindow({
    Name = "My Hub",           -- Window title
    ShowLoading = true,        -- Show loading animation
    LoadingDuration = 3        -- Loading screen duration (seconds)
})

📑 Creating Tabs
lualocal Tab = Window:CreateTab("Tab Name", "icon_optional")

🎛️ UI Elements
1️⃣ Button
luaTab:CreateButton({
    Name = "Click Me",
    Callback = function()
        print("Button clicked!")
    end
})
2️⃣ Toggle
luaTab:CreateToggle({
    Name = "Enable Feature",
    Default = false,              -- Starting state
    Callback = function(value)
        print("Toggled:", value)  -- true/false
    end
})
3️⃣ Slider
luaTab:CreateSlider({
    Name = "Speed",
    Min = 0,                      -- Minimum value
    Max = 100,                    -- Maximum value
    Default = 50,                 -- Starting value
    Increment = 1,                -- Step size
    Callback = function(value)
        print("Slider value:", value)
    end
})
4️⃣ Dropdown
luaTab:CreateDropdown({
    Name = "Select Option",
    Options = {"Option 1", "Option 2", "Option 3"},
    Default = "Option 1",         -- Starting selection
    Callback = function(selected)
        print("Selected:", selected)
    end
})
5️⃣ Label (Text Display)
lualocal MyLabel = Tab:CreateLabel("This is some text")

-- Update label text later:
MyLabel.UpdateText("New text here")

🔔 Notifications
luaScawsHub:CreateNotification({
    Title = "Success!",
    Content = "Operation completed successfully",
    Duration = 5,                 -- Display time (seconds)
    Type = "Success"              -- "Info", "Success", "Warning", "Error"
})
Notification Types:

"Info" - Blue (default)
"Success" - Green
"Warning" - Orange/Yellow
"Error" - Red


📋 Full Example Script
lualocal ScawsHub = loadstring(game:HttpGet("your-url-here"))()

-- Create Window
local Window = ScawsHub:CreateWindow({
    Name = "My Awesome Hub",
    ShowLoading = true,
    LoadingDuration = 3
})

-- Create Tabs
local MainTab = Window:CreateTab("Main")
local SettingsTab = Window:CreateTab("Settings")

-- Add Elements to Main Tab
MainTab:CreateButton({
    Name = "Test Button",
    Callback = function()
        ScawsHub:CreateNotification({
            Title = "Button Pressed",
            Content = "You clicked the button!",
            Duration = 3,
            Type = "Success"
        })
    end
})

MainTab:CreateToggle({
    Name = "Auto Farm",
    Default = false,
    Callback = function(value)
        print("Auto Farm:", value)
    end
})

MainTab:CreateSlider({
    Name = "Walk Speed",
    Min = 16,
    Max = 100,
    Default = 16,
    Increment = 1,
    Callback = function(value)
        game.Players.LocalPlayer.Character.Humanoid.WalkSpeed = value
    end
})

-- Add Elements to Settings Tab
SettingsTab:CreateDropdown({
    Name = "Theme",
    Options = {"Dark", "Light", "Blue"},
    Default = "Dark",
    Callback = function(selected)
        print("Theme changed to:", selected)
    end
})

SettingsTab:CreateLabel("Version 1.0.0")
