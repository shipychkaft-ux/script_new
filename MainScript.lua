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

-- Remote shader bridge: reads SystemDLC shader definitions as data and renders compatible effects with Roblox APIs.
local ShaderBridge = Functions:RunFile("ShaderBridge.lua")
Mana.ShaderBridge = ShaderBridge.new({
    BaseUrl = GitHubRepo .. "shaders/",
    CacheFolder = "Mana/Shaders",
})
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
        Color = Color3.fromRGB(197, 132, 211),
        TabIcon = "CombatTabIcon.png"
    }),
    Movement = GuiLibrary:CreateTab({
        Name = "Movement",
        Color = Color3.fromRGB(197, 132, 211),
        TabIcon = "MovementTabIcon.png"
    }),
    Visuals = GuiLibrary:CreateTab({
        Name = "Visuals",
        Color = Color3.fromRGB(197, 132, 211),
        TabIcon = "RenderTabIcon.png"
    }),
    Player = GuiLibrary:CreateTab({
        Name = "Player",
        Color = Color3.fromRGB(197, 132, 211),
        TabIcon = "PlayerImage.png"
    }),
    Miscellaneous = GuiLibrary:CreateTab({
        Name = "Miscellaneous",
        Color = Color3.fromRGB(197, 132, 211),
        TabIcon = "rbxassetid://89294237251926",
    }),
}

-- Backward-compatible names used by the existing module files.
Tabs.Render = Tabs.Visuals
Tabs.Utility = Tabs.Miscellaneous
Tabs.Friends = Tabs.Player
Tabs.Settings = Tabs.Miscellaneous
Tabs.Confings = Tabs.Miscellaneous
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

