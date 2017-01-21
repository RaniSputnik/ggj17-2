color = require("color")
physics = require("physics")
geom = require("geom")
clouds = require("clouds")
msg = require("message")

DEBUG_DRAW_WATER_POLY = false
DEBUG_DRAW_NO_BG = false
DEBUG_DRAW_PHYSICS = false
DEBUG_DRAW_WATER_HEIGHT = false
DEBUG_DRAW_CLOUDS = false

KEY_RESTART = "r"
KEY_QUIT = "escape"
KEY_RIGHT = "right"
KEY_LEFT = "left"

COL_WHITE = color.rgb(255,255,255)
COL_WATER = color.rgb(41,63,101)
COL_WATER_OUTLINE = color.rgb(28,42,70)

REST_Y = love.graphics.getHeight()*0.6
NUMBER_OF_WAVE_POINTS = 100
STARTING_WAVE_SIZE = 50
WAVE_GROWTH_RATE = 2.2
RIPPLE_GROWTH_RATE = 2.6
RIPPLE_FREQUENCY = 0.014
WATER_SPEED = 15
WAVE_FREQUENCY = 0.01
WIND_SPEED = 1.4
DIST_BETWEEN_WATER_POINTS = love.graphics.getWidth() / NUMBER_OF_WAVE_POINTS * 2
DEPTH_TO_LOSE = 55
ANGLE_TO_LOSE = math.rad(90)
INPUT_XSTRENGTH = 0
INPUT_YSTRENGTH = 100

BAL_REMEMBER = 1
BAL_STORM_AT_SEA = 0

CLOUD_CENTER_X = 156
CLOUD_CENTER_Y = 111

function love.load()
	if assets == nil then
		assets = require("assets")
	end

	total_time = 0
	wave_offset = 0
	wave_points = {}
	for i=1,NUMBER_OF_WAVE_POINTS do
		local xx = (i-1) * DIST_BETWEEN_WATER_POINTS
		local yy = REST_Y

		wave_points[i] = {
			i = i,
			x = xx,
			y = yy,
			dist = math.sin(xx * WAVE_FREQUENCY) * STARTING_WAVE_SIZE
		}
	end

	createBoat(150,440)

	if lost then
		love.audio.stop(assets.music.remember)
	end
	love.audio.play(assets.music.remember)
	love.audio.play(assets.music.stormatsea)
	assets.music.remember:setVolume(BAL_REMEMBER)
	assets.music.stormatsea:setVolume(BAL_STORM_AT_SEA)

	lost = false
	msg.hide()
	fade_in = 255

	show_instructions = true
	instructions_fade = 255
end

function love.update(dt)
	-- The seas only get rougher if we haven't lost yet
	if not lost and not show_instructions then
		total_time = total_time + dt
	end

	local sp = dt * 90
	wave_offset = wave_offset - sp
	for i,pt in ipairs(wave_points) do
		pt.y = REST_Y + pt.dist + math.sin((pt.x + wave_offset*.5) * RIPPLE_FREQUENCY) * total_time * RIPPLE_GROWTH_RATE
	end

	if wave_offset < -wave_points[1].x - DIST_BETWEEN_WATER_POINTS then
		local pt = table.remove(wave_points, 1)
		local n = table.getn(wave_points)
		local lastpt = wave_points[n]
		pt.i = lastpt.i + 1
		pt.x = (pt.i-1) * DIST_BETWEEN_WATER_POINTS
		pt.dist = math.sin(pt.x * WAVE_FREQUENCY) * (STARTING_WAVE_SIZE + total_time * WAVE_GROWTH_RATE)
		table.insert(wave_points, pt)
	end

	-- Gather player input
	if not lost then
		local input = 0
		if love.keyboard.isDown(KEY_RIGHT) then input = input + 1 end
		if love.keyboard.isDown(KEY_LEFT) then input = input - 1 end

		if input == 1 then
			show_instructions = false
			boat_right.ay = boat_right.ay + INPUT_YSTRENGTH
		elseif input == -1 then
			show_instructions = false
			boat_left.ax = boat_left.ax - INPUT_XSTRENGTH
			boat_left.ay = boat_left.ay + INPUT_YSTRENGTH
		end
	end

	-- Physics the boat
	local wind_if_behind_x = love.graphics.getWidth()*.5
	local on_the_screen = false
	for i,p in ipairs(physics.points) do
		if p.x > 0 then on_the_screen = true end

		local water_level = waterHeightAtX(p.x)
		if p.y > water_level then
			-- If we've lost, mark underwater particles as 'underwater'
			-- this will ensure they never leave the water. You shouldn't
			-- be able to bounce around after you've already lost the game
			if lost then 
				p.underwater = true
			end
			if p == boat_top then
				local a = getBoatAngle()
				if not lost and p.y - water_level > DEPTH_TO_LOSE and a > math.pi - ANGLE_TO_LOSE and a < math.pi + ANGLE_TO_LOSE then
					loseBecausePlayerHasCapsized()
				end
			else
				local f = math.max(-physics.gravity*1.5, water_level-p.y)
				p.oldx = p.x
				p.y = p.y - (p.y - water_level)*0.01

				if not show_instructions then
					p.ax = p.ax - WATER_SPEED
				end
			end
		elseif p.underwater then
			p.y = p.y + (water_level - p.y) * .1
		elseif p ~= boat_top and p.x < wind_if_behind_x then
			p.ax = p.ax + WIND_SPEED
		end
	end
	-- Pull down the top of the boat if we've lost
	if lost and boat_top.underwater then boat_top.ay = boat_top.ay + 5 end
	-- Run the verlet and constraints
	physics.run(dt)

	if not lost and not on_the_screen then 
		loseBecausePlayerIsOffTheScreen()
	end

	-- fade the music
	if lost then
		local v = assets.music.remember:getVolume() * 0.98
		if v < 0.005 then v = 0 end
		assets.music.remember:setVolume(BAL_REMEMBER * v)
	end

	clouds.run(dt)
