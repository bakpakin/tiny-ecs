local TimerEvent = require "src.entities.TimerEvent"

local SpawnSystem = tiny.system(class "SpawnSystem")

SpawnSystem.filter = tiny.requireAll("isSpawner")

function SpawnSystem:init(levelState)
	self.levelState = levelState
	self.time = 0
end

function SpawnSystem:update(dt)
	self.time = self.time + dt
	local levelState = self.levelState
	if levelState.isSpawning and levelState.enemiesSpawned < levelState.totalEnemiesToKill and self.time >= levelState.spawnInterval then
		local choice = math.ceil(math.random() * levelState.spawnerCount)
		for spnr in pairs(levelState.spawners) do
			choice = choice - 1
			if choice == 0 then
				spnr:spawn()
			end
		end
		self.time = 0
	end
end

function SpawnSystem:onAdd(e)
	self.levelState.spawners[e] = true
	self.levelState.spawnerCount = self.levelState.spawnerCount + 1
end

function SpawnSystem:onRemove(e)
	self.levelState.spawners[e] = false
	self.levelState.spawnerCount = self.levelState.spawnerCount - 1
end

return SpawnSystem
