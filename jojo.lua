local jojo = {
    _VERSION = "0.0.2",
    _URL = "https://github.com/bakpakin/Jojo"
}

-- Simplified class implementation with no inheritance or polymorphism.
local setmetatable = setmetatable
local function class()
    local c = {}
    local mt = {}
    setmetatable(c, mt)
    c.__index = c
    function mt.__call(_, ...)
        local newobj = {}
        setmetatable(newobj, c)
        if c.init then
            c.init(newobj, ...)
        end
        return newobj
    end
    return c
end

local World = class()
local Aspect = class()
local System = class()

jojo.World = World
jojo.Aspect = Aspect
jojo.System = System

local tinsert = table.insert
local tremove = table.remove
local tconcat = table.concat
local pairs = pairs
local ipairs = ipairs
local print = print

----- Aspect -----

-- Aspect(required, excluded, oneRequired)

-- Creates an Aspect. Aspects are used to select which Entities are inlcuded
-- in each system. An Aspect has three fields, namely all required Components,
-- all excluded Components, and Components of which a system requires only one.
-- If an Entitiy has all required Components, none of the excluded Components,
-- and at least one of the oneRequired Components, it matches the Aspects.
-- This method expects at least one and up to three lists of strings, the names
-- of components. If no arguments are supplied, the Aspect will not match any
-- Entities. Will not mutate supplied arguments.
function Aspect:init(required, excluded, oneRequired)

    local r, e, o = {}, {}, {}
    self[1], self[2], self[3] = r, e, o

    -- Check for empty Aspect
    if not required and not oneRequired then
        self[4] = true
        return
    end
    self[4] = false

    local excludeSet, requiredSet = {}, {}

    -- Iterate through excluded Components
    for _, v in ipairs(excluded or {}) do
        tinsert(e, v)
        excludeSet[v] = true
    end

    -- Iterate through required Components
    for _, v in ipairs(required or {}) do
        if excludeSet[v] then -- If Comp. is required and excluded, empty Aspect
            self[1], self[2], self[3], self[4] = {}, {}, {}, true
            return
        else
            tinsert(r, v)
            requiredSet[v] = true
        end
    end

    -- Iterate through one-required Components
    for _, v in ipairs(oneRequired or {}) do
        if requiredSet[v] then -- If one-required Comp. is also required,
            -- don't need one required Components
            self[3] = {}
            return
        end
        if not excludeSet[v] then
            tinsert(o, v)
        end
    end
end

-- Aspect.compose(...)

-- Composes multiple Aspects into one Aspect. The resulting Aspect will match
-- any Entity that matches all sub Aspects.
function Aspect.compose(...)

    local newa = {{}, {}, {}}

    for _, a in ipairs{...} do

        if a[4] then -- Aspect must be empty Aspect
            return Aspect()
        end

        for i = 1, 3 do
            for _, c in ipairs(a[i]) do
                tinsert(newa[i], c)
            end
        end

    end

    return Aspect(newa[1], newa[2], newa[3])
end

-- Aspect:matches(entity)

-- Returns boolean indicating if an Entity matches the Aspect.
function Aspect:matches(entity)

    -- Aspect is the empty Aspect
    if self[4] then return false end

    local rs, es, os = self[1], self[2], self[3]

    -- Assert Entity has all required Components
    for i = 1, #rs do
        local r = rs[i]
        if entity[r] == nil then return false end
    end

    -- Assert Entity has no excluded Components
    for i = 1, #es do
        local e = es[i]
        if entity[e] ~= nil then return false end
    end

    -- if Aspect has at least one Component in the one-required
    -- field, assert that the Entity has at least one of these.
    if #os >= 1 then
        for i = 1, #os do
            local o = os[i]
            if entity[o] ~= nil then return true end
        end
        return false
    end

    return true
end

function Aspect:__tostring()
    if self[4] then
        return "JojoAspect<>"
    else
        return "JojoAspect<Required: {" ..
        tconcat(self[1], ", ") ..
        "}, Excluded: {" ..
        tconcat(self[2], ", ") ..
        "}, One Req.: {" ..
        tconcat(self[3], ", ") ..
        "}>"
    end
end

----- System -----

System.nextID = 0

-- System(preupdate, update, [aspect, addCallback, removeCallback])

-- Creates a new System with the given aspect and update callback. The update
-- callback should be a function of one parameter, an entity. If no aspect is
-- provided the empty Aspect, which matches no Entity, is used. Preupdate is a
-- function of no arguments that is called once per system update before the
-- entities are updated. The add and remove callbacks are optional functions
-- that are called when entities are added or removed from the system. They
-- should each take one argument - an Entity.
function System:init(preupdate, update, aspect, add, remove)
    self.preupdate = preupdate
    self.update = update
    self.aspect = aspect or Aspect()
    self.active = true
    self.add = add
    self.remove = remove
    local id = System.nextID
    self.id = id
    System.nextID = id + 1
end

function System:__tostring()
    return "JojoSystem<id: "..
    self.id ..
    "preupdate: " ..
    self.preupdate ..
    ", update: " ..
    self.update ..
    ", aspect: " ..
    self.aspect ..
    ", active: " ..
    self.active ..
    ">"
end

----- World -----

-- World(...)

-- Creates a new World with the given Systems in order. TODO - Add or remove
-- Systems after creation.
function World:init(...)

    local args = {...}

    -- Table of Entity IDs to status
    self.status = {}

    -- Table of Entity IDs to Entities
    self.entities = {}

    -- Number of Entities in World.
    self.entityCount = 0

    -- List of Systems
    self.systems = args

    -- Table of System IDs to System Indices
    local systemIndices = {}
    self.systemIndices = systemIndices

    -- Next available entity ID
    self.nextID = 0

    -- Table of System IDs to Sets of matching Entity IDs
    local systemEntities = {}
    self.systemEntities = systemEntities

    for i, sys in ipairs(args) do
        local id = sys.id
        systemEntities[id] = {}
        systemIndices[id] = i
    end

    -- List of Systems to add next update
    self.systemsToAdd = {}

    -- List of System ids to remove next update
    self.systemsToRemove = {}

