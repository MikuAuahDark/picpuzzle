-- Picture Puzzle menu

local AquaShine = ...
local love = love
local stars = require("expanding_stars")
local ButtonText = AquaShine.LoadModule("uielement.button_text")
local SelectImage = AquaShine.LoadModule("uielement.selection")
local Main = {}
Main.SegmentString = {
	[162] = "3 x 3",
	[81] = "6 x 6",
	[54] = "9 x 9",
	[27] = "18 x 18",
	[18] = "27 x 27"
}
Main.SegmentIndex = {162, 81, 54, 27, 18}

function Main.Start(arg)
	-- Initialize
	local savedir = love.filesystem.getSaveDirectory()
	Main.FileList = {}
	Main.SelectedSegment = arg.Segment or 81
	Main.CurrentPage = 0
	stars.setColorTransition(1, 1, 1)
	
	for i, v in ipairs(love.filesystem.getDirectoryItems("")) do
		local info = love.filesystem.getInfo(v)
		if love.filesystem.getRealDirectory(v) == savedir and info.type == "file" then
			Main.FileList[#Main.FileList + 1] = v
		end
	end
	
	-- Initialize node list, 11 images per node
	Main.NodeList = {}
	
	for i = 1, math.ceil(#Main.FileList / 11) do
		local n = AquaShine.Node()
		
		for j = 1, 11 do
			local v = Main.FileList[(i - 1) * 11 + j]
			
			if v then
				local btn = SelectImage(v, Main)
				btn:setPosition(190, 48 + j * 32)
				n:addChild(btn)
			else
				break
			end
		end
		
		Main.NodeList[#Main.NodeList + 1] = n
	end
	
	Main.MainNode = AquaShine.Node()
	Main.TitleFont = AquaShine.LoadFont(nil, 36)
	Main.MainFont = AquaShine.LoadFont(nil, 18)
	
	-- Node for segment buttons
	for i = 1, #Main.SegmentIndex do
		local btn = ButtonText(Main.SegmentString[Main.SegmentIndex[i]], {1, 1, 0.5}, function()
			Main.SelectedSegment = Main.SegmentIndex[i]
		end)
		btn:setPosition(16, 40 + i * 40)
		Main.MainNode:addChild(btn)
	end
	
	-- Back and Next button
	local next_btn = ButtonText("Next >>", {0.5, 1, 1}, function()
		Main.CurrentPage = Main.CurrentPage + 1
		local idx = (Main.CurrentPage) % #Main.NodeList
		Main.CurrentPage = (idx == idx and idx or 0)
		Main.MainNode.brother = Main.NodeList[Main.CurrentPage + 1]
	end)
	local back_btn = ButtonText("<< Previous", {0.5, 1, 1}, function()
		Main.CurrentPage = Main.CurrentPage - 1
		local idx = (Main.CurrentPage) % #Main.NodeList
		Main.CurrentPage = (idx == idx and idx or 0)
		Main.MainNode.brother = Main.NodeList[Main.CurrentPage + 1]
	end)
	next_btn:setPosition(694, 442)
	back_btn:setPosition(524, 442)
	Main.MainNode:addChild(next_btn)
	Main.MainNode:addChild(back_btn)
	
	-- "Open Pictures Dir" button
	do
		local btn = ButtonText("Pictures Dir", nil, function()
			love.system.openURL(savedir)
		end)
		btn:setPosition(450, 40)
		Main.MainNode:addChild(btn)
	end
	
	-- "Select Image" button using FileSelection
	if AquaShine.FileSelection then
		local btn = ButtonText("Select Image", nil, function()
			local res = AquaShine.FileSelection("Select Image", nil, "*.jpg *.jpeg *.png *.bmp", false)
			
			if res then
				return AquaShine.LoadEntryPoint(":puzzle_main", {res, Main.SelectedSegment})
			end
		end)
		btn:setPosition(620, 40)
		Main.MainNode:addChild(btn)
	end
	
	-- Main node brother is the file list node
	Main.MainNode.brother = Main.NodeList[1]
end

function Main.Update(deltaT)
	return stars.update(deltaT * 0.001)
end

function Main.Draw()
	love.graphics.setColor(1, 1, 1)
	love.graphics.setFont(Main.TitleFont)
	stars.draw()
	love.graphics.print("Picture Puzzle", 16, 10)
	love.graphics.setFont(Main.MainFont)
	love.graphics.print(string.format("Puzzle Size: %s", Main.SegmentString[Main.SelectedSegment]), 16, 50)
	love.graphics.print("Available Images:", 200, 50)
	return Main.MainNode:draw()
end

function Main.MousePressed(x, y, b)
	return Main.MainNode:triggerEvent("MousePressed", x, y, b, false)
end

function Main.MouseMoved(x, y, dx, dy)
	return Main.MainNode:triggerEvent("MouseMoved", x, y, dx, dy, false)
end

function Main.MouseReleased(x, y, b)
	return Main.MainNode:triggerEvent("MouseReleased", x, y, b, false)
end

return Main
