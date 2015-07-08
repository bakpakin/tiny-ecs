local assets = require "src.assets"
local Pig = require "src.entities.Pig"

local Spawner = class "Spawner"

Spawner.sprite = assets.img_spawner

function Spawner:init(args)
	self.pos = {x = args.x + 32, y = args.y + 32}
	self.offset = {x = 32, y = 32}
	self.scale = {x = 1, y  = 1}
	self.rot = 0
	self.bg = true
	self.isSpawner = true
end

function Spawner:update(dt)
	self.rot = self.rot + 2 * dt
	local s = math.random() * 0.2 + 0.9
	self.scale.x, self.scale.y = s, s
end

function Spawner:spawn()
	world:add(Pig(self.pos.x - 15, self.pos.y - 10, nil))
end

return Spawner
