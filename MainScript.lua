--[[
    Credits to anyones code I used or looked at

    Removed the key system permamently.
]]

repeat task.wait() until game:IsLoaded()

if shared.Mana then
    local Mana = shared.Mana
    if shared.ManaDeveloper then
        Mana.GuiLibrary:Destruct()
        warn("[Nightix]: Already loaded but developer mode is enabled, so reinjecting.")
    else
        warn("[Nightix]: Already loaded.")
        Mana.GuiLibrary:playsound("rbxassetid://421058925", 1)
        return
    end
end

local startTick = tick()

-- // GitHub repository to load files from
local GitHubRepo = "https://raw.githubusercontent.com/shipychkaft-ux/script_new/main/"

local UserInputService = game:GetService("UserInputService")
local TextChatService = game:GetService("TextChatService")
local TeleportService = game:GetService("TeleportService")
local httpService = game:GetService("HttpService")
local RunService = game:GetService("RunService")
local Players = game:GetService("Players")
local CoreGui = game:GetService("CoreGui")

local LocalPlayer = Players.LocalPlayer
local Character = LocalPlayer.Character or LocalPlayer.CharacterAdded:Wait()
local HumanoidRootPart = Character:WaitForChild("HumanoidRootPart")
local Humanoid = Character:WaitForChild("Humanoid")
local Camera = workspace.CurrentCamera
local RealCamera = workspace.Camera
local Mouse = LocalPlayer:GetMouse()
local PlayerGui = LocalPlayer.PlayerGui
local PlaceId = game.PlaceId
local JobId = game.JobId
local saveasuniversal = false
local loadasuniversal = false
local SliderScaleValue = 1
local Functions = {}
local LocalPlayerEvents = {}
local Mana = {Connections = {}, Friends = {}}

local httprequest = (request and http and http.request or http_request or fluxus and fluxus.request)
local queueteleport = syn and syn.queue_on_teleport or queue_on_teleport or fluxus and fluxus.queue_on_teleport
local function runFunction(func) func() end

local requestfunc = syn and syn.request or http and http.request or http_request or fluxus and fluxus.request or request or function(tab)
    if tab.Method == "GET" then
        return {
            Body = game:HttpGet(tab.Url, true),
            Headers = {},
            StatusCode = 200
        }
    else
        return {
            Body = "bad exploit",
            Headers = {},
            StatusCode = 404
        }
    end
end 

local betterisfile = function(file)
    local suc, res = pcall(function() return readfile(file) end)
    return suc and res ~= nil
end

local function isAlive(Player, headCheck)
    local Player = Player or LocalPlayer
    if Player and Player.Character and ((Player.Character:FindFirstChildOfClass("Humanoid")) and (Player.Character:FindFirstChild("HumanoidRootPart")) and (headCheck and Player.Character:FindFirstChild("Head") or not headCheck)) then
        return true
    else
        return false
    end
end

do
    function Functions:RunFile(filepath)
        local req = requestfunc({
            Url = GitHubRepo .. filepath,
            Method = "GET"
        })
        if betterisfile(filepath) then
            return loadstring(readfile(filepath))()
        elseif isfile("NewMana/"..filepath) and shared.ManaDeveloper then
            return loadstring(readfile("NewMana/" .. filepath))()
        elseif not betterisfile(filepath) and not shared.ManaDeveloper then -- auto update workspace files
            local content = req.Body
            writefile("Mana/"..filepath, content)
            return loadstring(content)()
        else
            if isfile("Mana/" .. filepath) then
                return loadstring(readfile("Mana/" .. filepath))()
            else
                return loadstring(game:HttpGet(GitHubRepo .. filepath))()
            end
        end
    end
end

local RunLoops = {RenderStepTable = {}, StepTable = {}, HeartTable = {}}

do
	function RunLoops:BindToRenderStep(name, func)
		if RunLoops.RenderStepTable[name] == nil then
			RunLoops.RenderStepTable[name] = RunService.RenderStepped:Connect(func)
		end
	end

	function RunLoops:UnbindFromRenderStep(name)
		if RunLoops.RenderStepTable[name] then
			RunLoops.RenderStepTable[name]:Disconnect()
			RunLoops.RenderStepTable[name] = nil
		end
	end

	function RunLoops:BindToStepped(name, func)
		if RunLoops.StepTable[name] == nil then
			RunLoops.StepTable[name] = RunService.Stepped:Connect(func)
		end
	end

	function RunLoops:UnbindFromStepped(name)
		if RunLoops.StepTable[name] then
			RunLoops.StepTable[name]:Disconnect()
			RunLoops.StepTable[name] = nil
		end
	end

	function RunLoops:BindToHeartbeat(name, func) 
		if RunLoops.HeartTable[name] == nil then
			RunLoops.HeartTable[name] = RunService.Heartbeat:Connect(func)
		end
	end

	function RunLoops:UnbindFromHeartbeat(name)
		if RunLoops.HeartTable[name] then
			RunLoops.HeartTable[name]:Disconnect()
			RunLoops.HeartTable[name] = nil
		end
	end
