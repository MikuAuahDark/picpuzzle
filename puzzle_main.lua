-- Test puzzle
local AquaShine = ...
local love = love
local flux = require("flux")
local stars = require("expanding_stars")
local lily = require("lily")

-- 1	2	3	6	9	18	27	54	81	162	243	486
local PuzzleMain = {Segments = 18}
local ButtonText = AquaShine.LoadModule("uielement.button_text")
PuzzleMain.Size = 486 / PuzzleMain.Segments
PuzzleMain.SegmentString = {
	[162] = "3 x 3",
	[81] = "6 x 6",
	[54] = "9 x 9",
	[27] = "18 x 18",
	[18] = "27 x 27"
}

function PuzzleMain.StartAvgColorThread(id)
	PuzzleMain.AvgColThread = love.thread.newThread [[
	local li = require("love.image")
	local le = require("love.event")
	local imagedata = ...
	local w, h = imagedata:getDimensions()
	local size = w*h
	local coldiv = love._version >= "0.11.0" and size or 255 * size	-- color range changes
	local col = {0, 0, 0}
	
	for i = 0, size - 1 do
		local r, g, b = imagedata:getPixel(i % w, math.floor(i / w))
		col[1] = col[1] + r
		col[2] = col[2] + g
		col[3] = col[3] + b
	end
	
	le.push("stars_setcolor", col[1] / coldiv, col[2] / coldiv, col[3] / coldiv)
	return
	]]
	PuzzleMain.AvgColThread:start(id)
end

-- Custom flux interpolation
function PuzzleMain.CustomFluxInterpolation(p)
	return math.log10(p*90 + 10) - 1
end

function PuzzleMain.Start(arg)
	local fd
	if arg.lovepath then
		lily.newImageData(arg.lovepath)
			:onComplete(PuzzleMain.MainStart)
			:setUserData(arg)
	else
		local image = assert(io.open(arg[1], "rb"))
		local fd = love.filesystem.newFileData(image:read("*a"), "_")
		lily.newImageData(fd)
			:onComplete(PuzzleMain.MainStart)
			:setUserData(arg)
		image:close()
	end
	
	PuzzleMain.Font = AquaShine.LoadFont(nil, 18)	-- Vera sans
end
	
function PuzzleMain.MainStart(arg, image)
	local len = PuzzleMain.Size * PuzzleMain.Size
	
	-- Load image supplied by arg
	PuzzleMain.ImageData = image
	PuzzleMain.Image = love.graphics.newImage(image)
	PuzzleMain.ImageWH = {image:getDimensions()}
	
	-- Get puzzle size
	PuzzleMain.Segments = assert(tonumber(arg[2] or 81), "Invalid number specificed")
	assert(PuzzleMain.SegmentString[PuzzleMain.Segments], "Invalid segment specificed")
	PuzzleMain.Size = 486 / PuzzleMain.Segments
	PuzzleMain.StartAvgColorThread(PuzzleMain.ImageData)
	
	-- Initialize canvas and font
	PuzzleMain.Canvas = love.graphics.newCanvas(486, 486)
	
	-- Draw it to canvas
	PuzzleMain.Canvas:renderTo(PuzzleMain.Redraw)
	
	-- Create tons of Quads
	PuzzleMain.Quads = {}
	PuzzleMain.ShouldBeInIndex = {}
	PuzzleMain.SelectedIndex = -1
	for i = 0, len - 1 do
		local x = i % PuzzleMain.Size
		local y = math.floor(i / PuzzleMain.Size)
		PuzzleMain.Quads[i] = love.graphics.newQuad(
			x * PuzzleMain.Segments,    -- Position
			y * PuzzleMain.Segments,    -- Position
			PuzzleMain.Segments,        -- Quad size
			PuzzleMain.Segments,        -- Quad size
			486, 486                    -- Reference size
		)
		PuzzleMain.ShouldBeInIndex[i] = i
	end
	
	-- Create size string
	PuzzleMain.SizeString = string.format("Puzzle Size:\n%d x %d", PuzzleMain.Size, PuzzleMain.Size)
	
	-- Initialize
	PuzzleMain.ResetState()
	
	-- Node initialization
	PuzzleMain.MainNode = AquaShine.Node()
	PuzzleMain.ResetButton = ButtonText("Reset Puzzle", {1, 0.96, 0.38}, PuzzleMain.ResetState)
	PuzzleMain.ResetButton:setPosition(694, 188)
	PuzzleMain.MainNode:addChild(PuzzleMain.ResetButton)
	PuzzleMain.BackButton = ButtonText("Back", {1, 1, 1}, function()
		return AquaShine.LoadEntryPoint(":menu", {Segment = PuzzleMain.Segments})
	end)
	PuzzleMain.BackButton:setPosition(16, 16)
	PuzzleMain.MainNode:addChild(PuzzleMain.BackButton)
