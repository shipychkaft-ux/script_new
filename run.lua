-- Nursultan entry point with maximum executor compatibility.
-- Works when loadstring or game:HttpGet is missing, and prints the exact
-- failure reason instead of "attempt to call a nil value".

local URL = "https://raw.githubusercontent.com/shipychkaft-ux/script_new/main/MainScript.lua?v=" .. tostring(math.floor(tick() * 1000))

local function fetch(url)
    local function try(name, fn)
        local ok, result = pcall(fn)
        if ok and type(result) == "string" and #result > 20 then
            print("[Nursultan]: fetched via " .. name)
            return result
        end
        if not ok then
            warn("[Nursultan]: " .. name .. " failed: " .. tostring(result))
        end
    end

    local source =
        (request and try("request", function()
            local res = request({ Url = url, Method = "GET" })
            return res and res.Body
        end))
        or (http_request and try("http_request", function()
            local res = http_request({ Url = url, Method = "GET" })
            return res and res.Body
        end))
        or (syn and syn.request and try("syn.request", function()
            local res = syn.request({ Url = url, Method = "GET" })
            return res and res.Body
        end))
        or (http and http.request and try("http.request", function()
            local res = http.request({ Url = url, Method = "GET" })
            return res and res.Body
        end))
        or (game and game.HttpGet and try("game:HttpGet", function()
            return game:HttpGet(url)
        end))

    return source
end

local source = fetch(URL)
if not source then
    error("[Nursultan]: no HTTP function available (request/http_request/HttpGet all failed)", 0)
end

local compile = loadstring or load
if not compile then
    error("[Nursultan]: this executor exposes neither loadstring nor load", 0)
end

local chunk, compileError = compile(source)
if not chunk then
    error("[Nursultan]: MainScript.lua compile error: " .. tostring(compileError), 0)
end

chunk()