end

shared.Mana = Mana
local GuiLibrary = Functions:RunFile("GuiLibrary.lua")--loadstring(game:HttpGet("https://raw.githubusercontent.com/Maanaaaa/ManaV2ForRoblox/refs/heads/main/GuiLibrary.lua"))()
local playersHandler = Functions:RunFile("playersHandler.lua") --loadstring(game:HttpGet("https://raw.githubusercontent.com/7GrandDadPGN/VapeV4ForRoblox/refs/heads/main/libraries/entity.lua"))()
local toolHandler = Functions:RunFile("toolHandler.lua")
local espLibrary = Functions:RunFile("espLibrary.lua") --loadstring(game:HttpGet("https://raw.githubusercontent.com/Maanaaaa/ManaV2ForRoblox/main/Libraries/espLibrary.lua"))()
--local whitelistHandler = Functions:RunFile("Libraries/whiltelistHandler.lua")
Mana.GuiLibrary = GuiLibrary
Mana.Functions = Functions
Mana.RunLoops = RunLoops
Mana.PlayersHandler = playersHandler
Mana.ToolHandler = toolHandler
Mana.EspLibrary = espLibrary
--Mana.WhitelistHandler = whitelistHandler
Mana.Activated = true
Mana.Whitelisted = false
Mana.Loaded = false

-- // Nightix-style menu (ported from Nightix Minecraft client)
local nightixOk, nightixErr = pcall(function()
    local nightixMenu = Functions:RunFile("NightixMenu.lua")
    nightixMenu(GuiLibrary, GuiLibrary.OptionFunctions or {}, Mana.Connections, UserInputService, game:GetService("TweenService"), game:GetService("TextService"), Mouse, function(func) return coroutine.wrap(func)() end)
end)
if not nightixOk then
    error("[Nightix/MainScript.lua]: Failed to initialize NightixMenu before creating tabs: " .. tostring(nightixErr))
end

if type(GuiLibrary.CreateTab) ~= "function" or type(GuiLibrary.CreateOptionsTab) ~= "function" then
    error("[Nightix/MainScript.lua]: NightixMenu did not register the tab API")
end

GuiLibrary:CreateWindow()

local Tabs = {
    Combat = GuiLibrary:CreateTab({
        Name = "Combat",
        Color = Color3.fromRGB(252, 60, 68), --252, 60, 68
        TabIcon = "CombatTabIcon.png"
    }),
    Movement = GuiLibrary:CreateTab({
        Name = "Movement",
        Color = Color3.fromRGB(255, 148, 36), --255, 148, 36
        TabIcon = "MovementTabIcon.png"
    }),
    Render = GuiLibrary:CreateTab({
        Name = "Visuals",
        Color = Color3.fromRGB(59, 170, 222), --59, 170, 222
        TabIcon = "RenderTabIcon.png"
    }),
    Utility = GuiLibrary:CreateTab({
        Name = "Utility",
        Color = Color3.fromRGB(83, 214, 110),
        TabIcon = "rbxassetid://89294237251926",
    }),
    Settings = GuiLibrary:CreateOptionsTab({
        Name = "Settings",
        Color = Color3.fromRGB(240, 157, 62), --240, 157, 62
        TabIcon = "MiscTabIcon.png"
    }),
    Profiles = GuiLibrary:CreateOptionsTab({
        Name = "Profiles",
        Color = Color3.fromRGB(255, 255, 255), --255, 255, 255
        TabIcon = "MiscTabIcon.png"
    }),
    Friends = GuiLibrary:CreateOptionsTab({
        Name = "Friends",
        Color = Color3.fromRGB(240, 157, 62), --240, 157, 62
        TabIcon = "PlayerImage.png"
    }),
    --[[
    FE = GuiLibrary:CreateTab({
        Name = "FE + Trolling",
        Color = Color3.fromRGB(255, 0, 34),
        Visible = true,
        TabIcon = "Utility.png",
        Callback = function() end
    }),
    Plugins = GuiLibrary:CreateTab({
        Name = "Plugins",
        Color = Color3.fromRGB(49, 204, 90),
        Visible = true,
        TabIcon = "MiscTabIcon.png",
        Callback = function() end
    }),
    ]]
    --[[
    SessionInfo = GuiLibrary:CreateCustomTab({
        Name = "Session info",
        Color = Color3.fromRGB(240, 157, 62)
    })
    ]]
}
Mana.Tabs = Tabs

