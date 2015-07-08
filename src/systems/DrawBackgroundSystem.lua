local DrawBackgroundSystem = tiny.system(class "DrawBackgroundSystem")

function DrawBackgroundSystem:init(r, g, b)
	self.r, self.g, self.b = r, g, b
end

function DrawBackgroundSystem:update(dt)
	local r1, g1, b1, a = love.graphics.getColor()
	love.graphics.setColor(self.r, self.g, self.b, 255)
	love.graphics.rectangle("fill", 0, 0, love.graphics.getWidth(), love.graphics.getHeight())
	love.graphics.setColor(r1, g1, b1, a)
end

return DrawBackgroundSystem
