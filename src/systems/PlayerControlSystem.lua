local assets = require "src.assets"
local Bullet = require "src.entities.Bullet"

local PlayerControlSystem = tiny.processingSystem(class "PlayerControlSystem")

PlayerControlSystem.filter = tiny.requireAll("controlable")

function PlayerControlSystem:process(e, dt)
	local vel =	e.vel
	local p = e.platforming
	local l, r, u = love.keyboard.isDown('a'), love.keyboard.isDown('d'), love.keyboard.isDown('w')
	local gl, gr = love.keyboard.isDown('left'), love.keyboard.isDown('right')
	local fire = love.keyboard.isDown('down')

	e.shotTimer = math.max(0, e.shotTimer - dt)

	if l and not r then
		p.moving = true
		if p.direction == 'r' then
			e.gunAngle = math.pi * 3 - e.gunAngle
		end
		p.direction = 'l'
	elseif r and not l then
		p.moving = true
		if p.direction == 'l' then
			e.gunAngle = math.pi * 3 - e.gunAngle
		end
		p.direction = 'r'
	else
		p.moving = false
	end

	p.jumping = u

	if gr and not gl then
		e.gunAngle = math.min(2 * math.pi, e.gunAngle + 8 * dt)
	elseif gl and not gr then
		e.gunAngle = math.max(math.pi, e.gunAngle - 8 * dt)
	end

	if e.hasGun and fire and e.shotTimer == 0 then
		local dx =	e.platforming.direction == 'l' and 2 or -2
		local bullet = Bullet(e.pos.x + 16 + dx, e.pos.y + 9, e.gunAngle)
		assets.snd_cannon:play()
		world:add(bullet)
		e.shotTimer = e.shotInterval
	end
end

return PlayerControlSystem