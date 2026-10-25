--[[
    Credits to anyones code I used or looked at

    Removed the key system permamently.
]]

repeat task.wait() until game:IsLoaded()

if shared.Mana then
    local previousMana = shared.Mana
    if previousMana.Loaded then
        warn("[Nursultan]: Reloading the existing client from the current build.")
    else
        warn("[Nursultan]: Recovering an incomplete previous load.")
    end
    pcall(function()
        if previousMana.GuiLibrary and previousMana.GuiLibrary.Destruct then
            previousMana.GuiLibrary:Destruct()
        end
    end)
    shared.Mana = nil
end

local startTick = tick()

-- // Bump on every published change so the console shows whether the fresh
-- // build is actually running instead of a cached copy.
local BUILD_TAG = "2026-10-25-nursultan16"
print("[Nursultan]: build " .. BUILD_TAG)

-- // GitHub repository to load files from
local GitHubRepo = "https://raw.githubusercontent.com/shipychkaft-ux/script_new/main/"
local GitHubCacheKey = tostring(math.floor(tick()))
local function GitHubFileUrl(filepath)
    return GitHubRepo .. filepath .. "?v=" .. GitHubCacheKey
end

-- Clear legacy Lua module cache files at startup without deleting Mana assets
-- or user data. Versioned filenames prevent stale files being reused even on
-- executors that do not expose delfile.
local cacheFolder = "Mana"
if makefolder then pcall(makefolder, cacheFolder) end
local MODULE_CACHE_VERSION = "2026-10-25-nursultan16"
local legacyModuleFiles = {
    "GuiLibrary.lua", "playersHandler.lua", "toolHandler.lua", "espLibrary.lua",
    "NightixMenu.lua", "NeverLose.lua", "Universal.lua",
    "Scripts/" .. tostring(game.PlaceId) .. ".lua"
}
if delfile then
    -- Remove every cached Lua module, not only the old fixed filenames. This
    -- prevents a previous Theme preset (including 1.21.11) from surviving
    -- under a versioned filename after an update.
    if listfiles then
        pcall(function()
            for _, cachedPath in ipairs(listfiles(cacheFolder)) do
                if tostring(cachedPath):lower():sub(-4) == ".lua" then
                    pcall(delfile, cachedPath)
                end
            end
        end)
    end
    for _, filepath in ipairs(legacyModuleFiles) do
        pcall(delfile, cacheFolder .. "/" .. filepath)
    end
    print("[Nursultan]: cleared all Lua module cache")
else
    warn("[Nursultan]: delfile unavailable; legacy cache will be bypassed")
end
local function moduleCachePath(filepath)
    local safeName = tostring(filepath):gsub("[/\\\\]", "__")
    return cacheFolder .. "/" .. MODULE_CACHE_VERSION .. "_" .. safeName
end

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
        local cachePath = moduleCachePath(filepath)

        -- Normal mode must never execute legacy local modules. They are being
        -- removed above when delfile is available; versioned cache is fallback.
        local legacyPath = "Mana/" .. filepath
        if shared.ManaDeveloper and betterisfile(legacyPath) then
            local devChunk, devError = loadstring(readfile(legacyPath))
            if not devChunk then
                error("[Nursultan]: compile error in local " .. filepath .. ": " .. tostring(devError), 0)
            end
            return devChunk()
        end

        -- In normal mode, refresh from GitHub first so cached modules cannot
        -- hide updates published to the repository.
        local ok, req = pcall(function()
            return requestfunc({
                Url = GitHubFileUrl(filepath),
                Method = "GET",
                Headers = { ["Cache-Control"] = "no-cache" }
            })
        end)
        local content
        if ok and req and (req.StatusCode == nil or req.StatusCode < 400) then
            content = req.Body
        end
        if type(content) == "string" and #content >= 20 then
            pcall(function() writefile(cachePath, content) end)
            if delfile then pcall(delfile, legacyPath) end
            if shared.ManaDeveloper then pcall(writefile, legacyPath, content) end
            local chunk, compileError = loadstring(content)
            if not chunk then
                error("[Nursultan]: compile error in " .. filepath .. ": " .. tostring(compileError), 0)
            end
            print("[Nursultan]: loaded " .. filepath .. " from GitHub")
            return chunk()
        end

        -- If GitHub is unavailable, keep the last working local copy usable.
        if betterisfile(cachePath) then
            return loadstring(readfile(cachePath))()
        end
        error("[Nursultan]: failed to download " .. filepath .. " (no cached version " .. MODULE_CACHE_VERSION .. ")")
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

