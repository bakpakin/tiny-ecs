local TimerEvent = require "src.entities.TimerEvent"

local WaveSystem = tiny.system(class "WaveSystem")

WaveSystem.filter = tiny.requireAll("isEnemy")

function WaveSystem:init(levelState)
	self.levelState = levelState
end

function WaveSystem:onAdd(e)
	self.levelState.enemiesSpawned = self.levelState.enemiesSpawned + 1
end

function WaveSystem:onRemove(e)
	local levelState = self.levelState
	levelState.enemiesKilled = levelState.enemiesKilled + 1
	if levelState.enemiesKilled >= levelState.totalEnemiesToKill then
		world:add(TimerEvent(1, function()
			levelState:nextWave()
		end))
	end
end

return WaveSystem
