local color = {}

color.rgb = function(r, g, b)
	return { r=r, g=g, b=b }
end

color.val = function(col) 
	return col.r, col.g, col.b
end

return color
