local intro = require "intro" 
local map = require "map"

local player={x=514, y=360, w=20, h=40, xV = 0, yV = 0, r = 0, legWheel=0}

love.graphics.setBackgroundColor(intro.HSL(220/360, 0.5, 0.1))
love.graphics.setLineWidth(5)
intro:init()

local function IK(p1x, p1y, l1, p2x, p2y, l2) --p1 is the foundation node, p2 is the goal node, l1/l2 are the lengths of each segment
	local dist = distanceBetween(p1x, p1y, p2x, p2y)
	local atan = math.atan2(p2y-p1y, p2x-p1x)

	if dist > l1+l2 then --if the mouse is too far away then
		local theta = math.atan2((p2x - p1x), (p2y - p1y)) --finding angle of l1 and l2
		return p1x, p1y --[[]](math.sin(theta)*l1)+p1x, (math.cos(theta)*l1)+p1y, --[[]](math.sin(theta)*(l1+l2))+p1x, (math.cos(theta)*(l1+l2))+p1y	
	else --else run the inverse kinematics taken from (https://github.com/lost-in-thoughts/ik-spider/blob/main/leg.lua)
	local cosAngle0 = ((dist * dist) + (l1 * l1) - (l2 * l2)) / (2 * dist * l1)
	local theta1 = atan - math.acos(cosAngle0)

	return p1x, p1y, (math.cos(theta1)*l1)+p1x, (math.sin(theta1)*l1)+p1y, p2x, p2y}
end

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
	player.r = (player.xV*1.5*math.min(1, math.max(-1, player.yV/-7)))/15
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
	-- love.graphics.rectangle("fill", -player.w/2, -player.h/2, player.w, player.h)
	love.graphics.pop()
	-- love.graphics.setColour(0,0,0)
	love.graphics.circle("fill", x+math.sin(player.r+math.pi)*-13,y+math.cos(player.r)*-13,7)
	love.graphics.line(x+math.sin(player.r+math.pi)*6,y+math.cos(player.r)*6, x+math.sin(player.r+math.pi)*-13,y+math.cos(player.r)*-13)
	
	player.legWheel = player.legWheel + player.xV/60*math.pi
	x,y = x+math.sin(player.r+math.pi)*6,y+math.cos(player.r)*6
	love.graphics.line(x,y, x+math.sin(player.r+math.pi+math.sin(player.legWheel)*player.xV/5)*14,y+math.cos(player.r+math.sin(player.legWheel)*player.xV/5)*14)
	-- love.graphics.setColour(1,0,0)
	love.graphics.line(x,y, x+math.sin(player.r+math.pi-math.sin(player.legWheel)*player.xV/5)*14,y+math.cos(player.r-math.sin(player.legWheel)*player.xV/5)*14)

	-- intro
	intro:draw()
end

function love.keypressed(k)
	if k == "r" then
		player.x = 514
		player.y = 360
	end	
end
