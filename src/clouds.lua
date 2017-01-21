
local clouds = {}

function createCloud(dist, angle, speed)
	c = {
		angle = angle,
		distance = dist,
		speed = speed
	}
	table.insert(clouds,c)
	return c
end

createCloud(500,math.rad(240), 1)
createCloud(200,math.rad(50), 2)
createCloud(300,math.rad(120), -2)
createCloud(250,math.rad(270), -.5)
createCloud(320,math.rad(290), 1.5)
createCloud(400,math.rad(90), -5)
createCloud(120,math.rad(120), -.5)
createCloud(320,math.rad(20), 1.5)
createCloud(400,math.rad(10), -1)
createCloud(250,math.rad(320), -.5)
createCloud(320,math.rad(240), 1.5)
createCloud(100,math.rad(180), -3)
createCloud(230,math.rad(120), -.3)
createCloud(310,math.rad(20), .2)
createCloud(180,math.rad(10), .5)
createCloud(279,math.rad(320), 2)
createCloud(250,math.rad(240), -1)
createCloud(300,math.rad(180), -6)


local lib = {}

lib.run = function(dt)
	for i,c in ipairs(clouds) do
		c.angle = c.angle + c.speed * dt * 0.005
	end
end

lib.draw = function(cx,cy,sx,sy,debugDraw)
	love.graphics.setColor(255,255,255)
	for i,c in ipairs(clouds) do
		local img = assets.img.cloud1
		local cx = cx + geom.lengthDirX(c.distance,c.angle)
		local cy = cy + geom.lengthDirY(c.distance,c.angle)
		local ox = img:getWidth() * 0.5
		local oy = img:getHeight() * 0.5
		love.graphics.draw(img, cx,cy, -c.angle, sx,sy, ox,oy)
		if debugDraw then 
			love.graphics.setColor(255,0,0)
			love.graphics.circle("fill", cx,cy, 12, 12)
			love.graphics.line(cx,cy, cx,cy)
			love.graphics.setColor(255,255,255)
		end
	end
end

return lib
