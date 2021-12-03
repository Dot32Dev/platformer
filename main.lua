local intro = require "intro" 
local map = require "map"

local player={x=514, y=360, w=10, h=40, xV = 0, yV = 0, r = 0, legWheel=0}

love.graphics.setBackgroundColor(intro.HSL(220/360, 0.5, 0.1))
love.graphics.setLineWidth(5)
love.graphics.setLineJoin("bevel")
intro:init()

local function inverseKinematics(p1x, p1y, l1, p2x, p2y, l2) --p1 is the foundation node, p2 is the goal node, l1/l2 are the lengths of each segment
	local dist = intro.distanceBetween(p1x, p1y, p2x, p2y)
	local atan = math.atan2(p2y-p1y, p2x-p1x)

	if dist > l1+l2 then --if the mouse is too far away then
		local theta = math.atan2((p2x - p1x), (p2y - p1y)) --finding angle of l1 and l2
		return p1x, p1y, --[[]](math.sin(theta)*l1)+p1x, (math.cos(theta)*l1)+p1y, --[[]](math.sin(theta)*(l1+l2))+p1x, (math.cos(theta)*(l1+l2))+p1y	
	else --else run the inverse kinematics taken from (https://github.com/lost-in-thoughts/ik-spider/blob/main/leg.lua)
		local cosAngle0 = ((dist * dist) + (l1 * l1) - (l2 * l2)) / (2 * dist * l1)
		local theta = atan - math.acos(cosAngle0)

		return p1x, p1y, math.cos(theta)*l1 + p1x, math.sin(theta)*l1 + p1y, p2x, p2y
	end
end

local function sign(number)
	return (number > 0 and 1) or -1
end

local function lerp(a, b, t) 
	return (b-a)*t+a
end

function love.update(dt)
	-- player
	player.yV = player.yV + 0.8 -- gravity is 0.5
	player.xV = player.xV * 0.87--(1 / (1 + (dt * 8)))
	player.legWheel = player.legWheel + player.xV/60*math.pi
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
	
	x,y = x+math.sin(player.r+math.pi)*6,y+math.cos(player.r)*6
	local dir = sign(math.cos(player.legWheel)*player.xV/5)

	love.graphics.setColour(1,1,1,1*dir)
	love.graphics.line(x,y, x+math.sin(player.r+math.pi+math.sin(player.legWheel)*player.xV/5)*14,y+math.cos(player.r+math.sin(player.legWheel)*player.xV/5)*14)
	love.graphics.line(x,y, 
		lerp(x+math.sin(player.r+math.pi+1*player.xV/5)*14, x+math.sin(player.r+math.pi-1*player.xV/5)*14, (math.sin(player.legWheel)+1)*0.5),
		lerp(y+math.cos(player.r+1*player.xV/5)*14, y+math.cos(player.r-1*player.xV/5)*14, (math.sin(player.legWheel)+1)*0.5))

	love.graphics.setColour(1,1,1,-1*dir)
	love.graphics.line(x,y, x+math.sin(player.r+math.pi-math.sin(player.legWheel)*player.xV/5)*14,y+math.cos(player.r-math.sin(player.legWheel)*player.xV/5)*14)
	love.graphics.line(x,y, 
		lerp(x+math.sin(player.r+math.pi-1*player.xV/5)*14, x+math.sin(player.r+math.pi+1*player.xV/5)*14, (math.sin(player.legWheel)+1)*0.5),
		lerp(y+math.cos(player.r-1*player.xV/5)*14, y+math.cos(player.r+1*player.xV/5)*14, (math.sin(player.legWheel)+1)*0.5))


	-- intro
	intro:draw()

	-- test
	-- love.graphics.line(inverseKinematics(400, 300, 100, love.mouse.getX(), love.mouse.getY(), 100))
	love.graphics.setColour(1,0,0)
	-- if math.cos(player.legWheel)*player.xV/5 < 0 then love.graphics.setColour(0,0, 1) end
	-- love.graphics.circle("fill", 200+player.r+math.pi+math.sin(player.legWheel)*player.xV/5*100, 100, 10)
	-- love.graphics.line()
	-- love.graphics.line(x+math.sin(player.r+math.pi+1*player.xV/5)*14, y+math.cos(player.r+1*player.xV/5)*14,
	 -- x+math.sin(player.r+math.pi-1*player.xV/5)*14,y+math.cos(player.r-1*player.xV/5)*14)

	 -- love.graphics.circle("fill", lerp(x+math.sin(player.r+math.pi+1*player.xV/5)*14, x+math.sin(player.r+math.pi-1*player.xV/5)*14, (math.sin(player.legWheel)+1)*0.5), y, 3)
end

function love.keypressed(k)
	if k == "r" then
		player.x = 514
		player.y = 360
		player.xV = 0
		player.yV = 0
	end	
end