end

-- Canvas redraw function
function PuzzleMain.Redraw()
	love.graphics.draw(PuzzleMain.Image, 0, 0, 0, 486/PuzzleMain.ImageWH[1], 486/PuzzleMain.ImageWH[2])
end

function PuzzleMain.DoneTween()
	local qt
	PuzzleMain.TweenInProgress = false
	
	-- Start swapping place and re-add to SpriteBatch
	qt = PuzzleMain.QuadTarget[1]
	PuzzleMain.Quads[qt[1]] = qt[2]
	qt = PuzzleMain.QuadTarget[2]
	PuzzleMain.Quads[qt[1]] = qt[2]
	
	-- Increase move
	PuzzleMain.Moves = PuzzleMain.Moves + 1
	
	-- Check if it's complete
	PuzzleMain.IsPuzzleComplete = PuzzleMain.IsComplete()
	if PuzzleMain.IsPuzzleComplete then
		-- It's complete. Slowly clear the rectangle line and stop timer
		PuzzleMain.StartTimer = false
		flux.to(PuzzleMain.RectangleOpacity, 1000, {0}):ease("linear")
	end
end

-- Start move piece
function PuzzleMain.StartTween(idx1, idx2)
	-- Set quad target
	PuzzleMain.QuadTarget[1] = {idx2, PuzzleMain.Quads[idx1]}
	PuzzleMain.QuadTarget[2] = {idx1, PuzzleMain.Quads[idx2]}
	PuzzleMain.Quads[idx1] = nil
	PuzzleMain.Quads[idx2] = nil
	PuzzleMain.XTween[1] = idx1 % PuzzleMain.Size
	PuzzleMain.XTween[2] = idx2 % PuzzleMain.Size
	PuzzleMain.YTween[1] = math.floor(idx1 / PuzzleMain.Size)
	PuzzleMain.YTween[2] = math.floor(idx2 / PuzzleMain.Size)
	PuzzleMain.ShouldBeInIndex[idx1], PuzzleMain.ShouldBeInIndex[idx2] =
	PuzzleMain.ShouldBeInIndex[idx2], PuzzleMain.ShouldBeInIndex[idx1]
	
	local destx, desty = {}, {}
	destx[1] = PuzzleMain.XTween[2]
	destx[2] = PuzzleMain.XTween[1]
	desty[1] = PuzzleMain.YTween[2]
	desty[2] = PuzzleMain.YTween[1]
	
	-- X position
	flux.to(PuzzleMain.XTween, 500, destx):ease("quadout"):oncomplete(PuzzleMain.DoneTween)
	-- Y position
	flux.to(PuzzleMain.YTween, 500, desty):ease("quadin")
	-- Scale
	flux.to(PuzzleMain.ScaleInfo, 250, {1.25})
		:ease(PuzzleMain.CustomFluxInterpolation)
		:after(PuzzleMain.ScaleInfo, 250, {1})
		:ease(PuzzleMain.CustomFluxInterpolation)
	-- Move distance
	local distlen = math.sqrt((PuzzleMain.XTween[1] - PuzzleMain.XTween[2]) ^ 2 + (PuzzleMain.YTween[2] - PuzzleMain.YTween[1]) ^ 2)
	flux.to(PuzzleMain.MoveDistance, 500, {PuzzleMain.MoveDistance[1] + distlen}):ease("linear")
	
	-- Flag tween is in progress
	PuzzleMain.TweenInProgress = true