if GuiLibrary.Device == "Mobile" then
    SliderScaleValue = 0.5
end

-- // key strokes
local keyStrokes = GuiLibrary:CreateKeyStrokes()
Mana.KeyStrokes = keyStrokes
keyStrokes:toggle()

--[[ // text list (soon (never))
local textList = GuiLibrary:CreateTextList()
Mana.TextList = textList
Tabs.TextList = textList.tab
]]

-- // Settings tab
runFunction(function()
    local volume = {Value = 1}

    Tabs.Settings:CreateDivider("UI")

    Tabs.Settings:CreateToggle({
        Name = "Notifications",
        Default = true,
        Callback = function(v)
            GuiLibrary.Notifications = v
        end
    })

    local sounds = Tabs.Settings:CreateToggle({
        Name = "Sounds",
        Default = true,
        Callback = function(v)
            GuiLibrary.Sounds = v
            if volume.MainObject then volume.MainObject.Visible = v end
        end
    })

    volume = Tabs.Settings:CreateSlider({
        Name = "Volume",
        Function = function(v) GuiLibrary.SoundVolume = v end,
        Min = 0, Max = 1, Default = 1, Round = 2
    })

    Tabs.Settings:CreateSlider({
        Name = "UI scale",
        Function = function(v)
            GuiLibrary.UIScale.Scale = v
            local w = GuiLibrary.NightixMenu and GuiLibrary.NightixMenu.Window
            if w then
                w:SetSize(UDim2.fromOffset(math.floor(640 * v), math.floor(480 * v)))
            end
        end,
        Min = 0.5, Max = 2, Default = 1, Round = 2
    })

    Tabs.Settings:CreateButton({
        Name = "Сбросить UI scale",
        Function = function()
            local defaultScale = 1
            GuiLibrary.UIScale.Scale = defaultScale
            local w = GuiLibrary.NightixMenu and GuiLibrary.NightixMenu.Window
            if w then
                w:SetSize(UDim2.fromOffset(640, 480))
            end
        end
    })

    -- Icon is a real function. All appearance controls live inside its option window.
    local iconFunction = Tabs.Settings:CreateToggle({
        Name = "Icon",
        Default = true,
        Callback = function(v)
            local nl = GuiLibrary.NightixMenu and GuiLibrary.NightixMenu.NeverLose
            if nl then
                nl.IconSettings = nl.IconSettings or {}
                nl.IconSettings.Enabled = v
            end
        end
    })

    local nl = GuiLibrary.NightixMenu and GuiLibrary.NightixMenu.NeverLose
    if nl then
        nl.IconSettings = nl.IconSettings or {}
        nl.IconSettings.Enabled = true
        nl.IconSettings.Mode = nl.IconSettings.Mode or "Double"
        nl.IconSettings.Color1 = nl.IconSettings.Color1 or Color3.fromRGB(216, 148, 245)
        nl.IconSettings.Color2 = nl.IconSettings.Color2 or Color3.fromRGB(123, 131, 243)
        nl.IconSettings.Speed = nl.IconSettings.Speed or 0.65
    end

    local iconColor2, iconSpeed
    local iconMode = iconFunction:CreateDropdown({
        Name = "Режим",
        List = {"Одиночный", "Двойной"},
        Default = "Двойной",
        Function = function(v)
            local nl2 = GuiLibrary.NightixMenu and GuiLibrary.NightixMenu.NeverLose
            if not nl2 then return end
            nl2.IconSettings.Mode = (v == "Одиночный") and "Single" or "Double"
            if nl2.IconSettings.Mode == "Single" and not nl2.IconSettings.SingleInitialized then
                nl2.IconSettings.Color1 = Color3.fromRGB(255, 255, 255)
                nl2.IconSettings.SingleInitialized = true
            end
            local double = nl2.IconSettings.Mode == "Double"
            if iconColor2 and iconColor2.Container then iconColor2.Container.Visible = double end
            if iconSpeed and iconSpeed.Container then iconSpeed.Container.Visible = double end
        end
    })

    local iconColor1 = iconFunction:CreateColorSlider({
        Name = "Первый цвет",
        Default = (nl and nl.IconSettings and nl.IconSettings.Color1) or Color3.fromRGB(216, 148, 245),
        Function = function(v)
            local nl2 = GuiLibrary.NightixMenu and GuiLibrary.NightixMenu.NeverLose
            if nl2 then nl2.IconSettings.Color1 = v end
        end
    })

    iconColor2 = iconFunction:CreateColorSlider({
        Name = "Второй цвет",
        Default = (nl and nl.IconSettings and nl.IconSettings.Color2) or Color3.fromRGB(123, 131, 243),
        Function = function(v)
            local nl2 = GuiLibrary.NightixMenu and GuiLibrary.NightixMenu.NeverLose
            if nl2 then nl2.IconSettings.Color2 = v end
        end
    })

    iconSpeed = iconFunction:CreateSlider({
        Name = "Скорость переливания",
        Min = 0.05, Max = 1.5, Default = (nl and nl.IconSettings and nl.IconSettings.Speed) or 0.65, Round = 2,
        Function = function(v)
            local nl2 = GuiLibrary.NightixMenu and GuiLibrary.NightixMenu.NeverLose
            if nl2 then nl2.IconSettings.Speed = v end
        end
    })

    local function applyTheme(v)
        local nl2 = GuiLibrary.NightixMenu and GuiLibrary.NightixMenu.NeverLose
        local palette = GuiLibrary.GuiPallet
        if not nl2 or not palette then return end

        -- Presets are actions, not a persistent "theme selection". Clicking a
        -- preset immediately writes the complete client palette and refreshes
        -- already-created UI objects. A custom theme can therefore be replaced
        -- instantly without changing any separate theme state.
        local themes = {
            ["Nursultan 1.21.11"] = {
                Color1 = Color3.fromRGB(14, 14, 23),
                Color2 = Color3.fromRGB(47, 48, 64),
                Color3 = Color3.fromRGB(66, 68, 66),
                Color4 = Color3.fromRGB(49, 51, 64),
                Color5 = Color3.fromRGB(20, 20, 20),
                Color6 = Color3.fromRGB(200, 200, 200),
                ToggleColor = Color3.fromRGB(0, 0, 0),
                ToggleColor2 = Color3.fromRGB(123, 131, 243),
                TextColor = Color3.fromRGB(255, 255, 255),
                PlaceholderColor = Color3.fromRGB(220, 220, 220),
                PlaceholderColor2 = Color3.fromRGB(200, 200, 200),
                InfoColor = Color3.fromRGB(180, 180, 180),
                WarningColor = Color3.fromRGB(198, 205, 64),
                ErrorColor = Color3.fromRGB(205, 64, 78),
                Icon1 = Color3.fromRGB(216, 148, 245),
                Icon2 = Color3.fromRGB(123, 131, 243),
            },
            ["Nursultan 1.16.5"] = {
                Color1 = Color3.fromRGB(14, 14, 23),
                Color2 = Color3.fromRGB(47, 48, 64),
                Color3 = Color3.fromRGB(66, 68, 66),
                Color4 = Color3.fromRGB(49, 51, 64),
                Color5 = Color3.fromRGB(20, 20, 20),
                Color6 = Color3.fromRGB(200, 200, 200),
                ToggleColor = Color3.fromRGB(0, 0, 0),
                ToggleColor2 = Color3.fromRGB(94, 74, 103),
                TextColor = Color3.fromRGB(255, 255, 255),
                PlaceholderColor = Color3.fromRGB(220, 220, 220),
                PlaceholderColor2 = Color3.fromRGB(200, 200, 200),
                InfoColor = Color3.fromRGB(180, 180, 180),
                WarningColor = Color3.fromRGB(198, 205, 64),
                ErrorColor = Color3.fromRGB(205, 64, 78),
                Icon1 = Color3.fromRGB(207, 156, 211),
                Icon2 = Color3.fromRGB(94, 74, 103),
            },
        }
        local theme = themes[v]
        if not theme then return end

        for key, value in pairs(theme) do
            if key ~= "Icon1" and key ~= "Icon2" then
                GuiLibrary:setColor(key, value)
            end
        end
        palette.ThemeMode = "Preset"
        GuiLibrary:updateObjects()

        nl2.IconSettings = nl2.IconSettings or {}
        nl2.IconSettings.Mode = "Double"
        nl2.IconSettings.Color1 = theme.Icon1
        nl2.IconSettings.Color2 = theme.Icon2
        nl2.IconSettings.Speed = 0.65
        if nl2.RefreshNightixTheme then
            nl2:RefreshNightixTheme()
        end
    end

    -- Presets are buttons: pressing one applies the palette immediately.
    iconFunction:CreateButton({
        Name = "Nursultan 1.21.11",
        Callback = function() applyTheme("Nursultan 1.21.11") end
    })
    iconFunction:CreateButton({
        Name = "Nursultan 1.16.5",
        Callback = function() applyTheme("Nursultan 1.16.5") end
    })

    -- The function itself starts with the default client theme.
    iconMode:Select("Двойной")
    if iconColor2.Container then iconColor2.Container.Visible = true end
    if iconSpeed.Container then iconSpeed.Container.Visible = true end
end)

