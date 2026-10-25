-- Nursultan launcher.
-- Always prefers the latest MainScript.lua from GitHub, falls back to the
-- local copy, and reports real compile errors instead of "nil value".

local REPO = "https://raw.githubusercontent.com/shipychkaft-ux/script_new/main/MainScript.lua"
local cacheBuster = "?v=" .. tostring(math.floor(tick() * 1000))
local source

pcall(function()
    if request then
        local response = request({ Url = REPO .. cacheBuster, Method = "GET" })
        if response and type(response.Body) == "string" and #response.Body > 20 then
            source = response.Body
        end
    elseif http_request then
        local response = http_request({ Url = REPO .. cacheBuster, Method = "GET" })
        if response and type(response.Body) == "string" and #response.Body > 20 then
            source = response.Body
        end
    end
end)

if not source then
    pcall(function()
        if syn and syn.request then
            local response = syn.request({ Url = REPO .. cacheBuster, Method = "GET" })
            if response and type(response.Body) == "string" and #response.Body > 20 then
                source = response.Body
            end
        end
    end)
end

if not source then
    pcall(function()
        source = game:HttpGet(REPO .. cacheBuster)
    end)
end

if (not source or #source < 20) and isfile and isfile("MainScript.lua") then
    warn("[Nursultan]: GitHub unavailable, using the local MainScript.lua copy.")
    source = readfile("MainScript.lua")
end

if not source or #source < 20 then
    error("[Nursultan]: could not download MainScript.lua from GitHub", 0)
end

local loader = loadstring or load
local chunk, compileError = loader(source)
if not chunk then
    error("[Nursultan]: MainScript.lua compile error: " .. tostring(compileError), 0)
end

chunk()
