--[[
    Credits to anyones code i used or looked at

    Made by Maanaaaa and Wowzers
]]

repeat task.wait() until game:IsLoaded()

local startTick = tick()

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local UserInputService = game:GetService("UserInputService")
local teleportService = game:GetService("TeleportService")
local TextChatService = game:GetService("TextChatService")
local NetworkClient = game:GetService("NetworkClient")
local TweenService = game:GetService("TweenService")
local HttpService = game:GetService("HttpService")
local TextService = game:GetService("TextService")
local virtualUser = game:GetService("VirtualUser")
local StarterGui = game:GetService("StarterGui")
local RunService = game:GetService("RunService")
local Lighting = game:GetService("Lighting")
local CoreGui = game:GetService("CoreGui")
local Players = game:GetService("Players")
local debris = game:GetService("Debris")

local LocalPlayer = Players.LocalPlayer
local localPlayer = Players.LocalPlayer
local lplr = Players.LocalPlayer
local Character = LocalPlayer.Character or LocalPlayer.CharacterAdded:Wait()
local HumanoidRootPart = Character:WaitForChild("HumanoidRootPart")
local Humanoid = Character:WaitForChild("Humanoid")
local workspace = workspace
local Workspace = workspace
local Camera = workspace.CurrentCamera
local Mouse = LocalPlayer:GetMouse()
local PlayerGui = LocalPlayer.PlayerGui
local Backpack = LocalPlayer.Backpack
local Animate = Character:FindFirstChild("Animate")
local LightingTime = Lighting.TimeOfDay
local workspaceGravity = workspace.Gravity
local PlayerWalkSpeed = Humanoid.WalkSpeed
local PlayerJumpPower = Humanoid.JumpPower
local PlayerHipHeight = Humanoid.HipHeight

-- Keep legacy globals in sync after respawn. Most modules use the helper
-- functions below, but a few older paths still reference these locals.
LocalPlayer.CharacterAdded:Connect(function(newCharacter)
    Character = newCharacter
    HumanoidRootPart = newCharacter:WaitForChild("HumanoidRootPart")
    Humanoid = newCharacter:WaitForChild("Humanoid")
    Animate = newCharacter:FindFirstChild("Animate")
    PlayerWalkSpeed = Humanoid.WalkSpeed
    PlayerJumpPower = Humanoid.JumpPower
    PlayerHipHeight = Humanoid.HipHeight
end)
local OldCameraMaxZoomDistance = LocalPlayer.CameraMaxZoomDistance
local PlaceId = game.PlaceId
local JobId = game.JobId
local CurrentTool = nil
local allplayers = {}

local Mana = shared.Mana
local GuiLibrary = Mana.GuiLibrary
local Tabs = Mana.Tabs
local Functions = Mana.Functions
local RunLoops = Mana.RunLoops
local connections = Mana.Connections
local friends = Mana.Friends
local playersHandler = Mana.PlayersHandler
local toolHandler = Mana.ToolHandler
local espLibrary = Mana.EspLibrary
local guifont = GuiLibrary.Font
Mana.StartTick = startTick

playersHandler:start()
toolHandler:start()
CurrentTool = toolHandler.currentTool

local getasset = getcustomasset
local function runFunction(func) func() end

local spawn = function(func) 
    return coroutine.wrap(func)()
end

local requestfunc = http and http.request or http_request or request or function(tab)
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

local cachedassets = {}
local function GetCustomAsset(path)
    if Mana.Developer then
        return getasset("NewMana/" .. path)
    else
        if not betterisfile(path) then
            spawn(function()
                local textlabel = Instance.new("TextLabel")
                textlabel.Size = UDim2.new(1, 0, 0, 36)
                textlabel.Text = "Downloading "..path
                textlabel.BackgroundTransparency = 1
                textlabel.TextStrokeTransparency = 0
                textlabel.TextSize = 30
                textlabel.Font = GuiLibrary.Font
                textlabel.TextColor3 = Color3.new(1, 1, 1)
                textlabel.Position = UDim2.new(0, 0, 0, -36)
                textlabel.Parent = GuiLibrary.ScreenGui
                repeat wait() until betterisfile(path)
                textlabel:Remove()
            end)
            local req = requestfunc({
                Url = "https://raw.githubusercontent.com/Maanaaaa/ManaV2ForRoblox/main/" .. path:gsub("Mana/Assets", "Assets"),
                Method = "GET"
            })
            writefile(path, req.Body)
        end
        if cachedassets[path] == nil then
            cachedassets[path] = getasset(path) 
        end
        return cachedassets[path]
    end
end

local spawn = function(func) 
    return coroutine.wrap(func)()
end

local function CreateCoreNotification(title, text, duration)
	StarterGui:SetCore("SendNotification", {
		Title = title,
		Text = text,
		Duration = duration,
	})
end

--[[
while isAlive() and wait(0.1) do
    local Tool = Character:FindFirstChildWhichIsA("Tool")
    if Tool then
        CurrentTool = Tool
    end
end
]]

-- Players handler part
local function isAlive(Player, headCheck)
    local Player = Player or LocalPlayer
    if Player and Player.Character and ((Player.Character:FindFirstChildOfClass("Humanoid")) and Player.Character:FindFirstChild("HumanoidRootPart") and (headCheck and Player.Character:FindFirstChild("Head") or not headCheck)) then
        return true
    else
        return false
    end
end

local function TargetCheck(plr, check)
	return (check and plr.Character.Humanoid.Health > 0 and plr.Character:FindFirstChild("ForceField") == nil or check == false)
end

local function isPlayerTargetable(plr, target)
    return plr ~= LocalPlayer and plr and isAlive(plr) and TargetCheck(plr, target)
end

--[[
local function getClosestPlayer(MaxDistance, TeamCheck, lowesthealth)
	local MaximumDistance = MaxDistance
	local Target = nil
    local lowest = 100
    local unsorted = {}
    local humanoids = {}
    local sorted = {}

    local function sortByHealth()
        for i, player in next, unsorted do
            if isAlive(player) then
                table.insert(humanoids, player.Character.Humanoid.Health)
            end
        end
        table.sort(humanoids, function(a, b)
            return a.health < b.health
        end)

        for i, v in next, humanoids do
            table.insert(sorted, v.player)
        end
    end

    local function checkPlayer(v, byHealth)
        sortByHealth()
        if v.Character ~= nil then
            if v.Character:FindFirstChild("HumanoidRootPart") ~= nil then
                if v.Character:FindFirstChild("Humanoid") ~= nil and v.Character:FindFirstChild("Humanoid").Health ~= 0 then
                    local ScreenPoint = Camera:WorldToScreenPoint(v.Character:WaitForChild("HumanoidRootPart", math.huge).Position)
                    local VectorDistance = (Vector2.new(UserInputService:GetMouseLocation().X, UserInputService:GetMouseLocation().Y) - Vector2.new(ScreenPoint.X, ScreenPoint.Y)).Magnitude
                    
                    if byHealth then
                        if v == sorted[1] then
                            Target = v
                        end
                    else
                        if VectorDistance < MaximumDistance then
                            Target = v
                        end
                    end
                end
            end
        end
        sortByHealth()
        return sorted[1]
    end

	for _, v in next, Players:GetPlayers() do
		if v.Name ~= LocalPlayer.Name then
            table.insert(unsorted, player)
			if TeamCheck then
				if v.Team ~= LocalPlayer.Team then
					checkPlayer(v)
				end
			else
				checkPlayer(v)
			end
		end
	end

	return Target
end
]]

local function getClosestPlayer(MaxDisance, TeamCheck)
	local MaximumDistance = MaxDisance
	local Target = nil

	for _, v in next, Players:GetPlayers() do
		if v.Name ~= LocalPlayer.Name then
			if TeamCheck then
				if v.Team ~= LocalPlayer.Team then
					if v.Character ~= nil then
						if v.Character:FindFirstChild("HumanoidRootPart") ~= nil then
							if v.Character:FindFirstChild("Humanoid") ~= nil and v.Character:FindFirstChild("Humanoid").Health ~= 0 then
								local ScreenPoint = Camera:WorldToScreenPoint(v.Character:WaitForChild("HumanoidRootPart", math.huge).Position)
								local VectorDistance = (Vector2.new(UserInputService:GetMouseLocation().X, UserInputService:GetMouseLocation().Y) - Vector2.new(ScreenPoint.X, ScreenPoint.Y)).Magnitude
								
								if VectorDistance < MaximumDistance then
									Target = v
								end
							end
						end
					end
				end
			else
				if v.Character ~= nil then
					if v.Character:FindFirstChild("HumanoidRootPart") ~= nil then
						if v.Character:FindFirstChild("Humanoid") ~= nil and v.Character:FindFirstChild("Humanoid").Health ~= 0 then
							local ScreenPoint = Camera:WorldToScreenPoint(v.Character:WaitForChild("HumanoidRootPart", math.huge).Position)
							local VectorDistance = (Vector2.new(UserInputService:GetMouseLocation().X, UserInputService:GetMouseLocation().Y) - Vector2.new(ScreenPoint.X, ScreenPoint.Y)).Magnitude
							
							if VectorDistance < MaximumDistance then
								Target = v
							end
						end
					end
				end
			end
		end
	end

	return Target
end

local function GetColorFromPlayer(Player) 
    if Player.Team ~= nil then return Player.TeamColor.Color end
end

local function ConvertHealthToColor(Health, MaxHealth)
    -- Input validation
    if type(Health) ~= "number" or type(MaxHealth) ~= "number" then
        return Color3.fromRGB(255, 255, 255)
    end
    
    if MaxHealth <= 0 then
        return Color3.fromRGB(255, 0, 0)
    end
    
    if Health <= 0 then
        return Color3.fromRGB(255, 0, 0)
    end
    
    local Percent = math.clamp((Health / MaxHealth) * 100, 0, 100)
    
    if Percent >= 70 then
        return Color3.fromRGB(96, 253, 48) -- Green
    elseif Percent >= 45 then
        return Color3.fromRGB(255, 196, 0) -- Yellow
    else
        return Color3.fromRGB(255, 71, 71) -- Red
    end
end

local function getCharacter(plr)
    plr = plr or lplr
    return plr.Character or plr.CharacterAdded:Wait()
end

local function getPlrByCharacter(character)
    for _, plr in next, Players:GetPlayers() do
        if plr.Character == character then
            return plr
        end
    end
end

local function getHumanoid(plr)
    plr = plr or lplr
    if isAlive(plr) then
        return getCharacter(plr):FindFirstChildOfClass("Humanoid")
    end
end

local function getHumanoidRootPart(plr)
    plr = plr or lplr
    if isAlive(plr) then
        return getCharacter(plr):FindFirstChild("HumanoidRootPart")
    end
end

local function getHead(plr)
    plr = plr or lplr
    if isAlive(plr) then
        return getCharacter(plr):FindFirstChild("Head")
    end
end

local function IsVisible(Position, WallCheck, ...)
    if not WallCheck then
        return true
    end
    return #Camera:GetPartsObscuringTarget({Position}, {Camera, LocalPlayer.Character, ...}) == 0
end

local function getClosestPlayerToMouse(Fov, TeamCheck, AimPart, WallCheck)
    local AimFov = Fov
    local TargetPosition = nil
    for _, Player in pairs(Players:GetPlayers()) do
        if Player ~= LocalPlayer then
            local Character = Player.Character
            if isAlive(Player) and Character:FindFirstChild(AimPart) then
                if not TeamCheck or ((TeamCheck and Player.Team ~= LocalPlayer.Team) or (TeamCheck and (Player.Team == nil or Player.Team == "nil") and Player.Neutral == true)) then
                    local ScreenPosition, OnScreen = Camera:WorldToViewportPoint(Character[AimPart].Position)
                    if OnScreen then
                        local ScreenPosition2D = Vector2.new(ScreenPosition.X, ScreenPosition.Y)
                        local NewMagnitude = (ScreenPosition2D - UserInputService:GetMouseLocation()).Magnitude
                        if NewMagnitude < AimFov and IsVisible(Character[AimPart].Position, WallCheck, Character) then
                            AimFov = NewMagnitude
                            TargetPosition = Player
                        end
                    end
                end
            end
        end
    end
    return TargetPosition
end

local function AimAt(Target, Smoothness, AimPart)
    local AimPart = Target.Character:FindFirstChild(AimPart)
    if AimPart then
        local LookAt = nil
        local Distance = (LocalPlayer.Character:FindFirstChild("HumanoidRootPart").Position - Target.Character:FindFirstChild("HumanoidRootPart").Position).Magnitude
        local AdjustedDistance = Distance / 10
        LookAt = Camera.CFrame:PointToWorldSpace(Vector3.new(0, 0, -Smoothness * AdjustedDistance)):Lerp(AimPart.Position, 0.01)
        Camera.CFrame = CFrame.lookAt(Camera.CFrame.Position, LookAt)
    end
end

-- check for CustomAnimations so if any param is missing CustomAnimations wont load, also it was made by ChatGPT (yeah)
local function CheckForAllAnimateParams(Animate)
                print("[Nightix/Universal.lua]: Checking Animate parameters for CustomAnimations...")

    if not Animate then
                warn("[Nightix/Universal.lua]: CustomAnimations can't be loaded, 'Animate' script is missing!")
        return false
    end

    local requiredAnimations = {
        {"idle", "Animation1", "AnimationId"},
        {"idle", "Animation2", "AnimationId"},
        {"walk", "WalkAnim", "AnimationId"},
        {"run", "RunAnim", "AnimationId"},
        {"jump", "JumpAnim", "AnimationId"},
        {"fall", "FallAnim", "AnimationId"},
        {"climb", "ClimbAnim", "AnimationId"},
        {"swim", "Swim", "AnimationId"},
    }

    for _, path in ipairs(requiredAnimations) do
        local current = Animate
        for _, step in ipairs(path) do
            if not current:FindFirstChild(step) then
                warn("[Nightix/Universal.lua]: CustomAnimations can't be loaded, missing: " .. table.concat(path, "."))
                return false
            end
            current = current[step]
        end
    end

            print("[Nightix/Universal.lua]: All Animate parameters are valid, CustomAnimations can be loaded.")
    return true
end



local function FindTouchInterest(Tool)
    return Tool and Tool:FindFirstChildWhichIsA("TouchTransmitter", true)
end

local function findToolWithTouchInterest(plr)
    for _, tool in next, plr.Backpack do
        local touchInterest = FindTouchInterest(tool)
        if touchInterest then
            return tool
        end
    end
    return
end

-- CanClick is from vape
local function CanClick()
    local MousePosition = UserInputService:GetMouseLocation() - Vector2.new(0, 36)
    for i,v in pairs(PlayerGui:GetGuiObjectsAtPosition(MousePosition.X, MousePosition.Y)) do
        if v.Active and v.Visible and v:FindFirstAncestorOfClass("ScreenGui").Enabled then
            return false
        end
    end
    for i,v in pairs(CoreGui:GetGuiObjectsAtPosition(MousePosition.X, MousePosition.Y)) do
        if v.Active and v.Visible and v:FindFirstAncestorOfClass("ScreenGui").Enabled then
            return false
        end
    end
    return true
end

local function GetNearInstances(Radius, Player, RequiredInstance, IgnoreInstances)
    local Instances = {}
    local UselessInstances = {}

    local function IsIgnored(Instance)
        if IgnoreInstances == nil then
            return false
        end
        for _, v in pairs(IgnoreInstances) do
            if Instance:IsA(v) then
                return true
            end
        end
        return false
    end

    for _, Instance in next, workspace:GetDescendants() do
        if (not RequiredInstance or Instance:IsA(RequiredInstance)) and not IsIgnored(Instance) then
            if Instance:IsA("ClickDetector") and RequiredInstance ~= "ClickDetector" then
                Instance = Instance.Parent
            end
            local Distance = (Instance.Position - Player.Character.HumanoidRootPart.Position).Magnitude
            if Distance <= Radius then
                table.insert(Instances, Instance)
            end
        else
            if IsIgnored(Instance) then
                table.insert(UselessInstances, Instance)
            end
        end
    end

    return Instances
end

local function isFriend(name)
    for _, friend in next, playersHandler.players do
        if friend == name or name == friend then
            return true
        end
    end
    return false
end

local function betterDisconnect(connection)
    if typeof(connection) == "RBXScriptConnection" then
        connection:Disconnect()
    end
end

-- // Combat tab
runFunction(function()
    local attackAura = {Enabled = false}
    local range = {Value = 100}
    local cps = {Value = 8}
    local aimPart = {Value = "Голова"}
    local teamCheck = {Value = false}
    local silentRotate = {Value = false}
    local fov = {Value = 360}
    local aimSpeed = {Value = 12}
    local currentTarget = nil
    local oldAutoRotate = true

    local function valid(plr)
        if not plr or plr == LocalPlayer or not isAlive(plr) or not isAlive() then return false end
        if teamCheck.Value and plr.Team and LocalPlayer.Team and plr.Team == LocalPlayer.Team then return false end
        local r = getHumanoidRootPart(plr)
        local mr = getHumanoidRootPart(LocalPlayer)
        local h = getHumanoid(plr)
        return r and mr and h and h.Health > 0 and (r.Position - mr.Position).Magnitude <= range.Value
    end

    local function part(plr)
        local c = getCharacter(plr)
        if not c then return nil end
        return c:FindFirstChild(aimPart.Value == "Голова" and "Head" or "HumanoidRootPart")
            or c:FindFirstChild("HumanoidRootPart")
    end

    local function acquire()
        local mr = getHumanoidRootPart(LocalPlayer)
        if not mr then return nil end
        local best, score = nil, math.huge
        local mousePos = UserInputService:GetMouseLocation()

        for _, plr in ipairs(Players:GetPlayers()) do
            if valid(plr) then
                local a = part(plr)
                if a then
                    local sp, on = Camera:WorldToViewportPoint(a.Position)
                    local d = (a.Position - mr.Position).Magnitude
                    if on and d <= range.Value then
                        local sd = (Vector2.new(sp.X, sp.Y) - mousePos).Magnitude
                        if sd <= fov.Value then
                            local sc = sd + d * 0.15
                            if sc < score then
                                best, score = plr, sc
                            end
                        end
                    end
                end
            end
        end
        return best
    end

    local function aim(plr, dt, forceCamera)
        if not valid(plr) then return end
        local r = getHumanoidRootPart(LocalPlayer)
        local a = part(plr)
        if not r or not a then return end

        local flat = Vector3.new(a.Position.X - r.Position.X, 0, a.Position.Z - r.Position.Z)
        if flat.Magnitude < 0.001 then return end

        local targetYaw = math.atan2(-flat.X, -flat.Z)
        local _, yaw, _ = r.CFrame:ToOrientation()
        local diff = math.atan2(math.sin(targetYaw - yaw), math.cos(targetYaw - yaw))
        local step = math.rad(math.max(1, aimSpeed.Value) * 90) * math.max(dt or 1/60, 1/240)
        local newYaw = yaw + math.clamp(diff, -step, step)

        r.CFrame = CFrame.new(r.Position) * CFrame.Angles(0, newYaw, 0)

        -- Roblox tools commonly resolve their hit from the mouse/camera ray.
        -- Rotate the camera for a real hit instead of only rotating the body.
        if forceCamera or not silentRotate.Value then
            local camPos = Camera.CFrame.Position
            Camera.CFrame = CFrame.lookAt(camPos, a.Position)
        end
    end

    local function clickAttack()
        -- Use both paths: mouse1click drives normal mouse/tool input while
        -- Tool:Activate() covers tools that ignore synthetic mouse input.
        if mouse1click then
            pcall(mouse1click)
        end
        local character = LocalPlayer.Character
        local tool = character and character:FindFirstChildOfClass("Tool")
        if tool then
            pcall(function() tool:Activate() end)
        end
    end

    attackAura = Tabs.Combat:CreateToggle({
        Name = "AttackAura",
        HoverText = "Автоматически наводится на цель и атакует ЛКМ.",
        Callback = function(on)
            if on then
                local h = getHumanoid(LocalPlayer)
                oldAutoRotate = h and h.AutoRotate or true
                if h then h.AutoRotate = false end
                currentTarget = nil

                RunLoops:BindToRenderStep("AttackAuraAim", function(dt)
                    if not attackAura.Enabled then return end
                    if not valid(currentTarget) then
                        currentTarget = acquire()
                    end
                    if currentTarget then
                        -- Camera aiming is intentionally forced so attacks are
                        -- registered on the selected player, not merely beside them.
                        aim(currentTarget, dt, true)
                    end
                end)

                local lastClick = 0
                RunLoops:BindToHeartbeat("AttackAuraClick", function()
                    if attackAura.Enabled and currentTarget and valid(currentTarget)
                        and not GuiLibrary.Toggled and not UserInputService:GetFocusedTextBox() then
                        local now = tick()
                        if now - lastClick >= 1 / math.max(1, cps.Value) then
                            lastClick = now
                            clickAttack()
                        end
                    end
                end)
            else
                RunLoops:UnbindFromRenderStep("AttackAuraAim")
                RunLoops:UnbindFromHeartbeat("AttackAuraClick")
                currentTarget = nil
                local h = getHumanoid(LocalPlayer)
                if h then h.AutoRotate = oldAutoRotate end
            end
        end
    })

    range = attackAura:CreateSlider({Name="Дальность", Function=function() end, Min=1, Max=100, Default=100, Round=0})
    cps = attackAura:CreateSlider({Name="CPS", Function=function() end, Min=1, Max=30, Default=8, Round=0})
    fov = attackAura:CreateSlider({Name="FOV", Function=function() end, Min=10, Max=360, Default=360, Round=0})
    aimSpeed = attackAura:CreateSlider({Name="Скорость наведения", Function=function() end, Min=1, Max=30, Default=12, Round=0})
    aimPart = attackAura:CreateDropdown({Name="Часть наведения", Function=function() end, List={"Голова","Тело"}, Default="Голова"})
    teamCheck = attackAura:CreateToggle({Name="Проверка команды", Default=false, Function=function() end})
    silentRotate = attackAura:CreateToggle({Name="Без поворота камеры", Default=false, Function=function() end})

    shared.NightixAttackAuraTarget = function()
        return currentTarget
    end
end)

