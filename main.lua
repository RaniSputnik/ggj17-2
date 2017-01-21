color = require("color")

KEY_RESTART = "r"
KEY_QUIT = "escape"

COL_WHITE = color.rgb(255,255,255)
COL_WATER = color.rgb(41,63,101)

function love.load()
	if assets == nil then
		assets = require("assets")
	end

	wave_points = {}
	number_of_wave_points = 100

	local xinc = love.graphics.getWidth() / number_of_wave_points * 2
	for i=1,number_of_wave_points do
		local xx = (i-1)*xinc
		local yy = love.graphics.getHeight()*0.5

		wave_points[i] = {
			x = xx,
			y = yy,
			dist = math.sin(xx * 0.01) * 100
		}
	end

end

function love.update(dt)
	local sp = dt * 90
	local rest = love.graphics.getHeight()*0.5

	for i,pt in ipairs(wave_points) do
		pt.x = pt.x - sp
		pt.y = rest + pt.dist + math.sin(pt.x * 0.02) * 10
	end
end

function love.draw()
	local img = assets.img.bg_storm
	local sx, sy = love.graphics.getDimensions() / img:getDimensions()
	love.graphics.setColor(color.val(COL_WHITE))
	love.graphics.draw(img, 0,0, 0, sx,sy)

	local vertices = {}
	local n = table.getn(wave_points)
	local gh = love.graphics.getHeight()
	love.graphics.setColor(color.val(COL_WATER))
	for i,pt in ipairs(wave_points) do
		if i < n then
			local pt2 = wave_points[i+1]
			love.graphics.polygon("fill", pt.x,pt.y,pt2.x,pt2.y,pt2.x,gh,pt.x,gh)
		end
	end
end

function love.keypressed(key)
	if key == KEY_RESTART then
		love.load()
	elseif key == KEY_QUIT then
		love.quit()
	end
end
