local tiny = require('tiny')

local world = tiny.world()
local systemA = tiny.system()
local systemB = tiny.system()
world:addSystem(systemA)
world:addSystem(systemB)
world:setSystemIndex(systemA, 1)


--- test requireXXX/rejectXXX functions

local filt1 = tiny.requireAll("prop1", "prop2")

assert(filt1(nil, { }) == false)
assert(filt1(nil, { prop1 = 1 }) == false)
assert(filt1(nil, { prop1 = 1, prop3 = 2}) == false)
assert(filt1(nil, { prop1 = 1, prop2 = 2 }) == true)
assert(filt1(nil, { prop2 = 1 }) == false)
assert(filt1(nil, { prop2 = 1, prop1 = 1, prop3 = 2 }) == true)


local filt2 = tiny.requireAny("prop1", "prop2")

assert(filt2(nil, { }) == false)
assert(filt2(nil, { prop1 = 1 }) == true)
assert(filt2(nil, { prop1 = 1, prop3 = 2}) == true)
assert(filt2(nil, { prop1 = 1, prop2 = 2 }) == true)
assert(filt2(nil, { prop2 = 1 }) == true)
assert(filt2(nil, { prop2 = 1, prop1 = 1, prop3 = 2 }) == true)
assert(filt2(nil, { prop4 = 1, prop5 = 1, prop6 = 2 }) == false)


local filt3 = tiny.rejectAll("prop1", "prop2")

assert(filt3(nil, { }) == true)
assert(filt3(nil, { prop1 = 1 }) == true)
assert(filt3(nil, { prop1 = 1, prop3 = 2}) == true)
assert(filt3(nil, { prop1 = 1, prop2 = 2 }) == false)
assert(filt3(nil, { prop2 = 1 }) == true)
assert(filt3(nil, { prop2 = 1, prop1 = 1, prop3 = 2 }) == false)


local filt4 = tiny.rejectAny("prop1", "prop2")

assert(filt4(nil, { }) == true)
assert(filt4(nil, { prop1 = 1 }) == false)
assert(filt4(nil, { prop1 = 1, prop3 = 2}) == false)
assert(filt4(nil, { prop1 = 1, prop2 = 2 }) == false)
assert(filt4(nil, { prop2 = 1 }) == false)
assert(filt4(nil, { prop2 = 1, prop1 = 1, prop3 = 2 }) == false)
assert(filt4(nil, { prop4 = 1, prop5 = 1, prop6 = 2 }) == true)



local filt5 = tiny.requireAll("prop3", filt2)

assert(filt5(nil, {}) == false)
assert(filt5(nil, {prop1 = 1}) == false)
assert(filt5(nil, {prop1 = 1, prop2 = 1, prop3 = 1}) == true)
assert(filt5(nil, {prop1 = 1, prop2 = 1, prop3 = 1, prop4 = 1}) == true)
assert(filt5(nil, {prop1 = 1, prop2 = 1, prop4 = 1}) == false)

local filt6 = tiny.requireAny("prop3", filt2)

assert(filt6(nil, {}) == false)
assert(filt6(nil, {prop1 = 1}) == true)
assert(filt6(nil, {prop1 = 1, prop2 = 1, prop3 = 1}) == true)
assert(filt6(nil, {prop1 = 1, prop2 = 1, prop3 = 1, prop4 = 1}) == true)
assert(filt6(nil, {prop1 = 1, prop2 = 1, prop4 = 1}) == true)
assert(filt6(nil, {prop5 = 1, prop4 = 1}) == false)





