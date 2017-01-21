local geom = {}

geom.angleBetween = function(x1,y1,x2,y2)
	local o = y2 - y1
	local a = x2 - x1
	local theta = math.atan(o / a)
	if a < 0 then theta = theta + math.pi end
	return theta
end

geom.lengthDirX = function(len,dir)
	return len * math.sin(dir)
end

geom.lengthDirY = function(len,dir)
	return len * math.cos(dir)
end

return geom
