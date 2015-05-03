local tiny = require "tiny"

-- Taken from answer at http://stackoverflow.com/questions/640642/how-do-you-copy-a-lua-table-by-value
local function deep_copy(o, seen)
  seen = seen or {}
  if o == nil then return nil end
  if seen[o] then return seen[o] end

  local no
  if type(o) == 'table' then
    no = {}
    seen[o] = no

    for k, v in next, o, nil do
      no[deep_copy(k, seen)] = deep_copy(v, seen)
    end
    setmetatable(no, deep_copy(getmetatable(o), seen))
  else -- number, string, boolean, etc
    no = o
  end
  return no
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
            local fall = tiny.requireOne("spinalTap", "onlyTen", "littleMan")

            assert.truthy(fall(nil, entity1))
            assert.truthy(ftap(nil, entity1))
            assert.falsy(ftap(nil, entity2))
            assert.truthy(fxform(nil, entity1))
            assert.truthy(fxform(nil, entity2))

            assert.truthy(fall(nil, entity1))
            assert.truthy(fall(nil, entity2))
            assert.truthy(fall(nil, entity3))

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
        function oneTimeSystem:update(entities, dt)
            timePassed = timePassed + dt
        end

        before_each(function()
            entity1 = deep_copy(entityTemplate1)
            entity2 = deep_copy(entityTemplate2)
            entity3 = deep_copy(entityTemplate3)
            world = tiny.world(moveSystem, oneTimeSystem, entity1, entity2, entity3)
            timePassed = 0
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

        it("Disable and Enable Systems", function()
            world:deactivate(moveSystem)
            world:deactivate(oneTimeSystem)
            world:update(1)
            assert.equals(world:getSystemCount(), 2)
            assert.equals(timePassed, 0)
            assert.equals(entity1.xform.x, entityTemplate1.xform.x)
            world:activate(moveSystem)
            world:activate(oneTimeSystem)
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
            world:update(1)
            world:remove(entity1, entity2, entity3)
            world:update(2)
            world:remove(entity1, entity2, entity3)
            world:update(2)
            assert.equals(2, world:getSystemCount())
            assert.equals(0, world:getEntityCount())
        end)

        it("Add Systems Multiple Times", function()
            world:update(1)
            world:add(moveSystem, oneTimeSystem)
            world:update(2)
            assert.equals(2, world:getSystemCount())
            assert.equals(3, world:getEntityCount())
        end)

        it("Remove Systems Multiple Times", function()
            world:update(1)
            world:remove(moveSystem)
            world:update(2)
            world:remove(moveSystem)
            world:update(2)
            assert.equals(1, world:getSystemCount())
            assert.equals(3, world:getEntityCount())
        end)

        it("Reorder Systems", function()
            world:update(1)
            world:setSystemIndex(moveSystem, 2)
            world:update(1)
            assert.equals(2, world:getSystemIndex(moveSystem))
            assert.equals(1, world:getSystemIndex(oneTimeSystem))
        end)

    end)

end)
