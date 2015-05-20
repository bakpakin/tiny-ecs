local AISystem = tiny.processingSystem(class "AISystem")

function AISystem:init(target)
    self.target = target
end

AISystem.filter = tiny.requireAll("ai", "pos", "platforming")

function AISystem:process(e, dt)
    if not self.target then
        return
    end
    local targetx = self.target.pos.x
    local pos = e.pos
    local p = e.platforming
    p.moving = self.target.isAlive
    if targetx > pos.x then
        p.direction = 'r'
    end
    if targetx < pos.x then
        p.direction = 'l'
    end
    p.jumping = math.random() < 0.5 * dt
end

return AISystem