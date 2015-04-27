local assets = require "src.assets"

local MainHud = class "MainHud"

function MainHud:drawHud(dt)
	local n = self.levelState.totalEnemiesToKill - self.levelState.enemiesKilled
	local d = self.levelState.totalEnemiesToKill
	love.graphics.setFont(assets.fnt_hud)
	love.graphics.printf("Wave " .. self.levelState.wave, 20, 20, 300, "left")			
	love.graphics.setFont(assets.fnt_smallhud)
	love.graphics.printf(n .. "/" .. d .. " Pigs Remaining", 20, 60, 500, "left")
	love.graphics.printf("Total Pigs Killed: " .. self.levelState.score, love.graphics.getWidth() - 420, 20, 400, "right")
end

function MainHud:init(levelState)
	self.levelState = levelState
	self.hudBg = true
end

return MainHud