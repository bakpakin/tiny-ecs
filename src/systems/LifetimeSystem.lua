local LifetimeSystem = tiny.processingSystem(class "LifetimeSystem")

LifetimeSystem.filter = tiny.requireAll("lifetime")

function LifetimeSystem:process(e, dt)
    e.lifetime = e.lifetime - dt
    if e.lifetime <= 0 then
        if e.onLifeover then
            e:onLifeover()
        end
        world:remove(e)
    end
end

return LifetimeSystem