-- // Interface / Theme Editor / UI settings
runFunction(function()
    local nl = GuiLibrary.NightixMenu and GuiLibrary.NightixMenu.NeverLose
    if not nl then return end

    GuiLibrary.GuiPallet.ThemeMode = "Nightix"
    nl.IconSettings = nl.IconSettings or {}
    nl.IconSettings.Enabled = true
    nl.IconSettings.Mode = "Double"
    nl.IconSettings.Color1 = Color3.fromRGB(197,132,211)
    nl.IconSettings.Color2 = Color3.fromRGB(95,63,121)
    nl.IconSettings.Speed = 0.65

    Tabs.Miscellaneous:CreateDivider("UI")
    Tabs.Miscellaneous:CreateToggle({Name="Notifications", Default=true, Function=function(v) GuiLibrary.Notifications=v end})
    local sounds = Tabs.Miscellaneous:CreateToggle({Name="Sounds", Default=true, Function=function(v) GuiLibrary.Sounds=v end})
    Tabs.Miscellaneous:CreateSlider({Name="Volume", Min=0, Max=1, Default=1, Round=2, Function=function(v) GuiLibrary.SoundVolume=v end})
    Tabs.Miscellaneous:CreateSlider({Name="UI scale", Min=.5, Max=2, Default=tonumber(GuiLibrary.NightixScale or 1) or 1, Round=2, Function=function(v)
        GuiLibrary.Scale=v; GuiLibrary.NightixScale=v
        if GuiLibrary.NightixMenu and GuiLibrary.NightixMenu.SetNightixScale then GuiLibrary.NightixMenu:SetNightixScale(v) end
    end})

    local function cloneTheme(theme)
        local out={}
        for k,v in pairs(theme) do out[k]=v end
        return out
    end

    local defaultTheme = {
        MenuBackground=Color3.fromRGB(30,30,52), FunctionBackground=Color3.fromRGB(30,30,52), ActiveFunction=Color3.fromRGB(41,35,67), FunctionStroke=Color3.fromRGB(45,38,72),
        VisualFunctions=Color3.fromRGB(197,132,211), VisualFunctions2=Color3.fromRGB(95,63,121), TextColor=Color3.fromRGB(255,255,255), InactiveText=Color3.fromRGB(210,210,220), HeaderText=Color3.fromRGB(255,255,255), PremiumText=Color3.fromRGB(205,180,95),
        Slider=Color3.fromRGB(197,132,211), SliderKnob=Color3.fromRGB(255,255,255), Toggle=Color3.fromRGB(20,20,34), ToggleActive=Color3.fromRGB(197,132,211), Button=Color3.fromRGB(41,35,67), ButtonInactive=Color3.fromRGB(30,30,52), HudBackground=Color3.fromRGB(18,18,31),
    }

    local themes = { ["Nursultan 1.16.5"] = cloneTheme(defaultTheme) }
    local themeOrder = {"Nursultan 1.16.5"}
    local selectedTheme = "Nursultan 1.16.5"
    local themeButtons = {}
    local themePickers = {}
    local loadingTheme = false
    local themeFile = "Nightix/Themes.json"
    local rebuildThemeButtons

    local function saveThemes()
        pcall(function()
            local data={Order=themeOrder, Themes={}}
            for name,theme in pairs(themes) do
                data.Themes[name]={}
                for k,c in pairs(theme) do
                    if typeof(c)=="Color3" then data.Themes[name][k]={math.floor(c.R*255+.5),math.floor(c.G*255+.5),math.floor(c.B*255+.5)} end
                end
            end
            writefile(themeFile,httpService:JSONEncode(data))
        end)
    end

    local function loadThemes()
        pcall(function()
            if not isfile(themeFile) then return end
            local data=httpService:JSONDecode(readfile(themeFile))
            if type(data)~="table" or type(data.Themes)~="table" then return end
            table.clear(themeOrder); table.clear(themes)
            for _,name in ipairs(data.Order or {}) do
                if type(data.Themes[name])=="table" then
                    local t={}
                    for k,rgb in pairs(data.Themes[name]) do if type(rgb)=="table" then t[k]=Color3.fromRGB(tonumber(rgb[1]) or 0,tonumber(rgb[2]) or 0,tonumber(rgb[3]) or 0) end end
                    themes[name]=t; table.insert(themeOrder,name)
                end
            end
            if #themeOrder==0 then themes["Nursultan 1.16.5"]=cloneTheme(defaultTheme); table.insert(themeOrder,"Nursultan 1.16.5") end
            selectedTheme=themeOrder[1]
        end)
    end
    loadThemes()

    local function applyTheme(name)
        local theme=themes[name]; if not theme then return end
        selectedTheme=name; loadingTheme=true
        nl.ThemePalette=theme
        GuiLibrary.GuiPallet.Color1=theme.MenuBackground or GuiLibrary.GuiPallet.Color1
        GuiLibrary.GuiPallet.Color2=theme.FunctionBackground or GuiLibrary.GuiPallet.Color2
        GuiLibrary.GuiPallet.Color3=theme.ActiveFunction or GuiLibrary.GuiPallet.Color3
        GuiLibrary.GuiPallet.Color4=theme.FunctionStroke or GuiLibrary.GuiPallet.Color4
        GuiLibrary.GuiPallet.ToggleColor=theme.Toggle or GuiLibrary.GuiPallet.ToggleColor
        GuiLibrary.GuiPallet.ToggleColor2=theme.ToggleActive or GuiLibrary.GuiPallet.ToggleColor2
        GuiLibrary.GuiPallet.TextColor=theme.TextColor or GuiLibrary.GuiPallet.TextColor
        nl.IconSettings.Color1=theme.VisualFunctions or defaultTheme.VisualFunctions
        nl.IconSettings.Color2=theme.VisualFunctions2 or defaultTheme.VisualFunctions2
        nl.IconSettings.Mode="Double"
        if nl.RefreshNightixTheme then nl:RefreshNightixTheme() end
        for key,picker in pairs(themePickers) do if theme[key] then pcall(function() picker:Set(theme[key],nil,nil,nil,true) end) end end
        for _,entry in ipairs(themeButtons) do
            if entry.stroke then entry.stroke.Thickness=(entry.name==selectedTheme and 2 or 1) end
        end
        loadingTheme=false
        saveThemes()
    end

    Tabs.Miscellaneous:CreateDivider("Theme Editor")
    local themeNameInput = Tabs.Miscellaneous:CreateTextBox({Name="Название", Placeholder="Название темы", Default=""})
    Tabs.Miscellaneous:CreateButton({Name="Создать", Icon="circle-plus", Function=function()
        local name=tostring(themeNameInput.Value or ""):gsub("^%s+",""):gsub("%s+$","")
        if name=="" or themes[name] then return end
        themes[name]=cloneTheme(defaultTheme); table.insert(themeOrder,name); themeNameInput:Set(""); saveThemes(); applyTheme(name)
        if rebuildThemeButtons then rebuildThemeButtons() end
    end})
    Tabs.Miscellaneous:CreateDivider("Нужен премиум")

    rebuildThemeButtons = function()
        -- The visual editor is intentionally represented by real module rows; each row gets a small color circle.
        for _,entry in ipairs(themeButtons) do if entry.root then pcall(function() entry.root:Destroy() end) end end
        table.clear(themeButtons)
        for _,name in ipairs(themeOrder) do
            local button=Tabs.Miscellaneous:CreateButton({Name="●  "..name, Icon="chevron-large-right", Function=function() applyTheme(name) end})
            local root=button.MainObject
            local dot=Instance.new("Frame"); dot.Name="NightixThemeDot"; dot.AnchorPoint=Vector2.new(0,0.5); dot.Position=UDim2.fromOffset(9,15); dot.Size=UDim2.fromOffset(10,10); dot.BorderSizePixel=0; dot.BackgroundColor3=themes[name].VisualFunctions or defaultTheme.VisualFunctions; dot.ZIndex=root.ZIndex+5; dot.Parent=root
            local c=Instance.new("UICorner",dot); c.CornerRadius=UDim.new(1,0)
            local stroke=Instance.new("UIStroke",root); stroke.Color=Color3.fromRGB(255,255,255); stroke.Transparency=(name==selectedTheme and 0 or .8); stroke.Thickness=(name==selectedTheme and 2 or 1)
            table.insert(themeButtons,{name=name,root=root,dot=dot,stroke=stroke})
        end
    end
    rebuildThemeButtons()

    local function addThemeColor(key,label,default)
        local picker=Tabs.Miscellaneous:CreateColorSlider({Name=label, Default=themes[selectedTheme][key] or default, Function=function(v)
            if loadingTheme then return end
            themes[selectedTheme][key]=v
            if key=="VisualFunctions" then nl.IconSettings.Color1=v end
            if key=="VisualFunctions2" then nl.IconSettings.Color2=v end
            nl.ThemePalette=themes[selectedTheme]
            if nl.RefreshNightixTheme then nl:RefreshNightixTheme() end
            for _,entry in ipairs(themeButtons) do if entry.name==selectedTheme and entry.dot then entry.dot.BackgroundColor3=v end end
            saveThemes()
        end})
        themePickers[key]=picker
    end
    addThemeColor("MenuBackground","Основной",defaultTheme.MenuBackground)
    addThemeColor("FunctionBackground","Визуальные модули",defaultTheme.FunctionBackground)
    addThemeColor("TextColor","Текст",defaultTheme.TextColor)
    addThemeColor("InactiveText","Неактивный текст",defaultTheme.InactiveText)
    addThemeColor("HeaderText","Текст заголовков",defaultTheme.HeaderText)
    addThemeColor("PremiumText","Премиум текст",defaultTheme.PremiumText)
    addThemeColor("Slider","Слайдер",defaultTheme.Slider)
    addThemeColor("SliderKnob","Круг слайдера",defaultTheme.SliderKnob)
    addThemeColor("FunctionStroke","Обводка функций",defaultTheme.FunctionStroke)
    addThemeColor("ActiveFunction","Активные функции",defaultTheme.ActiveFunction)
    addThemeColor("Toggle","Переключатель",defaultTheme.Toggle)
    addThemeColor("ToggleActive","Активный переключатель",defaultTheme.ToggleActive)
    addThemeColor("Button","Кнопка",defaultTheme.Button)
    addThemeColor("ButtonInactive","Неактивная кнопка",defaultTheme.ButtonInactive)
    addThemeColor("VisualFunctions","Цвет визуальных функций",defaultTheme.VisualFunctions)
    addThemeColor("VisualFunctions2","Второй цвет визуальных функций",defaultTheme.VisualFunctions2)

    applyTheme(selectedTheme)
end)

-- Confings
runFunction(function()
    Tabs.Miscellaneous:CreateConfigManager({Name="Configs"})
end)

-- Player / friends
runFunction(function()
    local Friends = Tabs.Player:CreateTextList({Name="Friends", List={}, PlaceholderText="Friend Name", Callback=function() end})
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
