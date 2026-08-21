if not isfile or not isfile("MainScript.lua") then
	error("[Nightix]: MainScript.lua was not found")
end

loadstring(readfile("MainScript.lua"))()