end

function PuzzleMain.IsComplete()
	for i = 0, PuzzleMain.Size * PuzzleMain.Size - 1 do
		if PuzzleMain.ShouldBeInIndex[i] ~= i then
			return false
		end
	end
	
	return true
end

-- Reset state. Includes re-randomizing things.
function PuzzleMain.ResetState()
	local len = PuzzleMain.Size * PuzzleMain.Size
	
	-- Randomize
	for i = 0, len - 1 do
		local rnd
		repeat rnd = math.random(0, len - 1) until rnd ~= i
		
		-- Swap
		PuzzleMain.ShouldBeInIndex[i], PuzzleMain.ShouldBeInIndex[rnd] =
		PuzzleMain.ShouldBeInIndex[rnd], PuzzleMain.ShouldBeInIndex[i]
		PuzzleMain.Quads[i], PuzzleMain.Quads[rnd] =
		PuzzleMain.Quads[rnd], PuzzleMain.Quads[i]
	end
	
	-- Variable init
	PuzzleMain.XTween = {0, 0}
	PuzzleMain.YTween = {0, 0}
	PuzzleMain.ScaleInfo = {1}
	PuzzleMain.QuadTarget = {}
	PuzzleMain.MoveDistance = {0}
	PuzzleMain.RectangleOpacity = {1}
	PuzzleMain.Timer = 0
	PuzzleMain.Moves = 0
	PuzzleMain.StartTimer = false
	PuzzleMain.IsPuzzleComplete = false
end

function PuzzleMain.Update(deltaT)
	stars.update(deltaT * 0.001)
	flux.update(deltaT)
	
	if PuzzleMain.StartTimer then
		PuzzleMain.Timer = PuzzleMain.Timer + deltaT * 0.001
	end
end

