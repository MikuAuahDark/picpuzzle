-- Button with text & shadow element

local AquaShine = ...
local love = love
local ButtonText = AquaShine.Node.Colorable:extend("PicPuzzle.ButtonText")

function ButtonText.init(this, text, color, action)
	AquaShine.Node.Colorable.init(this)
	color = color or {1, 1, 1, 1}
	
	this.color = color
	this.userdata.opacity = 0.75
	this.userdata.text = love.graphics.newText(AquaShine.LoadFont(nil, 18))
	this.userdata.text:add({{0, 0, 0}, text}, 1, 1)
	this.userdata.text:add(text, 0, 0)
	
	AquaShine.Node.Util.InitializeInArea(this, 154, 32)
	this.events.MousePressed = AquaShine.Node.Util.InAreaFunction(this, function(x, y)
		this.userdata.opacity = 1
	end)
	this.events.MouseMoved = AquaShine.Node.Util.InAreaFunction(this, function(x, y)
		this.userdata.opacity = 0.75
	end, true)
	this.events.MouseReleased = AquaShine.Node.Util.InAreaFunction(this, function(x, y)
		if this.userdata.opacity == 1 then
			action()
		end
		
		this.userdata.opacity = 0.75
	end)
end

function ButtonText.draw(this)
	local r, g, b, a = this.color[1], this.color[2], this.color[3], this.color[4] or 1
	
	love.graphics.push("all")
	love.graphics.setColor(r, g, b, a * this.userdata.opacity)
	love.graphics.setLineWidth(2)
	love.graphics.rectangle("fill", this.x, this.y, this.userdata.inarea.w, this.userdata.inarea.h)
	love.graphics.setColor(r, g, b, a)
	love.graphics.rectangle("line", this.x, this.y, this.userdata.inarea.w, this.userdata.inarea.h)
	love.graphics.setColor(1, 1, 1)
	love.graphics.draw(this.userdata.text, this.x + 6, this.y + 6)
	love.graphics.pop()
	
	return AquaShine.Node.Colorable.draw(this)
end

return ButtonText