-- // Nursultan menu (ported from the original client UI)
local nightixOk, nightixErr = pcall(function()
    local clientMenu = Functions:RunFile("NightixMenu.lua")
    clientMenu(GuiLibrary, GuiLibrary.OptionFunctions or {}, Mana.Connections, UserInputService, game:GetService("TweenService"), game:GetService("TextService"), Mouse, function(func) return coroutine.wrap(func)() end)
end)
if not nightixOk then
    error("[Nursultan/MainScript.lua]: Failed to initialize menu before creating tabs: " .. tostring(nightixErr))
end

if type(GuiLibrary.CreateTab) ~= "function" or type(GuiLibrary.CreateOptionsTab) ~= "function" then
    error("[Nursultan/MainScript.lua]: menu did not register the tab API")
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
    Confings = GuiLibrary:CreateOptionsTab({
        Name = "Confings",
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
            GuiLibrary.Scale = v
            GuiLibrary.NursultanScale = v
            GuiLibrary.NightixScale = v
            local clientMenu = GuiLibrary.NursultanMenu or GuiLibrary.NightixMenu
            if clientMenu and clientMenu.SetNursultanScale then
                clientMenu:SetNursultanScale(v)
            elseif GuiLibrary.UIScale then
                GuiLibrary.UIScale.Scale = v
            end
        end,
        Min = 0.5, Max = 2, Default = tonumber(GuiLibrary.NursultanScale or GuiLibrary.NightixScale or GuiLibrary.Scale or 1) or 1, Round = 2
    })

    Tabs.Settings:CreateButton({
        Name = "Сбросить UI scale",
        Function = function()
            local defaultScale = 1
            GuiLibrary.Scale = defaultScale
            GuiLibrary.NursultanScale = defaultScale
            GuiLibrary.NightixScale = defaultScale
            local clientMenu = GuiLibrary.NursultanMenu or GuiLibrary.NightixMenu
            if clientMenu and clientMenu.SetNursultanScale then
                clientMenu:SetNursultanScale(defaultScale)
            elseif GuiLibrary.UIScale then
                GuiLibrary.UIScale.Scale = defaultScale
            end
        end
    })

    -- Theme is a real function. All appearance controls live inside its option window.
    local themeFunction
    if type(Tabs.Settings.CreateModuleToggle) == "function" then
        themeFunction = Tabs.Settings:CreateModuleToggle({
            Name = "Theme",
            Default = true,
            Callback = function(v)
                local nl = (GuiLibrary.NursultanMenu or GuiLibrary.NightixMenu) and (GuiLibrary.NursultanMenu or GuiLibrary.NightixMenu).NeverLose
                if nl then
                    nl.IconSettings = nl.IconSettings or {}
                    nl.IconSettings.Enabled = v
                end
            end
        })
    else
        themeFunction = Tabs.Settings:CreateToggle({
            Name = "Theme",
            Default = true,
            Callback = function(v)
                local nl = (GuiLibrary.NursultanMenu or GuiLibrary.NightixMenu) and (GuiLibrary.NursultanMenu or GuiLibrary.NightixMenu).NeverLose
                if nl then
                    nl.IconSettings = nl.IconSettings or {}
                    nl.IconSettings.Enabled = v
                end
            end
        })
    end

    local nl = (GuiLibrary.NursultanMenu or GuiLibrary.NightixMenu) and (GuiLibrary.NursultanMenu or GuiLibrary.NightixMenu).NeverLose
    if nl then
        nl.IconSettings = nl.IconSettings or {}
        nl.IconSettings.Enabled = true
        nl.IconSettings.Mode = nl.IconSettings.Mode or "Double"
        nl.IconSettings.Color1 = nl.IconSettings.Color1 or Color3.fromRGB(216, 148, 245)
        nl.IconSettings.Color2 = nl.IconSettings.Color2 or Color3.fromRGB(123, 131, 243)
        nl.IconSettings.Speed = nl.IconSettings.Speed or 0.65
    end

    -- Theme controls belong to the Theme function's gear window. If an old
    -- adapter returns a plain toggle, use harmless local APIs instead of
    -- aborting MainScript before Universal.lua can register its sections.
    local themeOwner = themeFunction
    if type(themeFunction.CreateDropdown) ~= "function" then
        themeOwner = {}
        function themeOwner:CreateDropdown(config)
            local api = {Value = config.Default}
            function api:Select(value) self.Value = value end
            return api
        end
        function themeOwner:CreateColorSlider(config)
            local api = {Value = config.Default, Container = {Visible = true}}
            function api:Set(value)
                if typeof(value) == "Color3" then self.Value = value end
            end
            return api
        end
        function themeOwner:CreateSlider(config)
            local api = {Value = config.Default, Container = {Visible = true}}
            function api:Set(value) self.Value = value end
            return api
        end
        function themeOwner:CreateButton()
            return {}
        end
    end

    local themeColor2, themeSpeed
    local themeMode = themeOwner:CreateDropdown({
        Name = "Режим",
        List = {"Одиночный", "Двойной"},
        Default = "Двойной",
        Function = function(v)
            local nl2 = (GuiLibrary.NursultanMenu or GuiLibrary.NightixMenu) and (GuiLibrary.NursultanMenu or GuiLibrary.NightixMenu).NeverLose
            if not nl2 then return end
            nl2.IconSettings.Mode = (v == "Одиночный") and "Single" or "Double"
            nl2.IconSettings.SingleInitialized = false
            if nl2.IconSettings.Mode == "Single" and not nl2.IconSettings.SingleInitialized then
                nl2.IconSettings.Color1 = Color3.fromRGB(255, 255, 255)
                nl2.IconSettings.SingleInitialized = true
            end
            local double = nl2.IconSettings.Mode == "Double"
            if themeColor2 and themeColor2.Container then themeColor2.Container.Visible = double end
            if themeSpeed and themeSpeed.Container then themeSpeed.Container.Visible = double end
        end
    })

    local themeColor1 = themeOwner:CreateColorSlider({
        Name = "Первый цвет",
        Default = (nl and nl.IconSettings and nl.IconSettings.Color1) or Color3.fromRGB(216, 148, 245),
        Function = function(v)
            local nl2 = (GuiLibrary.NursultanMenu or GuiLibrary.NightixMenu) and (GuiLibrary.NursultanMenu or GuiLibrary.NightixMenu).NeverLose
            if nl2 then nl2.IconSettings.Color1 = v end
        end
    })

    themeColor2 = themeOwner:CreateColorSlider({
        Name = "Второй цвет",
        Default = (nl and nl.IconSettings and nl.IconSettings.Color2) or Color3.fromRGB(123, 131, 243),
        Function = function(v)
            local nl2 = (GuiLibrary.NursultanMenu or GuiLibrary.NightixMenu) and (GuiLibrary.NursultanMenu or GuiLibrary.NightixMenu).NeverLose
            if nl2 then nl2.IconSettings.Color2 = v end
        end
    })

    themeSpeed = themeOwner:CreateSlider({
        Name = "Скорость переливания",
        Min = 0.05, Max = 1.5, Default = (nl and nl.IconSettings and nl.IconSettings.Speed) or 0.65, Round = 2,
        Function = function(v)
            local nl2 = (GuiLibrary.NursultanMenu or GuiLibrary.NightixMenu) and (GuiLibrary.NursultanMenu or GuiLibrary.NightixMenu).NeverLose
            if nl2 then nl2.IconSettings.Speed = v end
        end
    })

    local function applyTheme(v)
        local nl2 = (GuiLibrary.NursultanMenu or GuiLibrary.NightixMenu) and (GuiLibrary.NursultanMenu or GuiLibrary.NightixMenu).NeverLose
        local palette = GuiLibrary.GuiPallet
        if not nl2 or not palette then return end

        -- Presets are actions, not a persistent "theme selection". Clicking a
        -- preset immediately writes the complete client palette and refreshes
        -- already-created UI objects. A custom theme can therefore be replaced
        -- instantly without changing any separate theme state.
        local themes = {
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

        -- Presets are text/client-icon themes only. Never repaint menu or
        -- button backgrounds when switching between presets.
        palette.ThemeMode = "Preset"

        nl2.IconSettings = nl2.IconSettings or {}
        nl2._LastThemePalette = nl2.ThemePalette
        nl2.ThemePalette = theme
        nl2.IconSettings.Mode = "Double"
        nl2.IconSettings.Color1 = theme.Icon1
        nl2.IconSettings.Color2 = theme.Icon2
        nl2.IconSettings.Speed = 0.65
        -- Update the visible controls too; changing the preset must not leave
        -- stale picker swatches from the previous theme.
        local h1, s1, v1 = theme.Icon1:ToHSV()
        local h2, s2, v2 = theme.Icon2:ToHSV()
        pcall(function() themeColor1:Set(h1, s1, v1, false) end)
        pcall(function() themeColor2:Set(h2, s2, v2, false) end)
        pcall(function() themeSpeed:Set(0.65) end)
        pcall(function() themeMode:Select("Двойной") end)
        if nl2.RefreshNightixTheme then
            nl2:RefreshNightixTheme()
        end

    end

    -- Presets are buttons: pressing one applies the palette immediately.
    themeOwner:CreateButton({
        Name = "Nursultan 1.16.5",
        Callback = function() applyTheme("Nursultan 1.16.5") end
    })

    -- The function itself starts with the default client theme.
    themeMode:Select("Двойной")
    if themeColor2.Container then themeColor2.Container.Visible = true end
    if themeSpeed.Container then themeSpeed.Container.Visible = true end
end)

