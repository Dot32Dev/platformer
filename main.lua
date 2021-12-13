local intro = require "intro"  
local map = require "map"

local player={w=10, h=40, r = 0, legWheel=0, groundTime = 0, airTime = 0, crouch = 0}
local ConnectedController = false
local zoom = 1

love.graphics.setBackgroundColor(intro.HSL(220/360, 0.5, 0.1))
love.graphics.setLineWidth(5)
love.graphics.setLineJoin("none")
intro:init()

local function inverseKinematics(p1x, p1y, l1, l2, p2x, p2y, direction) --p1 is the foundation node, p2 is the goal node, l1/l2 are the lengths of each segment
	if direction and direction > 0 then -- this swaps the points so as to reverse the direction in which the knee points
		-- plx, p2x = p2x, p1x
		-- ply, p2y = p2y, p1y
		local p3x, p3y = p1x, p1y
		p1x, p1y = p2x, p2y
		p2x, p2y = p3x, p3y
		-- print(math.floor(p1x), math.floor(p1y), "|", math.floor(p2x), math.floor(p2y))
	end

	local dist = intro.distanceBetween(p1x, p1y, p2x, p2y)

	if dist > l1+l2 then --if the mouse is too far away then
		local theta = math.atan2((p2x - p1x), (p2y - p1y)) --finding angle of l1 and l2
		return p1x, p1y, --[[]](math.sin(theta)*l1)+p1x, (math.cos(theta)*l1)+p1y, --[[]](math.sin(theta)*(l1+l2))+p1x, (math.cos(theta)*(l1+l2))+p1y	
	else --else run the inverse kinematics taken from (https://github.com/lost-in-thoughts/ik-spider/blob/main/leg.lua)
		local cosAngle0 = ((dist * dist) + (l1 * l1) - (l2 * l2)) / (2 * dist * l1)
		local atan = math.atan2(p2y-p1y, p2x-p1x)
		local theta = atan - math.acos(cosAngle0)

		return p1x, p1y, math.cos(theta)*l1 + p1x, math.sin(theta)*l1 + p1y, p2x, p2y
	end
end

local function sign(number)
	return (number < 0 and -1) or 1
end

local function lerp(a, b, t) 
	return (b-a)*t+a
end

local function resetPlayer()
	player.x = 514
	player.y = 360
	player.xV = 2
	player.yV = 0
end 
resetPlayer()

function love.update(dt)
	-- player
	player.yV = player.yV + 0.8 -- gravity is 0.5
	player.xV = player.xV * 0.87--(1 / (1 + (dt * 8)))
	player.crouch = player.crouch *0.8

	local inputX = (ConnectedController and ConnectedController:getGamepadAxis("leftx")) or 0

	if love.keyboard.isDown("a") or love.keyboard.isDown("left") or inputX < -0.2 then
		player.xV = player.xV - 1
	end
	if love.keyboard.isDown("d") or love.keyboard.isDown("right") or inputX > 0.2 then
		player.xV = player.xV + 1
	end

	player.x = player.x + player.xV
	player.y = player.y + player.yV

	local colided = false
	for i, rect in ipairs(map) do
		if player.x+player.w > rect.x and player.x < rect.x + rect.w and player.y+player.h > rect.y and player.y < rect.y + rect.h then
			if (player.x - player.xV)+player.w > rect.x and (player.x - player.xV) < rect.x + rect.w then 
				player.y = (player.y < rect.y and rect.y - player.h) or (player.y > rect.y+rect.h-player.y and rect.y+rect.h) or player.y
				player.crouch = math.max(player.crouch, (player.yV-1)/1.5)
				player.yV = 0

				player.r = player.xV/25 --+ (player.xV*0.8*math.min(1, math.max(-1, player.crouch*2/-7)))/15
				player.groundTime = player.groundTime + 1
				player.legWheel = player.legWheel + 15/180*math.pi*sign(player.xV)--player.xV/80*math.pi

				if (love.keyboard.isDown("w") or love.keyboard.isDown("up") or (ConnectedController and ConnectedController:isGamepadDown("a", "y"))) 
				and not (player.y == rect.y+rect.h) then
					player.yV = player.yV - 16
					player.crouch = math.max(player.crouch, math.abs(player.yV+1)/1.5)
				end

				colided = true
			else
				player.x = (player.x < rect.x and rect.x - player.w) or (player.x > rect.x+rect.w-player.x and rect.x+rect.w) or player.x
				player.xV = 0
			end
		end
	end

	if not colided then
		player.legWheel = player.legWheel % math.pi
		player.legWheel = player.legWheel * 0.9
		player.r = (player.xV*0.8*math.min(1, math.max(-1, player.yV/-7)))/15
		player.groundTime = 0
	end
	if player.y > 720 or (ConnectedController and ConnectedController:isGamepadDown("dpleft", "dpright", "dpup", "dpdown")) then 
		resetPlayer()
	end

	-- intro
	intro:update(dt)
end

function love.draw()
	love.graphics.push()
	love.graphics.scale(zoom)
	-- player
	love.graphics.setColour(1,1,1)
	local x = player.x + player.w/2
	local y = player.y + player.h/2 + player.crouch
	love.graphics.push()
	love.graphics.translate(x, y)	
	love.graphics.rotate(player.r)
	-- love.graphics.rectangle("fill", -player.w/2, -player.h/2, player.w, player.h)
	love.graphics.pop()
	-- love.graphics.setColour(0,0,0)
	love.graphics.circle("fill", x+math.sin(player.r+math.pi)*-(13-player.crouch/2),y+math.cos(player.r)*-(13-player.crouch/2),7, 21)
	love.graphics.line(x+math.sin(player.r+math.pi)*6,y+math.cos(player.r)*6, x+math.sin(player.r+math.pi)*-(13-player.crouch),y+math.cos(player.r)*-(13-player.crouch))
	
	x,y = x+math.sin(player.r+math.pi)*6,y+math.cos(player.r)*6
	local dir = sign(math.cos(player.legWheel)*player.xV)

	--[[foot 1 is the leg higher in the air, and foot 2 is the leg touching the ground/opposite of foot1]]
	local foot1X = lerp(x+math.sin(player.r+math.pi+dir*player.xV/5)*14, x+math.sin(player.r+math.pi-dir*player.xV/5)*14, (math.sin(player.legWheel)+1)*0.5) +player.crouch
	local foot1Y = math.min(lerp(y+math.cos(player.r+dir*player.xV/5)*14, y+math.cos(player.r-dir*player.xV/5)*14, (math.sin(player.legWheel)+1)*0.5), y+14-player.crouch)
	love.graphics.line(inverseKinematics(foot1X,foot1Y,7,7,x,y, player.xV))

	local foot2X = x+math.sin(player.r+math.pi+dir*math.sin(player.legWheel)*player.xV/5)*14 -player.crouch
	local foot2Y = math.min(y+math.cos(player.r+dir*math.sin(player.legWheel)*player.xV/5)*14, y+14-player.crouch)
	love.graphics.line(inverseKinematics(x,y, 7,7, foot2X,foot2Y, -player.xV))
	-- love.graphics.line(x,y, foot1X, foot1Y)

	-- ground
	love.graphics.setColour(intro.HSL(220/360, 0.5, 0.4))
	for i, rect in ipairs(map) do
		love.graphics.rectangle("fill", rect.x, rect.y, rect.w, rect.h)
	end

	love.graphics.pop()
	-- intro
	intro:draw()

	-- test
	love.graphics.setColour(1,0,0)
	-- love.graphics.line(inverseKinematics(400, 300, 100, 100, love.mouse.getX(), love.mouse.getY()))
	-- if math.cos(player.legWheel)*player.xV/5 < 0 then love.graphics.setColour(0,0, 1) end
	-- love.graphics.circle("fill", 200+player.r+math.pi+math.sin(player.legWheel)*player.xV/5*100, 100, 10)
	-- love.graphics.line()
	-- love.graphics.line(x+math.sin(player.r+math.pi+1*player.xV/5)*14, y+math.cos(player.r+1*player.xV/5)*14,
	-- x+math.sin(player.r+math.pi-1*player.xV/5)*14,y+math.cos(player.r-1*player.xV/5)*14)

	-- love.graphics.circle("fill", lerp(x+math.sin(player.r+math.pi+dir*player.xV/5)*14, x+math.sin(player.r+math.pi-dir*player.xV/5)*14, (math.sin(player.legWheel)+1)*0.5), lerp(y+math.cos(player.r+dir*player.xV/5)*14, y+math.cos(player.r-dir*player.xV/5)*14, (math.sin(player.legWheel)+1)*0.5) , 3)
	if ConnectedController then love.graphics.print(ConnectedController:getName()) end
end

function love.keypressed(k)
	if k == "r" then
		resetPlayer()
	end	
end

function love.joystickadded(j)
	if not ConnectedController then
		ConnectedController = j
	end
end
function love.joystickremoved(j)
	if j == ConnectedController then
		ConnectedController = false
	end
end

function love.resize(w,h)
	zoom = math.min(w/1280, h/720)
end