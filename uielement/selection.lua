-- Selection list

local AquaShine = ...
local love = love
local ButtonText = AquaShine.LoadModule("uielement.button_text")
local SelectImage = ButtonText:extend("PicPuzzle.SelectImage")

function SelectImage.init(this, name, maintbl)
	ButtonText.init(this, name, nil, function()
		return AquaShine.LoadEntryPoint(":puzzle_main", {lovepath = name, [2] = maintbl.SelectedSegment})
	end)
	this.userdata.inarea.w = 658
	this.userdata.inarea.h = 32
end

return SelectImage