-- TriggerBot: uses the same target/rotation path as AttackAura, but only
-- attacks a player that is currently under the crosshair.
runFunction(function()
    local triggerBot = {Enabled = false}
    local range = {Value = 100}
    local cps = {Value = 10}
    local aimSpeed = {Value = 20}
    local teamCheck = {Value = false}
    local lastClick = 0

    local function validTarget(plr)
        if not plr or plr == LocalPlayer or not isAlive(plr) or not isAlive() then return false end
        if teamCheck.Value and plr.Team and LocalPlayer.Team and plr.Team == LocalPlayer.Team then return false end
        local root = getHumanoidRootPart(plr)
        local me = getHumanoidRootPart(LocalPlayer)
        local hum = getHumanoid(plr)
        return root and me and hum and hum.Health > 0
            and (root.Position - me.Position).Magnitude <= range.Value
    end

    local function targetUnderCursor()
        local mousePos = UserInputService:GetMouseLocation()
        local best, bestScore = nil, math.huge

        for _, plr in ipairs(Players:GetPlayers()) do
            if validTarget(plr) then
                local character = getCharacter(plr)
                local head = character and character:FindFirstChild("Head")
                local root = getHumanoidRootPart(plr)
                local point = head or root
                if point then
                    local screen, visible = Camera:WorldToViewportPoint(point.Position)
                    if visible then
                        local distance2d = (Vector2.new(screen.X, screen.Y) - mousePos).Magnitude
                        if distance2d < bestScore then
                            best, bestScore = plr, distance2d
                        end
                    end
                end
            end
        end

        -- A small cursor tolerance avoids TriggerBot firing through the world
        -- at players that are merely somewhere on screen.
        return best, bestScore
    end

    local function rotateTo(plr, dt)
        local root = getHumanoidRootPart(plr)
        local me = getHumanoidRootPart(LocalPlayer)
        if not root or not me then return end
        local flat = Vector3.new(root.Position.X-me.Position.X,0,root.Position.Z-me.Position.Z)
        if flat.Magnitude < .001 then return end
        local targetYaw = math.atan2(-flat.X,-flat.Z)
        local _, yaw, _ = me.CFrame:ToOrientation()
        local diff = math.atan2(math.sin(targetYaw-yaw), math.cos(targetYaw-yaw))
        local step = math.rad(math.max(1, aimSpeed.Value)*90) * math.max(dt or 1/60,1/240)
        me.CFrame = CFrame.new(me.Position) * CFrame.Angles(0, yaw + math.clamp(diff,-step,step), 0)
        Camera.CFrame = CFrame.lookAt(Camera.CFrame.Position, (getCharacter(plr):FindFirstChild("Head") or root).Position)
    end

    local function attack()
        if mouse1click then pcall(mouse1click) end
        local character = LocalPlayer.Character
        local tool = character and character:FindFirstChildOfClass("Tool")
        if tool then pcall(function() tool:Activate() end) end
    end

    triggerBot = Tabs.Combat:CreateToggle({
        Name = "TriggerBot",
        HoverText = "Автоматически атакует игрока под прицелом.",
        Callback = function(on)
            if on then
                RunLoops:BindToRenderStep("TriggerBot", function(dt)
                    if not triggerBot.Enabled or GuiLibrary.Toggled or UserInputService:GetFocusedTextBox() then return end
                    local target, screenDistance = targetUnderCursor()
                    if target and screenDistance <= 55 then
                        rotateTo(target, dt)
                        local now = tick()
                        if now-lastClick >= 1/math.max(1,cps.Value) then
                            lastClick = now
                            attack()
                        end
                    end
                end)
            else
                RunLoops:UnbindFromRenderStep("TriggerBot")
            end
        end
    })

    range = triggerBot:CreateSlider({Name="Дальность", Function=function(v) range.Value=v end, Min=1, Max=100, Default=100, Round=0})
    cps = triggerBot:CreateSlider({Name="CPS", Function=function(v) cps.Value=v end, Min=1, Max=30, Default=10, Round=0})
    aimSpeed = triggerBot:CreateSlider({Name="Скорость наведения", Function=function(v) aimSpeed.Value=v end, Min=1, Max=30, Default=20, Round=0})
    teamCheck = triggerBot:CreateToggle({Name="Проверка команды", Default=false, Function=function(v) teamCheck.Value=v end})
end)

-- // Movement tab
runFunction(function()
    local autoWalk = {Enabled = false}
    autoWalk = Tabs.Movement:CreateToggle({
        Name = "AutoWalk",
        HoverText = "Automatically walks forward for you.",
        Callback = function(callback)
            if callback then
                RunLoops:BindToRenderStep("AutoWalk", function()
                    if isAlive() then
                        getHumanoid(LocalPlayer):Move(Vector3.new(0, 0, -1), true)
                    end
                end)
            else
                RunLoops:UnbindFromRenderStep("AutoWalk")
            end
        end
    })
end)

runFunction(function()
    local clickTP = {Enabled = false}
    local mode = {Value = "Click"}
    local tool
    local connection
    local connection2
    local function tp()
        if isAlive() then
            getHumanoidRootPart(LocalPlayer).CFrame = Mouse.Hit + Vector3.new(0, 3, 0)
        end 
    end
    clickTP = Tabs.Movement:CreateToggle({
        Name = "ClickTP",
        HoverText = "Teleports you to where you clicked.",
        Callback = function(callback) 
            if callback then
                if mode.Value == "Tool" then
                    tool = Instance.new("Tool")
                    tool.Name = "TPTool"
                    tool.Parent = Backpack
                    tool.RequiresHandle = false
                    tool.Activated:Connect(tp)
                elseif mode.Value == "Click" then
                    connection = Mouse.Button1Down:Connect(tp)
                elseif mode.Value == "RightClick" then
                    connection2 = Mouse.Button2Down:Connect(tp)
                end
            else
                if connection then 
                    connection:Disconnect()
                    connection = nil
                end
                if connection2 then 
                    connection2:Disconnect()
                    connection2 = nil
                end
                if tool then
                    tool:Destroy()
                end
            end
        end
    })

    mode = clickTP:CreateDropdown({
        Name = "Mode",
        Function = function(v)
            if clickTP.Enabled then clickTP:ReToggle() end
        end,
        List = {"Click", "RightClick", "Tool"},
        Default = "Click"
    })
end)

runFunction(function()
    local fastFall = {Enabled = false}
    local height = {Value = 5}
    local ticks = {Value = 5}
    fastFall = Tabs.Movement:CreateToggle({
        Name = "FastFall",
        HoverText = "Makes you fall faster.",
        Callback = function(callback)
            if callback then
                spawn(function() 
                    repeat task.wait()
                        if isAlive() then
                            local humanoid = getHumanoid(LocalPlayer)
                            local humanoidRootPart = getHumanoidRootPart(LocalPlayer)
                            local params = RaycastParams.new()
                            params.FilterDescendantsInstances = {LocalPlayer.Character}
                            params.FilterType = Enum.RaycastFilterType.Blacklist
                            local raycast = workspace:Raycast(humanoidRootPart.Position, Vector3.new(0, -height.Value * 3, 0), params)
                            if raycast and raycast.Instance then 
                                local velocity = humanoidRootPart.Velocity
                                if humanoid:GetState() == Enum.HumanoidStateType.Freefall and velocity.Y < 0 then 
                                    humanoidRootPart.Velocity = Vector3.new(velocity.X, -(ticks.Value * 30), velocity.Z)
                                end
                            end
                        end
                    until not fastFall.Enabled
                end)
            end
        end
    })
    
    height = fastFall:CreateSlider({
        Name = "FallHeight",
        Function = function(v) end,
        Min = 1,
        Max = 10,
        Default = 7,
        Round = 1
    })

    ticks = fastFall:CreateSlider({
        Name = "Ticks",
        Function = function(v) end,
        Min = 1,
        Max = 5,
        Default = 1,
        Round = 0
    })
end)

-- // fps based a little bit :sob:
-- // 60 fps is the best to avoid going down
runFunction(function()
    local fly = {Enabled = false}
    local mode = {Value = "Normal"}
    local keyboardMode = {Value = "LeftShift+Space"}
    local speed = {Value = 23}
    local verticalSpeed = {Value = 20}
    local linearVelocity
    fly = Tabs.Movement:CreateToggle({
        Name = "Fly",
        HoverText = "Makes you fly.\nFPS based, recommended FPS is 60.",
        Callback = function(callback)
            if callback then
                RunLoops:BindToHeartbeat("Fly", function(Delta)
                    local humanoid = getHumanoid(LocalPlayer)
                    local humanoidRootPart = getHumanoidRootPart(LocalPlayer)
                    local moveDirection = humanoid.MoveDirection
                    local velocity = humanoidRootPart.Velocity
                    local xDirection = moveDirection.X * speed.Value
                    local zDirection = moveDirection.Z * speed.Value
                    local yDirection = 0
                    local yVelocity = (math.abs(yDirection) < 0.1 and (workspace.Gravity * Delta * 0.6325)) or yDirection

                    if verticalSpeed.Value > 0 then
                        if UserInputService:IsKeyDown(Enum.KeyCode.Space) and (keyboardMode.Value == "LeftShift+Space" or keyboardMode.Value == "LeftCtrl+Space") then
                            yDirection = verticalSpeed.Value
                        elseif UserInputService:IsKeyDown(Enum.KeyCode.E) and keyboardMode.Value == "Q+E" then
                            yDirection = verticalSpeed.Value
                        elseif UserInputService:IsKeyDown(Enum.KeyCode.LeftShift) and keyboardMode.Value == "LeftShift+Space" then
                            yDirection = -verticalSpeed.Value
                        elseif UserInputService:IsKeyDown(Enum.KeyCode.LeftControl) and keyboardMode.Value == "LeftShift+Space" then
                            yDirection = -verticalSpeed.Value
                        elseif UserInputService:IsKeyDown(Enum.KeyCode.Q) and keyboardMode.Value == "Q+E" then
                            yDirection = -verticalSpeed.Value
                        end
                    end

                    if mode.Value == "AssemblyAngularVelocity" then
                        humanoidRootPart.AssemblyAngularVelocity = Vector3.new(0, 0, 0)
                        humanoidRootPart.AssemblyLinearVelocity = Vector3.new(xDirection, yVelocity, zDirection)
                    elseif mode.Value == "AssemblyLinearVelocity" then
                        humanoidRootPart.AssemblyLinearVelocity = Vector3.new(xDirection, yVelocity, zDirection)
                    elseif mode.Value == "LinearVelocity" then
                        linearVelocity = linearVelocity or Instance.new("LinearVelocity", humanoidRootPart)
                        linearVelocity.Attachment0 = humanoidRootPart:FindFirstChildWhichIsA("Attachment")
                        linearVelocity.MaxForce = math.huge
                        linearVelocity.VectorVelocity = Vector3.new(xDirection, yDirection, zDirection)
                    elseif mode.Value == "Velocity" then
                        humanoidRootPart.Velocity = Vector3.new(xDirection, yVelocity, zDirection)
                    elseif mode.Value == "CFrame" then
                        local factor = speed.Value - humanoid.WalkSpeed
                        local newMoveDirection = (moveDirection * factor) * Delta
                        local newCFrame = humanoidRootPart.CFrame + Vector3.new(newMoveDirection.X, yDirection * Delta, newMoveDirection.Z)
                        humanoidRootPart.CFrame = newCFrame
                        humanoidRootPart.Velocity = Vector3.zero
                    end
                end)
            else
                RunLoops:UnbindFromHeartbeat("Fly")
                if linearVelocity then
                    linearVelocity:Destroy()
                    linearVelocity = nil
                end
            end
        end
    })

    mode = fly:CreateDropdown({
        Name = "Mode",
        Function = function(v) 
            if speed.Container then speed.Container.Visible = v == "CFrame" end
        end,
        List = {"AssemblyAngularVelocity", "AssemblyLinearVelocity", "LinearVelocity", "Velocity", "CFrame"},
        Default = "Velocity"
    })

    speed = fly:CreateSlider({
        Name = "Speed",
        Function = function(v) end,
        Min = 1,
        Max = 100,
        Default = 23,
        Round = 0
    })
    speed.Container.Visible = false

    keyboardMode = fly:CreateDropdown({
        Name = "KeyboardMode",
        Function = function(v) end,
        List = {"LeftShift+Space", "Q+E", "LeftCtrl+Space"},
        Default = "LeftShift+Space"
    })

    verticalSpeed = fly:CreateSlider({
        Name = "VerticalSpeed",
        Function = function(v) end,
        Min = 1,
        Max = 100,
        Default = 20,
        Round = 0
    })
end)

runFunction(function()
    local forwardTP = {Enabled = false}
    local studs = {Value = 5}
    local teleporting = false
    forwardTP = Tabs.Movement:CreateToggle({
        Name = "ForwardTP",
        HoverText = "Teleports you forward.",
        Callback = function(callback)
            if callback and not teleporting then
                teleporting = true
                if isAlive() then
                    local humanoid = getHumanoid(LocalPlayer)
                    local humanoidRootPart = getHumanoidRootPart(LocalPlayer)
                    local look = humanoidRootPart.CFrame.LookVector
                    if humanoid.MoveDirection.Magnitude > 0 or Humanoid:GetState() == Enum.HumanoidStateType.Running then
                        local forward = look * studs.Value
                        humanoidRootPart.CFrame = humanoidRootPart.CFrame + forward
                    end
                end
                teleporting = false
                forwardTP:Toggle(true, false)
            end
        end
    })
    
    studs = forwardTP:CreateSlider({
        Name = "Studs",
        Function = function(v) end,
        Min = 1,
        Max = 50,
        Default = 5,
        Round = 0
    })
end)


--[[somewhen later
runFunction(function()
    local ForwardTPMode = {Value = "TP"}
    local ForwardTPValue = {Value = 5}
    local ForwardTPTweenTime = {Value = 0.1}
    local Teleporting = false
    
    ForwardTP = Tabs.Movement:CreateToggle({
        Name = "ForwardTP",
        Keybind = nil,
        Callback = function(callback)
            if callback and not Teleporting then
                if isAlive() then
                    Teleporting = true
                    local Humanoid = LocalPlayer.Character.Humanoid
                    local HumanoidRootPart = LocalPlayer.Character.HumanoidRootPart
                    local LookVector = HumanoidRootPart.LookVector
                    if Humanoid.MoveDirection.Magnitude > 0 or Humanoid:GetState() == Enum.HumanoidStateType.Running then
                        local ForwardVector = LookVector * ForwardTPValue.Value
                        if ForwardTPMode.Value == "TP" then
                            HumanoidRootPart.CFrame = HumanoidRootPart.CFrame + ForwardVector
                        elseif ForwardTPMode.Value == "Tween" then
                            local ForwardTweenInfo = TweenInfo.new(ForwardTPTweenTime.Value)
                            local Tween = TweenService:Create(HumanoidRootPart, ForwardTweenInfo, {Position = HumanoidRootPart.Position + ForwardVector})
                            Tween:Play()
                            wait(ForwardTPTweenTime.Value)
                            Tween:Cancel()
                        end
                    end
                else
                    ForwardTP:Toggle(false, false)
                end
                Teleporting = false
                ForwardTP:Toggle(false, false)
            end
        end
    })

    ForwardTPMode = ForwardTP:CreateDropdown({
        Name = "Mode",
        List = {"TP", "Tween"},
        Default = "TP",
        Function = function(v) 
            if v == "Tween" then
                if ForwardTPTweenTime.MainObject then
                    ForwardTPTweenTime.MainObject.Visible = true
                end
            elseif v == "TP" then
                if ForwardTPTweenTime.MainObject then
                    ForwardTPTweenTime.MainObject.Visible = false
                end
            end
        end
    })
    
    ForwardTPTweenTime = ForwardTP:CreateSlider({
        Name = "Tween Time",
        Function = function(v) end,
        Min = 0,
        Max = 5,
        Default = 0.1,
        Round = 1
    })
    
    ForwardTPValue = ForwardTP:CreateSlider({
        Name = "Studs",
        Function = function(v) end,
        Min = 1,
        Max = 50,
        Default = 5,
        Round = 0
    })
end)
]]

runFunction(function()
    local highJump = {Enabled = false}
    local jumpMode = {Value = "Velocity"}
    local jumps = {Value = 5}
    local mode = {Value = "Toggle"}
    local height = {Value = 20}
    local connection
    local linearVelocity

    local function jump()
        local humanoid = getHumanoid(LocalPlayer)
        local humanoidRootPart = getHumanoidRootPart(LocalPlayer)
        if jumpMode.Value == "AssemblyAngularVelocity" then
            humanoidRootPart.AssemblyAngularVelocity = Vector3.new(0, 0, 0)
            humanoidRootPart.AssemblyLinearVelocity = Vector3.new(0, height.Value, 0)
        elseif jumpMode.Value == "AssemblyLinearVelocity" then
            humanoidRootPart.AssemblyLinearVelocity = Vector3.new(0, height.Value, 0)
        elseif jumpMode.Value == "LinearVelocity" then
            linearVelocity = Instance.new("LinearVelocity", humanoidRootPart)
            linearVelocity.Attachment0 = humanoidRootPart:FindFirstChildWhichIsA("Attachment")
            linearVelocity.MaxForce = math.huge
            linearVelocity.VectorVelocity = Vector3.new(0, height.Value, 0)
            task.wait(0.1)
            linearVelocity:Destroy()
        elseif jumpMode.Value == "Velocity" then
            humanoid:ChangeState(Enum.HumanoidStateType.Jumping)
            humanoidRootPart.Velocity = humanoidRootPart.Velocity + Vector3.new(0, height.Value, 0)
        elseif jumpMode.Value == "TP" then
            humanoidRootPart.CFrame = humanoidRootPart.CFrame + Vector3.new(0, height.Value, 0)
        elseif jumpMode.Value == "Jump" then
            spawn(function()
                for i = 1, jumps.Value do
                    task.wait()
                    humanoid:ChangeState(Enum.HumanoidStateType.Jumping)
                end
            end)
        end
    end

    highJump = Tabs.Movement:CreateToggle({
        Name = "HighJump",
        HoverText = "Makes you jump higher.",
        Callback = function(callback)
            if callback then
                if mode.Value == "Toggle" then
                    jump()
                    highJump:Toggle(true)
                elseif mode.Value == "Normal" then
                    connection = UserInputService.JumpRequest:Connect(function()
                        jump()
                    end)
                    table.insert(connections, connection)
                end
            else
                betterDisconnect(connection)
                --workspace.Gravity = 196.19999694824
            end
        end
    })

    jumpMode = highJump:CreateDropdown({
        Name = "JumpMode",
        Function = function(v) 
            if mode.MainObject then
                mode.MainObject.Visible = v == "Jump"
            end
        end,
        List = {"AssemblyAngularVelocity", "AssemblyLinearVelocity", "LinearVelocity", "Velocity", "TP", "Jump"},
        Default = "Velocity"
    })

    mode = highJump:CreateDropdown({
        Name = "Mode",
        Callback = function(v) end,
        List = {"Toggle", "Normal"},
        Default = "Toggle"
    })

    jumps = highJump:CreateSlider({
        Name = "Jumps",
        Function = function() end,
        Min = 0,
        Max = 100,
        Default = 5,
        Round = 0
    })

    height = highJump:CreateSlider({
        Name = "Height",
        Function = function() end,
        Min = 0,
        Max = 100,
        Default = 25,
        Round = 0
    })
end)

