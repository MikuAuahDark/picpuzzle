assert(love.filesystem.createDirectory("screenshots", "Failed to create save directory"))

-- Splash
local aqs = love._getAquaShineHandle()
local isFused = love.filesystem.isFused()
love._getAquaShineHandle = nil

if (isFused and not(aqs.GetCommandLineConfig("nosplash"))) or (not(isFused) and aqs.GetCommandLineConfig("splash")) then
	-- Set splash screen
	aqs.SetSplashScreen("splash/love_splash.lua")
end