-- Profiles tab
runFunction(function()
    Tabs.Profiles:CreateConfigManager({
        Name = "Configs",
    })
end)

-- Friends tab
runFunction(function()
    local Friends = Tabs.Friends:CreateTextList({
        Name = "Friends",
        List = {},
        PlaceholderText = "Friend Name",
        Callback = function() end
    })
    -- Keep Mana.Friends pointing at the live list so Remove immediately
    -- affects target checks as well.
    Mana.Friends = Friends.List
end)

--[[ // TextList tab (soon)
runFunction(function()
    local sorting = {Value = "Alphabetical"}
    local backgroundTransparency = {Value = 0.7}
    local texSize = {Value = 15}
    local customTextEnabled = {Value = false}
    local customText = {Value = ""}
    local customTextSize = {Value = 18}
    local autoXAllignment = {Value = true}

    sorting = Tabs.TextList:CreateDropDown({
        Name = "Sorting",
        List = {"Alphabetical", "Length"},
        Default = "Alphabetical",
        Callback = function(v)
            textList:updateSortingMode(v)
        end
    })

    backgroundTransparency = Tabs.TextList:CreateSlider({
        Name = "Transparency",
        Function = function(v)
            textList:updateBackgroundTransparency(v)
        end,
        Min = 0,
        Max = 1,
        Default = 0.7,
        Round = 2
    })

    texSize = Tabs.TextList:CreateSlider({
        Name = "Text size",
        Function = function(v)
            textList:updateTextSize(v)
        end,
        Min = 10,
        Max = 30,
        Default = 15,
        Round = 0
    })

    customTextEnabled = Tabs.TextList:CreateToggle({
        Name = "Custom text",
        Default = true,
        Callback = function(callback)
            if customText.MainObject then customText.MainObject.Visible = callback end
            if customTextSize.MainObject then customTextSize.MainObject.Visible = callback end
            textList:addCustomText()
        end
    })

    customText = Tabs.TextList:CreateTextBox({
        Name = "Custom text",
        PlaceholderText = "Custom text text",
        Default = "Hello world!",
        Callback = function(v)
            textList:updateCustomText(v)
        end
    })
    customText.MainObject.Visible = false

    customTextSize = Tabs.TextList:CreateSlider({
        Name = "Custom text size",
        Function = function(v)
            textList:updateCustomTextSize(v)
        end,
        Min = 10,
        Max = 30,
        Default = 18,
        Round = 0
    })
    customTextSize.MainObject.Visible = false

    autoXAllignment = Tabs.TextList:CreateToggle({
        Name = "Auto text X align.",
        Default = false,
        Callback = function(callback)
            textList:updateAutoTextXAlignment(callback)
        end
    })
end)
]]

print("[Nightix/MainScript.lua]: Loaded in " .. tostring(tick() - startTick) .. ".")

Functions:RunFile("Universal.lua")

local suc, res = pcall(function()
    Functions:RunFile("Scripts/" .. PlaceId .. ".lua")
end)

if not suc then
    warn("[Nightix/MainScript.lua]: an error occured while attempting to load game script: " .. res)
    GuiLibrary.CanLoadConfig = true
end

LocalPlayer.OnTeleport:Connect(function(State)
    if State == Enum.TeleportState.Started then
        local QueueTeleportFunction = [[
            if shared.ManaDeveloper then 
                loadstring(readfile("NewMana/MainScript.lua"))()
            else 
                loadstring(game:HttpGet("]] .. GitHubRepo .. [[MainScript.lua"))()
            end
        ]]
        queueteleport(QueueTeleportFunction)
    end
end)

repeat task.wait() until GuiLibrary.CanLoadConfig -- game-specific modules are loaded before marking the client ready
GuiLibrary.Loaded = true
Mana.Loaded = true
-- Configs are loaded manually from Profiles. There is no automatic config load/save.