runFunction(function()
    local longJump = {Enabled = false}
    local mode = {Value = "Velocity"}
    local power = {Value = 50}

    longJump = Tabs.Movement:CreateToggle({
        Name = "LongJump",
        HoverText = "Makes you jump forward.",
        Callback = function(callback)
            if callback then
                local humanoid = getHumanoid(LocalPlayer)
                local humanoidRootPart = getHumanoidRootPart(LocalPlayer)
                local oldCFrame = humanoidRootPart.CFrame
                local oldVelocity = humanoidRootPart.Velocity
                local direction = humanoidRootPart.CFrame.LookVector

                humanoid:ChangeState(Enum.HumanoidStateType.Jumping)

                if mode.Value == "AssemblyAngularVelocity" then
                    humanoidRootPart.AssemblyAngularVelocity = Vector3.new(0, 0, 0)
                    humanoidRootPart.AssemblyLinearVelocity = Vector3.new(direction.X * power.Value, oldVelocity.Y, direction.Z * power.Value)
                elseif mode.Value == "AssemblyLinearVelocity" then
                    humanoidRootPart.AssemblyLinearVelocity = Vector3.new(direction.X * power.Value, oldVelocity.Y, direction.Z * power.Value)
                elseif mode.Value == "LinearVelocity" then
                    local linearVelocity = Instance.new("LinearVelocity")
                    linearVelocity.Attachment0 = humanoidRootPart:FindFirstChildWhichIsA("Attachment")
                    linearVelocity.MaxForce = math.huge
                    linearVelocity.VectorVelocity = Vector3.new(direction.X * power.Value, oldVelocity.Y, direction.Z * power.Value)
                    linearVelocity.Parent = humanoidRootPart
                    task.wait(0.1)
                    linearVelocity:Destroy()
                elseif mode.Value == "Velocity" then
                    local NewVelocity = oldVelocity * power.Value
                    humanoidRootPart.Velocity = Vector3.new(NewVelocity.X, oldVelocity.Y, NewVelocity.X)
                elseif mode.Value == "CFrame" then
                    local newCFrame = oldCFrame * CFrame.new(direction.X * power.Value, 0, direction.Z * power.Value)
                    humanoidRootPart.CFrame = CFrame.new(newCFrame.X, oldCFrame.Y, newCFrame.Z)
                end

                longJump:Toggle(true)
            end
        end
    })

    mode = longJump:CreateDropdown({
        Name = "Mode",
        Function = function(v) end,
        List = {"AssemblyAngularVelocity", "AssemblyLinearVelocity", "LinearVelocity", "Velocity", "CFrame"},
        Default = "Velocity"
    })

    power = longJump:CreateSlider({
        Name = "Power",
        Function = function(v) end,
        Min = 1,
        Max = 1000,
        Default = 100,
        Round = 0
    })
end)

runFunction(function()
    local phase = {Enabled = false}
    local parts = {}
    phase = Tabs.Movement:CreateToggle({
        Name = "Phase",
        HoverText = "Makes you walk through walls.",
        Callback = function(callback) 
            if callback then 
                if isAlive() then
                    RunLoops:BindToStepped("Phase", function()
                        for i, v in pairs(getCharacter(LocalPlayer):GetChildren()) do 
                            if v:IsA("BasePart") and v.CanCollide then 
                                parts[v] = v
                                v.CanCollide = false
                            end
                        end
                    end)
                end
            else
                for i, v in next, parts do
                    v.CanCollide = true
                end
                parts = {}
                RunLoops:UnbindFromStepped("Phase")
            end
        end
    })
end)

runFunction(function()
    local speed={Enabled=false}; local mode={Value="CFrame"}; local value={Value=50}; local autoJump={Value=false}; local jumpMode={Value="Normal"}; local autoJumpPower={Value=25}; local jumpPower={Value=50}; local noAnim={Value=false}; local shiftHold={Value=false}; local holdingShift=false; local savedWalkSpeed; local savedJumpPower; local savedUseJumpPower; local savedAnimateDisabled; local c1; local c2
    speed=Tabs.Movement:CreateToggle({Name="Speed",HoverText="Ускоряет передвижение игрока.",Callback=function(on)
        if on then
            local h=getHumanoid(LocalPlayer); local c=getCharacter(LocalPlayer); savedWalkSpeed=h and h.WalkSpeed or 16; savedJumpPower=h and h.JumpPower or 50; savedUseJumpPower=h and h.UseJumpPower; local a=c and c:FindFirstChild("Animate"); savedAnimateDisabled=a and a.Disabled or false; holdingShift=false
            betterDisconnect(c1); betterDisconnect(c2); c1=UserInputService.InputBegan:Connect(function(i,g) if i.KeyCode==Enum.KeyCode.LeftShift and not g then holdingShift=true end end); c2=UserInputService.InputEnded:Connect(function(i) if i.KeyCode==Enum.KeyCode.LeftShift then holdingShift=false end end)
            RunLoops:BindToHeartbeat("Speed",function(dt)
                if not isAlive() or (shiftHold.Value and not holdingShift) then return end
                local hum=getHumanoid(LocalPlayer); local root=getHumanoidRootPart(LocalPlayer); if not hum or not root then return end
                hum.UseJumpPower=true; hum.JumpPower=jumpPower.Value; hum.WalkSpeed=math.max(16,value.Value)
                local d=hum.MoveDirection
                if d.Magnitude>.01 then
                    d=Vector3.new(d.X,0,d.Z).Unit
                    if mode.Value=="Velocity" then local v=root.AssemblyLinearVelocity; root.AssemblyLinearVelocity=Vector3.new(d.X*value.Value,v.Y,d.Z*value.Value)
                    elseif mode.Value=="CFrame" then root.CFrame=root.CFrame+d*math.max(0,value.Value-16)*math.max(dt,1/240) end
                end
                if autoJump.Value and hum.FloorMaterial~=Enum.Material.Air and d.Magnitude>.01 then if jumpMode.Value=="Normal" then hum:ChangeState(Enum.HumanoidStateType.Jumping) else local v=root.AssemblyLinearVelocity; root.AssemblyLinearVelocity=Vector3.new(v.X,autoJumpPower.Value,v.Z) end end
                local anim=getCharacter(LocalPlayer):FindFirstChild("Animate"); if anim then anim.Disabled=noAnim.Value end
            end)
        else
            RunLoops:UnbindFromHeartbeat("Speed"); local h=getHumanoid(LocalPlayer); if h then h.WalkSpeed=savedWalkSpeed or 16; h.JumpPower=savedJumpPower or 50; if savedUseJumpPower~=nil then h.UseJumpPower=savedUseJumpPower end end; local a=getCharacter(LocalPlayer):FindFirstChild("Animate"); if a then a.Disabled=savedAnimateDisabled or false end; betterDisconnect(c1); betterDisconnect(c2); c1=nil; c2=nil; holdingShift=false
        end
    end})
    mode=speed:CreateDropdown({Name="Режим",List={"Velocity","CFrame","Normal"},Default="CFrame",Function=function(v) mode.Value=v end})
    value=speed:CreateSlider({Name="Скорость",Function=function(v) value.Value=v end,Min=0,Max=200,Default=50,Round=0})
    autoJumpPower=speed:CreateSlider({Name="Сила автопрыжка",Function=function(v) autoJumpPower.Value=v end,Min=0,Max=30,Default=25,Round=0})
    jumpPower=speed:CreateSlider({Name="Сила прыжка",Function=function(v) jumpPower.Value=v end,Min=0,Max=200,Default=50,Round=0})
    autoJump=speed:CreateToggle({Name="Автопрыжок",Default=false,Function=function(v) autoJump.Value=v end})
    jumpMode=speed:CreateDropdown({Name="Режим автопрыжка",List={"Normal","Velocity"},Default="Normal",Function=function(v) jumpMode.Value=v end})
    noAnim=speed:CreateToggle({Name="Без анимации",Default=false,Function=function(v) noAnim.Value=v end})
    shiftHold=speed:CreateToggle({Name="Только с Shift",Default=false,Function=function(v) shiftHold.Value=v end})
end)

runFunction(function()
    local spinBot = {Enabled = false}
    local spinBotSpeed = {Value = 360}
    local spinBotX = {Value = false}
    local spinBotY = {Value = true}
    local spinBotZ = {Value = false}
    local oldAutoRotate = true

    spinBot = Tabs.Movement:CreateToggle({
        Name = "SpinBot",
        HoverText = "Rotates the character without writing to Camera.CFrame.",
        Callback = function(enabled)
            if enabled then
                local humanoid = getHumanoid(LocalPlayer)
                oldAutoRotate = humanoid and humanoid.AutoRotate or true
                if humanoid then humanoid.AutoRotate = false end
                RunLoops:BindToHeartbeat("SpinBot", function(dt)
                    local root = getHumanoidRootPart(LocalPlayer)
                    if not root then return end
                    local x = spinBotX.Value and 1 or 0
                    local y = spinBotY.Value and 1 or 0
                    local z = spinBotZ.Value and 1 or 0
                    if x == 0 and y == 0 and z == 0 then return end
                    local step = math.rad(spinBotSpeed.Value) * math.max(dt, 1 / 240)
                    root.CFrame = root.CFrame * CFrame.Angles(step * x, step * y, step * z)
                end)
            else
                RunLoops:UnbindFromHeartbeat("SpinBot")
                local humanoid = getHumanoid(LocalPlayer)
                if humanoid then humanoid.AutoRotate = oldAutoRotate end
            end
        end
    })

    spinBotSpeed = spinBot:CreateSlider({
        Name = "SpinSpeed",
        Function = function() end,
        Min = 1,
        Max = 3600,
        Default = 360,
        Round = 0
    })
    spinBotX = spinBot:CreateToggle({Name = "Spin X", Default = false, Function = function() end})
    spinBotY = spinBot:CreateToggle({Name = "Spin Y", Default = true, Function = function() end})
    spinBotZ = spinBot:CreateToggle({Name = "Spin Z", Default = false, Function = function() end})
end)

-- // Render tab
runFunction(function()
    local breadcrumbs = {Enabled = false}
    local mode = {Value = "Trail"}
    local color = {Value = Color3.fromRGB(255, 255, 255)}
    local startColor = {Value = Color3.fromRGB(255, 255, 255)}
    local endColor = {Value = Color3.fromRGB(255, 255, 255)}
    local size = {Value = 0.5}
    local distance = {Value = 1}
    local lifeTime = {Value = 20}
    local transparency = {Value = 0}
    local objects = Instance.new("Folder", workspace)
    objects.Name = "breadcrumbsObjects"
    local trail
	local attachment
	local attachment2
    local lastPos
    --local objects = {}
    breadcrumbs = Tabs.Render:CreateToggle({
        Name = "Breadcrumbs",
        HoverText = "Creates a trail behind you.",
        Callback = function(callback)
            if callback then
                task.spawn(function()
					repeat
						if isAlive() then
                            local humanoidRootPart = getHumanoidRootPart()
                            if mode.Value == "Trail" then
                                if not trail then
                                    attachment = Instance.new("Attachment")
                                    attachment.Position = Vector3.new(0, 0.07 - 2.7, 0)
                                    attachment2 = Instance.new("Attachment")
                                    attachment2.Position = Vector3.new(0, -0.07 - 2.7, 0)
                                    trail = Instance.new("Trail")
                                    trail.Attachment0 = attachment
                                    trail.Attachment1 = attachment2
                                    trail.Color = ColorSequence.new(startColor.Value, endColor.Value)
                                    trail.FaceCamera = true
                                    trail.Lifetime = lifeTime.Value / 10
                                    trail.Enabled = true
                                else
                                    local Succes = pcall(function()
                                        attachment.Parent = humanoidRootPart
                                        attachment2.Parent = humanoidRootPart
                                        trail.Parent = Camera
                                    end)
                                    if not Succes then
                                        if trail then trail:Destroy() trail = nil end
                                        if attachment then attachment:Destroy() attachment = nil end
                                        if attachment2 then attachment2:Destroy() attachment2 = nil end
                                    end
                                end
                            elseif mode.Value == "Spheres" then
                                if (lastPos and (humanoidRootPart.Position - lastPos).Magnitude > distance.Value) or not lastPos then
                                    local sphere = Instance.new("Part", objects)
                                    sphere.Shape = Enum.PartType.Ball
                                    sphere.Size = Vector3.new(0.5, 0.5, 0.5)
                                    sphere.Color = color.Value
                                    sphere.Material = Enum.Material.Plastic
                                    sphere.CanCollide = false
                                    sphere.Anchored = true
                                    sphere.CFrame = humanoidRootPart.CFrame * CFrame.new(0, -2, 0)
                                    sphere.Transparency = transparency.Value
                                    sphere.TopSurface = Enum.SurfaceType.Smooth
                                    sphere.BottomSurface = Enum.SurfaceType.Smooth
                                    sphere.FrontSurface = Enum.SurfaceType.Smooth
                                    sphere.BackSurface = Enum.SurfaceType.Smooth
                                    sphere.LeftSurface = Enum.SurfaceType.Smooth
                                    sphere.RightSurface = Enum.SurfaceType.Smooth
                                    debris:AddItem(sphere, lifeTime.Value)
                                    lastPos = humanoidRootPart.Position
                                end
                            elseif mode.Value == "Cubes" then
                                if (lastPos and (humanoidRootPart.Position - lastPos).Magnitude > distance.Value) or not lastPos then
                                    local cube = Instance.new("Part", objects)
                                    cube.Size = Vector3.new(0.5, 0.5, 0.5)
                                    cube.Color = color.Value
                                    cube.Material = Enum.Material.Plastic
                                    cube.CanCollide = false
                                    cube.Anchored = true
                                    cube.CFrame = humanoidRootPart.CFrame * CFrame.new(0, -2, 0)
                                    cube.Transparency = transparency.Value
                                    cube.TopSurface = Enum.SurfaceType.Smooth
                                    cube.BottomSurface = Enum.SurfaceType.Smooth
                                    cube.FrontSurface = Enum.SurfaceType.Smooth
                                    cube.BackSurface = Enum.SurfaceType.Smooth
                                    cube.LeftSurface = Enum.SurfaceType.Smooth
                                    cube.RightSurface = Enum.SurfaceType.Smooth
                                    debris:AddItem(cube, lifeTime.Value)
                                    lastPos = humanoidRootPart.Position
                                end
                            end
						end
                        task.wait()
					until not breadcrumbs.Enabled
				end)
            else
                if trail then
                    trail:Destroy()
                    trail = nil
                end
				if attachment then
                    attachment:Destroy()
                    attachment = nil
                end
				if attachment2 then
                    attachment2:Destroy()
                    attachment2 = nil
                end
                for _, object in pairs(objects) do
                    object:Destroy()
                end
            end
        end
    })

    mode = breadcrumbs:CreateDropdown({
        Name = "Mode",
        List = {"Trail", "Spheres", "Cubes"},
        Default = "Trail",
        Function = function(v)
            if startColor.MainObject then startColor.MainObject.Visible = v == "Trail" end
            if endColor.MainObject then endColor.MainObject.Visible = v == "Trail" end
            if color.MainObject then color.MainObject.Visible = v ~= "Trail" end
            if size.MainObject then size.MainObject.Visible = v ~= "Trail" end
            if distance.MainObject then distance.MainObject.Visible = v ~= "Trail" end
        end
    })

    startColor = breadcrumbs:CreateColorSlider({
        Name = "Start color",
        Default = Color3.fromRGB(255, 255, 255),
        Function = function(v)
            if trail then
                trail.Color = ColorSequence.new(v, endColor.Value)
            end
        end
    })

    endColor = breadcrumbs:CreateColorSlider({
        Name = "End color",
        Default = Color3.fromRGB(255, 255, 255),
        Function = function(v)
            if trail then
                trail.Color = ColorSequence.new(startColor.Value, v)
            end
        end
    })

    color = breadcrumbs:CreateColorSlider({
        Name = "Color",
        Default = Color3.fromRGB(255, 255, 255),
        Function = function(v)
            if breadcrumbs.Enabled then
                for _, obj in next, objects:GetChildren() do
                    obj.Color = v
                end
            end
        end
    })
    color.MainObject.Visible = false

    size = breadcrumbs:CreateSlider({
        Name = "Size",
        Function = function(v)
            if breadcrumbs.Enabled then
                for _, obj in next, objects:GetChildren() do
                    obj.Size = Vector3.new(v, v, v)
                end
            end
        end,
        Min = 0.1,
        Max = 5,
        Default = 1,
        Round = 1
    })
    size.MainObject.Visible = false

    distance = breadcrumbs:CreateSlider({
        Name = "Distance",
        Function = function(v) end,
        Min = 0.1,
        Max = 10,
        Default = 1,
        Round = 1
    })

    lifeTime = breadcrumbs:CreateSlider({
        Name = "LifeTime",
        Function = function(v) end,
        Min = 1,
        Max = 100,
        Default = 10,
        Round = 0
    })

    transparency = breadcrumbs:CreateSlider({
        Name = "Transparency",
        Function = function(v)
            if breadcrumbs.Enabled then
                for _, obj in next, objects:GetChildren() do
                    obj.Transparency = v
                end
            end
        end,
        Min = 0,
        Max = 1,
        Default = 0,
        Round = 1
    })
end)

runFunction(function()
    local camFix = {Enabled = false}
    camFix = Tabs.Render:CreateToggle({
        Name = "CameraFix",
        HoverText = "Changes camera zooming.",
        Callback = function(callback) 
            spawn(function()
                repeat
                    UserSettings():GetService("UserGameSettings").RotationType = ((Camera.CFrame.Position - Camera.Focus.Position).Magnitude <= 0.5 and Enum.RotationType.CameraRelative or Enum.RotationType.MovementRelative)
                    task.wait()
                until not camFix.Enabled
            end)
        end
    })
end)

runFunction(function()
    local chinaHat = {Enabled = false}
    local color = {Value = Color3.fromRGB(255, 255, 255)}
    local chinaHatTrail
    chinaHat = Tabs.Render:CreateToggle({
        Name = "ChinaHat",
        HoverText = "Puts a china hat on your head.",
        Callback = function(callback)
            if callback then
                RunLoops:BindToHeartbeat("chinaHat", function()
					if isAlive() then
                        local head = getHead(LocalPlayer)
						if chinaHatTrail == nil or chinaHatTrail.Parent == nil then
							chinaHatTrail = Instance.new("Part")
							chinaHatTrail.CFrame =  head.CFrame * CFrame.new(0, 1.1, 0)
							chinaHatTrail.Size = Vector3.new(3, 0.7, 3)
							chinaHatTrail.Name = "ChinaHat"
							chinaHatTrail.Material = Enum.Material.Neon
							chinaHatTrail.CanCollide = false
							chinaHatTrail.Transparency = 0.3
                            chinaHatTrail.Color = color.Value
							local chinaHatMesh = Instance.new("SpecialMesh")
							chinaHatMesh.Parent = chinaHatTrail
							chinaHatMesh.MeshType = "FileMesh"
							chinaHatMesh.MeshId = "http://www.roblox.com/asset/?id=1778999"
							chinaHatMesh.Scale = Vector3.new(3, 0.6, 3)
							chinaHatTrail.Parent = workspace.Camera
						end
						chinaHatTrail.CFrame = head.CFrame * CFrame.new(0, 1.1, 0)
						chinaHatTrail.Velocity = Vector3.zero
						chinaHatTrail.LocalTransparencyModifier = head.LocalTransparencyModifier--((Camera.CFrame.Position - Camera.Focus.Position).Magnitude <= 0.6 and 1 or 0)
					else
						if chinaHatTrail then
							chinaHatTrail:Destroy()
							chinaHatTrail = nil
						end
					end
				end)
            else
                RunLoops:UnbindFromHeartbeat("chinaHat")
				if chinaHatTrail then
					chinaHatTrail:Destroy()
					chinaHatTrail = nil
				end
            end
        end
    })

    color = chinaHat:CreateColorSlider({
        Name = "Color",
        Default = Color3.fromRGB(255, 255, 255),
        Function = function(v)
            if chinaHatTrail then
                chinaHatTrail.Color = v
            end
        end
    })
end)


