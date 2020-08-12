local tiny = require('tiny')

local world = tiny.world()
local systemA = tiny.system()
local systemB = tiny.system()
world:addSystem(systemA)
world:addSystem(systemB)
world:setSystemIndex(systemA, 1)