end

function love.draw()
	local img = assets.img.bg_storm
	local sx, sy = love.graphics.getDimensions()
	local ix, iy = img:getDimensions()
	sx = sx / ix
	sy = sy / iy
	if not DEBUG_DRAW_NO_BG then
		love.graphics.setColor(color.val(COL_WHITE))
		love.graphics.draw(img, 0,0, 0, sx,sy)
	end
	clouds.draw(CLOUD_CENTER_X,CLOUD_CENTER_Y, sx,sy, DEBUG_DRAW_CLOUDS)
	
	-- draw a rectangle as a stencil. Each pixel touched by the rectangle will have its stencil value set to 1. The rest will be 0.
    love.graphics.stencil(drawWater, "replace", 1)
   	-- Only allow rendering on pixels which have a stencil value greater than 0.
    love.graphics.setStencilTest("greater", 0)
    local watertex = assets.img.water
    local texw = watertex:getWidth() * sx
    local texh = watertex:getHeight() * sy
    love.graphics.setColor(255,255,255)
    for xx = (wave_offset*0.5)%texw - texw, love.graphics.getWidth(), texw do
    	for yy = math.sin(wave_offset * 0.01) * 20, love.graphics.getHeight(), texh do
    		love.graphics.draw(watertex, xx,yy, 0, sx,sy)
    	end
    end
    -- Remove stencil restriction
    love.graphics.setStencilTest()
    drawWaterOutline()

	if DEBUG_DRAW_PHYSICS then
		love.graphics.setColor(0,255,0)
		physics.debugDraw()
	end
	local r = getBoatAngle()
	local ox = boat_img:getWidth() * 0.5
	local oy = boat_img:getHeight()
	love.graphics.setColor(color.val(COL_WHITE))
	love.graphics.draw(boat_img, boat_center.x,boat_center.y, r, sx,sy, ox,oy)

	if DEBUG_DRAW_WATER_HEIGHT then
		local mx = love.mouse.getX()
		local hy = waterHeightAtX(mx)
		love.graphics.setColor(0, 255, 255)
		love.graphics.circle("fill", mx, hy, 2, 5)
	end

	msg.draw()

	fade_in = fade_in - 2
	if fade_in > 0 then
		love.graphics.setColor(0, 0, 0, fade_in)
		love.graphics.rectangle("fill",0,0,love.graphics.getWidth(),love.graphics.getHeight())
	end

	if not show_instructions then
		instructions_fade = instructions_fade - 2
	end
	if instructions_fade > 0 and not lost then
		love.graphics.setColor(255,255,255, instructions_fade)
		love.graphics.print("Left/Right arrows to begin...",16,love.graphics.getHeight()-32)
	end

	love.graphics.setColor(255,255,255)
	love.graphics.printf(string.format("%.1f", total_time).." mi.",0,love.graphics.getHeight()-32,love.graphics.getWidth()-16,"right")
end

function love.keypressed(key)
	if key == KEY_RESTART then
		love.load()
	elseif key == KEY_QUIT then
		love.event.quit()
	end
end

function loseBecausePlayerIsOffTheScreen()
	lost = true
	msg.show("Lost at sea")
end

function loseBecausePlayerHasCapsized()
	lost = true
	boat_img = assets.img.sailboat_sunk
	msg.show("Drowned in the storm")
end

function drawWater()
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

function drawWaterOutline()
	local wx = wave_offset
	local n = table.getn(wave_points)
	love.graphics.setColor(color.val(COL_WATER_OUTLINE))
	for i,pt in ipairs(wave_points) do
		if i < n then
			local pt2 = wave_points[i+1]
			love.graphics.line(pt.x+wx,pt.y,pt2.x+wx,pt2.y)
		end
	end
end

function waterHeightAtX(x)
	for i,pt in ipairs(wave_points) do
		if pt.x+wave_offset > x and i > 1 then
			pt2 = pt
			pt = wave_points[i - 1]

			local dx = pt2.x - pt.x
			local dy = pt2.y - pt.y
			local dist = math.sqrt(dx*dx + dy*dy)
			local a = (x - (pt.x + wave_offset))/dx
			return pt.y + dy * a
		end
	end
end

function createBoat(x,y)
	physics.newWorld()

	--    p7
	-- p1-p2-p5
	-- p4-p3-p6
	local p1 = physics.newPoint(x-20,y)
	local p2 = physics.newPoint(x,y)
	local p3 = physics.newPoint(x,y+10)
	local p4 = physics.newPoint(x-20,y+5)
	local p5 = physics.newPoint(x+20,y)
	local p6 = physics.newPoint(x+20,y+5)
	local p7 = physics.newPoint(x,y-60)
	p7.float = false

	boat_img = assets.img.sailboat
	boat_center = p3
	boat_left = p1
	boat_right = p5
	boat_top = p7

	physics.newConstraint(p1,p2)
	physics.newConstraint(p2,p3)
	physics.newConstraint(p3,p4)
	physics.newConstraint(p4,p1)

	physics.newConstraint(p1,p3)
	physics.newConstraint(p2,p4)

	physics.newConstraint(p2,p5)
	physics.newConstraint(p5,p6)
	physics.newConstraint(p6,p3)

	physics.newConstraint(p2,p6)
	physics.newConstraint(p3,p5)

	physics.newConstraint(p2,p7)
	physics.newConstraint(p1,p7)
	physics.newConstraint(p5,p7)
end

function getBoatAngle()
	return geom.angleBetween(boat_left.x,boat_left.y, boat_right.x,boat_right.y)
end
