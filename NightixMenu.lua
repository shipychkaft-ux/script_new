-- Nightix menu powered by the NeverLose UI library.
-- All Mana modules (Universal.lua) are exposed through the standard Mana API
-- (CreateTab / CreateToggle / CreateSlider / ...). No module code is modified.

return function(guilibrary, OptionFunctions, connections, userInputService, tweenService, textService, mouse, spawn)
    local Mana = shared.Mana
    local Functions = Mana.Functions
    local ObjectsToSave = guilibrary.ObjectsToSave
    local localPlayer = game:GetService("Players").LocalPlayer
    local runService = game:GetService("RunService")

    -- Load the NeverLose UI library (Nightix-style UI)
    local NeverLose = Functions:RunFile("NeverLose.lua")
    if not (NeverLose and NeverLose.CreateWindow) then
        error("[NightixMenu]: failed to load the NeverLose UI library")
    end

    -- ------------------------------------------------------------------
    -- Window
    -- ------------------------------------------------------------------
    local window = NeverLose:CreateWindow({
        Logo = "rbxassetid://80320370259758",
        Name = "Nightix",
        Content = "Nightix",
        Size = NeverLose.Scales.Default,
        ConfigFolder = "NightixConfigs",
        Enable3DRenderer = false,
        Keybind = "None", -- the menu is toggled through GuiLibrary:Toggle() only
    })

    -- watermark
    local Watermark = window:Watermark()
    Watermark:AddBlock("cube-vertexes", "Nightix")
    Watermark:AddBlock("chevron-large-right", "Nightix")

    -- load notification
    local Notification = NeverLose:CreateNotification()
    Notification.new({
        Title = "Nightix",
        Content = "Nightix loaded",
        Duration = 4,
    })

    -- guilibrary state
    guilibrary.UIScale = { Scale = 1 }
    guilibrary.GuiKeybind = guilibrary.GuiKeybind or "RightShift"
    guilibrary.Toggled = false
    local previousMouseBehavior
    local previousMouseIconEnabled
    local previousCameraMinZoomDistance
    local previousCameraMaxZoomDistance
    local previousCameraMode
    local menuInputConnection
    local optionWindows = {}
    local toggleNotifications = {}
    local toggleOnSound = "rbxassetid://95856755098572"
    local toggleOffSound = "rbxassetid://74014422539208"

    local function showToggleNotification(name, enabled)
        local notification = Instance.new("Frame")
        local label = Instance.new("TextLabel")
        local status = enabled and "on" or "off"

        notification.AnchorPoint = Vector2.new(1, 0)
        notification.BackgroundColor3 = Color3.fromRGB(20, 22, 27)
        notification.BackgroundTransparency = 1
        notification.BorderSizePixel = 0
        notification.Size = UDim2.fromOffset(190, 26)
        notification.ZIndex = 200
        notification.Parent = NeverLose.ScreenGui

        label.BackgroundTransparency = 1
        label.Size = UDim2.fromScale(1, 1)
        label.Font = Enum.Font.GothamMedium
        label.Text = tostring(name) .. " " .. status
        label.TextColor3 = enabled and Color3.fromRGB(100, 235, 125) or Color3.fromRGB(255, 95, 105)
        label.TextSize = 13
        label.TextXAlignment = Enum.TextXAlignment.Center
        label.TextTransparency = 1
        label.Parent = notification

        table.insert(toggleNotifications, notification)

        local function refreshPositions()
            local maxVisible = math.max(1, math.floor((workspace.CurrentCamera.ViewportSize.Y * 0.3) / 31))
            local index = 1
            while index <= #toggleNotifications do
                local item = toggleNotifications[index]
                if index > maxVisible then
                    local itemLabel = item:FindFirstChildOfClass("TextLabel")
                    tweenService:Create(item, TweenInfo.new(0.2), {
                        Position = item.Position + UDim2.fromOffset(45, 0),
                        BackgroundTransparency = 1,
                    }):Play()
                    if itemLabel then
                        tweenService:Create(itemLabel, TweenInfo.new(0.2), {TextTransparency = 1}):Play()
                    end
                    task.delay(0.2, function()
                        if item.Parent then item:Destroy() end
                    end)
                    table.remove(toggleNotifications, index)
                else
                    index += 1
                end
            end

            for index, item in ipairs(toggleNotifications) do
                if item.Parent then
                    item.Position = UDim2.new(1, 220, 0.8, -((index - 1) * 31))
                    tweenService:Create(item, TweenInfo.new(0.2, Enum.EasingStyle.Quad), {
                        Position = UDim2.new(1, -15, 0.8, -((index - 1) * 31)),
                        BackgroundTransparency = 0.15,
                    }):Play()
                    local itemLabel = item:FindFirstChildOfClass("TextLabel")
                    if itemLabel then
                        tweenService:Create(itemLabel, TweenInfo.new(0.2), {TextTransparency = 0}):Play()
                    end
                end
            end
        end

        refreshPositions()
        task.delay(2, function()
            if notification.Parent then
                tweenService:Create(notification, TweenInfo.new(0.25), {
                    Position = notification.Position + UDim2.fromOffset(45, 0),
                    BackgroundTransparency = 1,
                }):Play()
                tweenService:Create(label, TweenInfo.new(0.25), {TextTransparency = 1}):Play()
                task.delay(0.25, function()
                    local index = table.find(toggleNotifications, notification)
                    if index then table.remove(toggleNotifications, index) end
                    notification:Destroy()
                    refreshPositions()
                end)
            end
        end)
    end

    -- the library reveals the window ~0.25s after creation; hide it again
    task.delay(0.4, function()
        if not guilibrary.Toggled then
            window.Signal:SetValue(false)
        end
    end)

    -- menu scale, adjustable through UserSettings
    local menuScale = NeverLose.Scales.Default

    -- ------------------------------------------------------------------
    -- helpers
    -- ------------------------------------------------------------------
    local function clampValue(v, min, max)
        return math.max(min, math.min(max, v))
    end

    local function roundValue(v, round)
        round = round or 0
        return math.floor(v * (10 ^ round) + 0.5) / (10 ^ round)
    end

    local function findStringInTable(t, str)
        for i, v in pairs(t) do
            if tostring(v) == tostring(str) then return i end
        end
        return nil
    end

    local function dummyContainer()
        return Instance.new("Frame")
    end

    -- tab state: name -> { tab = nltab, section = current section }
    local tabStates = {}

    local function getSection(tabname)
        local st = tabStates[tabname]
        if not st then
            error("[NightixMenu]: unknown tab '" .. tostring(tabname) .. "'")
        end
        if not st.section then
            st.section = st.tab:AddSection({ Name = "Modules", Position = "Auto" })
        end
        return st.section
    end

    local function registerOption(toggleName, tabName, name, api, otype)
        if toggleName and ObjectsToSave.Toggles[toggleName] then
            ObjectsToSave.Toggles[toggleName].Options[name] = { Name = name, API = api, Type = otype }
        elseif tabName and ObjectsToSave.Tabs[tabName] then
            ObjectsToSave.Tabs[tabName].Options[name] = { Name = name, API = api, Type = otype }
        end
        return api
    end

    -- ------------------------------------------------------------------
    -- option creators (shared by module toggles and option tabs)
    -- ------------------------------------------------------------------

    local function createSlider(container, argstable, toggleName, tabName)
        local name = tostring(argstable.Name or "Slider"):gsub("%s+$", "")
        local min = argstable.Min or 0
        local max = argstable.Max or 100
        local def = argstable.Default or argstable.DefaultValue or min
        local round = argstable.Round or 0
        local callback = argstable.Callback or argstable.Function or function() end

        local label = container:AddLabel(name)
        if argstable.HoverText then label:ToolTip(tostring(argstable.HoverText)) end

        local lib = label:AddSlider({
            Default = def,
            Min = min,
            Max = max,
            Rounding = round,
            Type = argstable.Type or "",
            Size = 100,
            Callback = callback,
        })

        local api = {
            Name = name,
            Value = def,
            Min = min,
            Max = max,
            Round = round,
            Callback = callback,
            MainObject = label.Root,
            Container = label.Root,
        }

        function api:Set(value, CanOverride)
            local v = CanOverride and value or roundValue(clampValue(value, min, max), round)
            api.Value = v
            lib:SetValue(v)
        end

        if def then
            api:Set(def)
        end

        return registerOption(toggleName, tabName, name, api, "Slider")
    end

    local function createDropdown(container, argstable, toggleName, tabName)
        local name = tostring(argstable.Name or "Dropdown"):gsub("%s+$", "")
        local list = argstable.List or {}
        local def = argstable.Default or argstable.DefaultValue
        if def == nil then
            local first = next(list)
            def = first and list[first] or "nil"
        end
        local callback = argstable.Callback or argstable.Function or function() end

        local label = container:AddLabel(name)
        if argstable.HoverText then label:ToolTip(tostring(argstable.HoverText)) end

        local api = {
            Name = name,
            List = {},
            Value = def,
            Callback = callback,
            MainObject = label.Root,
            Container = label.Root,
            Container1 = label.Root,
            Container2 = label.Root,
        }
        for i, v in pairs(list) do
            api.List[v] = v
        end

        local lib = label:AddDropdown({
            Name = name,
            Default = def,
            Size = 100,
            Callback = function(v)
                api.Value = v
                callback(v)
            end,
        })
        lib:SetValues(list)

        function api:Select(option)
            if option == nil then return end
            local opt = api.List[option] or list[option]
            if not opt then
                local i = findStringInTable(list, option)
                if i then opt = list[i] end
            end
            if opt then
                api.Value = opt
                lib:SetValue(opt)
            end
        end

        api:Select(def)

        return registerOption(toggleName, tabName, name, api, "Dropdown")
    end

    local function createOptionToggle(container, argstable, toggleName, tabName)
        local name = tostring(argstable.Name or "Toggle")
        local def = argstable.Default or argstable.DefaultValue or false
        local callback = argstable.Callback or argstable.Function or function() end

        local label = container:AddLabel(name)
        if argstable.HoverText then label:ToolTip(tostring(argstable.HoverText)) end

        local api = {
            Name = name,
            Value = def,
            Callback = callback,
            MainObject = label.Root,
            Container = label.Root,
        }

        local lib = label:AddToggle({
            Default = def,
            Callback = function(v)
                api.Value = v
                callback(v)
            end,
        })

        function api:Toggle(value)
            local v = value ~= nil and value or not api.Value
            api.Value = v
            lib:SetValue(v)
        end

        api:Toggle(def)

        return registerOption(toggleName, tabName, name, api, "Toggle")
    end

    local function createColorSlider(container, argstable, toggleName, tabName)
        local name = tostring(argstable.Name or "Color"):gsub("%s+$", "")
        local def = argstable.Default or argstable.DefaultValue or Color3.fromRGB(255, 255, 255)
        local callback = argstable.Callback or argstable.Function or function() end

        local label = container:AddLabel(name)
        if argstable.HoverText then label:ToolTip(tostring(argstable.HoverText)) end

        local api = {
            Name = name,
            Value = def,
            RelativeTable = {},
            Callback = callback,
            MainObject = label.Root,
            Container = label.Root,
        }

        local lib = label:AddColorPicker({
            Default = def,
            Callback = callback,
        })

        function api:Set(hueValue, satValue, valValue, rainbow, load)
            hueValue = hueValue or 0
            satValue = satValue or 1
            valValue = valValue or 1
            local color = guilibrary:HSVtoRGB(hueValue, satValue, valValue)
            api.Value = color
            api.RelativeTable = { hueValue, satValue, valValue }
            lib:SetValue(color)
            if not load then
                callback(color)
            end
        end

        local h, s, v = def:ToHSV()
        api.RelativeTable = { h, s, v }
        lib:SetValue(def)
        callback(def)

        return registerOption(toggleName, tabName, name, api, "ColorSlider")
    end

    local function createTextBox(container, argstable, toggleName, tabName)
        local name = tostring(argstable.Name or "Textbox"):gsub("%s+$", "")
        local def = tostring(argstable.Value or argstable.Default or argstable.DefaultValue or "")
        local callback = argstable.Callback or argstable.Function or function() end

        local label = container:AddLabel(name)
        if argstable.HoverText then label:ToolTip(tostring(argstable.HoverText)) end

        local api = {
            Name = name,
            Value = def,
            Callback = callback,
            MainObject = label.Root,
            Container = label.Root,
        }

        local lib = label:AddTextInput({
            Default = def,
            Placeholder = argstable.PlaceholderText or argstable.Placeholder or "",
            Numeric = argstable.Numeric or false,
            Size = argstable.Size or 100,
            Callback = function(v)
                api.Value = v
                callback(v)
            end,
        })

        function api:Set(text)
            api.Value = tostring(text or "")
            lib:SetValue(api.Value)
        end

        api:Set(def)

        return registerOption(toggleName, tabName, name, api, "TextBox")
    end

    local function createButton(container, argstable, toggleName, tabName)
        local name = tostring(argstable.Name or "Button")
        local callback = argstable.Callback or argstable.Function or function() end

        local lib = container:AddButton({
            Name = name,
            Icon = argstable.Icon or "chevron-large-right",
            Callback = callback,
        })

        local api = {
            Name = name,
            Callback = callback,
            MainObject = nil,
            Container = nil,
        }

        return registerOption(toggleName, tabName, name, api, "Button")
    end

    local function createTextList(container, argstable, toggleName, tabName)
        local name = tostring(argstable.Name or "List"):gsub("%s+$", "")
        local callback = argstable.Callback or argstable.Function or function() end

        local label = container:AddLabel(name)
        if argstable.HoverText then label:ToolTip(tostring(argstable.HoverText)) end

        local inputLib = label:AddTextInput({
            Default = "",
            Placeholder = argstable.PlaceholderText or "Value",
            Numeric = argstable.Numeric or false,
            Size = 100,
            Callback = function() end,
        })
        container:AddButton({
            Name = "Add",
            Icon = "circle-plus",
            Callback = function()
                local text = inputLib:GetValue()
                if text and text ~= "" then
                    api:CreateListObject(text)
                    inputLib:SetValue("")
                end
            end,
        })

        local api = {
            Name = name,
            List = {},
            Callback = callback,
            MainObject = label.Root,
            Container = label.Root,
        }

        function api:CreateListObject(value)
            local text = tostring(value)
            if text == "" then return end
            if findStringInTable(api.List, text) then return end
            table.insert(api.List, text)
            callback(text)

            local itemLabel = container:AddLabel(text)
            container:AddButton({
                Name = "Remove",
                Icon = "close",
                Callback = function()
                    for i, v in ipairs(api.List) do
                        if v == text then
                            table.remove(api.List, i)
                            break
                        end
                    end
                    itemLabel:SetVisible(false)
                    itemLabel.Root.Size = UDim2.new(1, 0, 0, 0)
                    for i, q in ipairs(NeverLose.NameRegisitry) do
                        if q.Root == itemLabel.Root then
                            table.remove(NeverLose.NameRegisitry, i)
                            break
                        end
                    end
                end,
            })
        end

        for _, v in pairs(argstable.DefaultList or argstable.List or {}) do
            api:CreateListObject(v)
        end

        return registerOption(toggleName, tabName, name, api, "TextList")
    end

    -- ------------------------------------------------------------------
    -- module toggle (a module row inside a tab)
    -- ------------------------------------------------------------------
    local function createModuleToggle(tabName, argstable)
        local toggleName = tostring(argstable.Name or "Toggle")
        local section = getSection(tabName)
        local label = section:AddLabel(toggleName)
        if argstable.HoverText then label:ToolTip(tostring(argstable.HoverText)) end

        local ToggleTable = {
            Name = toggleName,
            Value = argstable.Default or argstable.DefaultValue or false,
            Enabled = argstable.Default or argstable.DefaultValue or false,
            Keybind = argstable.Keybind or "None",
            Callback = argstable.Callback or argstable.Function or function() end,
            MainObject = label.Root,
            Container = label.Root,
            Options = {},
        }

        local keybindLib = label:AddKeybind({
            Default = ToggleTable.Keybind,
            Blacklist = { RightShift = true, Insert = true },
            Callback = function(v)
                ToggleTable.Keybind = v
            end,
        })

        local toggleLib = label:AddToggle({
            Default = ToggleTable.Enabled,
            Callback = function(v)
                if ToggleTable.Enabled ~= v then
                    ToggleTable.Enabled = v
                    ToggleTable:Toggle(false, v)
                end
            end,
        })

        local optionWindow = label:AddOption(1) -- gear: module options
        table.insert(optionWindows, optionWindow)

        function ToggleTable:Toggle(Silent, Bool)
            local Bool = Bool == nil and not ToggleTable.Enabled or Bool == true
            if ToggleTable.Enabled ~= Bool then
                ToggleTable.Enabled = Bool
                ToggleTable.Value = Bool
            end
            if not Silent and ToggleTable.Callback then
                ToggleTable.Callback(Bool)
            end
            guilibrary:playsound(Bool and toggleOnSound or toggleOffSound, 0.8)
            showToggleNotification(ToggleTable.Name, Bool)
            toggleLib:SetValue(Bool)
        end

        function ToggleTable:ReToggle(Silent)
            ToggleTable:Toggle(Silent, not ToggleTable.Enabled)
        end

        function ToggleTable:UpdateKeybind(remove, newKeybind)
            if remove then
                ToggleTable.Keybind = "None"
                keybindLib:SetValue("None")
            else
                local kb = newKeybind or "None"
                ToggleTable.Keybind = kb
                keybindLib:SetValue(kb)
            end
        end

        function ToggleTable:CreateSlider(argstable)
            return createSlider(optionWindow, argstable, toggleName, nil)
        end

        function ToggleTable:CreateDropdown(argstable)
            return createDropdown(optionWindow, argstable, toggleName, nil)
        end

        function ToggleTable:CreateColorSlider(argstable)
            return createColorSlider(optionWindow, argstable, toggleName, nil)
        end

        function ToggleTable:CreateToggle(argstable)
            return createOptionToggle(optionWindow, argstable, toggleName, nil)
        end

        function ToggleTable:CreateButton(argstable)
            return createButton(optionWindow, argstable, toggleName, nil)
        end

        function ToggleTable:CreateTextBox(argstable)
            return createTextBox(optionWindow, argstable, toggleName, nil)
        end

        function ToggleTable:CreateTextList(argstable)
            return createTextList(getSection(tabName), argstable, toggleName, nil)
        end

        table.insert(connections, userInputService.InputBegan:Connect(function(input, gameProcessed)
            if gameProcessed then return end

            local keybind = ToggleTable.Keybind
            local pressed = input.KeyCode ~= Enum.KeyCode.Unknown and input.KeyCode.Name == keybind
                or keybind == "M1B" and input.UserInputType == Enum.UserInputType.MouseButton1
                or keybind == "M2B" and input.UserInputType == Enum.UserInputType.MouseButton2

            if pressed then
                ToggleTable:ReToggle(false)
            end
        end))

        ObjectsToSave.Toggles[toggleName] = {
            Name = toggleName,
            API = ToggleTable,
            Options = ToggleTable.Options,
        }

        return ToggleTable
    end

    -- ------------------------------------------------------------------
    -- tabs
    -- ------------------------------------------------------------------
    local function createTab(argstable, isOptionsTab)
        local tabname = tostring(argstable.Name or "Tab")
        local tabIcons = {
            Combat = "sword",
            Movement = "mouse-scrollwheel",
            Render = "paint-brush",
            Utility = "wrench",
            World = "globe",
            Settings = "gear",
            Profiles = "three-dots-horizontal",
            Friends = "person",
        }

        local nltab = window:AddTab({
            Icon = tabIcons[tabname] or "folder",
            Name = tabname,
            Type = "Single",
        })

        tabStates[tabname] = { tab = nltab }

        local tabtable = {}
        tabtable.Options = {}
        tabtable.Container = dummyContainer()
        tabtable.Order = ObjectsToSave.Tabs and #ObjectsToSave.Tabs + 1 or 1

        if isOptionsTab then
            function tabtable:CreateToggle(argstable)
                return createOptionToggle(getSection(tabname), argstable, nil, tabname)
            end
        else
            function tabtable:CreateToggle(argstable)
                return createModuleToggle(tabname, argstable)
            end
        end

        function tabtable:CreateSlider(argstable)
            return createSlider(getSection(tabname), argstable, nil, tabname)
        end

        function tabtable:CreateDropdown(argstable)
            return createDropdown(getSection(tabname), argstable, nil, tabname)
        end

        function tabtable:CreateColorSlider(argstable)
            return createColorSlider(getSection(tabname), argstable, nil, tabname)
        end

        function tabtable:CreateButton(argstable)
            return createButton(getSection(tabname), argstable, nil, tabname)
        end

        function tabtable:CreateTextBox(argstable)
            return createTextBox(getSection(tabname), argstable, nil, tabname)
        end

        function tabtable:CreateTextList(argstable)
            return createTextList(getSection(tabname), argstable, nil, tabname)
        end

        function tabtable:CreateDivider(DividerText)
            return getSection(tabname):AddLabel(tostring(DividerText or ""))
        end

        ObjectsToSave.Tabs[tabname] = {
            Name = tabname,
            Type = isOptionsTab and "OptionTab" or "Tab",
            API = tabtable,
            Options = tabtable.Options,
        }

        return tabtable
    end

    local function createOptionsTab(argstable)
        return createTab(argstable, true)
    end

    -- ------------------------------------------------------------------
    -- window toggle (RightShift / GUI button)
    -- ------------------------------------------------------------------
    function guilibrary:Toggle(state)
        local current = window.Signal:GetValue()
        local newState
        if state == nil then
            newState = not current
        else
            newState = state and true or false
        end
        if current == newState then return end

        window:ToggleInterface()
        guilibrary.Toggled = window.Signal:GetValue()
        if guilibrary.Toggled then
            previousMouseBehavior = userInputService.MouseBehavior
            previousMouseIconEnabled = userInputService.MouseIconEnabled
            previousCameraMinZoomDistance = localPlayer.CameraMinZoomDistance
            previousCameraMaxZoomDistance = localPlayer.CameraMaxZoomDistance
            previousCameraMode = localPlayer.CameraMode
            localPlayer.CameraMode = Enum.CameraMode.Classic
            localPlayer.CameraMinZoomDistance = 1.5
            localPlayer.CameraMaxZoomDistance = 1.5
            userInputService.MouseBehavior = Enum.MouseBehavior.Default
            userInputService.MouseIconEnabled = true
            menuInputConnection = runService.RenderStepped:Connect(function()
                if guilibrary.Toggled then
                    localPlayer.CameraMode = Enum.CameraMode.Classic
                    localPlayer.CameraMinZoomDistance = 1.5
                    localPlayer.CameraMaxZoomDistance = 1.5
                    userInputService.MouseBehavior = Enum.MouseBehavior.Default
                    userInputService.MouseIconEnabled = true
                end
            end)
            window:SetSize(menuScale)
        else
            for _, optionWindow in ipairs(optionWindows) do
                if optionWindow.Signal then
                    optionWindow.Signal:SetValue(false)
                end
            end
            if menuInputConnection then
                menuInputConnection:Disconnect()
                menuInputConnection = nil
            end
            local restoreCameraMode = previousCameraMode
            local restoreMinZoomDistance = previousCameraMinZoomDistance
            local restoreMaxZoomDistance = previousCameraMaxZoomDistance
            local restoreCamera = function()
                localPlayer.CameraMode = restoreCameraMode
                localPlayer.CameraMinZoomDistance = restoreMinZoomDistance
                localPlayer.CameraMaxZoomDistance = restoreMaxZoomDistance
            end
            restoreCamera()
            task.defer(restoreCamera)
            userInputService.MouseBehavior = previousMouseBehavior
            userInputService.MouseIconEnabled = previousMouseIconEnabled
            previousMouseBehavior = nil
            previousMouseIconEnabled = nil
            previousCameraMinZoomDistance = nil
            previousCameraMaxZoomDistance = nil
        end
    end

    table.insert(connections, userInputService.InputBegan:Connect(function(input, gameProcessed)
        if not gameProcessed and input.UserInputType == Enum.UserInputType.Keyboard and input.KeyCode.Name == guilibrary.GuiKeybind then
            guilibrary:Toggle()
        end
    end))

    -- ------------------------------------------------------------------
    -- create window / clean up
    -- ------------------------------------------------------------------
    guilibrary.CreateWindow = function()
        guilibrary.TabsFrame = nil
        guilibrary.SearchFrame = nil
        return guilibrary
    end

    local oldDestruct = guilibrary.Destruct
    guilibrary.Destruct = function(self, ...)
        pcall(function()
            if NeverLose and NeverLose.ScreenGui then
                NeverLose.ScreenGui:Destroy()
            end
        end)
        return oldDestruct(self, ...)
    end

    -- the window keybind is handled by Mana (GuiLibrary:Toggle); the library's
    -- own handler never matches since the keybind is "None"
    guilibrary.CreateTab = function(_, argstable)
        return createTab(argstable, false)
    end
    guilibrary.CreateOptionsTab = function(_, argstable)
        return createOptionsTab(argstable)
    end

    guilibrary.NightixMenu = {
        Version = 2,
        Window = window,
        NeverLose = NeverLose,
    }

    return guilibrary
end