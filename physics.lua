function pointDistance(x1,y1,x2,y2)
	local dx = x2 - x1
	local dy = y2 - y1
	return math.sqrt(dx*dx + dy*dy)
end

local physics = {}

physics.newWorld = function()
	physics.points = {}
	physics.constraints = {}
	physics.gravity = 20
end

physics.newPoint = function(x,y)
	print("Physics::newPoint {"..x..","..y.."}")
	local p = { 
		x = x, 
		y = y,
		oldx = x, 
		oldy = y,
		ax = 0, 
		ay = 0,
		underwater = false
	}
	table.insert(physics.points, p)
	return p
end

physics.newConstraint = function(p1,p2)
	print("Physics::newConstraint {"..p1.x..","..p1.y.."}{"..p2.x..","..p2.y.."}")
	dist = pointDistance(p1.x,p1.y,p2.x,p2.y)
	local c = {
		p1 = p1,
		p2 = p2,
		restlength = dist
	}
	table.insert(physics.constraints, c)
	return c
end

physics.run = function(timestep)
	sqrtimestep = timestep * timestep * 10

	local world_width = love.graphics.getWidth()
	local world_height = love.graphics.getHeight()
	
	for i,p in ipairs(physics.points) do
		p.ay = p.ay + physics.gravity

		local tempx, tempy = p.x, p.y
		p.x = p.x + (p.x - p.oldx) + p.ax * sqrtimestep
		p.y = p.y + (p.y - p.oldy) + p.ay * sqrtimestep
		p.oldx = tempx
		p.oldy = tempy
		p.ax = 0
		p.ay = 0
	end

	for i,c in ipairs(physics.constraints) do
		local deltax = c.p2.x - c.p1.x
		local deltay = c.p2.y - c.p1.y
		local len = math.sqrt(deltax*deltax + deltay*deltay)
		local diff = (len-c.restlength)/len
		c.p1.x = c.p1.x + deltax * 0.5 * diff
		c.p1.y = c.p1.y + deltay * 0.5 * diff
		c.p2.x = c.p2.x - deltax * 0.5 * diff
		c.p2.y = c.p2.y - deltay * 0.5 * diff
	end
end

physics.debugDraw = function()
	for i,c in ipairs(physics.constraints) do
		love.graphics.line(c.p1.x,c.p1.y, c.p2.x,c.p2.y)
	end

	for i,p in ipairs(physics.points) do
		love.graphics.circle("fill", p.x, p.y, 5, 12)
	end
end

return physics
