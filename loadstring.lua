if isfile and isfile("MainScript.lua") then
	loadstring(readfile("MainScript.lua"))()
else
	loadstring(game:HttpGet("https://raw.githubusercontent.com/Maanaaaa/ManaV2ForRoblox/main/MainScript.lua"))()
end