function PuzzleMain.Draw()
	-- Draw stars
	stars.draw()
	
	-- If image is not loaded yet, display message
	if not(PuzzleMain.ImageData) then
		love.graphics.setFont(PuzzleMain.Font)
		love.graphics.print("Loading Image...", 364, 233)
		return
	end
	
	-- Push stack and initialize
	love.graphics.push("all")
	love.graphics.setLineWidth(1)
	love.graphics.setColor(1, 1, 1)
	love.graphics.rectangle("fill", 185, 0, 494, 486)
	
	-- Draw tiles
	for i = 0, PuzzleMain.Size * PuzzleMain.Size - 1 do
		if PuzzleMain.Quads[i] then
			local x = i % PuzzleMain.Size
			local y = math.floor(i / PuzzleMain.Size)
			
			love.graphics.draw(PuzzleMain.Canvas, PuzzleMain.Quads[i], 189 + x * PuzzleMain.Segments, y * PuzzleMain.Segments)
			
			if PuzzleMain.RectangleOpacity[1] > 0 and PuzzleMain.SelectedIndex ~= i then
				love.graphics.setColor(0, 0, 0, PuzzleMain.RectangleOpacity[1])
				love.graphics.rectangle("line", 189 + x * PuzzleMain.Segments, y * PuzzleMain.Segments, PuzzleMain.Segments, PuzzleMain.Segments)
			end
			
			love.graphics.setColor(1, 1, 1)
		end
	end
	
	-- Draw selected line
	if PuzzleMain.RectangleOpacity[1] > 0 and PuzzleMain.SelectedIndex ~= -1 then
		love.graphics.rectangle(
			"line",
			189 + (PuzzleMain.SelectedIndex % PuzzleMain.Size) * PuzzleMain.Segments,
			math.floor(PuzzleMain.SelectedIndex / PuzzleMain.Size) * PuzzleMain.Segments,
			PuzzleMain.Segments, PuzzleMain.Segments
		)
	end
	
	-- Draw text
	love.graphics.setFont(PuzzleMain.Font)
	love.graphics.print(PuzzleMain.SizeString, 16, 188)
	love.graphics.print(
		string.format("Time:\n%02d:%02d.%03d", PuzzleMain.Timer / 60, PuzzleMain.Timer % 60, (PuzzleMain.Timer % 1)*1000),
		16, 268
	)
	love.graphics.print(string.format("Moves:\n%d", PuzzleMain.Moves), 16, 348)
	love.graphics.print(string.format("Move Distance\nTotal: %.3f", PuzzleMain.MoveDistance[1]), 16, 428)
	
	-- Also draw object which is in transition
	if PuzzleMain.TweenInProgress then
		love.graphics.draw(PuzzleMain.Canvas, PuzzleMain.QuadTarget[1][2], 189 + PuzzleMain.XTween[1] * PuzzleMain.Segments, PuzzleMain.YTween[1] * PuzzleMain.Segments, 0, PuzzleMain.ScaleInfo[1])
		love.graphics.draw(PuzzleMain.Canvas, PuzzleMain.QuadTarget[2][2], 189 + PuzzleMain.XTween[2] * PuzzleMain.Segments, PuzzleMain.YTween[2] * PuzzleMain.Segments, 0, PuzzleMain.ScaleInfo[1])
	end
	
	-- Draw completed image
	love.graphics.draw(PuzzleMain.Image, 692, 314, 0, 160/PuzzleMain.ImageWH[1], 160/PuzzleMain.ImageWH[2])
	
	-- Draw buttons
	PuzzleMain.MainNode:draw()
	
	-- Pop stack
	love.graphics.pop()
end

function PuzzleMain.Resize()
	if not(PuzzleMain.ImageData) then return end
	PuzzleMain.Canvas:renderTo(PuzzleMain.Redraw)
end

function PuzzleMain.MousePressed(x, y, b)
	if not(PuzzleMain.ImageData) then return end
	if PuzzleMain.TweenInProgress then return end
	
	if not(PuzzleMain.IsPuzzleComplete) then
		-- Only able interact when puzzle is incomplete
		if x >= 189 and x < 675 and y >= 0 and y < 486 then
			local tx = math.floor((x - 189) / PuzzleMain.Segments)
			local ty = math.floor(y  / PuzzleMain.Segments)
			
			-- Start timer
			PuzzleMain.StartTimer = true
			
			-- Set index
			if PuzzleMain.SelectedIndex == -1 then
				PuzzleMain.SelectedIndex = tx + ty * PuzzleMain.Size
			else
				local idx = tx + ty * PuzzleMain.Size
				if idx ~= PuzzleMain.SelectedIndex then
					-- Move
					PuzzleMain.StartTween(PuzzleMain.SelectedIndex, idx)
				end
				
				PuzzleMain.SelectedIndex = -1
			end
		else
			-- Invalidate
			PuzzleMain.SelectedIndex = -1
		end
	end
	
	return PuzzleMain.MainNode:triggerEvent("MousePressed", x, y, b, false)
end

function PuzzleMain.MouseMoved(x, y, dx, dy)
	if not(PuzzleMain.ImageData) then return end
	if PuzzleMain.TweenInProgress then return end
	return PuzzleMain.MainNode:triggerEvent("MouseMoved", x, y, dx, dy, false)
end

function PuzzleMain.MouseReleased(x, y, b)
	if not(PuzzleMain.ImageData) then return end
	if PuzzleMain.TweenInProgress then return end
	return PuzzleMain.MainNode:triggerEvent("MouseReleased", x, y, b, false)
end

return PuzzleMain
