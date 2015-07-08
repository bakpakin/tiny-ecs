local assets =  require "src.assets"
local anim8 = require "lib.anim8"

local Explosion = class "Explosion"

Explosion.sprite = assets.img_explosion

function Explosion:init(x, y)
	self.pos = {x = x, y = y}
	self.bg = true
	local g = anim8.newGrid(64, 64, assets.img_explosion:getWidth(), assets.img_explosion:getHeight())
	self.animation = anim8.newAnimation(g('1-10', 1), 0.05)
	self.lifetime = 9 * 0.05
end

return Explosion
