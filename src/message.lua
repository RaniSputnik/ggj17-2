local msg = {}

local RATE = 1
local show = false
local text = ""
local opacity = 0

msg.show = function(message)
	text = message
	show = true
end

msg.hide = function()
	show = false
	opacity = 0
end

msg.draw = function()
	if show then
		opacity = opacity + RATE
		if opacity > 255 then opacity = 255 end
	else 
		opacity = opacity - RATE
		if opacity < 0 then opacity = 0 end
	end
	love.graphics.setColor(0,0,0,opacity*.5)
	love.graphics.rectangle("fill", 0, 0, love.graphics.getWidth(), love.graphics.getHeight())
	love.graphics.setColor(255,255,255,opacity)
	love.graphics.print(text, 15, love.graphics.getHeight()-30)
end

return msg
