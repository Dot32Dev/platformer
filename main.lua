local intro = require "intro" 
local map = require "map"

local player={x=514, y=360, w=20, h=40}

love.graphics.setBackgroundColor(intro.HSL(220/360, 0.5, 0.1))
intro:init()

function love.update(dt)
	-- player
	local xV = (player.x - (player.xPre or player.x))*0.87
	local yV = player.y - (player.yPre or player.y)
	player.xPre = player.x
	player.yPre = player.y
	player.y = player.y + 0.8 -- gravity is 0.5
	if love.keyboard.isDown("a") then
		player.x = player.x - 1
	end
	if love.keyboard.isDown("d") then
		player.x = player.x + 1
	end
	player.x = player.x + xV
	player.y = player.y + yV
	for i, rect in ipairs(map) do
		if player.x+player.w > rect.x and player.x < rect.x + rect.w and player.y+player.h > rect.y and player.y < rect.y + rect.h then
			if player.xPre+player.w > rect.x and player.xPre < rect.x + rect.w then 
				player.y = (player.y < rect.y and rect.y - player.h) or (player.y > rect.y+rect.h-player.y and rect.y+rect.h) or player.y
				if love.keyboard.isDown("w") and not (player.y == rect.y+rect.h) then
					player.yPre = player.y
					player.y = player.y - 15
				end
			else
				player.x = (player.x < rect.x and rect.x - player.w) or (player.x > rect.x+rect.w-player.x and rect.x+rect.w) or player.x
			end
		end
	end

	-- intro
	intro:update(dt)
end

function love.draw()
	-- ground
	love.graphics.setColour(intro.HSL(220/360, 0.5, 0.4))
	for i, rect in ipairs(map) do
		love.graphics.rectangle("fill", rect.x, rect.y, rect.w, rect.h)
	end

	-- player
	love.graphics.setColour(1,1,1)
	love.graphics.rectangle("fill", player.x, player.y, player.w, player.h)
	local s = math.sin(intro.timer)
	local c = math.sin(intro.timer)
	local x = player.x + player.w/2
	local y = player.y + player.h/2
	-- love.graphics.polygon("fill", player.x*s, player.y*c, (player.x+player.w)*s, player.y*c, (player.x+player.w)*s, (player.y+player.h)*c, player.x*s, (player.y+player.h)*c)
	love.graphics.circle("fill", x + s*-player.w/2 + c*-player.h/2, y + c*-player.w/2 + s*-player.h/2, 10)

	-- intro
	intro:draw()
end

function love.keypressed(k)
	if k == "r" then
		player = {x=514, y=360, w=20, h=40}
	end	
end
