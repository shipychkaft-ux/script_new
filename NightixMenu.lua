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
        Logo = "rbxassetid://106084104602244",
        Name = "Default",
        Content = "Default",
        Size = NeverLose.Scales.Default,
        ConfigFolder = "NightixConfigs",
        EnableConfig = false,
        Enable3DRenderer = false,
        Keybind = "None", -- the menu is toggled through GuiLibrary:Toggle() only
    })

    -- watermark
    local Watermark = window:Watermark()
    shared.NightixWatermark = Watermark
    Watermark:AddBlock("rbxassetid://106084104602244", "Default | UID: " .. tostring(localPlayer.UserId))

    -- load notification
    local Notification = NeverLose:CreateNotification()
    Notification.new({
        Title = "Default",
        Content = "Nightix loaded",
        Duration = 4,
    })

    -- guilibrary state
    -- Preserve UI scale across Nightix menu rebuilds/restarts.
    local savedNightixScale = tonumber(guilibrary.NightixScale or guilibrary.Scale or 1) or 1
    guilibrary.NightixScale = savedNightixScale
    guilibrary.UIScale = { Scale = savedNightixScale }
    guilibrary.GuiKeybind = guilibrary.GuiKeybind or "RightShift"
    guilibrary.Toggled = false
    -- Keep the interface/HUD independent from menu visibility.
    NeverLose.InterfaceSettings = NeverLose.InterfaceSettings or {HUD=false, Blur=false, BlurStrength=12, BackgroundColor=Color3.fromRGB(30,30,52)}
    local previousMouseBehavior
    local previousMouseIconEnabled
    local previousCameraMinZoomDistance
    local previousCameraMaxZoomDistance
    local previousCameraMode
    local menuWasFirstPerson = false
    local menuInputConnection
    local optionWindows = {}
    local toggleOnSound = "rbxassetid://95856755098572"
    local toggleOffSound = "rbxassetid://74014422539208"

    local function showToggleNotification(name, enabled)
        local status = enabled and "on" or "off"
        local color = enabled and "#64EB7D" or "#FF5F69"
        local Notification = NeverLose:CreateNotification()
        Notification.new({
            Title = "Default",
            Content = tostring(name) .. " <font color=\"" .. color .. "\">" .. status .. "</font>",
            Duration = 2,
        })
    end

    guilibrary.CreateNotification = function() end

    -- the library reveals the window ~0.25s after creation; hide it again
    task.delay(0.4, function()
        if not guilibrary.Toggled then
            window.Signal:SetValue(false)
        end
    end)

    -- menu scale, adjustable through UserSettings
    local function scaleSize(scale)
        scale = tonumber(scale) or 1
        return UDim2.fromOffset(math.floor(640 * scale), math.floor(480 * scale))
    end
    local menuScaleValue = savedNightixScale
    local menuScale = scaleSize(menuScaleValue)

    function guilibrary:SetNightixScale(scale)
        menuScaleValue = clampValue(tonumber(scale) or 1, 0.5, 2)
        guilibrary.NightixScale = menuScaleValue
        guilibrary.UIScale.Scale = menuScaleValue
        menuScale = scaleSize(menuScaleValue)
        if window and window.SetSize then
            window:SetSize(menuScale)
        end
    end

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
            st.section = st.tab:AddSection({ Name = "", Position = "Auto" })
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

        local api
        local lib = label:AddSlider({
            Default = def,
            Min = min,
            Max = max,
            Rounding = round,
            Type = argstable.Type or "",
            Size = 100,
            Callback = function(v)
                if api then
                    api.Value = v
                end
                callback(v)
            end,
        })

        api = {
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

        function api:ReToggle()
            api:Toggle(false)
            api:Toggle(true)
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
            Callback = function(v)
                api.Value = v
                if typeof(v) == "Color3" then
                    local h, ss, vv = v:ToHSV()
                    api.RelativeTable = {h, ss, vv}
                end
                callback(v)
            end,
        })

        function api:Set(hueValue, satValue, valValue, rainbow, load)
            -- The color picker can call the public API with either a Color3
            -- or HSV components.  Never pass a Color3 into HSVtoRGB.
            local directColor
            local okColor = pcall(function()
                if type(hueValue) == "userdata" or typeof(hueValue) == "Color3" then
                    directColor = hueValue
                    directColor:ToHSV()
                end
            end)
            if okColor and directColor then
                local color = directColor
                local h, s, v = color:ToHSV()
                api.Value = color
                api.RelativeTable = { h, s, v }
                lib:SetValue(color)
                if not load then callback(color) end
                return
            end
            hueValue = tonumber(hueValue) or 0
            satValue = tonumber(satValue) or 1
            valValue = tonumber(valValue) or 1
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
            MainObject = lib and lib.MainObject,
            Container = lib and lib.Container,
        }

        return registerOption(toggleName, tabName, name, api, "Button")
    end

    local function createTextList(container, argstable, toggleName, tabName)
        local name = tostring(argstable.Name or "List"):gsub("%s+$", "")
        local callback = argstable.Callback or argstable.Function or function() end

        local label = container:AddLabel(name)
        if argstable.HoverText then label:ToolTip(tostring(argstable.HoverText)) end
        local itemObjects = {}

        local inputLib = label:AddTextInput({
            Default = "",
            Placeholder = argstable.PlaceholderText or "Value",
            Numeric = argstable.Numeric or false,
            Size = 100,
            Callback = function() end,
        })
        if not argstable.HideAdd then
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
        end

        local api = {
            Name = name,
            List = {},
            Callback = callback,
            MainObject = label.Root,
            Container = label.Root,
        }

        function api:Clear()
            for _, item in ipairs(itemObjects) do
                if item.button and item.button.MainObject then
                    item.button.MainObject:Destroy()
                end
                if item.label and item.label.Root then
                    for i = #NeverLose.NameRegisitry, 1, -1 do
                        if NeverLose.NameRegisitry[i].Root == item.label.Root then
                            table.remove(NeverLose.NameRegisitry, i)
                        end
                    end
                    item.label.Root:Destroy()
                end
            end
            table.clear(itemObjects)
            table.clear(api.List)
        end

        function api:CreateListObject(value)
            local text = tostring(value)
            if text == "" then return end
            if findStringInTable(api.List, text) then return end
            table.insert(api.List, text)
            callback(text)

            local itemLabel = container:AddLabel(text)
            local removeButton = container:AddButton({
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
                    if removeButton.MainObject then
                        removeButton.MainObject:Destroy()
                    end
                    if itemLabel.Root then
                        for i = #NeverLose.NameRegisitry, 1, -1 do
                            if NeverLose.NameRegisitry[i].Root == itemLabel.Root then
                                table.remove(NeverLose.NameRegisitry, i)
                            end
                        end
                        itemLabel.Root:Destroy()
                    end
                    for i = #itemObjects, 1, -1 do
                        if itemObjects[i].label == itemLabel then
                            table.remove(itemObjects, i)
                            break
                        end
                    end
                end,
            })
            table.insert(itemObjects, {label = itemLabel, button = removeButton})
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
            Callback = function(v) ToggleTable.Keybind = v end,
        })

        local toggleLib = label:AddToggle({
            Default = ToggleTable.Enabled,
            Callback = function(v)
                if ToggleTable.Enabled ~= v then ToggleTable:Toggle(true, v) end
            end,
        })

        -- The old tiny toggle/keybind controls are hidden. The whole function
        -- row is now the toggle target; the three-dots control remains visible.
        toggleLib.Root:SetAttribute("NightixHiddenModuleControl", true)
        keybindLib.Root:SetAttribute("NightixHiddenModuleControl", true)
        toggleLib.Root.Visible = false
        keybindLib.Root.Visible = false

        local optionWindow = label:AddOption(3) -- three dots
        table.insert(optionWindows, optionWindow)
        label.Root:SetAttribute("NightixEnabled", ToggleTable.Enabled == true)
        label.Root.BackgroundColor3 = ToggleTable.Enabled and NeverLose.ThemeColors.Active or NeverLose.ThemeColors.Background
        local bindMode = "Toggle"

        local function reapplyModuleOptions()
            for _, optionData in next, ToggleTable.Options do
                local api = optionData.API
                if not api then continue end
                if optionData.Type == "TextList" then
                    for _, item in ipairs(api.List or {}) do
                        if api.Callback then pcall(function() api.Callback(item) end) end
                    end
                elseif api.Callback and api.Value ~= nil then
                    pcall(function() api.Callback(api.Value) end)
                end
            end
        end

        function ToggleTable:SetEnabled(Bool, Silent)
            Bool = Bool == true
            if ToggleTable.Enabled == Bool then return false end

            ToggleTable.Enabled = Bool
            ToggleTable.Value = Bool
            label.Root:SetAttribute("NightixEnabled", Bool)
            label.Root.BackgroundColor3 = Bool and NeverLose.ThemeColors.Active or NeverLose.ThemeColors.Background
            toggleLib:SetValue(Bool)

            -- Explicit state changes (config loading/restarts) still need the
            -- module callback even when UI feedback is suppressed.
            if ToggleTable.Callback then
                ToggleTable.Callback(Bool)
            end
            if Bool then
                reapplyModuleOptions()
            end

            if not Silent then
                guilibrary:playsound(Bool and toggleOnSound or toggleOffSound, 0.8)
                showToggleNotification(ToggleTable.Name, Bool)
            end
            return true
        end

        function ToggleTable:Toggle(Silent, Bool)
            local target = Bool == nil and not ToggleTable.Enabled or Bool == true
            if ToggleTable.Enabled == target then return end
            ToggleTable.Enabled = target
            ToggleTable.Value = target
            label.Root:SetAttribute("NightixEnabled", target)
            label.Root.BackgroundColor3 = target and NeverLose.ThemeColors.Active or NeverLose.ThemeColors.Background
            toggleLib:SetValue(target)
            if ToggleTable.Callback then
                ToggleTable.Callback(target)
            end
            if target then
                reapplyModuleOptions()
            end
            guilibrary:playsound(target and toggleOnSound or toggleOffSound, 0.8)
            if not Silent then
                showToggleNotification(ToggleTable.Name, target)
            end
        end

        function ToggleTable:ReToggle(Silent)
            -- Restart an enabled module so option changes are applied without
            -- accidentally leaving the module disabled.
            if not ToggleTable.Enabled then
                ToggleTable:SetEnabled(true, Silent == true)
                return
            end

            ToggleTable:SetEnabled(false, true)
            ToggleTable:SetEnabled(true, true)
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

        -- Click the function itself to toggle. RMB opens its inline options;
        -- MMB opens the compact bind dialog.
        local rowHit = Instance.new("ImageButton")
        rowHit.Name = "FunctionHitbox"
        rowHit.Parent = label.Root
        rowHit.Position = UDim2.fromOffset(0, 0)
        rowHit.Size = UDim2.new(1, -34, 1, 0)
        rowHit.BackgroundTransparency = 1
        rowHit.BorderSizePixel = 0
        rowHit.ImageTransparency = 1
        rowHit.ZIndex = label.Root.ZIndex + 11

        rowHit.MouseButton1Click:Connect(function() ToggleTable:Toggle(false) end)
        rowHit.MouseButton2Click:Connect(function() optionWindow.Signal:SetValue(not optionWindow.Signal:GetValue()) end)

        local function openBindPopup()
            local existing = NeverLose.ScreenGui:FindFirstChild("BindPopup_" .. toggleName)
            if existing then existing:Destroy(); return end
            local popup = Instance.new("Frame", NeverLose.ScreenGui)
            popup.Name = "BindPopup_" .. toggleName
            popup.Position = UDim2.fromOffset(label.Root.AbsolutePosition.X + label.Root.AbsoluteSize.X - 190, label.Root.AbsolutePosition.Y + label.Root.AbsoluteSize.Y + 4)
            popup.Size = UDim2.fromOffset(180, 96)
            popup.BackgroundColor3 = NeverLose.ThemeColors.Background
            popup.BorderSizePixel = 0
            popup.ZIndex = 600
            local pc=Instance.new("UICorner",popup); pc.CornerRadius=UDim.new(0,6)
            local ps=Instance.new("UIStroke",popup); ps.Color=NeverLose.ThemeColors.Outline; ps.Transparency=0.1
            local field=Instance.new("TextButton",popup)
            field.Position=UDim2.fromOffset(8,8); field.Size=UDim2.new(1,-40,0,26); field.BackgroundColor3=NeverLose.ThemeColors.Active; field.BorderSizePixel=0; field.Text=NeverLose:KeyCodeToStr(ToggleTable.Keybind); field.TextColor3=NeverLose.ThemeColors.Text; field.TextSize=12; field.ZIndex=601
            local fc=Instance.new("UICorner",field); fc.CornerRadius=UDim.new(0,4)
            local del=Instance.new("TextButton",popup); del.Position=UDim2.new(1,-29,0,8); del.Size=UDim2.fromOffset(21,26); del.BackgroundTransparency=1; del.Text="×"; del.TextColor3=NeverLose.ThemeColors.Text; del.TextSize=16; del.ZIndex=601
            local hold=Instance.new("TextButton",popup); hold.Position=UDim2.fromOffset(8,42); hold.Size=UDim2.fromOffset(78,24); hold.BackgroundColor3=NeverLose.ThemeColors.Active; hold.BorderSizePixel=0; hold.Text="Hold"; hold.TextColor3=NeverLose.ThemeColors.Text; hold.TextSize=11; hold.ZIndex=601
            local toggle=Instance.new("TextButton",popup); toggle.Position=UDim2.fromOffset(94,42); toggle.Size=UDim2.fromOffset(78,24); toggle.BackgroundColor3=NeverLose.ThemeColors.Active; toggle.BorderSizePixel=0; toggle.Text="Toggle"; toggle.TextColor3=NeverLose.ThemeColors.Text; toggle.TextSize=11; toggle.ZIndex=601
            local hint=Instance.new("TextLabel",popup); hint.Position=UDim2.fromOffset(8,70); hint.Size=UDim2.new(1,-16,0,18); hint.BackgroundTransparency=1; hint.Text="Средняя кнопка мыши — бинды"; hint.TextColor3=Color3.fromRGB(175,175,190); hint.TextSize=9; hint.ZIndex=601
            local binding=false; local bindConn
            local function stopBind() if bindConn then bindConn:Disconnect(); bindConn=nil end; binding=false end
            field.MouseButton1Click:Connect(function()
                if binding then return end
                binding=true; field.Text="Нажмите клавишу..."
                bindConn=userInputService.InputBegan:Connect(function(input)
                    local value=nil
                    if input.KeyCode ~= Enum.KeyCode.Unknown then value=input.KeyCode.Name
                    elseif input.UserInputType==Enum.UserInputType.MouseButton1 then value="M1B"
                    elseif input.UserInputType==Enum.UserInputType.MouseButton2 then value="M2B"
                    elseif input.UserInputType==Enum.UserInputType.MouseButton3 then value="M3B" end
                    if value then ToggleTable:UpdateKeybind(false,value); field.Text=value; stopBind() end
                end)
            end)
            del.MouseButton1Click:Connect(function() stopBind(); ToggleTable:UpdateKeybind(true); field.Text="None" end)
            hold.MouseButton1Click:Connect(function() bindMode="Hold" end)
            toggle.MouseButton1Click:Connect(function() bindMode="Toggle" end)
        end
        local middle=Instance.new("ImageButton")
        middle.Parent=label.Root; middle.Position=UDim2.new(1,-34,0,0); middle.Size=UDim2.fromOffset(34, label.Root.AbsoluteSize.Y); middle.BackgroundTransparency=1; middle.ImageTransparency=1; middle.ZIndex=label.Root.ZIndex+12
        middle.MouseButton3Click:Connect(openBindPopup)

        table.insert(connections, userInputService.InputBegan:Connect(function(input, gameProcessed)
            if gameProcessed then return end

            local keybind = ToggleTable.Keybind
            local pressed = input.KeyCode ~= Enum.KeyCode.Unknown and input.KeyCode.Name == keybind
                or (keybind == "M1B" or keybind == "MouseButton1") and input.UserInputType == Enum.UserInputType.MouseButton1
                or (keybind == "M2B" or keybind == "MouseButton2") and input.UserInputType == Enum.UserInputType.MouseButton2
                or (keybind == "M3B" or keybind == "MouseButton3") and input.UserInputType == Enum.UserInputType.MouseButton3

            if pressed then
                if bindMode == "Hold" then
                    ToggleTable:SetEnabled(true, true)
                else
                    ToggleTable:Toggle(false)
                end
            end
        end))

        table.insert(connections, userInputService.InputEnded:Connect(function(input)
            if bindMode ~= "Hold" then return end
            local keybind = ToggleTable.Keybind
            local released = input.KeyCode ~= Enum.KeyCode.Unknown and input.KeyCode.Name == keybind
                or (keybind == "M1B") and input.UserInputType == Enum.UserInputType.MouseButton1
                or (keybind == "M2B") and input.UserInputType == Enum.UserInputType.MouseButton2
                or (keybind == "M3B") and input.UserInputType == Enum.UserInputType.MouseButton3
            if released then ToggleTable:SetEnabled(false, true) end
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
            Visuals = "paint-brush",
            Utility = "rbxassetid://89294237251926",
            Settings = "gear",
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
                -- Settings -> Icon is a full function so its controls are opened from the gear.
                if tabname == "Settings" and tostring(argstable.Name or "") == "Icon" then
                    return createModuleToggle(tabname, argstable)
                end
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

        function tabtable:CreateConfigManager(argstable)
            argstable = argstable or {}
            local section = getSection(tabname)
            local manager = {}
            local selected = nil
            local rows = {}
            local renameBox

            local title = section:AddLabel(tostring(argstable.Name or "Configs"))
            title:ToolTip("Click a config to select it. Use Rename or Remove for the selected config.")

            local nameInput = title:AddTextInput({
                Default = "",
                Placeholder = "Config name",
                Numeric = false,
                Size = 120,
                Callback = function() end,
            })

            local function notify(text)
                local notification = NeverLose:CreateNotification()
                notification.new({Title = "Default", Content = tostring(text), Duration = 2.5})
            end

            local function clearRows()
                for _, row in ipairs(rows) do
                    if row.root then
                        pcall(function() row.glow:Render(false) end)
                        row.root:Destroy()
                    end
                end
                table.clear(rows)
            end

            local function selectRow(row)
                selected = row.name
                guilibrary.CurrentConfig = row.name
                for _, item in ipairs(rows) do
                    local active = item == row
                    if item.stroke then
                        item.stroke.Color = Color3.fromRGB(255,255,255)
                        item.stroke.Thickness = active and 2 or 1
                        item.stroke.Transparency = active and 0 or 0.7
                    end
                    if item.glow then item.glow:Render(active) end
                    if item.label then
                        item.label.Text = (active and "●  " or "○  ") .. item.name
                    end
                end
            end

            local function createRenameBox(row)
                if renameBox then renameBox:Destroy(); renameBox = nil end
                local box = Instance.new("TextBox")
                renameBox = box
                box.Name = NeverLose.RandomString()
                box.Parent = row.root
                box.BackgroundColor3 = Color3.fromRGB(18,20,26)
                box.BackgroundTransparency = 0.05
                box.BorderSizePixel = 0
                box.Position = UDim2.fromOffset(8, 3)
                box.Size = UDim2.new(1, -16, 0, 24)
                box.ZIndex = 220
                box.ClearTextOnFocus = false
                box.Font = Enum.Font.GothamMedium
                box.TextSize = 12
                box.TextColor3 = Color3.fromRGB(255,255,255)
                box.TextXAlignment = Enum.TextXAlignment.Left
                box.Text = row.name
                box:CaptureFocus()
                box.FocusLost:Connect(function(enterPressed)
                    if renameBox ~= box then return end
                    renameBox = nil
                    if enterPressed then
                        local newName = tostring(box.Text or ""):gsub("^%s+", ""):gsub("%s+$", "")
                        if newName ~= "" then
                            local oldName = row.name
                            local ok, err = guilibrary:RenameConfig(oldName, newName)
                            if ok then
                                selected = newName
                                guilibrary.CurrentConfig = newName
                                box:Destroy()
                                manager:Refresh()
                                notify("Renamed to " .. newName)
                                return
                            end
                            notify("Rename failed: " .. tostring(err))
                        end
                    end
                    box:Destroy()
                end)
            end

            function manager:Refresh()
                clearRows()
                local configs = guilibrary:ListConfigs()
                local exists = false
                for _, configName in ipairs(configs) do
                    if selected == configName then exists = true break end
                end
                if selected and not exists then
                    selected = nil
                end
                if guilibrary.CurrentConfig and not table.find(configs, guilibrary.CurrentConfig) then
                    guilibrary.CurrentConfig = nil
                end
                for _, configName in ipairs(configs) do
                    local row = section:AddLabel(configName)
                    local root = row.Root
                    local stroke = Instance.new("UIStroke")
                    stroke.Color = Color3.fromRGB(255,255,255)
                    stroke.Thickness = 1
                    stroke.Transparency = 0.7
                    stroke.Parent = root
                    local glow = NeverLose:CreateShadow(root, true, 0.75)
                    local entry = {name=configName, root=root, label=nil, stroke=stroke, glow=glow}
                    -- AddLabel does not expose its internal TextLabel, so use the first TextLabel child.
                    entry.label = root:FindFirstChildOfClass("TextLabel")
                    table.insert(rows, entry)
                    NeverLose:CreateInput(root, function()
                        -- Selecting a config never loads it. Loading is explicit via the Load button.
                        selectRow(entry)
                    end)
                    if selected == configName then selectRow(entry) end
                end
            end

            section:AddButton({
                Name = "Add",
                Icon = "circle-plus",
                Callback = function()
                    local name = tostring(nameInput:GetValue() or ""):gsub("^%s+", ""):gsub("%s+$", "")
                    if name == "" then notify("Enter a config name"); return end
                    local ok, err = guilibrary:CreateConfig(name)
                    if ok then
                        selected = name
                        nameInput:SetValue("")
                        manager:Refresh()
                        notify("Created " .. name)
                    else
                        notify("Create failed: " .. tostring(err))
                    end
                end,
            })

            section:AddButton({
                Name = "Load",
                Icon = "download",
                Callback = function()
                    if not selected then notify("Select a config first"); return end
                    local target = selected
                    local ok, err = guilibrary:LoadConfig(target)
                    if ok then
                        guilibrary.CurrentConfig = target
                        notify("Loaded " .. target)
                        manager:Refresh()
                    else
                        -- Never leave a ghost current config after a failed load.
                        if not guilibrary:ListConfigs()[1] then
                            guilibrary.CurrentConfig = nil
                        end
                        notify("Load failed: " .. tostring(err))
                    end
                end,
            })

            section:AddButton({
                Name = "Save",
                Icon = "floppy-disk",
                Callback = function()
                    local target = selected or guilibrary.CurrentConfig
                    if not target then notify("Select a config first"); return end
                    local ok, err = guilibrary:SaveConfig(target)
                    notify(ok and ("Saved " .. target) or ("Save failed: " .. tostring(err)))
                end,
            })

            section:AddButton({
                Name = "Remove",
                Icon = "trash-can",
                Callback = function()
                    if not selected then notify("Select a config first"); return end
                    local name = selected
                    local ok, err = guilibrary:DeleteConfig(name)
                    if ok then
                        selected = nil
                        if guilibrary.CurrentConfig == name then
                            guilibrary.CurrentConfig = nil
                        end
                        manager:Refresh()
                        notify("Removed " .. name)
                    else
                        notify("Remove failed: " .. tostring(err))
                    end
                end,
            })

            section:AddButton({
                Name = "Rename",
                Icon = "pencil",
                Callback = function()
                    if not selected then notify("Select a config first"); return end
                    for _, row in ipairs(rows) do
                        if row.name == selected then
                            createRenameBox(row)
                            return
                        end
                    end
                end,
            })

            manager:Refresh()
            return manager
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
            local camera = workspace.CurrentCamera
            local cameraDistance = 10
            pcall(function()
                cameraDistance = (camera.CFrame.Position - camera.Focus.Position).Magnitude
            end)
            menuWasFirstPerson = (previousCameraMode == Enum.CameraMode.LockFirstPerson) or cameraDistance <= 0.75

            -- Only force the camera out of first person. If the player already
            -- is in third person, opening the menu must not zoom them in.
            if menuWasFirstPerson then
                localPlayer.CameraMode = Enum.CameraMode.Classic
                localPlayer.CameraMinZoomDistance = 1.5
                localPlayer.CameraMaxZoomDistance = 1.5
            end

            userInputService.MouseBehavior = Enum.MouseBehavior.Default
            userInputService.MouseIconEnabled = true
            menuInputConnection = runService.RenderStepped:Connect(function()
                if guilibrary.Toggled then
                    if menuWasFirstPerson then
                        localPlayer.CameraMode = Enum.CameraMode.Classic
                        localPlayer.CameraMinZoomDistance = 1.5
                        localPlayer.CameraMaxZoomDistance = 1.5
                    end
                    userInputService.MouseBehavior = Enum.MouseBehavior.Default
                    userInputService.MouseIconEnabled = true
                end
            end)
            menuScale = scaleSize(menuScaleValue)
            window:SetSize(menuScale)
        else
            for _, optionWindow in ipairs(optionWindows) do
                if optionWindow.Signal then
                    optionWindow.Signal:SetValue(false)
                end
            end
            for _, popup in ipairs(NeverLose.ScreenGui:GetChildren()) do
                if popup:IsA("Frame") and popup.ZIndex >= 125 then
                    popup.BackgroundTransparency = 1
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
            menuWasFirstPerson = false
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

    -- ------------------------------------------------------------------
    -- Interface/HUD helpers. These are additive; the original NeverLose
    -- window, tabs and module API remain untouched.
    -- ------------------------------------------------------------------
    local Lighting = game:GetService("Lighting")
    NeverLose.InterfaceSettings = NeverLose.InterfaceSettings or {
        HUD = false, Blur = false, BlurStrength = 12,
        BackgroundColor = Color3.fromRGB(30,30,52)
    }
    local interfaceBlur

    local function ensureInterfaceBlur()
        if not interfaceBlur then
            interfaceBlur = Instance.new("BlurEffect")
            interfaceBlur.Name = "DefaultInterfaceBlur"
            interfaceBlur.Enabled = false
            interfaceBlur.Parent = Lighting
        end
        return interfaceBlur
    end

    function NeverLose:SetBlurStrength(v)
        local n = math.clamp(tonumber(v) or 12, 0, 56)
        NeverLose.InterfaceSettings.BlurStrength = n
        if interfaceBlur then interfaceBlur.Size = n end
    end

    function NeverLose:SetBlurEnabled(v)
        NeverLose.InterfaceSettings.Blur = v == true
        local b = ensureInterfaceBlur()
        b.Size = tonumber(NeverLose.InterfaceSettings.BlurStrength) or 12
        b.Enabled = NeverLose.InterfaceSettings.Blur == true
    end

    function NeverLose:SetHUDBackgroundColor(v)
        if typeof(v) ~= "Color3" then return end
        NeverLose.InterfaceSettings.BackgroundColor = v
        local wm = NeverLose.__WatermarkCache
        if wm and wm.Root then wm.Root.BackgroundColor3 = v end
    end

    function NeverLose:SetHUDEnabled(v)
        NeverLose.InterfaceSettings.HUD = v == true
        local wm = NeverLose.__WatermarkCache
        if wm and wm.SetRender then wm:SetRender(v == true) end
    end

    function NeverLose:SetInterfaceEnabled(v)
        NeverLose.InterfaceSettings.InterfaceOpen = v == true
    end

    local function makePopup(name, position, size)
        local f = Instance.new("Frame")
        f.Name = name
        f.Parent = NeverLose.ScreenGui
        f.Position = position
        f.Size = size
        f.BackgroundColor3 = NeverLose.ThemeColors.Background
        f.BackgroundTransparency = 0.04
        f.BorderSizePixel = 0
        f.ZIndex = 500
        f.Visible = false
        local c = Instance.new("UICorner", f)
        c.CornerRadius = UDim.new(0, 7)
        local st = Instance.new("UIStroke", f)
        st.Color = NeverLose.ThemeColors.Outline
        st.Transparency = 0.1
        return f
    end

    local themePopup = makePopup("DefaultThemeEditor", UDim2.fromOffset(18, 100), UDim2.fromOffset(260, 330))
    local configPopup = makePopup("DefaultConfigEditor", UDim2.new(1,-300,1,-360), UDim2.fromOffset(280,330))
    NeverLose.ThemePopup = themePopup
    NeverLose.ConfigPopup = configPopup

    local function addPopupTitle(parent, text)
        local t = Instance.new("TextLabel", parent)
        t.BackgroundTransparency = 1
        t.Position = UDim2.fromOffset(14, 10)
        t.Size = UDim2.new(1,-28,0,22)
        t.Font = Enum.Font.GothamBold
        t.TextSize = 16
        t.TextColor3 = NeverLose.ThemeColors.Text
        t.TextXAlignment = Enum.TextXAlignment.Left
        t.Text = text
        t.ZIndex = 501
        return t
    end
    addPopupTitle(themePopup, "Редактор тем")
    addPopupTitle(configPopup, "Редактор конфигов")

    -- Theme editor: one default swatch at first; each created theme adds one.
    local themeNameBox = Instance.new("TextBox", themePopup)
    themeNameBox.Position = UDim2.fromOffset(14,42)
    themeNameBox.Size = UDim2.new(1,-94,0,28)
    themeNameBox.BackgroundColor3 = NeverLose.ThemeColors.Background
    themeNameBox.BorderSizePixel = 0
    themeNameBox.TextColor3 = NeverLose.ThemeColors.Text
    themeNameBox.PlaceholderText = "Название темы"
    themeNameBox.Text = "Default"
    themeNameBox.ClearTextOnFocus = false
    themeNameBox.Font = Enum.Font.Gotham
    themeNameBox.TextSize = 12
    themeNameBox.ZIndex = 501
    local themeCreate = Instance.new("TextButton", themePopup)
    themeCreate.Position = UDim2.new(1,-78,0,42)
    themeCreate.Size = UDim2.fromOffset(64,28)
    themeCreate.BackgroundColor3 = NeverLose.ThemeColors.Active
    themeCreate.BorderSizePixel = 0
    themeCreate.TextColor3 = NeverLose.ThemeColors.Text
    themeCreate.Text = "Создать"
    themeCreate.Font = Enum.Font.GothamMedium
    themeCreate.TextSize = 11
    themeCreate.ZIndex = 501
    local tc=Instance.new("UICorner",themeCreate); tc.CornerRadius=UDim.new(0,5)

    local themeList = Instance.new("Frame", themePopup)
    themeList.Position = UDim2.fromOffset(14,84)
    themeList.Size = UDim2.new(1,-28,0,42)
    themeList.BackgroundTransparency = 1
    themeList.ZIndex = 501
    local themeLayout=Instance.new("UIListLayout",themeList)
    themeLayout.FillDirection=Enum.FillDirection.Horizontal
    themeLayout.Padding=UDim.new(0,8)
    themeLayout.VerticalAlignment=Enum.VerticalAlignment.Center

    local themes={
        Default={Background=Color3.fromRGB(30,30,52),Active=Color3.fromRGB(41,35,67),Outline=Color3.fromRGB(45,38,72),Accent=Color3.fromRGB(197,132,211),AccentDark=Color3.fromRGB(95,63,121),Text=Color3.fromRGB(255,255,255)}
    }
    local currentTheme="Default"
    local syncThemeEditors
    local function applyTheme(theme)
        NeverLose.ThemeColors=theme
        NeverLose.MainColor=theme.Background
        for _,o in ipairs(NeverLose.ScreenGui:GetDescendants()) do
            if o:IsA("Frame") and o:GetAttribute("NightixOptionRow") then
                local enabled=o:GetAttribute("NightixEnabled") == true
                o.BackgroundColor3=enabled and theme.Active or theme.Background
                o.BackgroundTransparency=0
            elseif o:IsA("TextLabel") and o:GetAttribute("NightixOptionLabel") then
                o.TextColor3=theme.Text
            elseif o:IsA("UIStroke") and o:GetAttribute("NightixThemeStroke") then
                o.Color=theme.Outline
            end
        end
        local wm=NeverLose.__WatermarkCache
        if wm and wm.Root then wm.Root.BackgroundColor3=theme.Background:Lerp(Color3.new(0,0,0),0.18) end
        if NeverLose.RefreshNightixTheme then pcall(function() NeverLose:RefreshNightixTheme() end) end
    end
    local function addThemeChip(themeName, theme)
        local b=Instance.new("TextButton",themeList)
        b.Name="Theme_"..themeName
        b.Size=UDim2.fromOffset(34,34)
        b.Text=""
        b.BackgroundColor3=theme.Accent
        b.BorderSizePixel=0
        b.ZIndex=502
        local c=Instance.new("UICorner",b); c.CornerRadius=UDim.new(1,0)
        b.MouseButton1Click:Connect(function() currentTheme=themeName; applyTheme(theme); syncThemeEditors() end)
    end
    addThemeChip("Default",themes.Default)

    local function addThemeColorEditor(y, title, key)
        local label=Instance.new("TextLabel",themePopup)
        label.Position=UDim2.fromOffset(14,y); label.Size=UDim2.new(1,-110,0,24); label.BackgroundTransparency=1
        label.Text=title; label.TextColor3=NeverLose.ThemeColors.Text; label.Font=Enum.Font.GothamMedium; label.TextSize=11; label.TextXAlignment=Enum.TextXAlignment.Left; label.ZIndex=501
        local box=Instance.new("TextBox",themePopup)
        box.Position=UDim2.new(1,-94,0,y); box.Size=UDim2.fromOffset(80,24); box.BackgroundColor3=NeverLose.ThemeColors.Active; box.BorderSizePixel=0; box.TextColor3=NeverLose.ThemeColors.Text; box.TextSize=10; box.Font=Enum.Font.Gotham; box.ClearTextOnFocus=false; box.ZIndex=501
        local c=Instance.new("UICorner",box); c.CornerRadius=UDim.new(0,4)
        local function sync()
            local t=themes[currentTheme] or themes.Default
            local v=t[key]
            local r=math.floor(v.R*255+0.5); local g=math.floor(v.G*255+0.5); local b=math.floor(v.B*255+0.5)
            box.Text=string.format("%d,%d,%d",r,g,b)
        end
        box.FocusLost:Connect(function()
            local r,g,b=tostring(box.Text):match("^(%d+)%s*,%s*(%d+)%s*,%s*(%d+)$")
            r,g,b=tonumber(r),tonumber(g),tonumber(b)
            if r and g and b and r<=255 and g<=255 and b<=255 then
                themes[currentTheme][key]=Color3.fromRGB(r,g,b); applyTheme(themes[currentTheme])
            end
            sync()
        end)
        return sync
    end
    local syncBg=addThemeColorEditor(136,"Фон", "Background")
    local syncActive=addThemeColorEditor(166,"Активные функции", "Active")
    local syncOutline=addThemeColorEditor(196,"Обводка", "Outline")
    local syncAccent=addThemeColorEditor(226,"Визуальные функции", "Accent")
    local syncDark=addThemeColorEditor(256,"Тёмный оттенок", "AccentDark")
    syncThemeEditors=function() syncBg(); syncActive(); syncOutline(); syncAccent(); syncDark() end
    syncThemeEditors()

    themeCreate.MouseButton1Click:Connect(function()
        local n=tostring(themeNameBox.Text or ""):gsub("^%s+",""):gsub("%s+$","")
        if n=="" or themes[n] then return end
        themes[n]={Background=Color3.fromRGB(30,30,52),Active=Color3.fromRGB(41,35,67),Outline=Color3.fromRGB(45,38,72),Accent=Color3.fromRGB(197,132,211),AccentDark=Color3.fromRGB(95,63,121),Text=Color3.fromRGB(255,255,255)}
        addThemeChip(n,themes[n])
        currentTheme=n
        applyTheme(themes[n])
        syncThemeEditors()
    end)

    -- Config editor: name + Create, cards with author/date/check and RMB menu.
    local cfgInput=Instance.new("TextBox",configPopup)
    cfgInput.Position=UDim2.fromOffset(14,42); cfgInput.Size=UDim2.new(1,-94,0,28)
    cfgInput.BackgroundColor3=NeverLose.ThemeColors.Background; cfgInput.BorderSizePixel=0
    cfgInput.TextColor3=NeverLose.ThemeColors.Text; cfgInput.PlaceholderText="Название"; cfgInput.ClearTextOnFocus=false; cfgInput.ZIndex=501
    local cfgCreate=Instance.new("TextButton",configPopup)
    cfgCreate.Position=UDim2.new(1,-78,0,42); cfgCreate.Size=UDim2.fromOffset(64,28); cfgCreate.BackgroundColor3=NeverLose.ThemeColors.Active; cfgCreate.BorderSizePixel=0; cfgCreate.TextColor3=NeverLose.ThemeColors.Text; cfgCreate.Text="Создать"; cfgCreate.ZIndex=501
    local cc=Instance.new("UICorner",cfgCreate); cc.CornerRadius=UDim.new(0,5)
    local cfgList=Instance.new("ScrollingFrame",configPopup)
    cfgList.Position=UDim2.fromOffset(14,80); cfgList.Size=UDim2.new(1,-28,1,-94); cfgList.BackgroundTransparency=1; cfgList.BorderSizePixel=0; cfgList.ScrollBarThickness=2; cfgList.ZIndex=501
    local cfgLayout=Instance.new("UIListLayout",cfgList); cfgLayout.Padding=UDim.new(0,6)

    local function refreshConfigEditor()
        for _,c in ipairs(cfgList:GetChildren()) do if c:IsA("Frame") then c:Destroy() end end
        for _,n in ipairs(guilibrary:ListConfigs()) do
            local row=Instance.new("Frame",cfgList); row.Size=UDim2.new(1,-4,0,62); row.BackgroundColor3=NeverLose.ThemeColors.Active; row.BorderSizePixel=0; row.ZIndex=502
            local rc=Instance.new("UICorner",row); rc.CornerRadius=UDim.new(0,5)
            local title=Instance.new("TextLabel",row); title.BackgroundTransparency=1; title.Position=UDim2.fromOffset(10,6); title.Size=UDim2.new(1,-42,0,17); title.Text=n; title.TextColor3=NeverLose.ThemeColors.Text; title.Font=Enum.Font.GothamMedium; title.TextSize=12; title.TextXAlignment=Enum.TextXAlignment.Left; title.ZIndex=503
            local author="Default"; local created=os.date("%d.%m.%Y %H:%M")
            pcall(function()
                local raw=readfile("Nightix/Configs/"..n..".json")
                local data=httpService:JSONDecode(raw)
                author=tostring(data.Author or "Default")
                created=tostring(data.CreatedAtText or created)
            end)
            local meta=Instance.new("TextLabel",row); meta.BackgroundTransparency=1; meta.Position=UDim2.fromOffset(10,25); meta.Size=UDim2.new(1,-42,0,14); meta.Text="от "..author.."  •  "..created; meta.TextColor3=Color3.fromRGB(190,190,205); meta.Font=Enum.Font.Gotham; meta.TextSize=10; meta.TextXAlignment=Enum.TextXAlignment.Left; meta.ZIndex=503
            local ok=Instance.new("TextLabel",row); ok.BackgroundTransparency=1; ok.Position=UDim2.new(1,-30,0,8); ok.Size=UDim2.fromOffset(20,20); ok.Text="✓"; ok.TextColor3=NeverLose.ThemeColors.Accent; ok.TextSize=16; ok.ZIndex=503
            local hit=Instance.new("ImageButton",row); hit.Size=UDim2.fromScale(1,1); hit.BackgroundTransparency=1; hit.ImageTransparency=1; hit.ZIndex=504
            hit.MouseButton2Click:Connect(function()
                local menu=Instance.new("Frame",NeverLose.ScreenGui); menu.Position=UDim2.fromOffset(row.AbsolutePosition.X,row.AbsolutePosition.Y-50); menu.Size=UDim2.fromOffset(150,44); menu.BackgroundColor3=NeverLose.ThemeColors.Background; menu.BorderSizePixel=0; menu.ZIndex=700
                local mc=Instance.new("UICorner",menu); mc.CornerRadius=UDim.new(0,5)
                local load=Instance.new("TextButton",menu); load.Size=UDim2.new(.5,0,1,0); load.BackgroundTransparency=1; load.Text="Загрузить"; load.TextColor3=NeverLose.ThemeColors.Text; load.ZIndex=701
                local del=Instance.new("TextButton",menu); del.Position=UDim2.new(.5,0,0,0); del.Size=UDim2.new(.5,0,1,0); del.BackgroundTransparency=1; del.Text="Удалить"; del.TextColor3=NeverLose.ThemeColors.Text; del.ZIndex=701
                load.MouseButton1Click:Connect(function() guilibrary:LoadConfig(n); menu:Destroy() end)
                del.MouseButton1Click:Connect(function() guilibrary:DeleteConfig(n); menu:Destroy(); refreshConfigEditor() end)
            end)
        end
    end
    cfgCreate.MouseButton1Click:Connect(function()
        local n=tostring(cfgInput.Text or ""):gsub("^%s+",""):gsub("%s+$","")
        if n~="" then guilibrary:CreateConfig(n); cfgInput.Text=""; refreshConfigEditor() end
    end)
    refreshConfigEditor()

    function NeverLose:OpenThemeEditor() themePopup.Visible=true; configPopup.Visible=false end
    function NeverLose:OpenConfigEditor() configPopup.Visible=true; themePopup.Visible=false; refreshConfigEditor() end
    function NeverLose:CloseInterfaceWindows() themePopup.Visible=false; configPopup.Visible=false end

    guilibrary.NightixMenu = {
        Version = 3,
        Window = window,
        NeverLose = NeverLose,
    }

    return guilibrary
end