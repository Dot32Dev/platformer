local intro = require "intro" 
local map = require "map"

local player={x=514, y=360, w=20, h=40, xV = 0, yV = 0, r = 0}

love.graphics.setBackgroundColor(intro.HSL(220/360, 0.5, 0.1))
intro:init()

function love.update(dt)
	-- player
	player.yV = player.yV + 0.8 -- gravity is 0.5
	player.xV = player.xV * 0.87--(1 / (1 + (dt * 8)))
	if love.keyboard.isDown("a") then
		player.xV = player.xV - 1
	end
	if love.keyboard.isDown("d") then
		player.xV = player.xV + 1
	end
	player.x = player.x + player.xV
	player.y = player.y + player.yV
	player.r = (player.xV*1.5*math.min(1, math.max(-1, player.yV/-10)))/15
	for i, rect in ipairs(map) do
		if player.x+player.w > rect.x and player.x < rect.x + rect.w and player.y+player.h > rect.y and player.y < rect.y + rect.h then
			if (player.x - player.xV)+player.w > rect.x and (player.x - player.xV) < rect.x + rect.w then 
				player.y = (player.y < rect.y and rect.y - player.h) or (player.y > rect.y+rect.h-player.y and rect.y+rect.h) or player.y
				player.yV = 0
				player.r = player.xV/25
				if love.keyboard.isDown("w") and not (player.y == rect.y+rect.h) then
					player.yV = player.yV - 16
				end
			else
				player.x = (player.x < rect.x and rect.x - player.w) or (player.x > rect.x+rect.w-player.x and rect.x+rect.w) or player.x
				player.xV = 0
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
	local x = player.x + player.w/2
	local y = player.y + player.h/2
	love.graphics.push()
	love.graphics.translate(x, y)	
	love.graphics.rotate(player.r)
	love.graphics.rectangle("fill", -player.w/2, -player.h/2, player.w, player.h)
	love.graphics.pop()

	-- intro
	intro:draw()
end

function love.keypressed(k)
	if k == "r" then
		player.x = 514
		player.y = 360
	end	
end
