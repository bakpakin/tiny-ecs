local GLOBALS = {}
for k, v in pairs(_G) do
    GLOBALS[k] = v
end

local tiny = require "tiny"

local function deep_copy(x)
    if type(x) == 'table' then
        local nx = {}
        for k, v in next, x, nil do
            nx[deep_copy(k)] = deep_copy(v)
        end
        return nx
    else
        return x
    end
end

local entityTemplate1 = {
    xform = {x = 0, y = 0},
    vel = {x = 1, y = 2},
    name = "E1",
    size = 11,
    description = "It goes to 11.",
    spinalTap = true
}

local entityTemplate2 = {
    xform = {x = 2, y = 2},
    vel = {x = -1, y = 0},
    name = "E2",
    size = 10,
    description = "It does not go to 11.",
    onlyTen = true
}

local entityTemplate3 = {
    xform = {x = 4, y = 5},
    vel = {x = 0, y = 3},
    name = "E3",
    size = 8,
    description = "The smallest entity.",
    littleMan = true
}

describe('tiny-ecs:', function()

    describe('Filters:', function()

        local entity1, entity2, entity3

        before_each(function()
            entity1 = deep_copy(entityTemplate1)
            entity2 = deep_copy(entityTemplate2)
            entity3 = deep_copy(entityTemplate3)
        end)

        it("Default Filters", function()

            local ftap = tiny.requireAll("spinalTap")
            local fvel = tiny.requireAll("vel")
            local fxform = tiny.requireAll("xform")
            local fall = tiny.requireAny("spinalTap", "onlyTen", "littleMan")

            -- Only select Entities without "spinalTap"
            local frtap = tiny.rejectAny("spinalTap")

            -- Select Entities without all three: "spinalTap", "onlyTen", and
            -- "littleMan"
            local frall = tiny.rejectAll("spinalTap", "onlyTen", "littleMan")

            assert.truthy(fall(nil, entity1))
            assert.truthy(ftap(nil, entity1))
            assert.falsy(ftap(nil, entity2))
            assert.truthy(fxform(nil, entity1))
            assert.truthy(fxform(nil, entity2))

            assert.truthy(fall(nil, entity1))
            assert.truthy(fall(nil, entity2))
            assert.truthy(fall(nil, entity3))

            assert.falsy(frtap(nil, entity1))
            assert.truthy(frtap(nil, entity2))
            assert.truthy(frtap(nil, entity3))

            assert.truthy(frall(nil, entity1))
            assert.truthy(frall(nil, entity2))
            assert.truthy(frall(nil, entity3))

        end)

        it("Can use functions as subfilters", function()

            local f1 = tiny.requireAny('a', 'b', 'c')
            local f2 = tiny.requireAll('x', 'y', 'z')
            local f = tiny.requireAll(f1, f2)

            assert.truthy(f(nil, {
                x = true, y = true, z = true, a = true, b = true, c = true
            }))
            assert.truthy(f(nil, {
                x = true, y = true, z = true, a = true
            }))
            assert.falsy(f(nil, {
                x = true, y = true, a = true
            }))
            assert.falsy(f(nil, {
                x = true, y = true, z = true
            }))

        end)

        it("Can use string filters", function()

            local f = tiny.filter('a|b|c')

            assert.truthy(f(nil, {
                a = true, b = true, c = true
            }))
            assert.truthy(f(nil, {
                a = true
            }))
            assert.truthy(f(nil, {
                b = true
            }))
            assert.truthy(f(nil, {
                c = true
            }))
            assert.falsy(f(nil, {
                x = true, y = true, z = true
            }))

        end)

    end)

    describe('World:', function()

        local world, entity1, entity2, entity3

        local moveSystem = tiny.processingSystem()
        moveSystem.filter = tiny.requireAll("xform", "vel")
        function moveSystem:process(e, dt)
            local xform = e.xform
            local vel = e.vel
            local x, y = xform.x, xform.y
            local xvel, yvel = vel.x, vel.y
            xform.x, xform.y = x + xvel * dt, y + yvel * dt
        end

        local timePassed = 0
        local oneTimeSystem = tiny.system()
        function oneTimeSystem:update(dt)
            timePassed = timePassed + dt
        end

        before_each(function()
            entity1 = deep_copy(entityTemplate1)
            entity2 = deep_copy(entityTemplate2)
            entity3 = deep_copy(entityTemplate3)
            world = tiny.world(moveSystem, oneTimeSystem, entity1, entity2, entity3)
            timePassed = 0
        end)

        after_each(function()
            world:clearSystems()
            world:refresh()
        end)

        it("Create World", function()
            assert.equals(world:getEntityCount(), 3)
            assert.equals(world:getSystemCount(), 2)
        end)

        it("Run simple simulation", function()
            world:update(1)
            assert.equals(timePassed, 1)
            assert.equals(entity1.xform.x, 1)
            assert.equals(entity1.xform.y, 2)
        end)

        it("Remove Entities", function()
            world:remove(entity1, entity2)
            world:update(1)
            assert.equals(timePassed, 1)
            assert.equals(entity1.xform.x, entityTemplate1.xform.x)
            assert.equals(entity2.xform.x, entityTemplate2.xform.x)
            assert.equals(entity3.xform.y, 8)
        end)

        it("Remove Systems", function()
            world:remove(moveSystem, oneTimeSystem)
            world:update(1)
            assert.equals(timePassed, 0)
            assert.equals(entity1.xform.x, entityTemplate1.xform.x)
            assert.equals(0, world:getSystemCount())
        end)

        it("Deactivate and Activate Systems", function()
            moveSystem.active = false
            oneTimeSystem.active = false
            world:update(1)
            assert.equals(world:getSystemCount(), 2)
            assert.equals(timePassed, 0)
            assert.equals(entity1.xform.x, entityTemplate1.xform.x)
            moveSystem.active = true
            oneTimeSystem.active = true
            world:update(1)
            assert.equals(timePassed, 1)
            assert.are_not.equal(entity1.xform.x, entityTemplate1.xform.x)
            assert.equals(world:getSystemCount(), 2)
        end)

        it("Clear Entities", function()
            world:clearEntities()
            world:update(1)
            assert.equals(0, world:getEntityCount())
        end)

        it("Clear Systems", function()
            world:clearSystems()
            world:update(1)
            assert.equals(0, world:getSystemCount())
        end)

        it("Add Entities Multiple Times", function()
            world:update(1)
            world:add(entity1, entity2, entity3)
            world:update(2)
            assert.equals(2, world:getSystemCount())
            assert.equals(3, world:getEntityCount())
        end)

        it("Remove Entities Multiple Times", function()
            assert.equals(3, world:getEntityCount())
            world:update(1)
            world:remove(entity1, entity2, entity3)
            world:update(2)
            assert.equals(0, world:getEntityCount())
            world:remove(entity1, entity2, entity3)
            world:update(2)
            assert.equals(2, world:getSystemCount())
            assert.equals(0, world:getEntityCount())
        end)

        it("Add Systems Multiple Times", function()
            world:update(1)
            assert.has_error(function() world:add(moveSystem, oneTimeSystem) end, "System already belongs to a World.")
            world:update(2)
            assert.equals(2, world:getSystemCount())
            assert.equals(3, world:getEntityCount())
        end)

        it("Remove Systems Multiple Times", function()
            world:update(1)
            world:remove(moveSystem)
            world:update(2)
            assert.has_error(function() world:remove(moveSystem) end, "System does not belong to this World.")
            world:update(2)
            assert.equals(1, world:getSystemCount())
            assert.equals(3, world:getEntityCount())
        end)

        it("Reorder Systems", function()
            world:update(1)
            world:setSystemIndex(moveSystem, 2)
            world:update(1)
            assert.equals(2, moveSystem.index)
            assert.equals(1, oneTimeSystem.index)
        end)

        it("Sorts Entities in Sorting Systems", function()
            local sortsys = tiny.sortedProcessingSystem()
            sortsys.filter = tiny.filter("vel|xform")
            function sortsys:compare(e1, e2)
                return e1.vel.x < e2.vel.x
            end
            world:add(sortsys)
            world:refresh()
            assert.equals(sortsys.entities[1], entity2)
            assert.equals(sortsys.entities[2], entity3)
            assert.equals(sortsys.entities[3], entity1)
        end)

        it("Runs preWrap and postWrap for systems.", function()
            local str = ""
            local sys1 = tiny.system()
            local sys2 = tiny.system()
            function sys1:preWrap(dt)
                str = str .. "<"
            end
            function sys2:preWrap(dt)
                str = str .. "{"
            end
            function sys1:postWrap(dt)
                str = str .. ">"
            end
            function sys2:postWrap(dt)
                str = str .. "}"
            end
            world:add(sys1, sys2)
            world:update(1)
            assert.equals(str, "{<>}")
        end)

    end)

    it("Doesn't pollute the global namespace", function()
        assert.are.same(_G, GLOBALS)
    end)

end)
