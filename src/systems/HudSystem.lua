local HudSystem = tiny.processingSystem(class "HudSystem")

function HudSystem:init(levelState, layerFlag)
	self.levelState = levelState
	self.filter = tiny.requireAll("drawHud", layerFlag)
end

function HudSystem:process(e, dt)
	e:drawHud(dt)
end 

return HudSystem