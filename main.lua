color = require("color")

DEBUG_DRAW_WATER_POLY = true
DEBUG_DRAW_NO_BG = true

KEY_RESTART = "r"
KEY_QUIT = "escape"

COL_WHITE = color.rgb(255,255,255)
COL_WATER = color.rgb(41,63,101)

REST_Y = love.graphics.getHeight()*0.7
NUMBER_OF_WAVE_POINTS = 100
DIST_BETWEEN_WATER_POINTS = love.graphics.getWidth() / NUMBER_OF_WAVE_POINTS * 2

function love.load()
	if assets == nil then
		assets = require("assets")
	end

	wave_offset = 0
	wave_points = {}
	for i=1,NUMBER_OF_WAVE_POINTS do
		local xx = (i-1) * DIST_BETWEEN_WATER_POINTS
		local yy = REST_Y

		wave_points[i] = {
			i = i,
			x = xx,
			y = yy,
			dist = math.sin(xx * 0.01) * 100
		}
	end

end

function love.update(dt)
	local sp = dt * 90
	wave_offset = wave_offset - sp
	for i,pt in ipairs(wave_points) do
		pt.y = REST_Y + pt.dist + math.sin((pt.x + wave_offset) * 0.02) * 10
	end

	if wave_offset < -wave_points[1].x - DIST_BETWEEN_WATER_POINTS then
		local pt = table.remove(wave_points, 1)
		local n = table.getn(wave_points)
		local lastpt = wave_points[n]
		pt.i = lastpt.i + 1
		pt.x = (pt.i-1) * DIST_BETWEEN_WATER_POINTS
		pt.dist = math.sin(pt.x * 0.01) * 100
		table.insert(wave_points, pt)
	end
end

function love.draw()
	if not DEBUG_DRAW_NO_BG then
		local img = assets.img.bg_storm
		local sx, sy = love.graphics.getDimensions() / img:getDimensions()
		love.graphics.setColor(color.val(COL_WHITE))
		love.graphics.draw(img, 0,0, 0, sx,sy)
	end

	local vertices = {}
	local n = table.getn(wave_points)
	local gh = love.graphics.getHeight()
	local wx = wave_offset
	local water_mode = "fill"
	if DEBUG_DRAW_WATER_POLY then water_mode = "line" end
	love.graphics.setColor(color.val(COL_WATER))
	for i,pt in ipairs(wave_points) do
		if i < n then
			local pt2 = wave_points[i+1]
			love.graphics.polygon(water_mode, pt.x+wx,pt.y,pt2.x+wx,pt2.y,pt2.x+wx,gh,pt.x+wx,gh)
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