-- Confings tab
runFunction(function()
    Tabs.Confings:CreateConfigManager({
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

print("[Nursultan/MainScript.lua]: Loaded in " .. tostring(tick() - startTick) .. ".")

Functions:RunFile("Universal.lua")

local suc, res = pcall(function()
    Functions:RunFile("Scripts/" .. PlaceId .. ".lua")
end)

if not suc then
    warn("[Nursultan/MainScript.lua]: an error occured while attempting to load game script: " .. res)
    GuiLibrary.CanLoadConfig = true
end

LocalPlayer.OnTeleport:Connect(function(State)
    if State == Enum.TeleportState.Started then
        local QueueTeleportFunction = [[
            if shared.ManaDeveloper then 
                loadstring(readfile("NewMana/MainScript.lua"))()
            else 
                loadstring(game:HttpGet("]] .. GitHubRepo .. [[MainScript.lua?v=]] .. tostring(math.floor(tick())) .. [["))()
            end
        ]]
        queueteleport(QueueTeleportFunction)
    end
end)

repeat task.wait() until GuiLibrary.CanLoadConfig -- game-specific modules are loaded before marking the client ready
GuiLibrary.Loaded = true
Mana.Loaded = true
-- Configs are loaded manually from Profiles. There is no automatic config load/save.
