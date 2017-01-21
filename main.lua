color = require("color")
physics = require("physics")
geom = require("geom")

DEBUG_DRAW_WATER_POLY = false
DEBUG_DRAW_NO_BG = false
DEBUG_DRAW_PHYSICS = false
DEBUG_DRAW_WATER_HEIGHT = false

KEY_RESTART = "r"
KEY_QUIT = "escape"
KEY_RIGHT = "right"
KEY_LEFT = "left"

COL_WHITE = color.rgb(255,255,255)
COL_WATER = color.rgb(41,63,101)

REST_Y = love.graphics.getHeight()*0.7
NUMBER_OF_WAVE_POINTS = 100
DIST_BETWEEN_WATER_POINTS = love.graphics.getWidth() / NUMBER_OF_WAVE_POINTS * 2
DEPTH_TO_LOSE = 20
ANGLE_TO_LOSE = math.rad(20)
INPUT_STRENGTH = 100

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
			dist = math.sin(xx * 0.01) * 100
		}
	end

	physics.newWorld()

	--    p7
	-- p1-p2-p5
	-- p4-p3-p6
	local p1 = physics.newPoint(130,540)
	local p2 = physics.newPoint(150,540)
	local p3 = physics.newPoint(150,550)
	local p4 = physics.newPoint(130,545)
	local p5 = physics.newPoint(170,540)
	local p6 = physics.newPoint(170,545)
	local p7 = physics.newPoint(150,500)
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

	lost = false
end

function love.update(dt)
	-- The seas only get rougher if we haven't lost yet
	if not lost then
		total_time = total_time + dt
	end

	local sp = dt * 90
	wave_offset = wave_offset - sp
	for i,pt in ipairs(wave_points) do
		pt.y = REST_Y + pt.dist + math.sin((pt.x + wave_offset) * 0.02) * (10 + total_time)
	end

	if wave_offset < -wave_points[1].x - DIST_BETWEEN_WATER_POINTS then
		local pt = table.remove(wave_points, 1)
		local n = table.getn(wave_points)
		local lastpt = wave_points[n]
		pt.i = lastpt.i + 1
		pt.x = (pt.i-1) * DIST_BETWEEN_WATER_POINTS
		pt.dist = math.sin(pt.x * 0.01) * (100 + total_time)
		table.insert(wave_points, pt)
	end

	-- Gather player input
	if not lost then
		local input = 0
		if love.keyboard.isDown(KEY_RIGHT) then input = input + 1 end
		if love.keyboard.isDown(KEY_LEFT) then input = input - 1 end

		if input == 1 then
			boat_right.ay = boat_right.ay + INPUT_STRENGTH
		elseif input == -1 then
			boat_left.ay = boat_left.ay + INPUT_STRENGTH
		end
	end

	-- Physics the boat
	for i,p in ipairs(physics.points) do
		local water_level = waterHeightAtX(p.x)
		if p.y > water_level then
			if p == boat_top then
				local a = getBoatAngle()
				if p.y - water_level > DEPTH_TO_LOSE and a > math.pi - ANGLE_TO_LOSE and a < math.pi + ANGLE_TO_LOSE then
					lost = true
					boat_img = assets.img.sailboat_sunk
				end
			else
				local f = math.max(-physics.gravity*1.5, water_level-p.y)
				p.oldx = p.x
				p.y = p.y - (p.y - water_level)*0.01
			end
		end
	end
	-- Run the verlet and constraints
	physics.run(dt)
end

function love.draw()
	local img = assets.img.bg_storm
	local sx, sy = love.graphics.getDimensions() / img:getDimensions()

	if not DEBUG_DRAW_NO_BG then
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
end

function love.keypressed(key)
	if key == KEY_RESTART then
		love.load()
	elseif key == KEY_QUIT then
		love.quit()
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

function getBoatAngle()
	return geom.angleBetween(boat_left.x,boat_left.y, boat_right.x,boat_right.y)
end