runFunction(function()
    local crossHair = {Enabled = false}
    local id = {Value = ""}
    crossHair = Tabs.Render:CreateToggle({
        Name = "CustomCrossHair",
        HoverText = "Changes your crosshair.",
        Callback = function(callback)
            if callback then
                Mouse.Icon = "rbxassetid://" .. id.Value
            else
                Mouse.Icon = ""
            end
        end
    })

    id = crossHair:CreateTextBox({
        Name = "CrossHairID",
        PlaceholderText = "Asset ID",
        DefaultValue = "",
        Function = function(v) end,
    })
end)

-- Target ESP: only Ромб (4 variants) and Circle.
runFunction(function()
    local targetESP = {Enabled = false}
    local mode = {Value = "Ромб"}
    local diamond = {Value = "1"}
    local size = {Value = 150}
    local speed = {Value = 180}
    local alpha = {Value = .2}
    local circleRadius = {Value = 2.4}
    local circleThickness = {Value = .09}
    local circleGlow = {Value = 1.5}

    local target
    local sg
    local img
    local circlePart
    local circleDecal
    local circleBloom
    local circleTrail

    local diamonds = {
        ["1"] = "113363639205880",
        ["2"] = "132493106112220",
        ["3"] = "108556924043797",
        ["4"] = "139726405706582"
    }

    local CIRCLE_TEXTURE = "rbxassetid://107258187506657"

    local function clearScreen()
        if sg then pcall(function() sg:Destroy() end) end
        sg, img = nil, nil
    end

    local function clearCircle()
        if circlePart then pcall(function() circlePart:Destroy() end) end
        circlePart = nil
        circleDecal = nil
        circleTrail = nil
        -- Bloom is global; remove only the one created by this module.
        if circleBloom then pcall(function() circleBloom:Destroy() end) end
        circleBloom = nil
    end

    local function ensureCircle()
        if circlePart and circlePart.Parent then return end

        circlePart = Instance.new("Part")
        circlePart.Name = "NightixTargetESPCircle"
        circlePart.Anchored = true
        circlePart.CanCollide = false
        circlePart.CanQuery = false
        circlePart.CanTouch = false
        circlePart.CastShadow = false
        circlePart.Transparency = 1
        circlePart.Size = Vector3.new(0.05, 0.05, 0.05)
        circlePart.Parent = workspace

        -- A real 3D horizontal disk carries the supplied circle texture.
        -- The disk is moved through the entire character height.
        local mesh = Instance.new("CylinderMesh")
        mesh.Scale = Vector3.new(2, 0.035, 2)
        mesh.Parent = circlePart

        circleDecal = Instance.new("Decal")
        circleDecal.Name = "CircleTexture"
        circleDecal.Texture = CIRCLE_TEXTURE
        circleDecal.Face = Enum.NormalId.Top
        circleDecal.Transparency = alpha.Value
        circleDecal.Parent = circlePart

        -- Real post-process glow (Bloom), not transparent duplicate rings.
        circleBloom = Instance.new("BloomEffect")
        circleBloom.Name = "NightixTargetESPCircleBloom"
        circleBloom.Intensity = circleGlow.Value
        circleBloom.Size = 24
        circleBloom.Threshold = 0.65
        circleBloom.Parent = Lighting

        -- Short-lived particles use the same supplied texture to leave a
        -- tight trail behind the moving ring. Bloom makes the trail glow.
        circleTrail = Instance.new("ParticleEmitter")
        circleTrail.Name = "CircleGlowTrail"
        circleTrail.Texture = CIRCLE_TEXTURE
        circleTrail.Rate = 0
        circleTrail.Speed = NumberRange.new(0, 0)
        circleTrail.Lifetime = NumberRange.new(.12, .22)
        circleTrail.SpreadAngle = Vector2.new(0, 0)
        circleTrail.LockedToPart = true
        circleTrail.LightEmission = 1
        circleTrail.LightInfluence = 0
        circleTrail.Size = NumberSequence.new(1)
        circleTrail.Transparency = NumberSequence.new({
            NumberSequenceKeypoint.new(0, .35),
            NumberSequenceKeypoint.new(1, 1)
        })
        circleTrail.Parent = circlePart
    end

    local function updateCircle(t)
        if not target or not isAlive(target) or not target.Character then
            clearCircle()
            return
        end

        local character = target.Character
        local boxCFrame, boxSize = character:GetBoundingBox()
        local bottomY = boxCFrame.Position.Y - boxSize.Y * .5
        local topY = boxCFrame.Position.Y + boxSize.Y * .5
        local height = math.max(.1, topY - bottomY)

        ensureCircle()

        -- Ping-pong from the exact bottom to the exact top and back.
        local cycle = math.max(.05, speed.Value / 180)
        local phase = (t * cycle) % 2
        local progress = phase <= 1 and phase or 2 - phase
        local eased = progress * progress * (3 - 2 * progress)
        local y = bottomY + eased * height

        circlePart.Position = Vector3.new(boxCFrame.Position.X, y, boxCFrame.Position.Z)
        local diameter = math.max(.1, circleRadius.Value * 2)
        circlePart.Size = Vector3.new(diameter, .05, diameter)

        if circleDecal then
            circleDecal.Transparency = math.clamp(alpha.Value, 0, 1)
        end
        if circleBloom then
            circleBloom.Intensity = circleGlow.Value
        end
        if circleTrail then
            circleTrail:Emit(1)
        end
    end

    local function updateScreen()
        if not target or not isAlive(target) then
            clearScreen()
            return
        end

        if not sg then
            sg = Instance.new("ScreenGui")
            sg.Name = "NightixTargetESP"
            sg.IgnoreGuiInset = true
            sg.ResetOnSpawn = false
            sg.Parent = CoreGui

            img = Instance.new("ImageLabel")
            img.Name = "TargetImage"
            img.AnchorPoint = Vector2.new(.5, .5)
            img.BackgroundTransparency = 1
            img.Parent = sg
        end

        local anchor = target.Character:FindFirstChild("Head") or getHumanoidRootPart(target)
        if not anchor then img.Visible = false return end

        local pos, onScreen = Camera:WorldToViewportPoint(anchor.Position)
        img.Visible = onScreen
        if not onScreen then return end

        img.Size = UDim2.fromOffset(size.Value, size.Value)
        img.Position = UDim2.fromOffset(pos.X, pos.Y)
        img.Image = "rbxassetid://" .. diamonds[diamond.Value]
        img.ImageTransparency = alpha.Value
        img.Rotation = (tick() * speed.Value) % 360
    end

    local function findTarget()
        local auraTarget = shared.NightixAttackAuraTarget and shared.NightixAttackAuraTarget()
        if auraTarget and isAlive(auraTarget) then return auraTarget end

        local me = getHumanoidRootPart(LocalPlayer)
        if not me then return end
        local best, bestDistance = nil, math.huge

        for _, player in ipairs(Players:GetPlayers()) do
            if player ~= LocalPlayer and isAlive(player) then
                local root = getHumanoidRootPart(player)
                if root then
                    local distance = (root.Position - me.Position).Magnitude
                    if distance < bestDistance then
                        best, bestDistance = player, distance
                    end
                end
            end
        end
        return best
    end

    targetESP = Tabs.Render:CreateToggle({
        Name = "Target ESP",
        HoverText = "Показывает Ромб или 3D Кольцо на цели.",
        Callback = function(on)
            if on then
                RunLoops:BindToRenderStep("TargetESP", function()
                    target = findTarget()
                    if mode.Value == "Circle" then
                        clearScreen()
                        updateCircle(tick())
                    else
                        clearCircle()
                        updateScreen()
                    end
                end)
            else
                RunLoops:UnbindFromRenderStep("TargetESP")
                clearScreen()
                clearCircle()
                target = nil
            end
        end
    })

    mode = targetESP:CreateDropdown({
        Name = "Режим",
        List = {"Ромб", "Circle"},
        Default = "Ромб",
        Function = function(v)
            mode.Value = v
            if diamond.Container then diamond.Container.Visible = v == "Ромб" end
            if size.Container then size.Container.Visible = v == "Ромб" end
            if circleRadius.Container then circleRadius.Container.Visible = v == "Circle" end
            if circleGlow.Container then circleGlow.Container.Visible = v == "Circle" end
            if alpha.Container then alpha.Container.Visible = true end
        end
    })

    diamond = targetESP:CreateDropdown({
        Name = "Ромб",
        List = {"1", "2", "3", "4"},
        Default = "1",
        Function = function(v) diamond.Value = v end
    })

    size = targetESP:CreateSlider({
        Name = "Размер ромба",
        Function = function(v) size.Value = v end,
        Min = 60, Max = 300, Default = 150, Round = 0
    })

    speed = targetESP:CreateSlider({
        Name = "Скорость",
        Function = function(v) speed.Value = v end,
        Min = 0, Max = 720, Default = 180, Round = 0
    })

    alpha = targetESP:CreateSlider({
        Name = "Прозрачность",
        Function = function(v) alpha.Value = v end,
        Min = 0, Max = 1, Default = .2, Round = 2
    })

    circleRadius = targetESP:CreateSlider({
        Name = "Радиус круга",
        Function = function(v) circleRadius.Value = v end,
        Min = 1, Max = 5, Default = 2.4, Round = 1
    })

    circleGlow = targetESP:CreateSlider({
        Name = "Свечение круга",
        Function = function(v)
            circleGlow.Value = v
            if circleBloom then circleBloom.Intensity = v end
        end,
        Min = 0, Max = 5, Default = 1.5, Round = 1
    })

    -- Only the mode-specific controls are shown.
    diamond.Container.Visible = true
    size.Container.Visible = true
    circleRadius.Container.Visible = false
    circleGlow.Container.Visible = false
end)

runFunction(function()
    local targetESP = {Enabled = false}
    local mode = {Value = "Vortex"}
    local diamond = {Value = "1"}
    local size = {Value = 150}
    local speed = {Value = 180}
    local alpha = {Value = .2}
    local circleRadius = {Value = 2.4}
    local circleThickness = {Value = .09}
    local circleGlow = {Value = 1.5}

    local target
    local sg
    local img
    local circlePart
    local circleAttachments = {}
    local circleBeams = {}
    local circleBloom

    local diamonds = {
        ["1"] = "113363639205880",
        ["2"] = "132493106112220",
        ["3"] = "108556924043797",
        ["4"] = "139726405706582"
    }

    local ids = {
        Vortex = "113363639205880",
        Garland = "77939595216474",
        Brackets = "113363639205880",
        Ghosts = "5538771868",
        Default = "77939595216474"
    }

    local function clearScreen()
        if sg then
            pcall(function() sg:Destroy() end)
            sg = nil
            img = nil
        end
    end

    local function clearCircle()
        for _, beam in ipairs(circleBeams) do
            pcall(function() beam:Destroy() end)
        end
        table.clear(circleBeams)

        for _, attachment in ipairs(circleAttachments) do
            pcall(function() attachment:Destroy() end)
        end
        table.clear(circleAttachments)

        if circlePart then
            pcall(function() circlePart:Destroy() end)
            circlePart = nil
        end

        if circleBloom then
            pcall(function() circleBloom:Destroy() end)
            circleBloom = nil
        end
    end

    local function ensureCircle()
        if circlePart and circlePart.Parent then
            return
        end

        circlePart = Instance.new("Part")
        circlePart.Name = "NightixTargetESPCircle"
        circlePart.Anchored = true
        circlePart.CanCollide = false
        circlePart.CanQuery = false
        circlePart.CanTouch = false
        circlePart.Transparency = 1
        circlePart.Size = Vector3.new(0.1, 0.1, 0.1)
        circlePart.Parent = workspace

        local segments = 48
        for i = 1, segments do
            local attachment = Instance.new("Attachment")
            attachment.Name = "CircleAttachment"
            attachment.Parent = circlePart
            circleAttachments[i] = attachment
        end

        for i = 1, segments do
            local nextIndex = (i % segments) + 1
            local beam = Instance.new("Beam")
            beam.Name = "TargetESPCircleBeam"
            beam.Attachment0 = circleAttachments[i]
            beam.Attachment1 = circleAttachments[nextIndex]
            beam.FaceCamera = true
            beam.LightEmission = 1
            beam.LightInfluence = 0
            beam.Segments = 2
            beam.Width0 = circleThickness.Value
            beam.Width1 = circleThickness.Value
            beam.Transparency = NumberSequence.new(0.05)
            beam.Color = ColorSequence.new(Color3.fromRGB(255, 255, 255))
            beam.Parent = circlePart
            circleBeams[i] = beam
        end

        -- One post-process bloom for the ring itself. This is real glow,
        -- rather than stacking transparent copies of the circle texture.
        circleBloom = Instance.new("BloomEffect")
        circleBloom.Name = "NightixTargetESPCircleBloom"
        circleBloom.Intensity = circleGlow.Value
        circleBloom.Size = 24
        circleBloom.Threshold = 0.65
        circleBloom.Parent = Lighting
    end

    local function updateCircle(t)
        if not target or not isAlive(target) or not target.Character then
            clearCircle()
            return
        end

        local character = target.Character
        local boxCFrame, boxSize = character:GetBoundingBox()
        local bottomY = boxCFrame.Position.Y - (boxSize.Y * 0.5)
        local topY = boxCFrame.Position.Y + (boxSize.Y * 0.5)
        local height = math.max(0.1, topY - bottomY)

        ensureCircle()

        local progress = (t * (math.max(0, speed.Value) / 180)) % 2
        if progress > 1 then
            progress = 2 - progress
        end

        -- Smoothstep: starts at the very bottom of the character and
        -- finishes at the very top without the abrupt vertical jump.
        local eased = progress * progress * (3 - 2 * progress)
        local y = bottomY + eased * height
        local center = Vector3.new(boxCFrame.Position.X, y, boxCFrame.Position.Z)
        circlePart.Position = center

        local radius = math.max(0.1, circleRadius.Value)
        local segments = #circleAttachments
        for i, attachment in ipairs(circleAttachments) do
            local angle = ((i - 1) / segments) * math.pi * 2
            attachment.Position = Vector3.new(
                math.cos(angle) * radius,
                0,
                math.sin(angle) * radius
            )
        end

        for _, beam in ipairs(circleBeams) do
            beam.Width0 = circleThickness.Value
            beam.Width1 = circleThickness.Value
            beam.Transparency = NumberSequence.new(math.clamp(alpha.Value * 0.45, 0, 0.95))
        end

        if circleBloom then
            circleBloom.Intensity = circleGlow.Value
        end
    end

    local function updateScreen()
        if not target or not isAlive(target) then
            clearScreen()
            return
        end

        if not sg then
            sg = Instance.new("ScreenGui")
            sg.Name = "NightixTargetESP"
            sg.IgnoreGuiInset = true
            sg.ResetOnSpawn = false
            sg.Parent = CoreGui

            img = Instance.new("ImageLabel")
            img.Name = "TargetImage"
            img.AnchorPoint = Vector2.new(.5, .5)
            img.BackgroundTransparency = 1
            img.Parent = sg
        end

        local anchor = target.Character:FindFirstChild("Head") or getHumanoidRootPart(target)
        if not anchor then
            img.Visible = false
            return
        end

        local pos, onScreen = Camera:WorldToViewportPoint(anchor.Position)
        img.Visible = onScreen
        if not onScreen then
            return
        end

        img.Size = UDim2.fromOffset(size.Value, size.Value)
        img.Position = UDim2.fromOffset(pos.X, pos.Y)
        img.Image = "rbxassetid://" .. (mode.Value == "Ромб" and diamonds[diamond.Value] or ids[mode.Value] or ids.Default)
        img.ImageTransparency = alpha.Value
        img.Rotation = (tick() * speed.Value) % 360
    end

    local function findTarget()
        local auraTarget = shared.NightixAttackAuraTarget and shared.NightixAttackAuraTarget()
        if auraTarget and isAlive(auraTarget) then
            return auraTarget
        end

        local me = getHumanoidRootPart(LocalPlayer)
        if not me then return end

        local best, bestDistance = nil, math.huge
        for _, player in ipairs(Players:GetPlayers()) do
            if player ~= LocalPlayer and isAlive(player) then
                local root = getHumanoidRootPart(player)
                if root then
                    local distance = (root.Position - me.Position).Magnitude
                    if distance < bestDistance then
                        best, bestDistance = player, distance
                    end
                end
            end
        end
        return best
    end

    targetESP = Tabs.Render:CreateToggle({
        Name = "Target ESP",
        HoverText = "Показывает эффект на цели.",
        Callback = function(on)
            if on then
                RunLoops:BindToRenderStep("TargetESP", function()
                    target = findTarget()
                    if mode.Value == "Circle" then
                        clearScreen()
                        updateCircle(tick())
                    else
                        clearCircle()
                        updateScreen()
                    end
                end)
            else
                RunLoops:UnbindFromRenderStep("TargetESP")
                clearScreen()
                clearCircle()
                target = nil
            end
        end
    })

    -- Create the dependent option first. The old code accessed
    -- diamond.Container before the dropdown existed, which caused the
    -- exact nil.Visible error from the screenshot and stopped the rest
    -- of the Target ESP settings from being created.
    diamond = targetESP:CreateDropdown({
        Name = "Вариант ромба",
        List = {"1", "2", "3", "4"},
        Default = "1",
        Function = function(v)
            diamond.Value = v
        end
    })

    mode = targetESP:CreateDropdown({
        Name = "Режим",
        List = {"Vortex", "Garland", "Brackets", "Ghosts", "Default", "Ромб", "Circle"},
        Default = "Vortex",
        Function = function(v)
            mode.Value = v
            if diamond.Container1 then
                diamond.Container1.Visible = v == "Ромб"
            end
            if circleRadius.Container then circleRadius.Container.Visible = v == "Circle" end
            if circleThickness.Container then circleThickness.Container.Visible = v == "Circle" end
            if circleGlow.Container then circleGlow.Container.Visible = v == "Circle" end
        end
    })

    diamond.Container1.Visible = false

    size = targetESP:CreateSlider({
        Name = "Размер",
        Function = function(v) size.Value = v end,
        Min = 60,
        Max = 300,
        Default = 150,
        Round = 0
    })

    speed = targetESP:CreateSlider({
        Name = "Скорость",
        Function = function(v) speed.Value = v end,
        Min = 0,
        Max = 720,
        Default = 180,
        Round = 0
    })

    alpha = targetESP:CreateSlider({
        Name = "Прозрачность",
        Function = function(v) alpha.Value = v end,
        Min = 0,
        Max = 1,
        Default = .2,
        Round = 2
    })

    circleRadius = targetESP:CreateSlider({
        Name = "Радиус круга",
        Function = function(v) circleRadius.Value = v end,
        Min = 1,
        Max = 5,
        Default = 2.4,
        Round = 1
    })

    circleThickness = targetESP:CreateSlider({
        Name = "Толщина круга",
        Function = function(v) circleThickness.Value = v end,
        Min = 0.02,
        Max = 0.3,
        Default = .09,
        Round = 2
    })

    circleGlow = targetESP:CreateSlider({
        Name = "Свечение круга",
        Function = function(v)
            circleGlow.Value = v
            if circleBloom then
                circleBloom.Intensity = v
            end
        end,
        Min = 0,
        Max = 5,
        Default = 1.5,
        Round = 1
    })

    circleRadius.Container.Visible = false
    circleThickness.Container.Visible = false
    circleGlow.Container.Visible = false
end)