end

function World:__tostring()
    return "JojoWorld<systemCount: " ..
    #self.systems ..
    ", entityCount: " ..
    #self.entityCount ..
    ">"
end

-- World:addSystems(...)

-- Appends Systems in order to the World. Systems will be added after the next
-- call to World:update(dt)
function World:addSystems(...)
    local args = {...}
    local systemsToAdd = self.systemsToAdd
    for i, sys in ipairs(args) do
        tinsert(systemsToAdd, sys)
    end
end

-- World:freeSystems(...)

-- Appends Systems in order to the World. Systems will be added after the next
-- call to World:update(dt)
function World:removeSystems(...)
    local args = {...}
    local systemsToRemove = self.systemsToRemove
    for i, sys in ipairs(args) do
        tinsert(systemsToRemove, sys)
    end
end

-- World:add(...)

-- Adds Entities to the World. Entities will enter the World the next time
-- World:update(dt) is called.
function World:add(...)
    local args = {...}
    local status = self.status
    local entities = self.entities
    for _, e in ipairs(args) do
        local id = self.nextID
        self.nextID = id + 1
        e.id = id
        entities[id] = e
        status[id] = "add"
    end
end

-- World:changed(...)

-- Call this function on any Entities that have changed such that they would
-- now match different systems. Entities will be updated in the world the next
-- time World:update(dt) is called.
function World:change(...)
    local args = {...}
    local status = self.status
    for _, e in ipairs(args) do
        status[e.id] = "add"
    end
end

-- World:free(...)

-- Removes Entities from the World. Entities will exit the World the next time
-- World:update(dt) is called.
function World:remove(...)
    local args = {...}
    local status = self.status
    for _, e in ipairs(args) do
        status[e.id] = "remove"
    end
end

-- World:updateSystem(system, dt)

function World:updateSystem(system, dt)
    local preupdate = system.preupdate
    local update = system.update
    local systemEntities = self.systemEntities

    if preupdate then
        preupdate(dt)
    end

    if update then
        local entities = self.entities
        local eids = systemEntities[system.id]
        for eid in pairs(eids) do
            update(entities[eid], dt)
        end
    end
end
-- World:update()

-- Updates the World, frees Entities that have been marked for freeing, adds
-- entities that have been marked for adding, etc.
function World:update(dt)

    local statuses = self.status
    local systemEntities = self.systemEntities
    local systemIndices = self.systemIndices
    local entities = self.entities
    local systems = self.systems
    local systemsToAdd = self.systemsToAdd
    local systemsToRemove = self.systemsToRemove

    -- Remove all Systems queued for removal
    for i = #systemsToRemove, 1, -1 do
        -- Pop system off the remove stack
        local sys = systemsToRemove[i]
        systemsToRemove[i] = nil


        local id = sys.id
        local sysIndex = systemIndices[id]
        tremove(systems, sysIndex)

        local removec = sys.remove
        if removec then -- call 'remove' on all entities in the System
            for eid in pairs(systemEntities[id]) do
                removec(entities[eid])
            end
        end

        systemEntities[id] = nil
    end

    -- Add Systems queued for addition
    for i = 1, #systemsToAdd do
        -- Pop system off the add queue
        local sys = systemsToAdd[i]
        systemsToAdd[i] = nil

        -- Add system to world
        local id = sys.id
        local eids = {}
        systemEntities[id] = eids
        tinsert(systems, sys)
        systemIndices[id] = #systems

        local a = sys.aspect
        for eid, e in pairs(entities) do
            eids[eid] = a:matches(e) and true or nil
        end
    end

    -- Kepp track of number of Entities in World
    local deltaEntityCount = 0

    -- Add, remove, or change Entities
    for eid, s in pairs(statuses) do
        local e = entities[eid]
        if s == "add" then
            deltaEntityCount = deltaEntityCount + 1
            for sysID, eids in pairs(systemEntities) do
                local sys = systems[systemIndices[sysID]]
                local matches = sys.aspect:matches(e) and true or nil
                local addc = sys.add
                if addc and matches and not eids[eid] then
                    addc(e)
                end
                eids[eid] = matches
            end
        elseif s == "remove" then
            deltaEntityCount = deltaEntityCount - 1
            entities[eid] = nil
            for sysID, eids in pairs(systemEntities) do
                local sys = systems[systemIndices[sysID]]
                local removec = sys.remove
                if removec then
                    removec(e)
                end
                eids[eid] = nil
            end
        end
        statuses[eid] = nil
    end

    -- Update Entity count
    self.entityCount = self.entityCount + deltaEntityCount

    --  Iterate through Systems IN ORDER
    for _, s in ipairs(self.systems) do
        if s.active then
            self:updateSystem(s, dt)
        end
    end
end

-- World:clearEntities()

-- Removes all Entities from the World. When World:update(dt) is next called,
-- all Entities will be removed.
function World:clearEntities()
    local status = self.status
    for eid in pairs(self.entity) do
        status[eid] = "remove"
    end
end

-- World:clearSystems()

-- Removes all Systems from the World. When World:update(dt) is next called,
-- all Systems will be removed.
function World:clearSystems()
    local newSystemsToRemove = {}
    local systems = self.systems
    for i = 1, #systems do
        newSystemsToRemove[i] = systems[i].id
    end
    self.systemsToRemove = newSystemsToRemove
end

return jojo
