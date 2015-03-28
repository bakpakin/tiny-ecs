local jojo = require "jojo"

local World = jojo.World
local Aspect = jojo.Aspect
local System = jojo.System

-- Aspect Test --

local e1 = {
    xform = {
        x = 0,
        y = 0
    },
    vel = {
        x = 1,
        y = 2,
    },
    name = "E1",
    size = 11,
    description = "It goes to 11.",
    spinalTap = true
}

local e2 = {
    xform = {
        x = 2,
        y = 2
    },
    vel = {
        x = -1,
        y = 0,
    },
    name = "E2",
    size = 10,
    description = "It does not go to 11."
}

local e3 = {
    xform = {
        x = 4,
        y = 5
    },
    vel = {
        x = 0,
        y = 3,
    },
    name = "E3",
    size = 8,
    description = "The smallest entity."
}

local atap = Aspect({"spinalTap"})
local avel = Aspect({"vel"})
local axform = Aspect({"xform"})
local aall = Aspect({})
local aboth = Aspect.compose(atap, axform)
local amove = Aspect.compose(axform, avel)

assert(atap:matches(e1), "Aspect atap should match e1.")
assert(not atap:matches(e2), "Aspect atap should not match e2.")
assert(axform:matches(e1), "Aspect axform should match e1.")
assert(axform:matches(e2), "Aspect axform should match e2.")
assert(aboth:matches(e1), "Aspect aboth should match e1.")
assert(not aboth:matches(e2), "Aspect aboth should not match e2.")

local moves = System(
    nil,
    function(e, dt)
        local xform = e.xform
        local vel = e.vel
        local x, y = xform.x, xform.y
        local xvel, yvel = vel.x, vel.y
        xform.x, xform.y = x + xvel * dt, y + yvel * dt
    end,
    amove
)

local world = World(moves, System(nil, nil, aall))

world:add(e1, e2, e3)
world:update(21)
assert(e1.xform.x == 21, "e1.xform.x should be 21, but is " .. e1.xform.x)
assert(e2.xform.x == -19, "e2.xform.x should be -19, but is " .. e2.xform.x)
assert(e3.xform.y == 68, "e3.xform.y should be 68, but is " .. e3.xform.y)

world:removeSystems(moves)
world:update(1234567890)
world:addSystems(moves)

world:remove(e3, e2)
world:update(20)
assert(e1.xform.x == 41, "e1.xform.x should be 41, but is " .. e1.xform.x)
assert(e2.xform.x == -19, "e2.xform.x should be -19, but is " .. e2.xform.x)
assert(e3.xform.y == 68, "e3.xform.y should be 68, but is " .. e3.xform.y)

world:removeSystems(moves)
world:update(12345)
world:addSystems(moves)

world:add(e3, e2)
world:update(19)
world:remove(e3, e2)
e1.vel = nil
world:change(e1)
world:update(11)

assert(e1.xform.x == 60, "e1.xform.x should be 60, but is " .. e1.xform.x)

-- TODO add some more tests, add some better tests.

print("Passed all tests.")
