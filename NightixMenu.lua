-- Nursultan / Default UI
-- Rebuilt menu layer: independent function buttons, inline right-click options,
-- middle-mouse bind editor, external theme/config editors and no legacy Modules UI.

return function(guilibrary, OptionFunctions, connections, userInputService, tweenService, textService, mouse, spawn)
    local Mana = shared.Mana
    local Functions = Mana.Functions
    local ObjectsToSave = guilibrary.ObjectsToSave
    local Players = game:GetService("Players")
    local LocalPlayer = Players.LocalPlayer
    local RunService = game:GetService("RunService")
    local Lighting = game:GetService("Lighting")
    local CoreGui = game:GetService("CoreGui")

    local NeverLose = Functions:RunFile("NeverLose.lua")
    if not NeverLose then error("[Nursultan]: NeverLose failed to load") end

    -- Never start with the old global blur implementation. Blur is controlled by Interface.
    NeverLose.EnabledBlur = false

    local C = {
        Background = Color3.fromRGB(30,30,52),
        Active = Color3.fromRGB(41,35,67),
        Outline = Color3.fromRGB(45,38,72),
        Text = Color3.fromRGB(245,245,250),
        Muted = Color3.fromRGB(160,157,178),
        Accent1 = Color3.fromRGB(197,132,211),
        Accent2 = Color3.fromRGB(95,63,121),
        White = Color3.fromRGB(255,255,255),
    }

    local function corner(obj, radius)
        local c = Instance.new("UICorner")
        c.CornerRadius = UDim.new(0, radius or 7)
        c.Parent = obj
        return c
    end
    local function stroke(obj, color, transparency, thickness)
        local s = Instance.new("UIStroke")
        s.Color = color or C.Outline
        s.Transparency = transparency or 0
        s.Thickness = thickness or 1
        s.Parent = obj
        return s
    end
    local function label(parent, text, size, color, font)
        local l = Instance.new("TextLabel")
        l.BackgroundTransparency = 1
        l.Text = tostring(text or "")
        l.TextColor3 = color or C.Text
        l.Font = font or Enum.Font.GothamMedium
        l.TextSize = size or 13
        l.TextXAlignment = Enum.TextXAlignment.Left
        l.TextYAlignment = Enum.TextYAlignment.Center
        l.Parent = parent
        return l
    end

    -- NeverLose is used only as the control backend. Do not create its legacy visual window.
    local legacyWindow={
        Signal=NeverLose:CreateSignal(false),
        SetRender=function() end,
    }

    local screen = NeverLose.ScreenGui
    screen.Name = "Nursultan"
    screen.DisplayOrder = 200

    -- Main menu root.
    local menu = Instance.new("Frame")
    menu.Name = "NursultanMenu"
    menu.AnchorPoint = Vector2.new(0.5,0.5)
    menu.Position = UDim2.fromScale(0.5,0.5)
    menu.Size = UDim2.fromOffset(1060,610)
    menu.BackgroundColor3 = C.Background
    menu.BackgroundTransparency = 0.10
    menu.BorderSizePixel = 0
    menu.Visible = false
    menu.Active = true
    menu.ZIndex = 100
    menu.Parent = screen
    corner(menu, 10)
    stroke(menu, C.Outline, 0.05, 1)

    local top = Instance.new("Frame")
    top.BackgroundTransparency = 1
    top.Size = UDim2.new(1,-28,0,50)
    top.Position = UDim2.fromOffset(14,10)
    top.Parent = menu

    local title = label(top, "Default", 19, C.Text)
    title.Position = UDim2.fromOffset(2,0)
    title.Size = UDim2.fromOffset(180,28)
    local sub = label(top, "Nursultan", 11, C.Muted)
    sub.Position = UDim2.fromOffset(3,27)
    sub.Size = UDim2.fromOffset(180,18)

    local search = Instance.new("TextBox")
    search.Size = UDim2.fromOffset(250,32)
    search.Position = UDim2.new(1,-250,0,4)
    search.BackgroundColor3 = C.Background
    search.BackgroundTransparency = 0.12
    search.BorderSizePixel = 0
    search.Text = ""
    search.PlaceholderText = "Поиск"
    search.PlaceholderColor3 = C.Muted
    search.TextColor3 = C.Text
    search.Font = Enum.Font.Gotham
    search.TextSize = 12
    search.ClearTextOnFocus = false
    search.Parent = top
    corner(search,7)
    stroke(search,C.Outline,0.1)

    local body = Instance.new("Frame")
    body.BackgroundTransparency = 1
    body.Position = UDim2.fromOffset(14,68)
    body.Size = UDim2.new(1,-28,-0,530)
    body.Parent = menu

    local tabBar = Instance.new("Frame")
    tabBar.BackgroundTransparency = 1
    tabBar.Size = UDim2.fromOffset(145,530)
    tabBar.Parent = body

    local tabLayout = Instance.new("UIListLayout")
    tabLayout.Padding = UDim.new(0,5)
    tabLayout.SortOrder = Enum.SortOrder.LayoutOrder
    tabLayout.Parent = tabBar

    local content = Instance.new("ScrollingFrame")
    content.BackgroundTransparency = 1
    content.Position = UDim2.fromOffset(158,0)
    content.Size = UDim2.new(1,-158,1,0)
    content.BorderSizePixel = 0
    content.ScrollBarThickness = 2
    content.ScrollBarImageColor3 = C.Active
    content.CanvasSize = UDim2.new()
    content.AutomaticCanvasSize = Enum.AutomaticSize.Y
    content.ScrollingDirection = Enum.ScrollingDirection.Y
    content.Parent = body

    local columnLayout = Instance.new("UIListLayout")
    columnLayout.Padding = UDim.new(0,7)
    columnLayout.SortOrder = Enum.SortOrder.LayoutOrder
    columnLayout.Parent = content

    local tabStates = {}
    local currentTab
    local moduleRows = {}
    local expandedRow

    local function tabButton(name)
        local b = Instance.new("TextButton")
        b.Size = UDim2.new(1,0,0,34)
        b.BackgroundColor3 = C.Background
        b.BackgroundTransparency = 0.20
        b.BorderSizePixel = 0
        b.AutoButtonColor = false
        b.Text = tostring(name)
        b.TextColor3 = C.Muted
        b.Font = Enum.Font.GothamMedium
        b.TextSize = 12
        b.TextXAlignment = Enum.TextXAlignment.Left
        b.Parent = tabBar
        corner(b,7)
        stroke(b,C.Outline,0.15)
        b.MouseEnter:Connect(function() if currentTab ~= name then b.BackgroundTransparency = 0.05 end end)
        b.MouseLeave:Connect(function() if currentTab ~= name then b.BackgroundTransparency = 0.20 end end)
        return b
    end

    local function clearContent()
        -- Rows are persistent objects; switching tabs only reparents them.
        for _, r in ipairs(moduleRows) do
            if r.Root then r.Root.Parent=nil end
        end
    end

    local function styleOptionTree(root)
        for _,o in ipairs(root:GetDescendants()) do
            if o:IsA("Frame") then
                if o.BackgroundTransparency < 1 then
                    o.BackgroundColor3 = C.Background
                    o.BackgroundTransparency = 0.08
                    if not o:FindFirstChildOfClass("UICorner") then corner(o,6) end
                    local st=o:FindFirstChildOfClass("UIStroke")
                    if st then st.Color=C.Outline; st.Transparency=0.15 end
                end
            elseif o:IsA("TextLabel") or o:IsA("TextButton") or o:IsA("TextBox") then
                if o.Text ~= "" then o.TextColor3=C.Text end
            end
        end
    end

    local function makeInlineOptions(row, signal)
        local panel = Instance.new("Frame")
        panel.Name = "InlineOptions"
        panel.BackgroundColor3 = C.Background
        panel.BackgroundTransparency = 0.03
        panel.BorderSizePixel = 0
        panel.Size = UDim2.new(1,0,0,8)
        panel.Visible = false
        panel.ClipsDescendants = true
        panel.ZIndex = 130
        panel.Parent = row.Root
        corner(panel,7)
        stroke(panel,C.Outline,0.05)

        local inner = Instance.new("Frame")
        inner.BackgroundTransparency = 1
        inner.Position = UDim2.fromOffset(7,5)
        inner.Size = UDim2.new(1,-14,0,1)
        inner.Parent = panel
        local layout = Instance.new("UIListLayout")
        layout.Padding = UDim.new(0,3)
        layout.SortOrder = Enum.SortOrder.LayoutOrder
        layout.Parent = inner

        local handler = NeverLose:RegisiterHandler(inner, signal)
        handler.Root = panel

        local function update()
            local h = math.max(8, layout.AbsoluteContentSize.Y + 10)
            panel.Size = UDim2.new(1,0,0,h)
            panel.Visible = row._expanded == true
            styleOptionTree(panel)
        end
        layout:GetPropertyChangedSignal("AbsoluteContentSize"):Connect(update)
        signal:Connect(function(v) panel.Visible = v == true; task.defer(update) end)
        return panel, handler, update
    end

    local function bindDisplay(value)
        if value == "None" or value == nil then return "None" end
        if value == "M1B" then return "Mouse 1" end
        if value == "M2B" then return "Mouse 2" end
        if value == "M3B" then return "Mouse 3" end
        return tostring(value):gsub("LeftControl","LCtrl"):gsub("RightControl","RCtrl")
    end

    local function createBindPopup(api, anchor)
        if menu:FindFirstChild("BindPopup") then menu.BindPopup:Destroy() end
        local pop = Instance.new("Frame")
        pop.Name="BindPopup"
        pop.Size=UDim2.fromOffset(260,155)
        pop.Position=UDim2.fromOffset(math.max(8,anchor.AbsolutePosition.X-menu.AbsolutePosition.X-245), math.max(8,anchor.AbsolutePosition.Y-menu.AbsolutePosition.Y+36))
        pop.BackgroundColor3=C.Background
        pop.BackgroundTransparency=0.02
        pop.BorderSizePixel=0
        pop.ZIndex=300
        pop.Parent=menu
        corner(pop,8); stroke(pop,C.Outline,0)
        local t=label(pop,"Бинд",13,C.Text); t.Position=UDim2.fromOffset(12,8); t.Size=UDim2.fromOffset(160,24)
        local field=Instance.new("TextButton")
        field.Size=UDim2.fromOffset(198,30); field.Position=UDim2.fromOffset(10,38)
        field.BackgroundColor3=C.Background; field.BorderSizePixel=0; field.AutoButtonColor=false
        field.Text=bindDisplay(api.Keybind or "None"); field.TextColor3=C.Text; field.Font=Enum.Font.Gotham; field.TextSize=12; field.TextXAlignment=Enum.TextXAlignment.Left
        field.Parent=pop; corner(field,6); stroke(field,C.Outline,0.1)
        local del=Instance.new("TextButton")
        del.Size=UDim2.fromOffset(34,30); del.Position=UDim2.fromOffset(216,38)
        del.BackgroundColor3=C.Background; del.BorderSizePixel=0; del.AutoButtonColor=false; del.Text="×"; del.TextColor3=C.Muted; del.TextSize=18; del.Font=Enum.Font.GothamBold
        del.Parent=pop; corner(del,6); stroke(del,C.Outline,0.1)
        del.MouseButton1Click:Connect(function() api:UpdateKeybind(true); field.Text="None" end)

        local modeLabel=label(pop,"Режим",11,C.Muted); modeLabel.Position=UDim2.fromOffset(12,76); modeLabel.Size=UDim2.fromOffset(70,20)
        local modes={"Toggle","Hold"}
        local current=api.BindMode or "Toggle"
        local modeButtons={}
        for i,m in ipairs(modes) do
            local b=Instance.new("TextButton"); b.Size=UDim2.fromOffset(82,28); b.Position=UDim2.fromOffset(10+(i-1)*92,103)
            b.BackgroundColor3=(current==m and C.Active or C.Background); b.BorderSizePixel=0; b.AutoButtonColor=false; b.Text=m; b.TextColor3=C.Text; b.Font=Enum.Font.Gotham; b.TextSize=11; b.Parent=pop; corner(b,6); stroke(b,C.Outline,0.1); modeButtons[m]=b
            b.MouseButton1Click:Connect(function()
                current=m; api.BindMode=m
                for n,x in pairs(modeButtons) do x.BackgroundColor3=(n==current and C.Active or C.Background) end
            end)
        end

        local captureOverlay
        local function beginCapture()
            if captureOverlay then captureOverlay:Destroy() end
            captureOverlay=Instance.new("Frame")
            captureOverlay.Name="BindCapture"
            captureOverlay.BackgroundColor3=Color3.new(0,0,0)
            captureOverlay.BackgroundTransparency=0.5
            captureOverlay.BorderSizePixel=0
            captureOverlay.Size=UDim2.fromScale(1,1)
            captureOverlay.ZIndex=900
            captureOverlay.Parent=screen
            local msg=label(captureOverlay,"Нажмите на клавишу чтобы забиндить",18,C.White)
            msg.AnchorPoint=Vector2.new(.5,.5); msg.Position=UDim2.fromScale(.5,.5); msg.Size=UDim2.fromOffset(500,40); msg.TextXAlignment=Enum.TextXAlignment.Center
            local conn
            conn=userInputService.InputBegan:Connect(function(input)
                local selected=nil
                if input.UserInputType==Enum.UserInputType.Keyboard and input.KeyCode~=Enum.KeyCode.Unknown then selected=input.KeyCode.Name
                elseif input.UserInputType==Enum.UserInputType.MouseButton1 then selected="M1B"
                elseif input.UserInputType==Enum.UserInputType.MouseButton2 then selected="M2B"
                elseif input.UserInputType==Enum.UserInputType.MouseButton3 then selected="M3B" end
                if selected then
                    api:UpdateKeybind(false,selected)
                    field.Text=bindDisplay(selected)
                    if conn then conn:Disconnect() end
                    captureOverlay:Destroy(); captureOverlay=nil
                end
            end)
        end
        field.MouseButton1Click:Connect(beginCapture)
    end

    local function createModule(tabName, argstable)
        local name=tostring(argstable.Name or "Function")
        local def=argstable.Default or argstable.DefaultValue or false
        local callback=argstable.Callback or argstable.Function or function() end
        local bind=argstable.Keybind or "None"

        local root=Instance.new("Frame")
        root.Name="Function_"..name
        root.Size=UDim2.new(1,0,0,38)
        root.AutomaticSize=Enum.AutomaticSize.Y
        root.BackgroundColor3=C.Background
        root.BackgroundTransparency=0.06
        root.BorderSizePixel=0
        root.ClipsDescendants=true
        root.LayoutOrder=#moduleRows+1
        root.Parent=content
        corner(root,7); local rs=stroke(root,C.Outline,0.08)

        local main=Instance.new("TextButton")
        main.BackgroundColor3=def and C.Active or C.Background
        main.BackgroundTransparency=def and 0.03 or 0.08
        main.BorderSizePixel=0
        main.AutoButtonColor=false
        main.Text=""
        main.Size=UDim2.new(1,0,0,38)
        main.Parent=root
        corner(main,7)
        local txt=label(main,name,13,C.Text); txt.Position=UDim2.fromOffset(12,0); txt.Size=UDim2.new(1,-75,1,0)
        local dots=Instance.new("TextButton")
        dots.BackgroundTransparency=1; dots.BorderSizePixel=0; dots.AutoButtonColor=false; dots.Text="•••"; dots.TextColor3=C.Muted; dots.Font=Enum.Font.GothamBold; dots.TextSize=12; dots.Size=UDim2.fromOffset(38,30); dots.Position=UDim2.new(1,-44,0,4); dots.Parent=main

        local signal=NeverLose:CreateSignal(false)
        local fake={Name=name,Enabled=def,Value=def,Keybind=bind,BindMode="Toggle",Options={},MainObject=root,Container=root,Callback=callback}
        local optionPanel, optionHandler, updateOptions=makeInlineOptions({Root=root,_expanded=false},signal)
        local function saveOption(api, kind)
            if api and api.Name then fake.Options[api.Name]={Name=api.Name,API=api,Type=kind} end
            return api
        end
        local rowRef={Root=root,Main=main,API=fake,OptionPanel=optionPanel,_expanded=false,Name=name}
        moduleRows[#moduleRows+1]=rowRef

        local function refreshVisual()
            main.BackgroundColor3=fake.Enabled and C.Active or C.Background
            main.BackgroundTransparency=fake.Enabled and 0.02 or 0.08
            txt.TextColor3=C.Text
            rs.Color=C.Outline
        end
        function fake:SetEnabled(v,Silent)
            v=v==true
            if fake.Enabled==v then return false end
            fake.Enabled=v; fake.Value=v
            callback(v)
            refreshVisual()
            return true
        end
        function fake:Toggle(Silent,v)
            local target=v==nil and not fake.Enabled or v==true
            if fake.Enabled==target then return end
            fake.Enabled=target; fake.Value=target; callback(target); refreshVisual()
        end
        function fake:UpdateKeybind(remove,newKeybind)
            fake.Keybind=remove and "None" or (newKeybind or "None")
        end
        function fake:ReToggle(Silent)
            if fake.Enabled then callback(false); callback(true) end
        end
        function fake:CreateSlider(a) return saveOption(optionHandler:AddSlider({Name=a.Name,Default=a.Default or a.DefaultValue or a.Min or 0,Min=a.Min or 0,Max=a.Max or 100,Rounding=a.Round or 0,Type=a.Type or "",Size=140,Callback=a.Callback or a.Function or function() end}),"Slider") end
        function fake:CreateDropdown(a) return saveOption(optionHandler:AddDropdown({Name=a.Name,Default=a.Default or a.DefaultValue,List=a.List or {},Size=140,Callback=a.Callback or a.Function or function() end}),"Dropdown") end
        function fake:CreateColorSlider(a) return saveOption(optionHandler:AddColorPicker({Name=a.Name,Default=a.Default or a.DefaultValue or C.Accent1,Callback=a.Callback or a.Function or function() end}),"ColorSlider") end
        function fake:CreateToggle(a) return saveOption(optionHandler:AddToggle({Name=a.Name,Default=a.Default or a.DefaultValue or false,Callback=a.Callback or a.Function or function() end}),"Toggle") end
        function fake:CreateTextBox(a) return saveOption(optionHandler:AddTextInput({Name=a.Name,Default=a.Default or a.Value or "",Placeholder=a.PlaceholderText or a.Placeholder or "",Numeric=a.Numeric or false,Callback=a.Callback or a.Function or function() end}),"TextBox") end
        function fake:CreateButton(a) return saveOption(optionHandler:AddButton({Name=a.Name or "Button",Icon=a.Icon or "chevron-large-right",Callback=a.Callback or a.Function or function() end}),"Button") end
        function fake:CreateTextList(a) return saveOption(optionHandler:AddTextInput({Name=a.Name,Default="",Placeholder=a.PlaceholderText or "Value",Callback=function() end}),"TextList") end

        main.MouseButton1Click:Connect(function() fake:Toggle(false); refreshVisual() end)
        main.MouseButton2Click:Connect(function()
            if expandedRow and expandedRow~=rowRef then
                expandedRow._expanded=false
                expandedRow.OptionPanel.Visible=false
            end
            rowRef._expanded=not rowRef._expanded
            expandedRow=rowRef._expanded and rowRef or nil
            signal:SetValue(rowRef._expanded)
            updateOptions()
        end)
        main.InputBegan:Connect(function(input)
            if input.UserInputType==Enum.UserInputType.MouseButton3 then
                createBindPopup(fake,main)
            end
        end)
        dots.MouseButton1Click:Connect(function()
            if expandedRow and expandedRow~=rowRef then expandedRow._expanded=false; expandedRow.OptionPanel.Visible=false end
            rowRef._expanded=not rowRef._expanded; expandedRow=rowRef._expanded and rowRef or nil; signal:SetValue(rowRef._expanded); updateOptions()
        end)

        connections[#connections+1]=userInputService.InputBegan:Connect(function(input,processed)
            if processed then return end
            local key=fake.Keybind
            local pressed=(input.UserInputType==Enum.UserInputType.Keyboard and input.KeyCode~=Enum.KeyCode.Unknown and input.KeyCode.Name==key)
                or (key=="M1B" and input.UserInputType==Enum.UserInputType.MouseButton1)
                or (key=="M2B" and input.UserInputType==Enum.UserInputType.MouseButton2)
                or (key=="M3B" and input.UserInputType==Enum.UserInputType.MouseButton3)
            if pressed then
                if fake.BindMode=="Hold" then
                    fake:SetEnabled(true,true)
                else
                    fake:Toggle(true)
                end
            end
        end)
        connections[#connections+1]=userInputService.InputEnded:Connect(function(input,processed)
            if processed or fake.BindMode~="Hold" then return end
            local key=fake.Keybind
            local released=(input.UserInputType==Enum.UserInputType.Keyboard and input.KeyCode~=Enum.KeyCode.Unknown and input.KeyCode.Name==key)
                or (key=="M1B" and input.UserInputType==Enum.UserInputType.MouseButton1)
                or (key=="M2B" and input.UserInputType==Enum.UserInputType.MouseButton2)
                or (key=="M3B" and input.UserInputType==Enum.UserInputType.MouseButton3)
            if released then fake:SetEnabled(false,true) end
        end)

        ObjectsToSave.Toggles[name]={Name=name,API=fake,Options=fake.Options}
        refreshVisual()
        return fake
    end

    local function showTab(name)
        currentTab=name
        clearContent()
        for tabName,state in pairs(tabStates) do
            local b=state.button
            b.BackgroundColor3=(tabName==name and C.Active or C.Background)
            b.BackgroundTransparency=(tabName==name and 0.02 or 0.20)
            b.TextColor3=(tabName==name and C.Text or C.Muted)
        end
        for _,r in ipairs(moduleRows) do
            if r.TabName==name then r.Root.Parent=content end
        end
        content.CanvasPosition=Vector2.new(0,0)
    end

    local function createTab(argstable,isOptions)
        local tabname=tostring(argstable.Name or "Tab")
        local b=tabButton(tabname)
        local state={Name=tabname,button=b,isOptions=isOptions,modules={}}
        tabStates[tabname]=state
        b.MouseButton1Click:Connect(function() showTab(tabname) end)

        local tabtable={Name=tabname,Container=content,Options={},Order=1}
        function tabtable:CreateDivider() end
        function tabtable:CreateSecondDivider() end
        function tabtable:CreateToggle(a)
            local api=createModule(tabname,a); api.TabName=tabname; state.modules[#state.modules+1]=api
            -- createModule initially parents to content; hide until tab is selected.
            api.MainObject.Parent=content
            if currentTab~=tabname then api.MainObject.Parent=nil end
            return api
        end
        function tabtable:CreateSlider(a) return createModule(tabname,{Name=a.Name,Default=true,Callback=function() end}):CreateSlider(a) end
        function tabtable:CreateDropdown(a) return createModule(tabname,{Name=a.Name,Default=true,Callback=function() end}):CreateDropdown(a) end
        function tabtable:CreateColorSlider(a) return createModule(tabname,{Name=a.Name,Default=true,Callback=function() end}):CreateColorSlider(a) end
        function tabtable:CreateButton(a) return createModule(tabname,{Name=a.Name,Default=false,Callback=a.Callback or a.Function}):CreateButton(a) end
        function tabtable:CreateTextBox(a) return createModule(tabname,{Name=a.Name,Default=true,Callback=function() end}):CreateTextBox(a) end
        function tabtable:CreateTextList(a) return createModule(tabname,{Name=a.Name,Default=true,Callback=function() end}):CreateTextList(a) end
        return tabtable
    end

    -- Disable the old GuiLibrary renderer; this rebuild owns the complete UI.
    guilibrary.CreateWindow=function() return true end
    guilibrary.CreateTab=function(_,a) return createTab(a,false) end
    guilibrary.CreateOptionsTab=function(_,a) return createTab(a,true) end

    -- Theme state. One Default theme initially; creating a theme adds a new circle.
    local themes={
        Default={
            Name="Default",
            Background=C.Background, Active=C.Active, Outline=C.Outline,
            Accent1=C.Accent1, Accent2=C.Accent2,
        }
    }
    local activeTheme="Default"
    local themeEditor, configEditor
    local hud, hudIcon, hudText, hudSub

    local function applyTheme(name)
        local t=themes[name] or themes.Default
        activeTheme=name
        C.Background=t.Background; C.Active=t.Active; C.Outline=t.Outline; C.Accent1=t.Accent1; C.Accent2=t.Accent2
        menu.BackgroundColor3=C.Background
        if hud then hud.BackgroundColor3=C.Background; hudIcon.ImageColor3=C.Accent1; hudText.TextColor3=C.Text; hudSub.TextColor3=C.Muted end
        for _,r in ipairs(moduleRows) do
            r.Main.BackgroundColor3=r.API.Enabled and C.Active or C.Background
        end
        if themeEditor and themeEditor.Parent then
            local sw=themeEditor:FindFirstChild("Swatches")
            if sw then for _,x in ipairs(sw:GetChildren()) do if x:IsA("TextButton") then local n=x:GetAttribute("ThemeName"); local tt=themes[n]; if tt then x.BackgroundColor3=tt.Accent1 end end end end
        end
    end

    local function createThemeEditor()
        if themeEditor and themeEditor.Parent then themeEditor.Visible=not themeEditor.Visible; return end
        themeEditor=Instance.new("Frame")
        themeEditor.Name="ThemeEditor"; themeEditor.Size=UDim2.fromOffset(320,560); themeEditor.AnchorPoint=Vector2.new(1,.5); themeEditor.Position=UDim2.new(.5,-545,.5,0)
        themeEditor.BackgroundColor3=C.Background; themeEditor.BackgroundTransparency=.02; themeEditor.BorderSizePixel=0; themeEditor.ZIndex=500; themeEditor.Parent=screen; corner(themeEditor,9); stroke(themeEditor,C.Outline,0)
        local h=label(themeEditor,"Редактор тем",15,C.Text); h.Position=UDim2.fromOffset(14,10); h.Size=UDim2.fromOffset(200,25)
        local close=Instance.new("TextButton"); close.Text="×"; close.BackgroundTransparency=1; close.TextColor3=C.Muted; close.TextSize=20; close.Size=UDim2.fromOffset(30,30); close.Position=UDim2.new(1,-38,0,6); close.Parent=themeEditor; close.MouseButton1Click:Connect(function() themeEditor.Visible=false end)
        local input=Instance.new("TextBox"); input.Size=UDim2.new(1,-88,0,30); input.Position=UDim2.fromOffset(10,48); input.BackgroundColor3=C.Background; input.Text=""; input.PlaceholderText="Название темы"; input.PlaceholderColor3=C.Muted; input.TextColor3=C.Text; input.Font=Enum.Font.Gotham; input.TextSize=11; input.BorderSizePixel=0; input.Parent=themeEditor; corner(input,6); stroke(input,C.Outline,.1)
        local create=Instance.new("TextButton"); create.Size=UDim2.fromOffset(65,30); create.Position=UDim2.new(1,-75,0,48); create.BackgroundColor3=C.Active; create.Text="Создать"; create.TextColor3=C.Text; create.Font=Enum.Font.Gotham; create.TextSize=11; create.BorderSizePixel=0; create.Parent=themeEditor; corner(create,6)
        local sw=Instance.new("Frame"); sw.Name="Swatches"; sw.BackgroundTransparency=1; sw.Position=UDim2.fromOffset(12,90); sw.Size=UDim2.new(1,-24,0,45); sw.Parent=themeEditor
        local sl=Instance.new("UIListLayout"); sl.FillDirection=Enum.FillDirection.Horizontal; sl.Padding=UDim.new(0,7); sl.Parent=sw
        local function addCircle(name,t)
            local b=Instance.new("TextButton"); b.Size=UDim2.fromOffset(32,32); b.Text=""; b.BackgroundColor3=t.Accent1; b.BorderSizePixel=0; b.AutoButtonColor=false; b:SetAttribute("ThemeName",name); b.Parent=sw; corner(b,16); stroke(b,C.White,.55)
            b.MouseButton1Click:Connect(function() applyTheme(name) end)
        end
        addCircle("Default",themes.Default)
        create.MouseButton1Click:Connect(function()
            local n=tostring(input.Text or ""):gsub("^%s+",""):gsub("%s+$","")
            if n=="" or themes[n] then return end
            -- New themes always start from the first/default client colors.
            themes[n]={Name=n,Background=Color3.fromRGB(30,30,52),Active=Color3.fromRGB(41,35,67),Outline=Color3.fromRGB(45,38,72),Accent1=Color3.fromRGB(197,132,211),Accent2=Color3.fromRGB(95,63,121)}
            addCircle(n,themes[n]); input.Text=""; applyTheme(n)
        end)

        local colorsFrame=Instance.new("Frame")
        colorsFrame.Name="VisualFunctions"
        colorsFrame.BackgroundTransparency=1
        colorsFrame.Position=UDim2.fromOffset(10,145)
        colorsFrame.Size=UDim2.new(1,-20,0,260)
        colorsFrame.Parent=themeEditor
        local ct=label(colorsFrame,"Визуальные функции",12,C.Text); ct.Position=UDim2.fromOffset(4,0); ct.Size=UDim2.new(1,-8,0,22)
        local cs=NeverLose:CreateSignal(true)
        local handler=NeverLose:RegisiterHandler(colorsFrame,cs)
        local function themeColor(name,key)
            local holder
            holder=handler:AddColorPicker({Name=name,Default=themes[activeTheme][key],Callback=function(v)
                local t=themes[activeTheme]
                t[key]=v
                applyTheme(activeTheme)
            end})
            return holder
        end
        themeColor("Фон", "Background")
        themeColor("Активные функции", "Active")
        themeColor("Обводка", "Outline")
        themeColor("Цвет 1", "Accent1")
        themeColor("Цвет 2", "Accent2")
        local info=label(themeEditor,"Цвета функций настраиваются здесь, а HUD использует ту же тему.",11,C.Muted); info.Position=UDim2.fromOffset(14,420); info.Size=UDim2.new(1,-28,0,42); info.TextWrapped=true
        return themeEditor
    end

    local function configDate(path)
        local ok,data=pcall(function() return game:GetService("HttpService"):JSONDecode(readfile(path)) end)
        if ok and type(data)=="table" and data.Meta and data.Meta.CreatedAt then return data.Meta.CreatedAt,data.Meta.Author end
        return "—", "Nursultan"
    end

    local function createConfigEditor()
        if configEditor and configEditor.Parent then configEditor.Visible=not configEditor.Visible; return end
        configEditor=Instance.new("Frame"); configEditor.Name="ConfigEditor"; configEditor.Size=UDim2.fromOffset(330,390); configEditor.AnchorPoint=Vector2.new(1,1); configEditor.Position=UDim2.new(1,-18,1,-18); configEditor.BackgroundColor3=C.Background; configEditor.BackgroundTransparency=.02; configEditor.BorderSizePixel=0; configEditor.ZIndex=600; configEditor.Parent=screen; corner(configEditor,9); stroke(configEditor,C.Outline,0)
        local h=label(configEditor,"Конфиги",15,C.Text); h.Position=UDim2.fromOffset(14,10); h.Size=UDim2.fromOffset(180,25)
        local close=Instance.new("TextButton"); close.Text="×"; close.BackgroundTransparency=1; close.TextColor3=C.Muted; close.TextSize=20; close.Size=UDim2.fromOffset(30,30); close.Position=UDim2.new(1,-38,0,6); close.Parent=configEditor; close.MouseButton1Click:Connect(function() configEditor.Visible=false end)
        local input=Instance.new("TextBox"); input.Size=UDim2.new(1,-88,0,30); input.Position=UDim2.fromOffset(10,48); input.BackgroundColor3=C.Background; input.Text=""; input.PlaceholderText="Название"; input.PlaceholderColor3=C.Muted; input.TextColor3=C.Text; input.Font=Enum.Font.Gotham; input.TextSize=11; input.BorderSizePixel=0; input.Parent=configEditor; corner(input,6); stroke(input,C.Outline,.1)
        local create=Instance.new("TextButton"); create.Size=UDim2.fromOffset(65,30); create.Position=UDim2.new(1,-75,0,48); create.BackgroundColor3=C.Active; create.Text="Создать"; create.TextColor3=C.Text; create.Font=Enum.Font.Gotham; create.TextSize=11; create.BorderSizePixel=0; create.Parent=configEditor; corner(create,6)
        local list=Instance.new("ScrollingFrame"); list.BackgroundTransparency=1; list.BorderSizePixel=0; list.Position=UDim2.fromOffset(10,88); list.Size=UDim2.new(1,-20,1,-98); list.ScrollBarThickness=2; list.AutomaticCanvasSize=Enum.AutomaticSize.Y; list.Parent=configEditor
        local ll=Instance.new("UIListLayout"); ll.Padding=UDim.new(0,5); ll.Parent=list
        local function refresh()
            for _,x in ipairs(list:GetChildren()) do if not x:IsA("UIListLayout") then x:Destroy() end end
            for _,n in ipairs(guilibrary:ListConfigs()) do
                local row=Instance.new("TextButton"); row.Size=UDim2.new(1,0,0,62); row.BackgroundColor3=C.Background; row.BorderSizePixel=0; row.Text=""; row.AutoButtonColor=false; row.Parent=list; corner(row,7); stroke(row,C.Outline,.12)
                local nm=label(row,n,12,C.Text); nm.Position=UDim2.fromOffset(10,5); nm.Size=UDim2.new(1,-20,0,20)
                local dt,au=configDate(guilibrary.ConfigRoot.."/"..n..".json")
                local meta=label(row,"от "..tostring(au).."   •   "..tostring(dt),10,C.Muted); meta.Position=UDim2.fromOffset(10,29); meta.Size=UDim2.new(1,-20,0,18)
                local ok=label(row,"✓",14,C.Accent1); ok.AnchorPoint=Vector2.new(1,.5); ok.Position=UDim2.new(1,-9,.5,0); ok.Size=UDim2.fromOffset(24,24); ok.TextXAlignment=Enum.TextXAlignment.Center
                row.MouseButton1Click:Connect(function() guilibrary:LoadConfig(n) end)
                row.MouseButton2Click:Connect(function()
                    local p=Instance.new("Frame"); p.Size=UDim2.fromOffset(120,70); p.Position=UDim2.fromOffset(mouse.X-configEditor.AbsolutePosition.X,mouse.Y-configEditor.AbsolutePosition.Y); p.BackgroundColor3=C.Background; p.ZIndex=900; p.Parent=configEditor; corner(p,6); stroke(p,C.Outline,0)
                    local l=Instance.new("TextButton"); l.Size=UDim2.new(1,0,0,32); l.BackgroundTransparency=1; l.Text="Загрузить"; l.TextColor3=C.Text; l.Font=Enum.Font.Gotham; l.TextSize=11; l.Parent=p
                    local d=Instance.new("TextButton"); d.Size=UDim2.new(1,0,0,32); d.Position=UDim2.fromOffset(0,34); d.BackgroundTransparency=1; d.Text="Удалить"; d.TextColor3=C.Text; d.Font=Enum.Font.Gotham; d.TextSize=11; d.Parent=p
                    l.MouseButton1Click:Connect(function() guilibrary:LoadConfig(n); p:Destroy() end)
                    d.MouseButton1Click:Connect(function() guilibrary:DeleteConfig(n); p:Destroy(); refresh() end)
                end)
            end
        end
        create.MouseButton1Click:Connect(function()
            local n=tostring(input.Text or ""):gsub("^%s+",""):gsub("%s+$","")
            if n~="" then guilibrary:CreateConfig(n); input.Text=""; refresh() end
        end)
        refresh()
        return configEditor
    end

    function guilibrary:OpenThemeEditor() return createThemeEditor() end
    function guilibrary:OpenConfigEditor() return createConfigEditor() end

    -- Interface is also available as a real function in Visuals; Universal.lua wires it.
    guilibrary.InterfaceState={Logo=false,Blur=false,BlurStrength=8,BackgroundColor=C.Background,ThemeEditor=createThemeEditor,ConfigEditor=createConfigEditor}

    local blurEffect
    function guilibrary:SetInterfaceBlur(enabled,strength)
        enabled=enabled==true
        guilibrary.InterfaceState.Blur=enabled
        guilibrary.InterfaceState.BlurStrength=tonumber(strength) or guilibrary.InterfaceState.BlurStrength or 8
        if blurEffect then blurEffect:Destroy(); blurEffect=nil end
        if enabled then
            -- Roblox's post-process blur is the reliable runtime shader path available to Lua.
            blurEffect=Instance.new("BlurEffect")
            blurEffect.Name="NursultanInterfaceBlur"
            blurEffect.Size=math.clamp(guilibrary.InterfaceState.BlurStrength,0,56)
            blurEffect.Parent=Lighting
        end
    end


    -- Menu toggle, default OFF.
    guilibrary.GuiKeybind=guilibrary.GuiKeybind or "RightShift"
    guilibrary.Toggled=false
    function guilibrary:Toggle(state)
        if state==nil then state=not guilibrary.Toggled end
        guilibrary.Toggled=state==true
        menu.Visible=guilibrary.Toggled
        if not guilibrary.Toggled then
            if themeEditor then themeEditor.Visible=false end
            -- Config editor intentionally stays independent in the bottom-right.
        end
        if guilibrary.Toggled and not currentTab then
            for n in pairs(tabStates) do currentTab=n; break end
        end
        if guilibrary.Toggled and currentTab then showTab(currentTab) end
    end

    connections[#connections+1]=userInputService.InputBegan:Connect(function(input,processed)
        if processed then return end
        if input.UserInputType==Enum.UserInputType.Keyboard and input.KeyCode.Name==guilibrary.GuiKeybind then guilibrary:Toggle() end
    end)

    search:GetPropertyChangedSignal("Text"):Connect(function()
        local q=search.Text:lower()
        for _,r in ipairs(moduleRows) do
            local match=q=="" or r.Name:lower():find(q,1,true)
            if r.TabName==currentTab then r.Root.Visible=match end
        end
    end)

    -- Custom HUD. It is off at startup and is controlled by Interface -> Логотип.
    hud=Instance.new("Frame")
    hud.Name="NursultanHUD"
    hud.Position=UDim2.fromOffset(8,8)
    hud.Size=UDim2.fromOffset(250,40)
    hud.BackgroundColor3=C.Background
    hud.BackgroundTransparency=.10
    hud.BorderSizePixel=0
    hud.Visible=false
    hud.ZIndex=1000
    hud.Parent=screen
    corner(hud,7); stroke(hud,C.Outline,.05)
    hudIcon=Instance.new("ImageLabel")
    hudIcon.BackgroundTransparency=1
    hudIcon.Position=UDim2.fromOffset(5,5)
    hudIcon.Size=UDim2.fromOffset(33,30)
    hudIcon.Image="rbxassetid://106084104602244"
    hudIcon.ImageColor3=C.Accent1
    hudIcon.ScaleType=Enum.ScaleType.Fit
    hudIcon.Parent=hud
    hudText=label(hud,"Default",12,C.Text)
    hudText.Position=UDim2.fromOffset(46,3); hudText.Size=UDim2.fromOffset(195,18)
    hudSub=label(hud,"Nursultan",10,C.Muted)
    hudSub.Position=UDim2.fromOffset(46,20); hudSub.Size=UDim2.fromOffset(195,15)

    function guilibrary:SetInterfaceLogo(enabled)
        guilibrary.InterfaceState.Logo=enabled==true
        hud.Visible=enabled==true
    end
    function guilibrary:SetInterfaceBackground(color)
        if typeof(color)=="Color3" then C.Background=color; menu.BackgroundColor3=color; hud.BackgroundColor3=color; guilibrary.InterfaceState.BackgroundColor=color end
    end

    -- Theme palette hook for external callers.
    NeverLose.ThemePalette=NeverLose.ThemePalette or {}
    NeverLose.ThemePalette.Icon1=C.Accent1
    NeverLose.ThemePalette.Icon2=C.Accent2
    NeverLose.IconSettings=NeverLose.IconSettings or {Enabled=true,Mode="Double",Color1=C.Accent1,Color2=C.Accent2,Speed=.65}

    guilibrary.NightixMenu={Version=4,Window=legacyWindow,NeverLose=NeverLose,Menu=menu,Themes=themes}
    return guilibrary
end