runFunction(function()
    local esp = {Enabled = false}
    local adorneePart = {Value = "HumanoidRootPart"}
    local mode = {Value = "SelectionBox"}
    local fill = {Value = false}
    local fillColor = {Value = Color3.fromRGB(255, 0, 0)}
    local fillTransparency = {Value = 0}
    local outline = {Value = true}
    local outlineColor = {Value = Color3.fromRGB(255, 0, 0)}
    local outlineTransparency = {Value = 0}
    local color = {Value = Color3.fromRGB(255, 0, 0)}
    local transparency = {Value = 0}
    --local lineThickness = {Value = 0}
    --local surfaceTransparency = {Value = 0}
    local useTeamColor = {Value = false}
    local teammates = {Value = false}
    local alwaysOnTop = {Value = true}
    local connection
    local connection2

    local espLibrary = espLibrary:create("ESP")

    esp = Tabs.Render:CreateToggle({
        Name = "ESP",
        HoverText = "Shows people through walls.",
        Callback = function(callback)
            if callback then
                espLibrary:start()
            else
                espLibrary:stop()
            end
        end
    })

    adorneePart = esp:CreateDropdown({
        Name = "Attach Part",
        List = {"Head", "HumanoidRootPart", "Full Character"},
        Default = "Full Character",
        Function = function(v)
            espLibrary.adorneePart = v
            if esp.Enabled then
                espLibrary:updateAll()
            end
        end
    })

    mode = esp:CreateDropdown({
        Name = "Mode",
        List = {"BoxHandleAdornment", "Highlight"}, --"SelectionBox", "BoxHandleAdornment", "Highlight"
        Default = "Highlight",
        Callback = function(v)
            espLibrary.mode = v
            local modeVisibility = {
                --SelectionBox = {lineThickness, surfaceTransparency, color, transparency},
                BoxHandleAdornment = {color, transparency},
                Highlight = {outline, fill}
            }
            if color.Container then color.Container.Visible = v == "BoxHandleAdornment" end
            if transparency.Container then transparency.Container.Visible = v == "BoxHandleAdornment" end
            if outline.Container then outline.Container.Visible = v == "Highlight" end
            if fill.Container then fill.Container.Visible = v == "Highlight" end
            if esp.Enabled then
                esp:ReToggle(true)
                espLibrary:updateAll()
            end
        end
    })

    outline = esp:CreateToggle({
        Name = "Outline",
        Default = false,
        Function = function(v)
            espLibrary.outline = v
            if outlineColor.Container then outlineColor.Container.Visible = v end
            if outlineTransparency.Container then outlineTransparency.Container.Visible = v end
        end
    })

    outlineColor = esp:CreateColorSlider({
        Name = "Outline color",
        Default = Color3.fromRGB(255, 0, 0),
        Function = function(v)
            espLibrary.outlineColor = v
            if esp.Enabled then
                espLibrary:updateAll()
            end
        end
    })
    outlineColor.Container.Visible = false

    outlineTransparency = esp:CreateSlider({
        Name = "Outline Transparency",
        Function = function(v)
            espLibrary.outlineTransparency = v
            if esp.Enabled then
                espLibrary:updateAll()
            end
        end,
        Min = 0,
        Max = 1,
        Default = 0,
        Round = 1
    })
    outlineTransparency.Container.Visible = false

    fill = esp:CreateToggle({
        Name = "Fill",
        Default = false,
        Function = function(v)
            espLibrary.fill = v
            if fillColor.Container then fillColor.Container.Visible = v end
            if fillTransparency.Container then fillTransparency.Container.Visible = v end
        end
    })

    fillColor = esp:CreateColorSlider({
        Name = "Fill color",
        Default = Color3.fromRGB(255, 0, 0),
        Function = function(v)
            espLibrary.fillColor = v
            if esp.Enabled then
                espLibrary:updateAll()
            end
        end
    })
    fillColor.Container.Visible = false

    fillTransparency = esp:CreateSlider({
        Name = "Fill Transparency",
        Function = function(v)
            espLibrary.fillTransparency = v
            if esp.Enabled then
                espLibrary:updateAll()
            end
        end,
        Min = 0,
        Max = 1,
        Default = 0,
        Round = 1
    })
    fillTransparency.Container.Visible = false

    color = esp:CreateColorSlider({
        Name = "Color",
        Default = Color3.fromRGB(255, 0, 0),
        Function = function(v)
            espLibrary.color = v
            if esp.Enabled then
                espLibrary:updateAll()
            end
        end
    })
    color.Container.Visible = false

    transparency = esp:CreateSlider({
        Name = "Transparency",
        Function = function(v)
            espLibrary.transparency = v
            if esp.Enabled then
                espLibrary:updateAll()
            end
        end,
        Min = 0,
        Max = 1,
        Default = 0,
        Round = 1
    })
    transparency.Container.Visible = false

    --[[
    lineThickness = esp:CreateSlider({
        Name = "Line Thickness",
        Function = function(v)
            espLibrary.lineThickness = v
            if esp.Enabled then
                espLibrary:updateAll()
            end
        end,
        Min = 0,
        Max = 1,
        Default = 0,
        Round = 1
    })

    surfaceTransparency = esp:CreateSlider({
        Name = "Surface Transparency",
        Function = function(v)
            espLibrary.surfaceTransparency = v
            if esp.Enabled then
                espLibrary:updateAll()
            end
        end,
        Min = 0,
        Max = 10,
        Default = 1,
        Round = 1
    })
    ]]

    alwaysOnTop = esp:CreateToggle({
        Name = "AlwaysOnTop",
        Default = true,
        Function = function(v)
            if mode.Value == "BoxHandleAdornment" then
                esp.boxHandleAlwaysOnTop = v
            elseif mode.Value == "Highlight" then
                esp.highlightAlwaysOnTop = v
            end
        end
    })

    useTeamColor = esp:CreateToggle({
        Name = "TeamColor",
        Default = false,
        Function = function(v)
            espLibrary.useTeamColor = v
            if esp.Enabled then
                espLibrary:updateAll()
            end
        end
    })

    teammates = esp:CreateToggle({
        Name = "Teammates",
        Default = false,
        Function = function(v)
            espLibrary.teammates = v
            if esp.Enabled then
                espLibrary:updateAll()
            end
        end
    })
end)

runFunction(function()
    local fovChanger = {Enabled = false}
    local fov = {Value = 80}
    local oldfov
    fovChanger = Tabs.Render:CreateToggle({
        Name = "FOVChanger",
        HoverText = "Changes your field of view.",
        Callback = function(callback)
            if callback then
                oldfov = Camera.FieldOfView
                Camera.FieldOfView = fov.Value
            else
                Camera.FieldOfView = oldfov
            end
        end
    })
    
    fov = fovChanger:CreateSlider({
        Name = "FOV",
        Function = function(v) end,
        Min = 1,
        Max = 150,
        Default = 80,
        Round = 0
    })
end)

runFunction(function()
    local fullbright = {Enabled = false}
    local params = {}
	local changed = false
    local connection
    fullbright = Tabs.Render:CreateToggle({
        Name = "Fullbright",
        HoverText = "Makes everything brigher.",
        Callback = function(callback)
            if callback then
                params.Brightness = Lighting.Brightness
                params.ClockTime = Lighting.ClockTime
                params.FogEnd = Lighting.FogEnd
                params.GlobalShadows = Lighting.GlobalShadows
                params.OutdoorAmbient = Lighting.OutdoorAmbient
                changed = true
                Lighting.Brightness = 2
                Lighting.ClockTime = 14
                Lighting.FogEnd = 100000
                Lighting.GlobalShadows = false
                Lighting.OutdoorAmbient = Color3.fromRGB(128, 128, 128)
                betterDisconnect(connection)
                changed = false
                connection = Lighting.Changed:Connect(function()
                    if callback and not changed then
                        changed = true
                        Lighting.Brightness = 2
                        Lighting.ClockTime = 14
                        Lighting.FogEnd = 100000
                        Lighting.GlobalShadows = false
                        Lighting.OutdoorAmbient = Color3.fromRGB(128, 128, 128)
                        changed = false
                    end
                end)
            else
                betterDisconnect(connection)
                connection = nil
                changed = true
                for Name, Value in pairs(params) do
                    Lighting[Name] = Value
                end
                changed = false
            end
        end
    })  
end)

runFunction(function()
    local keyStrokes = {Enabled = false}
    local mode = {Value = "Letters"}
    local textSize = {Value = 15}
    local spaceTextSize = {Value = 17}
    local size = {Value = 1}
    local transparency = {Value = 0.5}
    local showMouseButtons = {Value = false}
    local textXAllignment = {Value = "Left"}
    local textYAllignment = {Value = "Top"}

    keyStrokes = Tabs.Render:CreateToggle({
        Name = "KeyStrokes",
        HoverText = "Creates ui with keys and shows which ones you held.",
        Callback = function(callback)
            Mana.KeyStrokes:toggle()
        end
    })

    mode = keyStrokes:CreateDropdown({
        Name = "Mode",
        Function = function(v) 
            Mana.KeyStrokes:changeSymbols(v)
        end,
        List = {"Letters", "Directions", "Directions2", "Arrows"},
        Default = "Letters"
    })

    textSize = keyStrokes:CreateSlider({
        Name = "Text Size",
        Function = function(v) 
            Mana.KeyStrokes:updateTextSize(v)
        end,
        Min = 10,
        Max = 30,
        Default = 15,
        Round = 0
    })

    spaceTextSize = keyStrokes:CreateSlider({
        Name = "Space Text Size",
        Function = function(v) 
            Mana.KeyStrokes:updateSpaceTextSize(v)
        end,
        Min = 10,
        Max = 30,
        Default = 17,
        Round = 0
    })

    size = keyStrokes:CreateSlider({
        Name = "Size",
        Function = function(v) 
            Mana.KeyStrokes:updateSize(v)
        end,
        Min = 0.1,
        Max = 5,
        Default = 1,
        Round = 2
    })

    transparency = keyStrokes:CreateSlider({
        Name = "Transparency",
        Function = function(v) 
            Mana.KeyStrokes:updateBackgroundTransparency(v)
        end,
        Min = 0,
        Max = 1,
        Default = 0.5,
        Round = 1
    })

    showMouseButtons = keyStrokes:CreateToggle({
        Name = "Mouse Buttons",
        Default = false,
        Function = function(v) 
            Mana.KeyStrokes:toggleMouseButtons(v)
        end
    })

    textXAllignment = keyStrokes:CreateDropdown({
        Name = "Text X Pos",
        Function = function(v) 
            Mana.KeyStrokes:updateTextPosition(v, textYAllignment.Value)
        end,
        List = {"Left", "Center", "Right"},
        Default = "Left"
    })

    textYAllignment = keyStrokes:CreateDropdown({
        Name = "Text Y Pos",
        Function = function(v) 
            Mana.KeyStrokes:updateTextPosition(textXAllignment.Value, v)
        end,
        List = {"Top", "Center", "Bottom"},
        Default = "Top"
    })
end)

-- Nightix NameTags
runFunction(function()
    local nameTags={Enabled=false}; local mode={Value="Username"}; local color={Value=Color3.fromRGB(255,255,255)}; local teamColor={Value=false}; local showHP={Value=false}; local guis={}; local folder=Instance.new("Folder"); folder.Name="NightixNameTags"; folder.Parent=CoreGui
    local function clear(plr) local n=typeof(plr)=="string" and plr or plr.Name; if guis[n] then pcall(function() guis[n]:Destroy() end); guis[n]=nil end end
    local function make(plr) clear(plr); if not isAlive(plr,true) then return end; local g=Instance.new("BillboardGui"); g.Name="NameTag_"..plr.Name; g.Adornee=plr.Character:FindFirstChild("Head"); g.AlwaysOnTop=true; g.Size=UDim2.fromOffset(220,70); g.StudsOffset=Vector3.new(0,2.8,0); g.Parent=folder; local f=Instance.new("Frame"); f.Size=UDim2.fromScale(1,1); f.BackgroundColor3=Color3.fromRGB(20,20,24); f.BackgroundTransparency=.12; f.BorderSizePixel=0; f.Parent=g; local n=Instance.new("TextLabel"); n.Name="Nickname"; n.BackgroundTransparency=1; n.Position=UDim2.fromOffset(8,5); n.Size=UDim2.new(1,-16,0,24); n.Font=guifont or Enum.Font.GothamBold; n.TextSize=16; n.TextXAlignment=Enum.TextXAlignment.Center; n.TextStrokeTransparency=1; n.Parent=f; local icon=Instance.new("ImageLabel"); icon.Name="HealthIcon"; icon.BackgroundTransparency=1; icon.Image="rbxassetid://99142118523333"; icon.Size=UDim2.fromOffset(17,17); icon.Position=UDim2.fromOffset(8,39); icon.Parent=f; local hp=Instance.new("TextLabel"); hp.Name="Health"; hp.BackgroundTransparency=1; hp.Position=UDim2.fromOffset(29,35); hp.Size=UDim2.new(1,-35,0,24); hp.Font=guifont or Enum.Font.GothamBold; hp.TextSize=16; hp.TextColor3=Color3.fromRGB(255,255,255); hp.TextXAlignment=Enum.TextXAlignment.Left; hp.TextStrokeTransparency=1; hp.Parent=f; guis[plr.Name]=g; return g end
    local function update(plr) if not isAlive(plr) then clear(plr); return end; local g=guis[plr.Name] or make(plr); if not g then return end; local f=g:FindFirstChildOfClass("Frame"); local n=f and f:FindFirstChild("Nickname"); local hp=f and f:FindFirstChild("Health"); local icon=f and f:FindFirstChild("HealthIcon"); local h=getHumanoid(plr); if not n or not hp or not h then return end; local c=(teamColor.Value and plr.Team and plr.Team.TeamColor.Color) or color.Value; n.Text=mode.Value=="DisplayName" and plr.DisplayName or plr.Name; n.TextColor3=c; hp.Text=tostring(math.floor(h.Health)).." HP"; hp.Visible=showHP.Value; icon.Visible=showHP.Value; g.Size=UDim2.fromOffset(220,showHP.Value and 70 or 40) end
    local conns={}; nameTags=Tabs.Render:CreateToggle({Name="NameTags",HoverText="Показывает ник и здоровье.",Callback=function(on) if on then for _,p in ipairs(Players:GetPlayers()) do if p~=LocalPlayer then make(p) end end; table.insert(conns,Players.PlayerRemoving:Connect(clear)); RunLoops:BindToRenderStep("NameTags",function() for _,p in ipairs(Players:GetPlayers()) do if p~=LocalPlayer then update(p) end end end) else RunLoops:UnbindFromRenderStep("NameTags"); for _,c in ipairs(conns) do betterDisconnect(c) end; table.clear(conns); for n,g in pairs(guis) do pcall(function() g:Destroy() end); guis[n]=nil end end end}); mode=nameTags:CreateDropdown({Name="Режим ника",List={"Username","DisplayName"},Default="Username",Function=function() end}); color=nameTags:CreateColorSlider({Name="Цвет ника",Default=Color3.fromRGB(255,255,255),Function=function() end}); teamColor=nameTags:CreateToggle({Name="Цвет команды",Default=false,Function=function() end}); showHP=nameTags:CreateToggle({Name="Здоровье",Default=false,Function=function() end})
end)


runFunction(function()
    local rainbowSkin = {Enabled = false}
    local mode = {Value = "FullCharacter"}
    local colorMode = {Value = "Random"}
    local color = {Value = Color3.fromRGB(255, 255, 255)}
    local delay = {Value = 0.1}
    local newColor

    rainbowSkin = Tabs.Render:CreateToggle({
        Name = "RainbowSkin",
        HoverText = "Makes your skin rainbow/random color.",
        Callback = function(callback)
            repeat
                for _, part in next, getCharacter():GetDescendants() do
                    if part:IsA("BasePart") then
                        if mode.Value == "FullCharacter" then
                            part.Color = (colorMode.Value == "Random") and Color3.new(math.random(), math.random(), math.random()) or color.Value
                        else
                            part.Color = (colorMode.Value == "Random") and Color3.new(math.random(), math.random(), math.random()) or color.Value
                        end
                    end
                end
                wait(delay.Value)
            until not rainbowSkin.Enabled
        end
    })

    mode = rainbowSkin:CreateDropdown({
        Name = "Mode",
        List = {"FullCharacter", "PerPart"},
        Default = "PerPart",
        Function = function(v) end
    })

    colorMode = rainbowSkin:CreateDropdown({
        Name = "ColorMode",
        List = {"Random", "Custom"},
        Default = "Random",
        Function = function(v)
            if delay.MainObject then
                delay.MainObject.Visible = v == "Random"
            end
        end
    })

    color = rainbowSkin:CreateColorSlider({
        Name = "Color",
        Default = Color3.fromRGB(255, 255, 255),
        Function = function(v) end
    })

    delay = rainbowSkin:CreateSlider({
        Name = "Delay",
        Function = function(v) end,
        Min = 0.1,
        Max = 5,
        Default = 0.1,
        Round = 1
    })
end)

--[[
runFunction(function()
    --6018555426
    local santaHat = {Enabled = false}
    local color = {Value = Color3.fromRGB(255, 255, 255)}
    local hat
    santaHat = Tabs.Render:CreateToggle({
        Name = "SantaHat",
        HoverText = "Puts a china hat on your head.",
        Callback = function(callback)
            if callback then
                RunLoops:BindToHeartbeat("santaHat", function()
					if isAlive() then
                        local head = getHead(LocalPlayer)
						if hat == nil or hat.Parent == nil then
							hat = Instance.new("Part")
							hat.CFrame = head.CFrame * CFrame.new(0, 1.1, 0)
							hat.Size = Vector3.new(3, 0.7, 3)
							hat.Name = "santaHat"
							hat.Material = Enum.Material.Neon
							hat.CanCollide = false
							hat.Transparency = 0.3
                            hat.Color = color.Value
                            hat.Parent = Camera
							local mesh = Instance.new("SpecialMesh")
							mesh.Parent = hat
							mesh.MeshType = "FileMesh"
							mesh.MeshId = "http://www.roblox.com/asset/?id=15854272807" --15854272807 rbxassetid://15854272807
							mesh.Scale = Vector3.new(3, 0.6, 3)
						end
						hat.CFrame = head.CFrame * CFrame.new(0, 1.1, 0)
						hat.Velocity = Vector3.zero
						hat.LocalTransparencyModifier = head.LocalTransparencyModifier--((Camera.CFrame.Position - Camera.Focus.Position).Magnitude <= 0.6 and 1 or 0)
					else
						if hat then
							hat:Destroy()
							hat = nil
						end
					end
				end)
            else
                RunLoops:UnbindFromHeartbeat("santaHat")
				if hat then
					hat:Destroy()
					hat = nil
				end
            end
        end
    })

    color = santaHat:CreateColorSlider({
        Name = "Color",
        Default = Color3.fromRGB(255, 255, 255),
        Function = function(v)
            if hat then
                hat.Color = v
            end
        end
    })
end)
]]

-- // first time in life using number range :omg:
runFunction(function()
    local snowing = {Enabled = false}
    local speed = {Value = 15}
    local rate = {Value = 1000}
    local part, effect, connection

    snowing = Tabs.Render:CreateToggle({
        Name = "Snowing",
        HoverText = "Makes it snow in game.",
        Callback = function(callback)
            if callback then
                RunLoops:BindToHeartbeat("snowing", function(dt)
                    if isAlive() then
                        local head = getHead()
                        part = part or Instance.new("Part", Camera)
                        part.Size = Vector3.new(300, 2, 300)
                        part.CFrame = head.CFrame * CFrame.new(0, 100, 0)
                        part.Transparency = 1
                        part.Anchored = true
                        part.CanCollide = false
                        effect = effect or Instance.new("ParticleEmitter", part)
                        effect.EmissionDirection = Enum.NormalId.Bottom
                        effect.Lifetime = NumberRange.new(30, 35)
                        effect.Rate = rate.Value
                        effect.Speed = NumberRange.new(speed.Value - 5, speed.Value + 5)
                    end
                end)
            else
                RunLoops:UnbindFromHeartbeat("snowing")
                if part then
                    part:Destroy()
                    part = nil
                end
                if effect then
                    effect:Destroy()
                    effect = nil
                end
            end
        end
    })

    speed = snowing:CreateSlider({
        Name = "Speed",
        Min = 1,
        Max = 50,
        Default = 15,
        Round = 0
    })

    rate = snowing:CreateSlider({
        Name = "Rate",
        Min = 500,
        Max = 2000,
        Default = 1000,
        Round = 0
    })
end)

