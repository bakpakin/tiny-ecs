local UpdateSystem = tiny.processingSystem(class "UpdateSystem")

UpdateSystem.filter = tiny.requireAll("update")

function UpdateSystem:process(e, dt)
	e:update(dt)
end

return UpdateSystem