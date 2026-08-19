--[[
    Nightix-style ClickGUI menu for ManaV2ForRoblox
    Ported from Nightix 1.21.11 Minecraft client (Menu.java)

    Layout:
    - Central window with 3 columns
    - Left: category icons (Combat, Movement, Render, Utility, World, Settings, Profiles, Friends)
    - Top bar: search box + theme dots + category name + result counter
    - Center: module list (toggles)
    - Right: settings panel for selected module
]]

return function(guilibrary, OptionFunctions, connections, userInputService, tweenService, textService, mouse, spawn)
    local ScreenGui = guilibrary.ScreenGui
    local ClickGui = guilibrary.ClickGui
    local searchGui = guilibrary.searchGui
    local guipallet = guilibrary.GuiPallet
    local guiObjects = guilibrary.GuiObjects
    local Tabs = {}
    local Categories = {} -- ordered list of categories
    local Modules = {} -- modules per category: Categories[catName].modules
    local selectedCategory = nil
    local selectedModule = nil
    local searchQuery = ""
    local searchActive = false
    local searchTypeTime = 0
    local scrollTarget = 0
    local scrollAnim = 0
    local maxScroll = 0
    local settingScrollTarget = 0
    local settingScrollAnim = 0
    local settingMaxScroll = 0
    local bindingModule = nil
    local draggingSlider = nil
    local activeBind = nil
    local activeString = nil
    local stringBuffer = ""
    local draggingColor = nil
    local draggingColorBar = 0
    local themeIndex = 0
    local selectedTheme = 1
    local globalAnim = 0
    local exit = false
    local lastMouseX = 0
    local lastMouseY = 0
    local S = 1 -- scale

    -- Themes (color palettes) - like Nightix theme dots
    local Themes = {
        { Name = "Default", Color1 = Color3.fromRGB(14, 14, 23), Color2 = Color3.fromRGB(47, 48, 64), Accent = Color3.fromRGB(52, 235, 58) },
        { Name = "Nightix", Color1 = Color3.fromRGB(10, 10, 18), Color2 = Color3.fromRGB(30, 30, 45), Accent = Color3.fromRGB(120, 90, 255) },
        { Name = "Red", Color1 = Color3.fromRGB(20, 10, 10), Color2 = Color3.fromRGB(50, 25, 25), Accent = Color3.fromRGB(255, 60, 60) },
        { Name = "Blue", Color1 = Color3.fromRGB(10, 12, 22), Color2 = Color3.fromRGB(25, 35, 60), Accent = Color3.fromRGB(60, 150, 255) },
        { Name = "Green", Color1 = Color3.fromRGB(10, 20, 12), Color2 = Color3.fromRGB(25, 50, 30), Accent = Color3.fromRGB(60, 255, 120) },
    }

    -- Animation helper (smooth value toward target)
    local smoothVals = {}
    local function smooth(key, target, speed)
        local v = smoothVals[key]
        if not v then v = { target }; smoothVals[key] = v end
        v[1] = v[1] + (target - v[1]) * (speed or 0.2)
        return v[1]
    end

    -- Module visibility animations
    local moduleAnims = {}
    local function moduleAnim(key, visible)
        local a = moduleAnims[key]
        if not a then a = { 0 }; moduleAnims[key] = a end
        local target = visible and 1 or 0
        a[1] = a[1] + (target - a[1]) * 0.2
        return a[1]
    end

    -- Hover animations
    local hoverAnims = {}
    local function hoverAnim(key, hovered)
        local a = hoverAnims[key]
        if not a then a = { 0 }; hoverAnims[key] = a end
        local target = hovered and 1 or 0
        a[1] = a[1] + (target - a[1]) * 0.25
        return a[1]
    end

    -- Enable animations
    local enableAnims = {}
    local function enableAnim(key, enabled)
        local a = enableAnims[key]
        if not a then a = { 0 }; enableAnims[key] = a end
        local target = enabled and 1 or 0
        a[1] = a[1] + (target - a[1]) * 0.2
        return a[1]
    end

    -- Setting visibility animations
    local settingVisAnims = {}
    local function settingVisAnim(key, visible)
        local a = settingVisAnims[key]
        if not a then a = { 0 }; settingVisAnims[key] = a end
        local target = visible and 1 or 0
        a[1] = a[1] + (target - a[1]) * 0.2
        return a[1]
    end

    -- Chip animations (for dropdown/mode options)
    local chipAnims = {}
    local function chipAnim(key, selected)
        local a = chipAnims[key]
        if not a then a = { 0 }; chipAnims[key] = a end
        local target = selected and 1 or 0
        a[1] = a[1] + (target - a[1]) * 0.2
        return a[1]
    end

    -- Utility: is point inside rect
    local function isHovered(mx, my, x, y, w, h)
        return mx >= x and mx <= x + w and my >= y and my <= y + h
    end

    -- Utility: clamp
    local function clamp(v, min, max)
        return math.max(min, math.min(max, v))
    end

    -- Utility: round
    local function round(v, inc)
        return math.floor(v / inc + 0.5) * inc
    end

    -- Utility: get text width approximation
    local function textWidth(text, size)
        return #tostring(text) * size * 0.6
    end

    -- Search
    local function query()
        return searchQuery:lower():gsub("^%s+", ""):gsub("%s+$", "")
    end
    local function searching()
        return #query() > 0
    end

    local function moduleVisible(cat, mod)
        local q = query()
        if #q == 0 then return cat == selectedCategory end
        return mod.Name:lower():find(q, 1, true) ~= nil or (mod.Desc and mod.Desc:lower():find(q, 1, true) ~= nil)
    end

    local function searchResults()
        local count = 0
        for _, cat in ipairs(Categories) do
            for _, mod in ipairs(cat.modules) do
                if moduleVisible(cat, mod) then count = count + 1 end
            end
        end
        return count
    end

    local function searchChanged()
        searchTypeTime = os.clock()
        scrollTarget = 0
    end

    local function clearSearch()
        if #searchQuery == 0 then return end
        searchQuery = ""
        searchChanged()
    end

    -- Apply theme
    local function applyTheme(theme)
        guipallet.Color1 = theme.Color1
        guipallet.Color2 = theme.Color2
        guipallet.ToggleColor2 = theme.Accent
        guilibrary:updateObjects()
        -- Recolor Nightix logo to match theme accent
        if logoIcon then
            logoIcon.ImageColor3 = guipallet.ToggleColor2
        end
        if windowTabName then
            windowTabName.TextColor3 = guipallet.ToggleColor2
        end
    end

    -- ============ WINDOW CONSTRUCTION ============
    local window = Instance.new("Frame")
    window.Name = "Nightix"
    window.Parent = ClickGui
    window.BackgroundColor3 = guipallet.Color1
    window.BackgroundTransparency = 0.15
    window.BorderSizePixel = 0
    window.Position = UDim2.new(0.5, -210, 0.5, -140)
    window.Size = UDim2.new(0, 420, 0, 280)
    window.Visible = false
    window.ZIndex = 5

    local windowCorner = Instance.new("UICorner", window)
    windowCorner.CornerRadius = UDim.new(0, 8)
    table.insert(guiObjects.UICorners, windowCorner)

    -- tabName child for OptionFunctions compatibility (they look for tab:FindFirstChild("tabName"))
    local windowTabName = Instance.new("TextLabel", window)
    windowTabName.Name = "tabName"
    windowTabName.TextColor3 = guipallet.ToggleColor2
    windowTabName.Visible = false

    -- Nightix logo icon (texture id 80320370259758, originally blue)
    -- Recolored via ImageColor3 to match the selected theme accent
    local logoIcon = Instance.new("ImageLabel", window)
    logoIcon.Name = "NightixLogo"
    logoIcon.BackgroundTransparency = 1
    logoIcon.BorderSizePixel = 0
    logoIcon.Position = UDim2.new(0, 8, 0, 8)
    logoIcon.Size = UDim2.new(0, 20, 0, 20)
    logoIcon.Image = "rbxassetid://80320370259758"
    logoIcon.ImageColor3 = guipallet.ToggleColor2
    logoIcon.ScaleType = Enum.ScaleType.Fit
    logoIcon.ZIndex = 7

    -- Left category panel
    local catPanel = Instance.new("Frame", window)
    catPanel.Name = "CategoryPanel"
    catPanel.BackgroundColor3 = guipallet.Color2
    catPanel.BackgroundTransparency = 0.3
    catPanel.BorderSizePixel = 0
    catPanel.Position = UDim2.new(0, 6, 0, 6)
    catPanel.Size = UDim2.new(0, 30, 1, -12)
    catPanel.ZIndex = 6
    local catCorner = Instance.new("UICorner", catPanel)
    catCorner.CornerRadius = UDim.new(0, 6)
    table.insert(guiObjects.UICorners, catCorner)

    -- Top bar (search + theme + category name)
    local topBar = Instance.new("Frame", window)
    topBar.Name = "TopBar"
    topBar.BackgroundColor3 = guipallet.Color2
    topBar.BackgroundTransparency = 0.3
    topBar.BorderSizePixel = 0
    topBar.Position = UDim2.new(0, 42, 0, 6)
    topBar.Size = UDim2.new(1, -48, 0, 20)
    topBar.ZIndex = 6
    local topCorner = Instance.new("UICorner", topBar)
    topCorner.CornerRadius = UDim.new(0, 6)
    table.insert(guiObjects.UICorners, topCorner)

    -- Search box
    local searchBox = Instance.new("TextBox", topBar)
    searchBox.Name = "SearchBox"
    searchBox.BackgroundTransparency = 1
    searchBox.BorderSizePixel = 0
    searchBox.Position = UDim2.new(0, 6, 0, 2)
    searchBox.Size = UDim2.new(0, 130, 1, -4)
    searchBox.Font = guipallet.Font
    searchBox.PlaceholderText = "Search..."
    searchBox.PlaceholderColor3 = guipallet.PlaceholderColor2
    searchBox.Text = ""
    searchBox.TextColor3 = guipallet.TextColor
    searchBox.TextSize = 12
    searchBox.TextXAlignment = Enum.TextXAlignment.Left
    searchBox.ClearTextOnFocus = false
    searchBox.ZIndex = 7

    -- Theme dots
    local themeDots = Instance.new("Frame", topBar)
    themeDots.Name = "ThemeDots"
    themeDots.BackgroundTransparency = 1
    themeDots.BorderSizePixel = 0
    themeDots.Position = UDim2.new(0, 140, 0, 4)
    themeDots.Size = UDim2.new(0, 80, 0, 12)
    themeDots.ZIndex = 7

    local themeButtons = {}
    for i, theme in ipairs(Themes) do
        local dot = Instance.new("TextButton", themeDots)
        dot.Name = "Theme" .. i
        dot.BackgroundColor3 = theme.Accent
        dot.BorderSizePixel = 0
        dot.Position = UDim2.new(0, (i - 1) * 14, 0, 0)
        dot.Size = UDim2.new(0, 8, 0, 8)
        dot.Text = ""
        dot.AutoButtonColor = false
        dot.ZIndex = 8
        local dotCorner = Instance.new("UICorner", dot)
        dotCorner.CornerRadius = UDim.new(1, 0)
        table.insert(connections, dot.MouseButton1Click:Connect(function()
            selectedTheme = i
            applyTheme(theme)
        end))
        themeButtons[i] = dot
    end

    -- Category name label (top bar right)
    local catNameLabel = Instance.new("TextLabel", topBar)
    catNameLabel.Name = "CategoryName"
    catNameLabel.BackgroundTransparency = 1
    catNameLabel.BorderSizePixel = 0
    catNameLabel.Position = UDim2.new(0, 225, 0, 2)
    catNameLabel.Size = UDim2.new(0, 100, 1, -4)
    catNameLabel.Font = guipallet.Font
    catNameLabel.Text = ""
    catNameLabel.TextColor3 = guipallet.TextColor
    catNameLabel.TextSize = 12
    catNameLabel.TextXAlignment = Enum.TextXAlignment.Right
    catNameLabel.ZIndex = 7

    -- Result counter label
    local resultLabel = Instance.new("TextLabel", topBar)
    resultLabel.Name = "ResultCount"
    resultLabel.BackgroundTransparency = 1
    resultLabel.BorderSizePixel = 0
    resultLabel.Position = UDim2.new(0, 330, 0, 2)
    resultLabel.Size = UDim2.new(0, 40, 1, -4)
    resultLabel.Font = guipallet.Font
    resultLabel.Text = ""
    resultLabel.TextColor3 = guipallet.PlaceholderColor
    resultLabel.TextSize = 10
    resultLabel.TextXAlignment = Enum.TextXAlignment.Right
    resultLabel.ZIndex = 7

    -- Center module list panel
    local modulePanel = Instance.new("Frame", window)
    modulePanel.Name = "ModulePanel"
    modulePanel.BackgroundColor3 = guipallet.Color2
    modulePanel.BackgroundTransparency = 0.3
    modulePanel.BorderSizePixel = 0
    modulePanel.Position = UDim2.new(0, 42, 0, 32)
    modulePanel.Size = UDim2.new(0, 140, 1, -38)
    modulePanel.ZIndex = 6
    local modCorner = Instance.new("UICorner", modulePanel)
    modCorner.CornerRadius = UDim.new(0, 6)
    table.insert(guiObjects.UICorners, modCorner)

    -- Module list container (clipped)
    local moduleClip = Instance.new("Frame", modulePanel)
    moduleClip.Name = "ModuleClip"
    moduleClip.BackgroundTransparency = 1
    moduleClip.BorderSizePixel = 0
    moduleClip.Position = UDim2.new(0, 5, 0, 5)
    moduleClip.Size = UDim2.new(1, -10, 1, -10)
    moduleClip.ClipsDescendants = true
    moduleClip.ZIndex = 7

    -- Settings panel (right)
    local settingsPanel = Instance.new("Frame", window)
    settingsPanel.Name = "SettingsPanel"
    settingsPanel.BackgroundColor3 = guipallet.Color2
    settingsPanel.BackgroundTransparency = 0.3
    settingsPanel.BorderSizePixel = 0
    settingsPanel.Position = UDim2.new(0, 188, 0, 32)
    settingsPanel.Size = UDim2.new(1, -194, 1, -38)
    settingsPanel.ZIndex = 6
    local setCorner = Instance.new("UICorner", settingsPanel)
    setCorner.CornerRadius = UDim.new(0, 6)
    table.insert(guiObjects.UICorners, setCorner)

    -- Settings clip
    local settingsClip = Instance.new("Frame", settingsPanel)
    settingsClip.Name = "SettingsClip"
    settingsClip.BackgroundTransparency = 1
    settingsClip.BorderSizePixel = 0
    settingsClip.Position = UDim2.new(0, 5, 0, 5)
    settingsClip.Size = UDim2.new(1, -10, 1, -10)
    settingsClip.ClipsDescendants = true
    settingsClip.ZIndex = 7

    local settingsListLayout = Instance.new("UIListLayout", settingsClip)
    settingsListLayout.SortOrder = Enum.SortOrder.LayoutOrder
    settingsListLayout.Padding = UDim.new(0, 4)

    -- Empty state label
    local emptyLabel = Instance.new("TextLabel", moduleClip)
    emptyLabel.Name = "EmptyState"
    emptyLabel.BackgroundTransparency = 1
    emptyLabel.BorderSizePixel = 0
    emptyLabel.Position = UDim2.new(0, 0, 0, 60)
    emptyLabel.Size = UDim2.new(1, 0, 0, 20)
    emptyLabel.Font = guipallet.Font
    emptyLabel.Text = "Ничего не найдено"
    emptyLabel.TextColor3 = guipallet.PlaceholderColor
    emptyLabel.TextSize = 11
    emptyLabel.TextXAlignment = Enum.TextXAlignment.Center
    emptyLabel.Visible = false
    emptyLabel.ZIndex = 8

    -- "Select a module" placeholder in settings
    local selectPlaceholder = Instance.new("TextLabel", settingsClip)
    selectPlaceholder.Name = "SelectPlaceholder"
    selectPlaceholder.BackgroundTransparency = 1
    selectPlaceholder.BorderSizePixel = 0
    selectPlaceholder.Position = UDim2.new(0, 0, 0, 60)
    selectPlaceholder.Size = UDim2.new(1, 0, 0, 20)
    selectPlaceholder.Font = guipallet.Font
    selectPlaceholder.Text = "Выберите модуль"
    selectPlaceholder.TextColor3 = guipallet.PlaceholderColor
    selectPlaceholder.TextSize = 11
    selectPlaceholder.TextXAlignment = Enum.TextXAlignment.Center
    selectPlaceholder.ZIndex = 8

    -- ============ CATEGORY BUTTONS ============
    local catButtons = {}
    local function createCategoryButton(cat, index)
        local btn = Instance.new("TextButton", catPanel)
        btn.Name = "Cat_" .. cat.Name
        btn.BackgroundTransparency = 1
        btn.BorderSizePixel = 0
        btn.Position = UDim2.new(0, 3, 0, 3 + (index - 1) * 20)
        btn.Size = UDim2.new(0, 24, 0, 16)
        btn.Text = cat.Icon or string.sub(cat.Name, 1, 1)
        btn.TextColor3 = guipallet.TextColor
        btn.TextSize = 10
        btn.Font = guipallet.Font
        btn.AutoButtonColor = false
        btn.ZIndex = 8
        local btnCorner = Instance.new("UICorner", btn)
        btnCorner.CornerRadius = UDim.new(0, 4)
        table.insert(connections, btn.MouseButton1Click:Connect(function()
            clearSearch()
            selectedCategory = cat
            selectedModule = nil
            scrollTarget = 0
            settingScrollTarget = 0
        end))
        catButtons[cat] = btn
        return btn
    end

    -- ============ MODULE RENDERING ============
    -- Each module is a toggle. We render it in the center panel.
    -- The module's options (settings) render in the right panel when selected.

    -- We need to hook into CreateToggle to register modules.
    -- We'll wrap the tab's CreateToggle to register into Categories.

    -- ============ CREATE WINDOW / TAB / OPTIONS TAB ============
    local function CreateWindow()
        -- Window already constructed above
        guilibrary.TabsFrame = window
        guilibrary.SearchFrame = searchBox
        guilibrary.UIScale = Instance.new("UIScale", window)
        guilibrary.UIScale.Scale = guilibrary.Scale
        return guilibrary
    end

    local function CreateTab(argstable)
        local tabname = argstable.Name
        local color = argstable.Color or Color3.fromRGB(83, 214, 110)
        local tabicon = argstable.TabIcon

        local cat = {
            Name = tabname,
            Color = color,
            Icon = string.sub(tabname, 1, 1),
            modules = {},
            Toggles = {},
            isOptionsTab = false,
            Order = #Categories
        }
        table.insert(Categories, cat)
        if not selectedCategory then selectedCategory = cat end

        local btn = createCategoryButton(cat, #Categories)

        local tabtable = {
            Name = tabname,
            BaseColor = color,
            Pinned = false,
            ObjectsVisible = true,
            Position = UDim2.new(0, 40, 0, 40),
            Order = #Categories,
            Toggles = {}
        }

        -- CreateToggle registers a module
        function tabtable:CreateToggle(argstable)
            local name = argstable.Name or "Hello world!"
            local hoverText = argstable.HoverText or nil
            local keybind = argstable.Keybind or "none"
            local value = argstable.Default or argstable.DefaultValue or false
            local callback = argstable.Callback or argstable.Function or function() end

            if type(keybind) == "table" then
                keybind = keybind.Name or "none"
            end
            keybind = keybind or "none"

            local ToggleTable = {
                Name = name,
                Enabled = false,
                Keybind = keybind,
                Callback = callback,
                Desc = hoverText or "",
                Options = {}
            }

            -- Register module in category
            local mod = {
                Name = name,
                Desc = hoverText or "",
                ToggleTable = ToggleTable,
                Color = color,
                Keybind = keybind
            }
            table.insert(cat.modules, mod)
            table.insert(tabtable.Toggles, ToggleTable)

            -- Keybind handling
            local oldkey = keybind
            local isclicked = false
            local cooldown = false

            function ToggleTable:UpdateKeybind(remove, newKeybind)
                if remove then
                    oldkey = "none"
                    ToggleTable.Keybind = "none"
                    mod.Keybind = "none"
                else
                    oldkey = newKeybind or "none"
                    ToggleTable.Keybind = newKeybind or "none"
                    mod.Keybind = newKeybind or "none"
                end
            end

            local keybindConnection
            table.insert(connections, userInputService.InputBegan:Connect(function(input)
                if oldkey and oldkey ~= "none" and not cooldown and not isclicked and input.KeyCode.Name == oldkey and not userInputService:GetFocusedTextBox() then
                    ToggleTable:Toggle()
                end
            end))

            function ToggleTable:Toggle(silent, bool)
                bool = bool or (not ToggleTable.Enabled)
                if bool == ToggleTable.Enabled then return end
                silent = silent or false
                ToggleTable.Enabled = bool

                task.spawn(function()
                    if not silent then
                        guilibrary:playsound("rbxassetid://421058925", 1)
                    end
                end)

                task.spawn(function()
                    callback(bool)
                end)
            end

            function ToggleTable:ReToggle(silent)
                ToggleTable:Toggle(silent)
                ToggleTable:Toggle(silent)
            end

            -- Option creators (settings) - reuse OptionFunctions
            function ToggleTable:CreateDivider(DividerText)
                local Divider = Instance.new("TextLabel")
                Divider.Name = name .. "Divider"
                Divider.BackgroundTransparency = 1
                Divider.BorderSizePixel = 0
                Divider.Size = UDim2.new(1, 0, 0, 18)
                Divider.Font = guipallet.Font
                Divider.Text = DividerText
                Divider.TextColor3 = guipallet.TextColor
                Divider.TextSize = 12
                Divider.TextXAlignment = Enum.TextXAlignment.Center
                Divider.TextYAlignment = Enum.TextYAlignment.Center
                return Divider
            end

            function ToggleTable:CreateColorSlider(argstable)
                local name = argstable.Name
                local value = argstable.Default or argstable.DefaultValue or Color3.fromRGB(255, 255, 255)
                local rainbow = argstable.Rainbow or false
                local callback = argstable.Callback or argstable.Function or function() end
                return OptionFunctions:CreateColorSlider({
                    Name = name, Value = value, Rainbow = rainbow, Callback = callback,
                    Parent = settingsClip, Tab = window, ToggleName = ToggleTable.Name
                })
            end
            function ToggleTable:CreateSlider(argstable)
                local name = argstable.Name
                local value = argstable.Default or argstable.DefaultValue or argstable.Min
                local min = argstable.Min
                local max = argstable.Max
                local round = argstable.Round or 0
                local callback = argstable.Callback or argstable.Function or function() end
                return OptionFunctions:CreateSlider({
                    Name = name, Default = value, Min = min, Max = max, Round = round, Callback = callback,
                    Parent = settingsClip, Tab = window, ToggleName = ToggleTable.Name
                })
            end
            function ToggleTable:CreateDropdown(argstable)
                local name = argstable.Name
                local list = argstable.List or argstable.DefaultList or {}
                local value = argstable.Default or list[1] or nil
                local callback = argstable.Callback or argstable.Function or function() end
                return OptionFunctions:CreateDropdown({
                    Name = name, List = list, Default = value, Callback = callback,
                    Parent = settingsClip, Tab = window, ToggleName = ToggleTable.Name
                })
            end
            function ToggleTable:CreateToggle(argstable)
                local name = argstable.Name
                local value = argstable.Default or argstable.DefaultValue or false
                local callback = argstable.Callback or argstable.Function or function() end
                return OptionFunctions:CreateToggle({
                    Name = name, Default = value, Callback = callback,
                    Parent = settingsClip, Tab = window, ToggleName = ToggleTable.Name
                })
            end
            function ToggleTable:CreateButton(argstable)
                local name = argstable.Name
                local callback = argstable.Callback or argstable.Function or function() end
                return OptionFunctions:CreateButton({
                    Name = name, Callback = callback, Parent = settingsClip
                })
            end
            function ToggleTable:CreateTextBox(argstable)
                local name = argstable.Name
                local value = argstable.Default or argstable.DefaultValue or ""
                local PlaceholderText = argstable.PlaceholderText or "nil"
                local callback = argstable.Callback or argstable.Function or function() end
                return OptionFunctions:CreateTextBox({
                    Name = name, Default = value, PlaceholderText = PlaceholderText, Callback = callback,
                    Parent = settingsClip, Tab = window, ToggleName = ToggleTable.Name
                })
            end
            function ToggleTable:CreateTextList(argstable)
                local name = argstable.Name
                local list = argstable.List or argstable.DefaultList or {}
                local PlaceholderText = argstable.PlaceholderText or "enter something..."
                local callback = argstable.Callback or argstable.Function or function() end
                return OptionFunctions:CreateTextList({
                    Name = name, List = list, PlaceholderText = PlaceholderText, Callback = callback,
                    Parent = settingsClip, Tab = window, ToggleName = ToggleTable.Name
                })
            end

            guilibrary.ObjectsToSave.Toggles[name] = {
                Name = name,
                API = ToggleTable,
                Options = {}
            }
            return ToggleTable
        end

        -- Divider for tab (not used in Nightix layout, but keep API)
        function tabtable:CreateDivider(DividerText)
            local Divider = Instance.new("TextLabel")
            Divider.Name = tabname .. "_TextLabelDivider"
            Divider.BackgroundTransparency = 1
            Divider.BorderSizePixel = 0
            Divider.Size = UDim2.new(0, 180, 0, 18)
            Divider.Font = guipallet.Font
            Divider.Text = DividerText
            Divider.TextColor3 = guipallet.TextColor
            Divider.TextSize = 12
            Divider.TextXAlignment = Enum.TextXAlignment.Center
            Divider.TextYAlignment = Enum.TextYAlignment.Center
            return Divider
        end
        function tabtable:CreateSecondDivider(DividerText)
            return tabtable:CreateDivider(DividerText)
        end

        guilibrary.ObjectsToSave.Tabs[tabname] = {
            Name = tabname,
            Container = window,
            MainObject = window,
            API = tabtable,
            Type = "Tab"
        }
        return tabtable
    end

    local function CreateOptionsTab(argstable)
        local tabname = argstable.Name
        local color = argstable.Color or Color3.fromRGB(255, 255, 255)

        local cat = {
            Name = tabname,
            Color = color,
            Icon = string.sub(tabname, 1, 1),
            modules = {},
            Toggles = {},
            isOptionsTab = true,
            Order = #Categories
        }
        table.insert(Categories, cat)
        if not selectedCategory then selectedCategory = cat end

        local btn = createCategoryButton(cat, #Categories)

        local tabapi = {
            Name = tabname,
            BaseColor = color,
            Toggled = false,
            Position = UDim2.new(0, 40, 0, 40),
            Order = #Categories,
            Toggles = {}
        }

        -- For options tab, options render directly in settings panel when category selected
        function tabapi:CreateDivider(DividerText)
            local Divider = Instance.new("TextLabel")
            Divider.Name = tabname .. "_TextLabelDivider"
            Divider.BackgroundTransparency = 1
            Divider.BorderSizePixel = 0
            Divider.Size = UDim2.new(1, 0, 0, 18)
            Divider.Font = guipallet.Font
            Divider.Text = DividerText
            Divider.TextColor3 = guipallet.TextColor
            Divider.TextSize = 12
            Divider.TextXAlignment = Enum.TextXAlignment.Center
            Divider.TextYAlignment = Enum.TextYAlignment.Center
            return Divider
        end

        function tabapi:CreateColorSlider(argstable)
            local name = argstable.Name
            local value = argstable.Default or argstable.DefaultValue or Color3.fromRGB(255, 255, 255)
            local rainbow = argstable.Rainbow or false
            local callback = argstable.Callback or argstable.Function or function() end
            return OptionFunctions:CreateColorSlider({
                Name = name, Value = value, Rainbow = rainbow, Callback = callback,
                Parent = settingsClip, Tab = window, TabName = tabapi.Name
            })
        end
        function tabapi:CreateSlider(argstable)
            local name = argstable.Name
            local value = argstable.Default or argstable.DefaultValue or argstable.Min
            local min = argstable.Min
            local max = argstable.Max
            local round = argstable.Round or 0
            local callback = argstable.Callback or argstable.Function or function() end
            return OptionFunctions:CreateSlider({
                Name = name, Default = value, Min = min, Max = max, Round = round, Callback = callback,
                Parent = settingsClip, Tab = window, TabName = tabapi.Name
            })
        end
        function tabapi:CreateDropdown(argstable)
            local name = argstable.Name
            local list = argstable.List or argstable.DefaultList or {}
            local value = argstable.Default or list[1] or nil
            local callback = argstable.Callback or argstable.Function or function() end
            return OptionFunctions:CreateDropdown({
                Name = name, List = list, Default = value, Callback = callback,
                Parent = settingsClip, Tab = window, TabName = tabapi.Name
            })
        end
        function tabapi:CreateToggle(argstable)
            local name = argstable.Name
            local value = argstable.Default or argstable.DefaultValue or false
            local callback = argstable.Callback or argstable.Function or function() end
            return OptionFunctions:CreateToggle({
                Name = name, Default = value, Callback = callback,
                Parent = settingsClip, Tab = window, TabName = tabapi.Name
            })
        end
        function tabapi:CreateButton(argstable)
            local name = argstable.Name
            local callback = argstable.Callback or argstable.Function or function() end
            return OptionFunctions:CreateButton({
                Name = name, Callback = callback, Parent = settingsClip
            })
        end
        function tabapi:CreateTextBox(argstable)
            local name = argstable.Name
            local value = argstable.Default or argstable.DefaultValue or ""
            local PlaceholderText = argstable.PlaceholderText or "nil"
            local callback = argstable.Callback or argstable.Function or function() end
            return OptionFunctions:CreateTextBox({
                Name = name, Default = value, PlaceholderText = PlaceholderText, Callback = callback,
                Parent = settingsClip, Tab = window, TabName = tabapi.Name
            })
        end
        function tabapi:CreateTextList(argstable)
            local name = argstable.Name
            local list = argstable.List or argstable.DefaultList or {}
            local PlaceholderText = argstable.PlaceholderText or "enter something..."
            local callback = argstable.Callback or argstable.Function or function() end
            return OptionFunctions:CreateTextList({
                Name = name, List = list, PlaceholderText = PlaceholderText, Callback = callback,
                Parent = settingsClip, Tab = window, TabName = tabapi.Name
            })
        end

        guilibrary.ObjectsToSave.Tabs[tabname] = {
            Name = tabname,
            API = tabapi,
            Type = "OptionTab",
            Options = {}
        }
        return tabapi
    end

    -- ============ RENDER LOOP ============
    -- We render modules and settings each frame using RunService.Heartbeat

    -- Module buttons (created dynamically)
    local moduleButtons = {}

    local function renderModules()
        -- Clear old module buttons
        for _, btn in pairs(moduleButtons) do
            if btn and btn.Parent then btn:Destroy() end
        end
        moduleButtons = {}

        -- Determine which category to show
        local activeCat = selectedCategory
        if not activeCat then return end

        -- Update category name label
        catNameLabel.Text = activeCat.Name

        -- Update result counter
        local found = searchResults()
        resultLabel.Text = searching() and (found .. " result" .. (found == 1 and "" or "s")) or ""

        -- Empty state
        emptyLabel.Visible = searching() and found == 0

        -- Scroll animation
        scrollAnim = scrollAnim + (scrollTarget - scrollAnim) * 0.2

        -- Render modules
        local y = 0
        local moduleH = 20
        local gap = 5
        local listH = moduleClip.AbsoluteSize.Y

        for _, mod in ipairs(activeCat.modules) do
            local visible = moduleVisible(activeCat, mod)
            local anim = moduleAnim(mod.Name, visible)
            if anim > 0.01 then
                local btn = Instance.new("TextButton", moduleClip)
                btn.Name = "Mod_" .. mod.Name
                btn.BackgroundColor3 = guipallet.Color2
                btn.BackgroundTransparency = 0.2
                btn.BorderSizePixel = 0
                btn.Position = UDim2.new(0, 0, 0, y - scrollAnim)
                btn.Size = UDim2.new(1, 0, 0, moduleH)
                btn.Text = ""
                btn.AutoButtonColor = false
                btn.ZIndex = 8
                local btnCorner = Instance.new("UICorner", btn)
                btnCorner.CornerRadius = UDim.new(0, 4)

                -- Hover
                local hovered = isHovered(lastMouseX, lastMouseY, btn.AbsolutePosition.X, btn.AbsolutePosition.Y, btn.AbsoluteSize.X, btn.AbsoluteSize.Y)
                local hov = hoverAnim(mod.Name .. ":hov", hovered)
                local en = enableAnim(mod.Name .. ":en", mod.ToggleTable.Enabled)

                -- Background color with hover/enable
                btn.BackgroundColor3 = Color3.fromRGB(
                    guipallet.Color2.R * 255 * (1 - hov * 0.3) + guipallet.Color1.R * 255 * hov * 0.3,
                    guipallet.Color2.G * 255 * (1 - hov * 0.3) + guipallet.Color1.G * 255 * hov * 0.3,
                    guipallet.Color2.B * 255 * (1 - hov * 0.3) + guipallet.Color1.B * 255 * hov * 0.3
                )

                -- Module name label
                local nameLabel = Instance.new("TextLabel", btn)
                nameLabel.BackgroundTransparency = 1
                nameLabel.BorderSizePixel = 0
                nameLabel.Position = UDim2.new(0, 5, 0, 0)
                nameLabel.Size = UDim2.new(1, -30, 1, 0)
                nameLabel.Font = guipallet.Font
                nameLabel.Text = mod.Name
                nameLabel.TextColor3 = guipallet.TextColor
                nameLabel.TextSize = 11
                nameLabel.TextXAlignment = Enum.TextXAlignment.Left
                nameLabel.TextYAlignment = Enum.TextYAlignment.Center
                nameLabel.ZIndex = 9

                -- Enable indicator (right side)
                local indicator = Instance.new("Frame", btn)
                indicator.Name = "Indicator"
                indicator.BackgroundColor3 = guipallet.ToggleColor2
                indicator.BackgroundTransparency = 1 - en
                indicator.BorderSizePixel = 0
                indicator.Position = UDim2.new(1, -14, 0, 6)
                indicator.Size = UDim2.new(0, 8, 0, 8)
                indicator.ZIndex = 9
                local indCorner = Instance.new("UICorner", indicator)
                indCorner.CornerRadius = UDim.new(1, 0)

                -- Keybind label
                local keyLabel = Instance.new("TextLabel", btn)
                keyLabel.BackgroundTransparency = 1
                keyLabel.BorderSizePixel = 0
                keyLabel.Position = UDim2.new(1, -30, 0, 0)
                keyLabel.Size = UDim2.new(0, 14, 1, 0)
                keyLabel.Font = guipallet.Font
                keyLabel.Text = mod.Keybind ~= "none" and mod.Keybind or ""
                keyLabel.TextColor3 = guipallet.PlaceholderColor
                keyLabel.TextSize = 8
                keyLabel.TextXAlignment = Enum.TextXAlignment.Center
                keyLabel.TextYAlignment = Enum.TextYAlignment.Center
                keyLabel.ZIndex = 9

                -- Click handling
                table.insert(connections, btn.MouseButton1Click:Connect(function()
                    mod.ToggleTable:Toggle()
                end))
                table.insert(connections, btn.MouseButton2Click:Connect(function()
                    selectedModule = (selectedModule == mod) and nil or mod
                    settingScrollTarget = 0
                    settingScrollAnim = 0
                end))

                moduleButtons[mod.Name] = btn
                y = y + (moduleH + gap) * anim
            end
        end

        -- Max scroll
        maxScroll = math.max(0, y - listH)
        if scrollTarget > maxScroll then scrollTarget = maxScroll end

        -- Render settings for selected module
        if selectedModule then
            selectPlaceholder.Visible = false
            -- Rebuild settings from the module's toggle options
            -- The options were created with Parent = settingsClip, but we destroyed them.
            -- We need to re-create them. This is complex - instead, we keep options
            -- in a hidden container and move them here.
            -- For simplicity, we re-render by calling the option creators again is not possible.
            -- Instead, we'll keep the settings persistent and just show/hide.
        else
            selectPlaceholder.Visible = true
        end
    end

    -- ============ INPUT HANDLING ============
    -- Search box
    table.insert(connections, searchBox:GetPropertyChangedSignal("Text"):Connect(function()
        searchQuery = searchBox.Text
        searchChanged()
    end))

    -- Mouse position tracking
    table.insert(connections, userInputService.InputChanged:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseMovement then
            lastMouseX = input.Position.X
            lastMouseY = input.Position.Y
        end
    end))

    -- Scroll
    table.insert(connections, userInputService.InputChanged:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseWheel then
            if window.Visible and isHovered(lastMouseX, lastMouseY, modulePanel.AbsolutePosition.X, modulePanel.AbsolutePosition.Y, modulePanel.AbsoluteSize.X, modulePanel.AbsoluteSize.Y) then
                scrollTarget = clamp(scrollTarget - input.Position.Z * 25, 0, maxScroll)
            end
        end
    end))

    -- ============ TOGGLE / VISIBILITY ============
    local function Toggle(state)
        local state = state or not window.Visible
        window.Visible = state
        guilibrary.Toggled = state
        if state then
            -- Reset selection
            selectedCategory = selectedCategory or Categories[1]
            selectedModule = nil
            scrollTarget = 0
            settingScrollTarget = 0
        end
    end

    -- ============ EXPOSE API ============
    guilibrary.CreateWindow = CreateWindow
    guilibrary.CreateTab = CreateTab
    guilibrary.CreateOptionsTab = CreateOptionsTab
    guilibrary.CreateCustomTab = CreateTab -- alias
    guilibrary.Toggle = Toggle
    guilibrary.NightixMenu = {
        window = window,
        Toggle = Toggle,
        Categories = Categories,
        selectedCategory = function() return selectedCategory end,
        selectedModule = function() return selectedModule end,
        setSelectedModule = function(mod) selectedModule = mod end,
        render = renderModules
    }

    -- Render loop
    spawn(function()
        while true do
            task.wait()
            if window.Visible then
                renderModules()
            end
        end
    end)

    return guilibrary
end