runFunction(function()
    local soundPlayer = {Enabled = false}
    local mode = {Value = "Random"}
    local sounds = {List = {}}
    local volume = {Value = 1}
    local sound
    local current, max = 1, 1
    local currentID

    soundPlayer = Tabs.Render:CreateToggle({
        Name = "SoundPlayer",
        HoverText = "Plays music.",
        Callback = function(callback)
            repeat
                if mode.Value == "Random" then
                    currentID = #sounds.List > 0 and sounds.List[math.random(1, #sounds.List)] or "142376088"
                elseif mode.Value == "Order" then
                    max = #sounds.List
                    currentID = sounds.List[current] or "142376088"
                    current = current + 1
                    if current > max then current = 1 end
                end
                if currentID and currentID ~= "" then
                    if sound then
                        sound:Stop()
                        sound:Destroy()
                    end

                    sound = Instance.new("Sound")
                    sound.SoundId = tonumber(currentID) and "rbxassetid://" .. currentID or currentID
                    sound.Volume = volume.Value
                    sound.Parent = workspace
                    sound:Play()

                    repeat task.wait() until sound.IsLoaded

                    sound.Ended:Wait()
                end
            until not soundPlayer.Enabled
            if not soundPlayer.Enabled and sound then
                sound:Stop()
                sound:Destroy()
                sound = nil
            end
        end
    })

    mode = soundPlayer:CreateDropdown({
        Name = "Mode",
        List = {"Random", "Order"},
        Default = "Random",
        Function = function(v) end
    })

    sounds = soundPlayer:CreateTextList({
        Name = "Sounds",
        PlaceholderText = "sound id",
        List = {},
        Default = "",
        HideAdd = true,
        Function = function(v) end
    })

    volume = soundPlayer:CreateSlider({
        Name = "Volume",
        Function = function(v)
            if sound then
                sound.Volume = v
            end
        end,
        Min = 0,
        Max = 1,
        Default = 1,
        Round = 1
    })
end)

runFunction(function()
    local spawnEsp = {Enabled = false}
    local outline = {Value = true}
    local outlineColor = {Value = Color3.fromRGB(255, 0, 0)}
    local outlineTransparency = {Value = 0}
    local fill = {Value = false}
    local fillColor = {Value = Color3.fromRGB(255, 0, 0)}
    local fillTransparency = {Value = 0}
    local objects = {}
    local connection

    local function addHighlight(obj)
        if obj:FindFirstChild("SpawnESP") then return end
        local highlight = Instance.new("Highlight")
        highlight.Name = "SpawnESP"
        highlight.Adornee = obj
        highlight.Parent = obj
        highlight.FillColor = fillColor.Value
        highlight.FillTransparency = fill.Value and fillTransparency.Value or 1
        highlight.OutlineColor = outlineColor.Value
        highlight.OutlineTransparency = outline.Value and outlineTransparency.Value or 1
        highlight.DepthMode = Enum.HighlightDepthMode.AlwaysOnTop
        table.insert(objects, highlight)
    end

    spawnEsp = Tabs.Render:CreateToggle({
        Name = "SpawnESP",
        HoverText = "Highlights every spawn that has 0 transparency.",
        Callback = function(callback)
            if callback then
                for _, obj in pairs(workspace:GetDescendants()) do
                    if obj:IsA("SpawnLocation") then
                        addHighlight(obj)
                    end
                end
                connection = workspace.ChildAdded:Connect(function(child)
                    if child:IsA("SpawnLocation") then
                        addHighlight(child)
                    end
                end)
            else
                for _, obj in pairs(objects) do
                    if obj and obj.Parent then
                        obj:Destroy()
                    end
                end
                table.clear(objects)
                if connection then
                    connection:Disconnect()
                    connection = nil
                end
            end
        end
    })

    outline = spawnEsp:CreateToggle({
        Name = "Outline",
        Default = true,
        Function = function(v)
            for _, obj in pairs(objects) do
                if obj and obj.Parent then
                    obj.OutlineTransparency = v and outlineTransparency.Value or 1
                end
            end
            if outlineColor.Container then
                outlineColor.Container.Visible = v
            end
            if outlineTransparency.Container then
                outlineTransparency.Container.Visible = v
            end
        end
    })

    outlineColor = spawnEsp:CreateColorSlider({
        Name = "Outline color",
        Default = Color3.fromRGB(255, 0, 0),
        Function = function(v)
            for _, obj in pairs(objects) do
                if obj and obj.Parent then
                    obj.OutlineColor = v
                end
            end
        end
    })
    outlineColor.Container.Visible = false

    outlineTransparency = spawnEsp:CreateSlider({
        Name = "Outline Transparency",
        Function = function(v)
            for _, obj in pairs(objects) do
                if obj and obj.Parent then
                    obj.OutlineTransparency = outline.Value and v or 1
                end
            end
        end,
        Min = 0,
        Max = 1,
        Default = 0,
        Round = 1
    })
    outlineTransparency.Container.Visible = false

    fill = spawnEsp:CreateToggle({
        Name = "Fill",
        Default = false,
        Function = function(v)
            for _, obj in pairs(objects) do
                if obj and obj.Parent then
                    obj.FillTransparency = v and fillTransparency.Value or 1
                end
            end
            if fillColor.Container then
                fillColor.Container.Visible = v
            end
            if fillTransparency.Container then
                fillTransparency.Container.Visible = v
            end
        end
    })

    fillColor = spawnEsp:CreateColorSlider({
        Name = "Fill color",
        Default = Color3.fromRGB(255, 0, 0),
        Function = function(v)
            for _, obj in pairs(objects) do
                if obj and obj.Parent then
                    obj.FillColor = v
                end
            end
        end
    })
    fillColor.Container.Visible = false

    fillTransparency = spawnEsp:CreateSlider({
        Name = "Fill Transparency",
        Function = function(v)
            for _, obj in pairs(objects) do
                if obj and obj.Parent then
                    obj.FillTransparency = fill.Value and v or 1
                end
            end
        end,
        Min = 0,
        Max = 1,
        Default = 0,
        Round = 1
    })
    fillTransparency.Container.Visible = false
end)

runFunction(function()
    local usernameHider = {Enabled = false}
    local mode = {Value = "DisplayName"}
    local customName = {Value = ""}
    local changedObjects = {}
    local connections = {} -- // note: this is a new connections table, not the one that is across this whole script
    local function hide(obj)
        if obj.Text:find(localPlayer.Name) then
            local originalText = obj.Text
            obj.Text = obj.Text:gsub(localPlayer.Name, (mode.Value == "DisplayName" and localPlayer.DisplayName) or customName.Value)
            changedObjects[obj] = originalText
        end
    end
    usernameHider = Tabs.Render:CreateToggle({
        Name = "UsernameHider",
        HoverText = "Hides your username and if choosed then display name too.\nNote that this is client sided.",
        Callback = function(callback)
            if callback then
                for _, obj in next, CoreGui:GetDescendants() do
                    if obj:IsA("TextLabel") or obj:IsA("TextButton") or obj:IsA("TextBox") then
                        hide(obj)
                        table.insert(connections, obj:GetPropertyChangedSignal("Text"):Connect(function()
                            hide(obj)
                        end))
                    end
                end
                for _, obj in next, PlayerGui:GetDescendants() do
                    if obj:IsA("TextLabel") or obj:IsA("TextButton") or obj:IsA("TextBox") then
                        hide(obj)
                        table.insert(connections, obj:GetPropertyChangedSignal("Text"):Connect(function()
                            hide(obj)
                        end))
                    end
                end
                table.insert(connections, game.DescendantAdded:Connect(function(obj)
                    if obj:IsA("TextLabel") or obj:IsA("TextButton") or obj:IsA("TextBox") then
                        hide(obj)
                        table.insert(connections, obj:GetPropertyChangedSignal("Text"):Connect(function()
                            hide(obj)
                        end))
                    end
                end))
                -- TextChatMessage.Text is read-only; do not try to mutate it.
                -- UI labels created by the chat system are already covered by
                -- the PlayerGui/CoreGui descendant listeners above.
            else
                for _, connection in next, connections do
                    betterDisconnect(connection)
                end
                connections = {}
                for obj, originalText in pairs(changedObjects) do
                    if obj and obj.Parent then
                        obj.Text = originalText
                    end
                end
                changedObjects = {}
            end
        end
    })

    mode = usernameHider:CreateDropdown({
        Name = "Change to",
        List = {"DisplayName", "Custom"},
        Default = "DisplayName",
        Function = function(v)
            if customName.Container then customName.Container.Visible = v == "Custom" end
            if usernameHider.Enabled then
                usernameHider:ReToggle(true)
            end
        end
    })

    customName = usernameHider:CreateTextBox({
        Name = "Custom Name",
        PlaceholderText = "Custom name",
        Default = "",
        Function = function(v)
            if usernameHider.Enabled then
                for obj, originalText in pairs(changedObjects) do
                    if obj and obj.Parent then
                        obj.Text = originalText
                    end
                end
                for obj, _ in pairs(changedObjects) do
                    hide(obj)
                end
            end
        end
    })
    customName.Container.Visible = false
end)

runFunction(function()
    local viewClip = {Enabled = false}
    viewClip = Tabs.Render:CreateToggle({
        Name = "ViewClip",
        HoverText = "Makes your camera go through objects.",
        Callback = function(callback)
            LocalPlayer.DevCameraOcclusionMode = callback and "Invisicam" or "Zoom"
        end
    })
end)

-- // Utility tab
runFunction(function()
    local antiAFK = {Enabled = false}
    local mode = {Value = "AutoClick"}
    local connection
    antiAFK = Tabs.Utility:CreateToggle({
        Name = "AntiAFK",
        HoverText = "Makes you able to idle for inf amount of time,\nAutoClick clicks when you idle.\nDisableConnections disables connections and requires getconnections function.",
        Callback = function(callback) 
            if callback then
                if mode.Value == "AutoClick" then
                connection = localPlayer.Idled:Connect(function()
                    virtualUser:Button2Down(Vector2.new(0, 0))
                    task.wait(0.1)
                    virtualUser:Button2Up(Vector2.new(0, 0))
                end)
                elseif mode.Value == "DisableConnections" then
                    if getconnections then
                        for i,v in next, getconnections(LocalPlayer.Idled) do
                            v:Disable()
                        end
                    else
                        GuiLibrary:CreateNotification("AntiAFK", "Missing getconnections function.", 10, "Error")
                        antiAFK:Toggle(true)
                    end
                end
            else
                betterDisconnect(connection)
                connection = nil
                if getconnections then
                    for _, v in next, getconnections(LocalPlayer.Idled) do
                        v:Enable()
                    end
                end
            end
        end
    })

    mode = antiAFK:CreateDropdown({
        Name = "Mode",
        List = {"AutoClick", "DisableConnections"},
        Default = "AutoClick",
        Function = function(v) end
    })
end)

runFunction(function()
    local antiFling = {Enabled = false}
    antiFling = Tabs.Utility:CreateToggle({
        Name = "AntiFling",
        HoverText = "Makes people unable to push/fling you.\nDisables collision.",
        Callback = function(callback) 
            if callback then 
                RunLoops:BindToHeartbeat("AntiFling", function()
                    for _, part in next, getCharacter():GetChildren() do
                        if part:IsA("BasePart") and part.Name ~= "HumanoidRootPart" then
                            part.CanCollide = false
                        end
                    end
                end)
            else
                RunLoops:UnbindFromHeartbeat("AntiFling")
                for _, part in next, getCharacter():GetChildren() do
                    if part:IsA("BasePart") and part.Name ~= "HumanoidRootPart" then
                        part.CanCollide = true
                    end
                end
            end
        end
    })
end)


--[[patched but i don't want to remove it
runFunction(function()
    local AutoReportNotifications = {Value = true}

    local ReportTable = {
        ez = "Bullying",
        gay = "Bullying",
        gae = "Bullying",
        hacks = "Scamming",
        hacker = "Scamming",
        hack = "Scamming",
        cheat = "Scamming",
        hecker = "Scamming",
        get = "Scamming",
        ["get a life"] = "Bullying",
        L = "Bullying",
        thuck = "Swearing",
        thuc = "Swearing",
        thuk = "Swearing",
        fatherless = "Bullying",
        yt = "Offsite Links",
        discord = "Offsite Links",
        dizcourde = "Offsite Links",
        retard = "Swearing",
        tiktok = "Offsite Links",
        bad = "Bullying",
        trash = "Bullying",
        die = "Bullying",
        lobby = "Bullying",
        ban = "Bullying",
        youtube = "Offsite Links",
        ["im hacking"] = "Cheating/Exploiting",
        ["I'm hacking"] = "Cheating/Exploiting",
        download = "Offsite Links",
        ["kill your"] = "Bullying",
        kys = "Bullying",
        ["hack to win"] = "Bullying",
        bozo = "Bullying",
        kid = "Bullying",
        adopted = "Bullying",
        vxpe = "Cheating/Exploiting",
        futureclient = "Cheating/Exploiting",
        nova6 = "Cheating/Exploiting",
        [".gg"] = "Offsite Links",
        gg = "Offsite Links",
        lol = "Bullying",
        suck = "Dating",
        love = "Dating",
        fuck = "Swearing",
        sthu = "Swearing",
        ["i hack"] = "Cheating/Exploiting",
        disco = "Offsite Links",
        dc = "Offsite Links",
        toxic = "Bullying",
        loser = "Bullying",
        noob = "Bullying",
        ["you suck"] = "Bullying",
        ["you're bad"] = "Bullying",
        ["your mom"] = "Bullying"
    }

    local function GetReport(Message)
        for word, reportType in pairs(ReportTable) do 
            if Message:lower():find(word) then 
                return reportType
            end
        end
        return nil
    end

    local AutoReport = Tabs.Utility:CreateToggle({
        Name = "AutoReport",
        Keybind = nil,
        Callback = function(Callback)
            if Callback then
                if TextChatService.ChatVersion == Enum.ChatVersion.TextChatService then 
                    TextChatService.MessageReceived:Connect(function(MessageData)
                        if MessageData.TextSource then
                            local Player = Players:GetPlayerByUserId(MessageData.TextSource.UserId)
                            if Player and Player ~= LocalPlayer then
                                local ReportFound = GetReport(MessageData.Text)
                                if ReportFound then
                                    Players:ReportAbuse(Player, ReportFound, "he said a bad word.")
                                    if AutoReportNotifications.Value then
                                        GuiLibrary:CreateNotification("AutoReport", "Reported: " .. Player.Name .. "\nFor: " .. MessageData.Text, 10, false, "warn")
                                    end
                                end
                            end
                        end
                    end)
                else
                    for _, Player in pairs(Players:GetPlayers()) do
                        if Player.Name ~= LocalPlayer.Name then
                            Player.Chatted:connect(function(Message)
                                local ReportFound = GetReport(Message)
                                if ReportFound then
                                    Players:ReportAbuse(Player, ReportFound, "he said a bad word.")
                                    if AutoReportNotifications.Value then
                                        GuiLibrary:CreateNotification("AutoReport", "Reported: " .. Player.Name .. "\nFor: " .. Message, 10, false, "warn")
                                    end
                                end
                            end)
                        end
                    end
                end
            end
        end
    })

    AutoReportNotifications = AutoReport:CreateToggle({
        Name = "Notifications",
        Default = true,
        Function = function() end
    })
end)
]]

runFunction(function()
    local antiKick = {Enabled = false}
    local installed = false
    local oldNameCall
    antiKick = Tabs.Utility:CreateToggle({
        Name = "AntiKick",
        HoverText = "Removes client sided kicks. Requires hookmetamethod function.",
        Callback = function(enabled)
            if not hookmetamethod then
                if enabled then GuiLibrary:CreateNotification("AntiKick", "Missing hookmetamethod function.", 10, "Error") end
                return
            end
            if installed then return end
            oldNameCall = hookmetamethod(game, "__namecall", function(Self, ...)
                local method = tostring(string.lower(getnamecallmethod()))
                if method == "kick" and antiKick.Enabled then
                    GuiLibrary:CreateNotification("AntiKick", "Detected kick attempt.", 7, "Warning")
                    return nil
                end
                return oldNameCall(Self, ...)
            end)
            installed = true
        end
    })
end)

--[[doesn't work, 2 days of work in nothing :sob:
runFunction(function()
    local Mode = {Value = "Toggle"}
    local Radius = {Value = 10}
    local Delay = {Value = 1}
    local AutoClickDetector = Tabs.Utility:CreateToggle({
        Name = "AutoClickDetector",
        Keybind = nil,
        Callback = function(callback) 
            if callback then 
                if fireclickdetector then
                    if Mode.Value == "Toggle" then
                        RunLoops:BindToHeartbeat("AutoClickDetector", function(Delta)
                            local NearClickDetectors = GetNearInstances(Radius.Value, LocalPlayer, "ClickDetector")

                            if NearClickDetectors and NearClickDetectors[1] then
                                for _, ClickDetector in pairs(NearClickDetectors) do
                                    fireclickdetector(ClickDetector)
                                end
                            end
                        end)
                    elseif Mode.Value == "Button" then
                        local NearClickDetectors = GetNearInstances()

                        if NearClickDetectors and NearClickDetectors[1] then
                            for _, ClickDetector in pairs(NearClickDetectors) do
                                fireclickdetector(ClickDetector)
                            end
                        end
                    end
                else
                    GuiLibrary:CreateNotification("AutoClickDetector", "Missing fireclickdetector function.", 10, false)
                    AntiKick:Toggle(true)
                    return
                end
            else
                RunLoops:UnbindFromHeartbeat("AutoClickDetector")
            end
        end
    })

    local Mode = AutoClickDetector:CreateDropdown({
        Name = "Mode",
        List = {"Toggle", "Button"},
        Default = "Toggle",
        Callback = function(v) end
    })

    local Delay = AutoClickDetector:CreateSlider({
        Name = "Delay (seconds)",
        Function = function(v) end,
        Min = 0,
        Max = 5,
        Default = 0.1,
        Round = 1
    })

    local Radius = AutoClickDetector:CreateSlider({
        Name = "Radius (studs)",
        Function = function(v) end,
        Min = 0,
        Max = 500,
        Default = 10,
        Round = 0
    })
end)
]]

runFunction(function()
    local autoRejoin = {Enabled = false}
    local delay = {Value = 5}
    local sameServer = {Value = false}
    autoRejoin = Tabs.Utility:CreateToggle({
        Name = "AutoRejoin",
        HoverText = "Automatically rejoins when you get kicked for idling.",
        Callback = function(callback) 
            if callback then 
                repeat wait(delay.Value) until autoRejoin.Enabled == false or #CoreGui.RobloxPromptGui.promptOverlay:GetChildren() ~= 0
                if autoRejoin.Enabled and sameServer then 
                    if #Players:GetPlayers() <= 1 then
                        localPlayer:Kick("\nRejoining...")
                        task.wait()
                        teleportService:Teleport(PlaceId, localPlayer)
                    else
                        teleportService:TeleportToPlaceInstance(PlaceId, JobId, localPlayer)
                    end
                else
                    if #Players:GetPlayers() <= 1 then
                        localPlayer:Kick("\nRejoining...")
                        task.wait()
                        teleportService:Teleport(PlaceId, localPlayer)
                    end
                end
            end
        end
    })

    delay = autoRejoin:CreateSlider({
        Name = "Delay",
        Function = function(v) end,
        Min = 0,
        Max = 60,
        Default = 5,
        Round = 0
    })

    sameServer = autoRejoin:CreateToggle({
        Name = "SameServer",
        Default = true,
        Function = function() end
    })
end)

runFunction(function()
    local cameraUnlock = {Enabled = false}
    local oldZoomDistance
    cameraUnlock = Tabs.Utility:CreateToggle({
        Name = "CameraUnlock",
        HoverText = "Makes you able to zoom out your camera very far.",
        Callback = function(callback)
            if callback then
                oldZoomDistance = localPlayer.CameraMaxZoomDistance
                localPlayer.CameraMaxZoomDistance = 99999999
            else
                localPlayer.CameraMaxZoomDistance = oldZoomDistance
            end
        end
    })
end)

