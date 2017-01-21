return {
	img = {
		bg_storm = love.graphics.newImage("assets/bg-storm.png"),
		boat = love.graphics.newImage("assets/boat.png"),
		sailboat = love.graphics.newImage("assets/sailboat.png"),
		sailboat_sunk = love.graphics.newImage("assets/sailboat-sunk.png"),
		cloud1 = love.graphics.newImage("assets/cloud-1.png")
	},
	fx = {},
	music = {
		-- Remember (We are Divine, We are Immortal) by Ars Sonor
		-- Create Commons Attribution-ShareAlike
		-- http://freemusicarchive.org/music/Ars_Sonor/In_Search_of_Home/11-Remember_We_Are_Divine_We_Are_Immortal
		remember = love.audio.newSource("assets/remember.mp3", "stream"),

		-- Storm At Sea by KevinT1001 of freesound.org
		-- http://freesound.org/people/KevinT1001/sounds/170829/
		stormatsea = love.audio.newSource("assets/stormatsea.mp3", "stream")
	},
}
