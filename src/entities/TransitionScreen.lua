local gamestate = require "lib.gamestate"
local TransitionScreen = class "TransitionScreen"

TransitionScreen.hudFg = true

-- mode is true for "toblack" or false for "totransparent"
function TransitionScreen:init(mode, newState)
	self.lifetime = 0.5
	self.newState = newState
	if mode then
		self.alpha = 0
		self.fadeTime = -0.5
	else
		self.alpha = 1
		self.fadeTime = 0.5
	end
end

function TransitionScreen:drawHud(dt)
	local r1, g1, b1, a = love.graphics.getColor()
    love.graphics.setColor(0, 0, 0, self.alpha * 255)
    love.graphics.rectangle("fill", 0, 0, love.graphics.getWidth(), love.graphics.getHeight())
    love.graphics.setColor(r1, g1, b1, a)
end

function TransitionScreen:onLifeover()
	if self.newState then
		gamestate.switch(self.newState)
	end
end

return TransitionScreen
