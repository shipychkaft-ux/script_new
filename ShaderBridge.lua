-- Nightix ShaderBridge 1.0
-- Ports the DESIGN/parameters of SystemDLC shaders to Roblox-native rendering.
-- It never attempts to compile GLSL. .vsh/.fsh are kept as reference sources.

local HttpService = game:GetService("HttpService")
local TweenService = game:GetService("TweenService")
local RunService = game:GetService("RunService")

local ShaderBridge = {}
ShaderBridge.__index = ShaderBridge

local function requestGet(url)
    local fn = request or http_request or (syn and syn.request) or (fluxus and fluxus.request)
    if fn then
        local ok, res = pcall(fn, {Url=url, Method="GET", Headers={['Cache-Control']='no-cache'}})
        if ok and res and (res.StatusCode == nil or res.StatusCode < 400) then return res.Body end
    end
    local ok, body = pcall(function() return game:HttpGet(url) end)
    if ok then return body end
    return nil
end

local function exists(path)
    if not isfile then return false end
    local ok = pcall(function() return isfile(path) end)
    return ok and isfile(path)
end

local function mkdir(path)
    if makefolder and not isfolder(path) then pcall(makefolder, path) end
end

function ShaderBridge.new(opts)
    local self=setmetatable({},ShaderBridge)
    self.BaseUrl=opts.BaseUrl
    self.CacheFolder=opts.CacheFolder or "Mana/Shaders"
    mkdir(self.CacheFolder)
    self.Definitions={}
    self.Active={}
    return self
end

function ShaderBridge:_url(name)
    return self.BaseUrl .. name .. ".json"
end

function ShaderBridge:LoadDefinition(name)
    name=tostring(name)
    if self.Definitions[name] then return self.Definitions[name] end
    local raw=requestGet(self:_url(name))
    if not raw then return nil,"request failed" end
    local ok,data=pcall(function() return HttpService:JSONDecode(raw) end)
    if not ok or type(data)~="table" then return nil,"invalid json" end
    self.Definitions[name]=data
    if writefile then pcall(writefile,self.CacheFolder.."/"..name..".json",raw) end
    return data
end

function ShaderBridge:Get(name)
    return self:LoadDefinition(name)
end

-- Roblox-native approximation of SystemDLC's 4-corner gradient.
function ShaderBridge:CreateGradient(parent, colors, speed)
    local frame=Instance.new("Frame")
    frame.Name="NightixShaderGradient"
    frame.BackgroundTransparency=0
    frame.BorderSizePixel=0
    frame.Size=UDim2.fromScale(1,1)
    frame.ZIndex=(parent.ZIndex or 1)+1
    frame.Parent=parent

    local corner=Instance.new("UICorner")
    corner.CornerRadius=UDim.new(0,12)
    corner.Parent=frame

    local gradient=Instance.new("UIGradient")
    local c1=colors[1] or Color3.new(1,1,1)
    local c2=colors[2] or c1
    gradient.Color=ColorSequence.new(c1,c2)
    gradient.Rotation=0
    gradient.Parent=frame

    local alive=true
    local phase=0
    local conn=RunService.RenderStepped:Connect(function(dt)
        if not alive or not frame.Parent then return end
        phase=(phase+(speed or 0.35)*dt)%1
        gradient.Offset=Vector2.new(phase*2-1,0)
    end)
    frame.Destroying:Connect(function() alive=false; conn:Disconnect() end)
    return frame
end

function ShaderBridge:CreateCircle(parent, color, diameter)
    local frame=Instance.new("Frame")
    frame.Name="NightixShaderCircle"
    frame.Size=UDim2.fromOffset(diameter or 64,diameter or 64)
    frame.AnchorPoint=Vector2.new(.5,.5)
    frame.BackgroundColor3=color or Color3.new(1,1,1)
    frame.BorderSizePixel=0
    frame.Parent=parent
    local c=Instance.new("UICorner")
    c.CornerRadius=UDim.new(1,0)
    c.Parent=frame
    return frame
end

function ShaderBridge:CreateRing(parent, color, thickness, size)
    local holder=self:CreateCircle(parent, Color3.new(1,1,1), size or 64)
    holder.BackgroundTransparency=1
    local stroke=Instance.new("UIStroke")
    stroke.Color=color or Color3.new(1,1,1)
    stroke.Thickness=thickness or 2
    stroke.Parent=holder
    return holder
end

function ShaderBridge:ApplyNativePostFX(options)
    options=options or {}
    local camera=workspace.CurrentCamera
    if not camera then return {} end
    local made={}
    if options.Blur then
        local blur=Instance.new("BlurEffect")
        blur.Size=math.clamp(tonumber(options.Blur) or 0,0,56)
        blur.Parent=camera
        table.insert(made,blur)
    end
    if options.Bloom then
        local bloom=Instance.new("BloomEffect")
        bloom.Intensity=tonumber(options.BloomIntensity) or 0.25
        bloom.Size=tonumber(options.BloomSize) or 24
        bloom.Threshold=tonumber(options.BloomThreshold) or 1
        bloom.Parent=camera
        table.insert(made,bloom)
    end
    if options.Saturation or options.Contrast then
        local cc=Instance.new("ColorCorrectionEffect")
        cc.Saturation=tonumber(options.Saturation) or 0
        cc.Contrast=tonumber(options.Contrast) or 0
        cc.Parent=camera
        table.insert(made,cc)
    end
    return made
end

return ShaderBridge