-- roblox removed old chat, rip
runFunction(function()
    local chatSpammer = {Enabled = false}
    local mode = {Value = "Random"}
    local spamMessages = {List = {}}
    local delay = {Value = 1}
    local hideFloodMessage = {Value = false}
    local connection, max, current = nil, 0, 1
    chatSpammer = Tabs.Utility:CreateToggle({
        Name = "ChatSpammer",
        HoverText = "Automatically sends messages in chat.",
        Callback = function(callback) 
            if callback then
                if TextChatService.ChatVersion == Enum.ChatVersion.TextChatService then
                    repeat
                        local msg
                        if mode.Value == "Random" then
                            if #spamMessages.List == 0 then
                                msg = "Hello world!"
                            else
                                msg = spamMessages.List[math.random(1, #spamMessages.List)]
                            end
                        elseif mode.Value == "Order" then
                            max = #spamMessages.List
                            if #spamMessages.List == 0 then
                                msg = "Hello world!"
                            end
                            if spamMessages.List[current] then
                                msg = spamMessages.List[current]
                                current = current + 1
                                if current > max then
                                    current = 1
                                end
                            else
                                current = 1
                            end
                        end
                        TextChatService.ChatInputBarConfiguration.TargetTextChannel:SendAsync(msg)
                        wait(delay.Value)
                    until not chatSpammer.Enabled
                end
                if hideFloodMessage.Value then
                    local ExperienceChat = CoreGui:FindFirstChild("ExperienceChat")
                    if ExperienceChat then
                        local RCTScrollContentView = ExperienceChat:FindFirstChild("RCTScrollContentView")
                        if RCTScrollContentView then
                            connection = RCTScrollContentView.ChildAdded:Connect(function(msg)
                                if msg.ContentText == "You must wait before sending another message." then
                                    msg.Visible = false
                                end
                            end)
                        end
                    end
                end
            else
                if connection then
                    connection:Disconnect()
                end
            end
        end
    })

    mode = chatSpammer:CreateDropdown({
        Name = "Mode",
        List = {"Random", "Order"},
        Default = "Random",
        Callback = function(v) end
    })

    spamMessages = chatSpammer:CreateTextList({
        Name = "SpamMessages",
        PlaceholderText = "Messages to spam",
        DefaultList = {},
        HideAdd = true,
        Function = function(v) end,
    })

    delay = chatSpammer:CreateSlider({
        Name = "Delay",
        Function = function(v) end,
        Min = 0,
        Max = 10,
        Default = 1,
        Round = 1
    })

    hideFloodMessage = chatSpammer:CreateToggle({
        Name = "HideFloodMessage",
        Default = false,
        Function = function(callback) end
    })
end)

runFunction(function()
    local customAnimations = {Enabled = false}
    local idleAnimation1 = {Value = ""}
    local idleAnimation2 = {Value = ""}
    local walkAnimation = {Value = ""}
    local runAnimation = {Value = ""}
    local jumpAnimation = {Value = ""}
    local fallAnimation = {Value = ""}
    local climbAnimation = {Value = ""}
    local swimIdleAnimation = {Value = ""}
    local swimAnimation = {Value = ""}
    local values = {}
    local animations = {
        Animation1 = "idle",
        Animation2 = "idle",
        WalkAnim = "walk",
        RunAnim = "run",
        JumpAnim = "jump",
        FallAnim = "fall",
        ClimbAnim = "climb",
        SwimIdle = "swimidle",
        Swim = "swim"
    }
    local oldAnimations = {}
    local availableAnimations = {}
    for name, path in next, animations do
        local animationFolder = Animate and Animate:FindFirstChild(path)
        local animationObject = animationFolder and animationFolder:FindFirstChild(name)
        if animationObject and animationObject:IsA("Animation") then
            oldAnimations[name] = animationObject.AnimationId
            table.insert(availableAnimations, {Name = name, Path = path})
        end
    end
    customAnimations = Tabs.Utility:CreateToggle({
        Name = "CustomAnimations",
        HoverText = "Customizes your animations.",
        Callback = function(callback) 
            if callback then
                --[[
                Animate.idle.Animation1.AnimationId = tonumber(idleAnimation1.Value) and "http://www.roblox.com/asset/?id=" .. idleAnimation1.Value or idleAnimation1.Value
                Animate.idle.Animation2.AnimationId = tonumber(idleAnimation2.Value) and "http://www.roblox.com/asset/?id=" .. idleAnimation2.Value or idleAnimation2.Value
                Animate.walk.WalkAnim.AnimationId = tonumber(walkAnimation.Value) and "http://www.roblox.com/asset/?id=" .. walkAnimation.Value or walkAnimation.Value
                Animate.run.RunAnim.AnimationId = tonumber(runAnimation.Value) and "http://www.roblox.com/asset/?id=" .. runAnimation.Value or runAnimation.Value
                Animate.jump.JumpAnim.AnimationId = tonumber(jumpAnimation.Value) and "http://www.roblox.com/asset/?id=" .. jumpAnimation.Value or jumpAnimation.Value
                Animate.fall.FallAnim.AnimationId = tonumber(fallAnimation.Value) and "http://www.roblox.com/asset/?id=" .. fallAnimation.Value or fallAnimation.Value
                Animate.climb.ClimbAnim.AnimationId = tonumber(climbAnimation.Value) and "http://www.roblox.com/asset/?id=" .. climbAnimation.Value or climbAnimation.Value
                Animate.swimidle.SwimIdle.AnimationId = tonumber(swimIdleAnimation.Value) and "http://www.roblox.com/asset/?id=" .. swimIdleAnimation.Value or swimIdleAnimation.Value
                Animate.swim.Swim.AnimationId = tonumber(swimAnimation.Value) and "http://www.roblox.com/asset/?id=" .. swimAnimation.Value or swimAnimation.Value
                ]]
                for _, entry in ipairs(availableAnimations) do
                    local animationObject = Animate:FindFirstChild(entry.Path):FindFirstChild(entry.Name)
                    animationObject.AnimationId = values[entry.Name].Value ~= "" and (tonumber(values[entry.Name].Value) and "http://www.roblox.com/asset/?id=" .. values[entry.Name].Value or values[entry.Name].Value) or oldAnimations[entry.Name]
                end
            else
                --[[
                Animate.idle.Animation1.AnimationId = oldAnimations.IdleAnimation1
                Animate.idle.Animation2.AnimationId = oldAnimations.IdleAnimation2
                Animate.walk.WalkAnim.AnimationId = oldAnimations.WalkAnimation
                Animate.run.RunAnim.AnimationId = oldAnimations.RunAnimation
                Animate.jump.JumpAnim.AnimationId = oldAnimations.JumpAnimation
                Animate.fall.FallAnim.AnimationId = oldAnimations.FallAnimation
                Animate.climb.ClimbAnim.AnimationId = oldAnimations.ClimbAnimation
                Animate.swimidle.SwimIdle.AnimationId = oldAnimations.SwimIdleAnimation
                Animate.swim.Swim.AnimationId = oldAnimations.SwimAnimation
                ]]
                for _, entry in ipairs(availableAnimations) do
                    Animate:FindFirstChild(entry.Path):FindFirstChild(entry.Name).AnimationId = oldAnimations[entry.Name]
                end
            end
        end
    })
    --[[
    idleAnimation1 = customAnimations:CreateTextBox({
        Name = "IdleAnimation1",
        PlaceholderText = "Idle Animation1 ID",
        DefaultValue = "",
        Function = function(v) end,
    })

    idleAnimation2 = customAnimations:CreateTextBox({
        Name = "IdleAnimation2",
        PlaceholderText = "Idle Animation1 ID",
        DefaultValue = "",
        Function = function(v) end,
    })

    walkAnimation = customAnimations:CreateTextBox({
        Name = "WalkAnimation",
        PlaceholderText = "Walk Animation ID",
        DefaultValue = "",
        Function = function(v) end,
    })

    runAnimation = customAnimations:CreateTextBox({
        Name = "RunAnimation",
        PlaceholderText = "Run Animation ID",
        DefaultValue = "",
        Function = function(v) end,
    })

    jumpAnimation = customAnimations:CreateTextBox({
        Name = "JumpAnimation",
        PlaceholderText = "Jump Animation ID",
        DefaultValue = "",
        Function = function(v) end,
    })

    fallAnimation = customAnimations:CreateTextBox({
        Name = "FallAnimation",
        PlaceholderText = "Fall Animation ID",
        DefaultValue = "",
        Function = function(v) end,
    })

    climbAnimation = customAnimations:CreateTextBox({
        Name = "ClimbAnimation",
        PlaceholderText = "Climb Animation ID",
        DefaultValue = "",
        Function = function(v) end,
    })

    swimIdleAnimation = customAnimations:CreateTextBox({
        Name = "SwimIdleAnimation",
        PlaceholderText = "Swim Idle Animation ID",
        DefaultValue = "",
        Function = function(v) end,
    })

    swimAnimation = customAnimations:CreateTextBox({
        Name = "SwimAnimation",
        PlaceholderText = "Swim Animation ID",
        DefaultValue = "",
        Function = function(v) end,
    })
    ]]
    for _, entry in ipairs(availableAnimations) do
        values[entry.Name] = customAnimations:CreateTextBox({
            Name = entry.Name == "Animation1" and "Idle1" or entry.Name == "Animation2" and "Idle2" or entry.Name,
            PlaceholderText = entry.Name.." ID",
            DefaultValue = ""
        })
    end
end)

runFunction(function()
    local consoleCommands = {Enabled = false}
    local commandbar
    local connection
    consoleCommands = Tabs.Utility:CreateToggle({
        Name = "ConsoleCommands",
        HoverText = "Creates a command bar in dev console.",
        Callback = function(callback)
            if callback then
                commandbar = Instance.new("Frame")
                local inputField = Instance.new("Frame")
                local textBox = Instance.new("TextBox")
                local arrow = Instance.new("TextLabel")

                commandbar.Name = "commandbar"
                commandbar.BackgroundColor3 = Color3.fromRGB(45.00000111758709, 45.00000111758709, 45.00000111758709)
                commandbar.BorderColor3 = Color3.fromRGB(184.00000423192978, 184.00000423192978, 184.00000423192978)
                commandbar.Position = UDim2.new(0, 0, 1, -30)
                commandbar.Size = UDim2.new(1, 0, 0, 30)
                commandbar.Parent = CoreGui.DevConsoleMaster.DevConsoleWindow

                inputField.Name = "inputfield"
                inputField.BackgroundTransparency = 1
                inputField.ClipsDescendants = true
                inputField.Position = UDim2.new(0, 30, 0, 0)
                inputField.Size = UDim2.new(1, -30, 0, 30)
                inputField.Parent = commandbar

                textBox.BackgroundTransparency = 1
                textBox.ClearTextOnFocus = false
                textBox.Font = Enum.Font.Code
                textBox.PlaceholderText = "command line"
                textBox.Text = ""
                textBox.TextColor3 = Color3.fromRGB(255, 255, 255)
                textBox.TextSize = 15
                textBox.TextXAlignment = Enum.TextXAlignment.Left
                textBox.Size = UDim2.new(1, 0, 1, 0)
                textBox.Parent = inputField
                textBox.ZIndex = 50

                arrow.Name = "arrow"
                arrow.BackgroundTransparency = 1
                arrow.Font = Enum.Font.Code
                arrow.Text = "> "
                arrow.TextColor3 = Color3.fromRGB(255, 255, 255)
                arrow.TextSize = 15
                arrow.TextXAlignment = Enum.TextXAlignment.Right
                arrow.Size = UDim2.new(0, 30, 1, 0)
                arrow.Parent = commandbar

                connection = textBox.FocusLost:Connect(function(enterpressed)
                    if enterpressed then
                        local suc, res = pcall(function()
                            loadstring(textBox.Text)()
                        end)
                        if not suc then
                            warn("[Nightix/ConsoleCommands]: " .. tostring(res))
                        end
                        textBox.Text = ""
                    end
                end)
                table.insert(connections, connection)
            else
                commandbar:Destroy()
                betterDisconnect(connection)
            end
        end
    })
end)

--[[this doesn't work
runFunction(function()
    local godMode = {Enabled = false}
    local mode = {Value = "Heal"}
    local healthThreshold = {Value = 100}
    local connection
    local notificationCooldown = 0
    local lastNotificationTime = 0
    local isInitialized = false
    local retryAttempts = 0
    local maxRetryAttempts = 5
    local retryDelay = 2
    local originalJumpPower
    local originalWalkSpeed
    local originalHealth
    local originalMaxHealth
    local damageHistory = {}
    local damageProtection = {active = false, cooldown = 0}
    
    local function cleanupConnections()
        if connection then
            connection:Disconnect()
            connection = nil
        end
    end
    
    local function restoreOriginalValues(humanoid)
        if originalJumpPower and humanoid then
            humanoid.JumpPower = originalJumpPower
        end
        
        if originalWalkSpeed and humanoid then
            humanoid.WalkSpeed = originalWalkSpeed
        end
        
        if originalHealth and humanoid then
            humanoid.Health = originalHealth
        end
        
        if originalMaxHealth and humanoid then
            humanoid.MaxHealth = originalMaxHealth
        end
    end
    
    local function showNotification(title, message, duration)
        local currentTime = tick()
        if currentTime - lastNotificationTime >= notificationCooldown then
            GuiLibrary:CreateNotification(title, message, duration or 3)
            lastNotificationTime = currentTime
            notificationCooldown = duration or 3
        end
    end
    
    local function initializeGodMode(character, humanoid, hrp)
        if not character or not humanoid or not hrp then return false end
        
        originalJumpPower = humanoid.JumpPower
        originalWalkSpeed = humanoid.WalkSpeed
        originalHealth = humanoid.Health
        originalMaxHealth = humanoid.MaxHealth
        
        isInitialized = true
        retryAttempts = 0
        
        return true
    end
    
    local function applyHealMode(humanoid)
        if not connection then
            connection = humanoid.GetPropertyChangedSignal("Health"):Connect(function()
                local targetHealth = healthThreshold.Value
                
                if humanoid.Health < targetHealth then
                    table.insert(damageHistory, {
                        time = tick(),
                        oldHealth = humanoid.Health,
                        damage = originalHealth - humanoid.Health
                    })
                    
                    if #damageHistory > 10 then
                        table.remove(damageHistory, 1)
                    end
                    
                    if not damageProtection.active then
                        damageProtection.active = true
                        damageProtection.cooldown = tick() + 0.5
                        humanoid.Health = targetHealth
                    end
                    
                    if tick() > damageProtection.cooldown then
                        damageProtection.active = false
                    end
                end
            end)
        end
    end
    
    local function applyHRPMode(character, hrp)
        cleanupConnections()
        
        if hrp then
            local clone = hrp:Clone()
            clone.Transparency = 1
            clone.CanCollide = false
            
            local weld = Instance.new("Weld")
            weld.Part0 = hrp
            weld.Part1 = clone
            weld.C0 = CFrame.new()
            weld.C1 = CFrame.new()
            weld.Parent = hrp
            
            hrp.CanCollide = false
            hrp.Transparency = 1
            
            clone.Parent = character
            hrp.Name = "RealHRP"
            clone.Name = "HumanoidRootPart"
        end
    end
    
    local function applyAntiKnockbackMode(character, humanoid)
        cleanupConnections()
        
        if humanoid then
            humanoid.StateChanged:Connect(function(oldState, newState)
                if newState == Enum.HumanoidStateType.Ragdoll or 
                   newState == Enum.HumanoidStateType.FallingDown then
                    task.wait()
                    humanoid:ChangeState(Enum.HumanoidStateType.GettingUp)
                end
            end)
            
            if humanoid.RigType == Enum.HumanoidRigType.R6 then
                for _, part in pairs(character:GetChildren()) do
                    if part:IsA("BasePart") and part.Name ~= "HumanoidRootPart" then
                        part.CustomPhysicalProperties = PhysicalProperties.new(math.huge, 0, 0)
                    end
                end
            else
                for _, part in pairs(character:GetDescendants()) do
                    if part:IsA("MeshPart") and part.Name ~= "HumanoidRootPart" then
                        part.CustomPhysicalProperties = PhysicalProperties.new(math.huge, 0, 0)
                    end
                end
            end
        end
    end
    
    local function applyInvulnerabilityMode(character, humanoid)
        cleanupConnections()
        
        if humanoid then
            humanoid.MaxHealth = math.huge
            humanoid.Health = math.huge
            
            connection = humanoid.GetPropertyChangedSignal("Health"):Connect(function()
                if humanoid.Health < math.huge then
                    humanoid.Health = math.huge
                end
            end)
        end
    end
    
    godMode = Tabs.Utility:CreateToggle({
        Name = "GodMode",
        Keybind = nil,
        Callback = function(callback)
            if callback then
                RunLoops:BindToHeartbeat("GodMode", function()
                    if isAlive(LocalPlayer, false) then
                        local Character = LocalPlayer.Character
                        local Humanoid = Character.Humanoid
                        local HumanoidRootPart = Character.HumanoidRootPart
                        
                        if not isInitialized then
                            if not initializeGodMode(Character, Humanoid, HumanoidRootPart) then
                                retryAttempts = retryAttempts + 1
                                if retryAttempts >= maxRetryAttempts then
                                    showNotification("GodMode", "Failed to initialize after multiple attempts. Please try again.", 5)
                                    godMode:Toggle(false)
                                    return
                                end
                                showNotification("GodMode", "Initializing... Attempt " .. retryAttempts .. "/" .. maxRetryAttempts, 1)
                                task.wait(retryDelay)
                                return
                            end
                            showNotification("GodMode", "Successfully initialized!", 2)
                        end
                        
                        if mode.Value == "Heal" then
                            applyHealMode(Humanoid)
                        elseif mode.Value == "HRP" then
                            applyHRPMode(Character, HumanoidRootPart)
                        elseif mode.Value == "AntiKnockback" then
                            applyAntiKnockbackMode(Character, Humanoid)
                        elseif mode.Value == "Invulnerability" then
                            applyInvulnerabilityMode(Character, Humanoid)
                        end
                    else
                        isInitialized = false
                        cleanupConnections()
                        if retryAttempts < maxRetryAttempts then
                            retryAttempts = retryAttempts + 1
                            showNotification("GodMode", "Character not found. Retrying... (" .. retryAttempts .. "/" .. maxRetryAttempts .. ")", 2)
                            task.wait(retryDelay)
                        else
                            showNotification("GodMode", "Unable to find character after multiple attempts. Please try again.", 5)
                            godMode:SetState(false)
                        end
                    end
                end)
            else
                isInitialized = false
                retryAttempts = 0
                cleanupConnections()
                RunLoops:UnbindFromHeartbeat("GodMode")
                
                if isAlive(LocalPlayer, false) then
                    local Character = LocalPlayer.Character
                    local Humanoid = Character.Humanoid
                    
                    restoreOriginalValues(Humanoid)
                    
                    if mode.Value == "HRP" then
                        local realHRP = Character:FindFirstChild("RealHRP")
                        local fakeHRP = Character:FindFirstChild("HumanoidRootPart")
                        
                        if realHRP and fakeHRP then
                            realHRP.Name = "HumanoidRootPart"
                            realHRP.Transparency = 0
                            realHRP.CanCollide = true
                            fakeHRP:Destroy()
                        end
                    end
                end
                
                showNotification("GodMode", "Disabled", 2)
            end
        end
    })

    mode = godMode:CreateDropdown({
        Name = "Mode",
        List = {"Heal", "HRP", "AntiKnockback", "Invulnerability"},
        Default = "Heal",
        Function = function(v)
            if godMode.Enabled then
                isInitialized = false
                cleanupConnections()
                showNotification("GodMode", "Mode changed to " .. v .. ". Reinitializing...", 2)
            end
        end
    })
    
    healthThreshold = godMode:CreateSlider({
        Name = "Health Threshold",
        Min = 1,
        Max = 200,
        Default = 100,
        Round = 0,
        Function = function(val) 
            if mode.Value == "Heal" and godMode.Enabled and connection then
                cleanupConnections()
                
                if isAlive(LocalPlayer, false, true) then
                    local Humanoid = LocalPlayer.Character.Humanoid
                    applyHealMode(Humanoid)
                end
            end
        end
    })
end)
]]

runFunction(function()
    local cache = {}
    local doing = false
    local waiting
    Tabs.Utility:CreateToggle({
        Name = "GodMode",
        HoverText = "Makes it almost impossible to kill you via deleteting humanoid.\n(does not bypass good anti cheats)",
        Callback = function(callback)
            if callback then
                RunLoops:BindToHeartbeat("godMode", function()
                    if isAlive() then
                        local character = getCharacter()
                        local humanoid = getHumanoid()
                        if doing or (not humanoid or (humanoid and cache[humanoid] == true)) or not character then return end--if not humanoid or not character then return end
                        doing = true
                        humanoid.Name = "oldone"
                        local new = humanoid:Clone()
                        cache[new] = true
                        new.Parent = character
                        new.Name = "Humanoid"
                        humanoid:Destroy()
                        Camera.CameraSubject = character
                        local animate = character:FindFirstChild("Animate")
                        waiting = tick()
                        repeat
                            task.wait()
                        until animate or tick() - waiting > 5
                        if not animate then
                            cache[new] = false
                            GuiLibrary:CreateNotification("GodMode", "Couldn't find animate script.", 5, "Error")
                        end
                        if animate then animate.Disabled = true end
                        task.wait(0.1)
                        if animate then animate.Disabled = false end
                        doing = false
                    end
                end)
            else
                RunLoops:UnbindFromHeartbeat("godMode")
                GuiLibrary:CreateNotification("GodMode", "Reset to get humanoid back.", 5, "Info")
                cache = {}
            end
        end
    })
end)

runFunction(function()
    local fastProximityPrompts = {Enabled = false}
    local duration = {Value = 0.1}
    local objects = {}
    fastProximityPrompts = Tabs.Utility:CreateToggle({
        Name = "FastProximityPrompts",
        HoverText = "Makes you able to customize proximity prompt hold duration.",
        Callback = function(callback)
            if callback then
                for _, ProximityObject in pairs(workspace:GetDescendants()) do
                    if ProximityObject:IsA("ProximityPrompt") then
                        objects[ProximityObject] = ProximityObject.HoldDuration
                        ProximityObject.HoldDuration = duration.Value
                    end
                end
            else
                for ProximityObject, OriginalHoldDuration in pairs(objects) do
                    if ProximityObject:IsA("ProximityPrompt") then
                        ProximityObject.HoldDuration = OriginalHoldDuration
                    end
                end
                table.clear(objects)
            end
        end
    })

    duration = fastProximityPrompts:CreateSlider({
        Name = "HoldDuration",
        Function = function(v)
            if fastProximityPrompts.Enabled then
                for _, Object in pairs(workspace:GetDescendants()) do
                    if Object:IsA("ProximityPrompt") then
                        Object.HoldDuration = duration.Value
                    end
                end
            end
        end,
        Min = 0,
        Max = 10,
        Default = 0,
        Round = 1
    })
end)

runFunction(function()
    local fpsUnlocker = {Enabled = false}
    fpsUnlocker = Tabs.Utility:CreateToggle({
        Name = "FPSUnlocker",
        HoverText = "Unlocks your FPS.",
        Callback = function(callback)
            if callback then
                if setfpscap then
                    setfpscap(10000000)
                else
                    GuiLibrary:CreateNotification("FPSUnlocker", "Missing setfpscap function.", 10, "Error")
                    fpsUnlocker:Toggle(true)
                    return
                end
            end
        end
    })
end)

runFunction(function()
    local infiniteJump = {Enabled = false}
    local connection
    infiniteJump = Tabs.Utility:CreateToggle({
        Name = "InfinityJump",
        HoverText  = "Allows you to jump infinitely.",
        Callback = function(callback) 
            if callback then 
                connection = UserInputService.JumpRequest:Connect(function()
                    if callback then
                        getHumanoid():ChangeState(3)
                    end
                end)
            else
                betterDisconnect(connection)
            end
        end
    })
end)

runFunction(function()
    local panic = {Enabled = false}
    panic = Tabs.Utility:CreateToggle({
        Name = "Panic",
        HoverText = "Disables all toggles.\nNote that it disables saving, to start it again reinject.",
        Callback = function(callback)
            if callback then
                GuiLibrary.CanSaveConfig = false
                for _, table in next, GuiLibrary.ObjectsToSave.Toggles do
                    if table.API.Enabled and table.API.Name ~= "Panic" then
                        if table.API.SetEnabled then
                            table.API:SetEnabled(false, true)
                        else
                            table.API:Toggle(false, false)
                        end
                    end
                end
                panic:Toggle(true)
            end
        end
    })
end)

runFunction(function()
    local reset = {Enabled = false}
    reset = Tabs.Utility:CreateToggle({
        Name = "Reset",
        HoverText = "Resets your character.",
        Callback = function(callback)
            if callback then
                if isAlive() then
                    local humanoid = getHumanoid()
                    humanoid:TakeDamage(humanoid.MaxHealth)
                end
                reset:Toggle(false, false)
            end
        end
    })
end)

runFunction(function()
    local rejoin = {Enabled = false}
    rejoin = Tabs.Utility:CreateToggle({
        Name = "Rejoin",
        HoverText = "Rejoins the same game to the same server.",
        Callback = function(callback) 
            if callback then 
                rejoin:Toggle(false, false)
                teleportService:TeleportToPlaceInstance(PlaceId, JobId, LocalPlayer)
            end
        end
    })
end)

runFunction(function()
    local serverHop = {Enabled = false}
    serverHop = Tabs.Utility:CreateToggle({
        Name = "ServerHop",
        HoverText = "Joins the same game but to the different server.",
        Callback = function(callback) 
            if callback then 
                serverHop:Toggle(false, false)
                teleportService:Teleport(PlaceId)
            end
        end
    })
end)

-- World tab
runFunction(function()
    local antiVoid = {Enabled = false}
    local mode = {Value = "Jump"}
    local delay = {Value = 0.1}
    local bounceForce = {Value = 150}
    local tpToSpawnLocation = {Value = false}
    local LastSafePosition = nil
    local IsBeingRescued = false
    local AntiVoidPlatform = nil
    local voidYpos = -200
    local oldjumppower
    local connection

    local function isOnGround()
        if not isAlive() then return false end
        
        local character = LocalPlayer.Character
        local humanoid = character:FindFirstChildOfClass("Humanoid")
        local rootPart = character:FindFirstChild("HumanoidRootPart")
        
        if not rootPart then return false end
        
        local rayParams = RaycastParams.new()
        rayParams.FilterDescendantsInstances = {character}
        rayParams.FilterType = Enum.RaycastFilterType.Blacklist
        
        local result = workspace:Raycast(
            rootPart.Position,
            Vector3.new(0, -10, 0),
            rayParams
        )
        
        return result ~= nil and humanoid:GetState() ~= Enum.HumanoidStateType.Freefall
    end
    
    local function savePosition()
        if not isAlive() or not isOnGround() then return end
        
        local rootPart = LocalPlayer.Character.HumanoidRootPart
        LastSafePosition = rootPart.CFrame
    end
    
    local function RescueFromVoid()
        local RootPart = LocalPlayer.Character:FindFirstChild("HumanoidRootPart")
        local Humanoid = LocalPlayer.Character:FindFirstChildOfClass("Humanoid")
        oldjumppower = Humanoid.JumpPower
        if not isAlive() or IsBeingRescued then return end
        
        if RootPart.Position.Y <= voidYpos then
            IsBeingRescued = true
            
            if mode.Value == "Jump" and AntiVoidPlatform then
                AntiVoidPlatform.CFrame = CFrame.new(RootPart.Position.X, voidYpos, RootPart.Position.Z)
                
                Humanoid.JumpPower = bounceForce.Value
                Humanoid:ChangeState(Enum.HumanoidStateType.Jumping)
            else
                if LastSafePosition then
                    RootPart.CFrame = LastSafePosition
                    Humanoid:ChangeState(Enum.HumanoidStateType.GettingUp)
                else
                    local spawnLocation = nil
                    for _, obj in pairs(workspace:GetDescendants()) do
                        if obj:IsA("SpawnLocation") and obj.Enabled then
                            spawnLocation = obj
                            break
                        end
                    end
                    
                    if spawnLocation and tpToSpawnLocation.Value then
                        RootPart.CFrame = spawnLocation.CFrame * CFrame.new(0, 5, 0)
                        Humanoid:ChangeState(Enum.HumanoidStateType.GettingUp)
                    else
                        RootPart.CFrame = CFrame.new(RootPart.Position.X, math.abs(voidYpos), RootPart.Position.Z)
                        Humanoid:ChangeState(Enum.HumanoidStateType.GettingUp)
                    end
                end
            end
            
            task.delay(delay.Value, function()
                Humanoid.JumpPower = oldjumppower
                IsBeingRescued = false
            end)
        end
    end

    antiVoid = Tabs.World:CreateToggle({
        Name = "AntiVoid",
        HoverText = "Makes you unable to fall into the void.",
        Callback = function(callback)
            if callback then
                RunLoops:BindToRenderStep("AntiVoid", function()
                    if mode.Value == "Jump" then
                        if not AntiVoidPlatform then
                            AntiVoidPlatform = Instance.new("Part")
                            AntiVoidPlatform.Name = "AntiVoidPlatform"
                            AntiVoidPlatform.Size = Vector3.new(400, 1, 400)
                            AntiVoidPlatform.Anchored = true
                            AntiVoidPlatform.CanCollide = true
                            AntiVoidPlatform.Transparency = 1
                            AntiVoidPlatform.Parent = workspace
                        end
                    end
                end)
                connection = RunService.Stepped:Connect(function(deltaTime)
                    local RootPart = LocalPlayer.Character:FindFirstChild("HumanoidRootPart")
                    if antiVoid.Enabled then
                        savePosition(deltaTime)
                        RescueFromVoid()
                        
                        if mode.Value == "Jump" and AntiVoidPlatform and RootPart and RootPart.Position.Y > (voidYpos + math.abs(voidYpos)) then
                            AntiVoidPlatform.CFrame = CFrame.new(RootPart.Position.X, voidYpos - 50, RootPart.Position.Z)
                        end
                    end
                end)
            else
                RunLoops:UnbindFromRenderStep("AntiVoid")
                if AntiVoidPlatform then
                    AntiVoidPlatform:Destroy()
                end
                betterDisconnect(connection)
            end
        end
    })

    mode = antiVoid:CreateDropdown({
        Name = "Mode",
        Function = function(v) end,
        List = {"Jump", "Teleport"},
        Default = "Jump"
    })

    delay = antiVoid:CreateSlider({
        Name = "PosCheckDelay",
        Function = function(v) end,
        Min = 0,
        Max = 1,
        Default = 0.1,
        Round = 1
    })

    bounceForce = antiVoid:CreateSlider({
        Name = "Bounce Force",
        Function = function(v) end,
        Min = 0,
        Max = 500,
        Default = 150,
        Round = 0
    })

    tpToSpawnLocation = antiVoid:CreateToggle({
        Name = "TP to Spawn Location",
        Default = false,
        Function = function(v) end
    })
end)

runFunction(function()
    local atmosphereModule = {Enabled = false}
    local color = {Value = Color3.fromRGB(255, 255, 255)}
    local decay = {Value = Color3.fromRGB(255, 255, 255)}
    local density = {Value = 0.5}
    local glare = {Value = 0.5}
    local haze = {Value = 0.5}
    local offset = {Value = 0.5}
    local atmosphere
    local old = {}

    local function applyAtmosphere()
        if not atmosphere or atmosphere.Parent ~= Lighting then return end
        atmosphere.Color = color.Value
        atmosphere.Decay = decay.Value
        atmosphere.Density = density.Value
        atmosphere.Glare = glare.Value
        atmosphere.Haze = haze.Value
        atmosphere.Offset = offset.Value
    end

    atmosphereModule = Tabs.World:CreateToggle({
        Name = "Atmosphere",
        HoverText = "Customizes the atmosphere of the game.",
        Callback = function(callback)
            if callback then
                -- Hide existing atmospheres without parenting them under game.
                -- The old LightingChanged listener recreated the custom
                -- atmosphere immediately after it was destroyed on disable.
                table.clear(old)
                for _, v in ipairs(Lighting:GetChildren()) do
                    if v:IsA("Atmosphere") then
                        table.insert(old, v)
                        v.Parent = nil
                    end
                end

                atmosphere = Instance.new("Atmosphere")
                atmosphere.Parent = Lighting
                applyAtmosphere()
            else
                if atmosphere then
                    atmosphere:Destroy()
                    atmosphere = nil
                end
                for _, v in ipairs(old) do
                    if v and v.Parent == nil then
                        v.Parent = Lighting
                    end
                end
                table.clear(old)
            end
        end
    })

    color = atmosphereModule:CreateColorSlider({
        Name = "Color",
        Default = Color3.fromRGB(255, 255, 255),
        Function = function(v)
            if atmosphere then atmosphere.Color = v end
        end
    })

    decay = atmosphereModule:CreateColorSlider({
        Name = "Decay",
        Default = Color3.fromRGB(255, 255, 255),
        Function = function(v)
            if atmosphere then atmosphere.Decay = v end
        end
    })

    density = atmosphereModule:CreateSlider({
        Name = "Density",
        Function = function(v)
            if atmosphere then atmosphere.Density = v end
        end,
        Min = 0,
        Max = 1,
        Default = 0.5,
        Round = 2
    })

    glare = atmosphereModule:CreateSlider({
        Name = "Glare",
        Function = function(v)
            if atmosphere then atmosphere.Glare = v end
        end,
        Min = 0,
        Max = 1,
        Default = 0.5,
        Round = 2
    })

    haze = atmosphereModule:CreateSlider({
        Name = "Haze",
        Function = function(v)
            if atmosphere then atmosphere.Haze = v end
        end,
        Min = 0,
        Max = 1,
        Default = 0.5,
        Round = 2
    })

    offset = atmosphereModule:CreateSlider({
        Name = "Offset",
        Function = function(v)
            if atmosphere then atmosphere.Offset = v end
        end,
        Min = -1,
        Max = 1,
        Default = 0,
        Round = 2
    })
end)

runFunction(function()
    local gravity = {Enabled = false}
    local value = {Value = 18}
    local oldGravity
    gravity = Tabs.World:CreateToggle({
        Name = "Gravity",
        HoverText = "Changes the game gravity.",
        Callback = function(callback)
            if callback then
                oldGravity = workspace.Gravity
                workspace.Gravity = value.Value
            else
                if oldGravity ~= nil then workspace.Gravity = oldGravity end
            end
        end
    })
    
    value = gravity:CreateSlider({
        Name = "Gravity",
        Function = function(v)
            if gravity.Enabled then
                workspace.Gravity = v
            end
        end,
        Min = 1,
        Max = 200,
        Default = 196,
        Round = 0
    })
end)

runFunction(function()
    local customLighting = {Enabled = false}
    local oldLighting = {
        ShadowSoftness = Lighting.ShadowSoftness,
        Brightness = Lighting.Brightness
    }
    local shadowSoftness = {Value = 1}
    local brightness = {Value = 1}
    local sunRaysIntensity = {Value = 1}
    local spread = {Value = 1}
    local bloomIntensity = {Value = 1}
    local bloomSize = {Value = 1}
    local bloomObject
    local sunRaysObject
    local oldLightingObjects = {}
    local connection
    customLighting = Tabs.World:CreateToggle({
        Name = "Lighting",
        HoverText = "Customizes the lighting of the game.",
        Callback = function(callback)
            if callback then
                betterDisconnect(connection)
                table.clear(oldLightingObjects)
                oldLighting.ShadowSoftness = Lighting.ShadowSoftness
                oldLighting.Brightness = Lighting.Brightness
                for _, v in ipairs(Lighting:GetChildren()) do
                    if (v:IsA("BloomEffect") or v:IsA("SunRaysEffect")) and v.Name ~= "BloomObject" and v.Name ~= "SunRaysObject" then
                        table.insert(oldLightingObjects, v)
                        v.Parent = nil
                    end
                end

                if bloomObject then bloomObject:Destroy() end
                if sunRaysObject then sunRaysObject:Destroy() end
                bloomObject = Instance.new("BloomEffect")
                bloomObject.Name = "BloomObject"
                bloomObject.Intensity = bloomIntensity.Value
                bloomObject.Size = bloomSize.Value
                bloomObject.Parent = Lighting

                sunRaysObject = Instance.new("SunRaysEffect")
                sunRaysObject.Name = "SunRaysObject"
                sunRaysObject.Intensity = sunRaysIntensity.Value
                sunRaysObject.Spread = spread.Value
                sunRaysObject.Parent = Lighting

                Lighting.ShadowSoftness = shadowSoftness.Value
                Lighting.Brightness = brightness.Value
            else
                betterDisconnect(connection)
                connection = nil
                if bloomObject then bloomObject:Destroy(); bloomObject = nil end
                if sunRaysObject then sunRaysObject:Destroy(); sunRaysObject = nil end
                Lighting.ShadowSoftness = oldLighting.ShadowSoftness
                Lighting.Brightness = oldLighting.Brightness
                for _, v in ipairs(oldLightingObjects) do
                    if v and v.Parent == nil then v.Parent = Lighting end
                end
                table.clear(oldLightingObjects)
            end
        end
    })

    shadowSoftness = customLighting:CreateSlider({
        Name = "ShadowSoftness",
        Function = function(v) 
            if customLighting.Enabled then
                Lighting.ShadowSoftness = v
            end
        end,
        Min = 0,
        Max = 1,
        Default = 0.5,
        Round = 1
    })

    brightness = customLighting:CreateSlider({
        Name = "Brightness",
        Function = function(v) 
            if customLighting.Enabled then
                Lighting.Brightness = v
            end
        end,
        Min = 0,
        Max = 10,
        Default = 3,
        Round = 1
    })

    sunRaysIntensity = customLighting:CreateSlider({
        Name = "SunRays Intensity",
        Function = function(v) 
            if customLighting.Enabled and sunRaysObject then
                sunRaysObject.Intensity = v
            end
        end,
        Min = 0,
        Max = 1,
        Default = 1,
        Round = 1
    })

    spread = customLighting:CreateSlider({
        Name = "SunRays Spread",
        Function = function(v) 
            if customLighting.Enabled and sunRaysObject then
                sunRaysObject.Spread = v
            end
        end,
        Min = 0,
        Max = 1,
        Default = 1,
        Round = 1
    })

    bloomIntensity = customLighting:CreateSlider({
        Name = "Bloom Intensity",
        Function = function(v) 
            if customLighting.Enabled and bloomObject then
                bloomObject.Intensity = v
            end
        end,
        Min = 0,
        Max = 1,
        Default = 1,
        Round = 2
    })

    bloomSize = customLighting:CreateSlider({
        Name = "Bloom Intensity",
        Function = function(v) 
            if customLighting.Enabled and bloomObject then
                bloomObject.Size = v
            end
        end,
        Min = 0,
        Max = 56,
        Default = 56,
        Round = 0
    })
end)

runFunction(function()
    local customSky={Enabled=false}; local choice={Value="Dune"}; local sky; local old={}; local ids={Dune="138907351102721",Celestial="86696473016531",Day="8613979186",Space="15983996673",Luminar="140307474008766"}
    local function apply() if not sky then return end; local a="rbxassetid://"..ids[choice.Value]; sky.SkyboxBk=a; sky.SkyboxDn=a; sky.SkyboxFt=a; sky.SkyboxLf=a; sky.SkyboxRt=a; sky.SkyboxUp=a end
    customSky=Tabs.World:CreateToggle({Name="SkyShader",HoverText="Меняет небо.",Callback=function(on) if on then table.clear(old); for _,v in ipairs(Lighting:GetChildren()) do if v:IsA("Sky") then table.insert(old,v); v.Parent=nil end end; sky=Instance.new("Sky"); sky.Name="NightixSkyShader"; sky.Parent=Lighting; apply() else if sky then sky:Destroy(); sky=nil end; for _,v in ipairs(old) do if v and v.Parent==nil then v.Parent=Lighting end end; table.clear(old) end end}); choice=customSky:CreateDropdown({Name="Небо",List={"Dune","Celestial","Day","Space","Luminar"},Default="Dune",Function=function(v) choice.Value=v; if customSky.Enabled then apply() end end})
end)

runFunction(function()
    local timeOfDay = {Enabled = false}
    local hours = {Value = 13}
    local minutes = {Value = 0}
    local seconds = {Value = 0}
    local connection
    local oldTime
    local function updateTime()
        Lighting.TimeOfDay = hours.Value..":"..minutes.Value..":"..seconds.Value
    end
    timeOfDay = Tabs.World:CreateToggle({
        Name = "TimeOfDay",
        HoverText = "Customizes the time of the game.",
        Callback = function(callback)
            if callback then
                oldTime = Lighting.TimeOfDay
                updateTime()
                connection = Lighting.Changed:Connect(updateTime)
            else
                betterDisconnect(connection)
                connection = nil
                if oldTime then Lighting.TimeOfDay = oldTime end
            end
        end
    })

    hours = timeOfDay:CreateSlider({
        Name = "Hours",
        Function = function(v)
            if timeOfDay.Enabled then
                updateTime()
            end
        end,
        Min = 0,
        Max = 24,
        Default = 13,
        Round = 0
    })

    minutes = timeOfDay:CreateSlider({
        Name = "Minutes",
        Function = function(v)
            if timeOfDay.Enabled then
                updateTime()
            end
        end,
        Min = 0,
        Max = 60,
        Default = 0,
        Round = 0
    })

    seconds = timeOfDay:CreateSlider({
        Name = "Seconds",
        Function = function(v)
            if timeOfDay.Enabled then
                updateTime()
            end
        end,
        Min = 0,
        Max = 60,
        Default = 0,
        Round = 0
    })
end)

print("[Nightix/Universal.lua]: Loaded in " .. tostring(tick() - startTick) .. ".")
task.spawn(function()
    repeat task.wait() until GuiLibrary.ConfigLoaded
    GuiLibrary:CreateNotification("Universal", "Loaded successfully! Press "..GuiLibrary.GuiKeybind.." to open GUI.", 5, "Info", true)
end)