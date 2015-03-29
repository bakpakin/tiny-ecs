local tiny = {
    _VERSION = "0.2.0",
    _URL = "https://github.com/bakpakin/tiny-ecs",
    _DESCRIPTION = "tiny-ecs - Entity Component System for lua."
}

local tinsert = table.insert
local tremove = table.remove
local tconcat = table.concat
local pairs = pairs
local ipairs = ipairs
local setmetatable = setmetatable
local getmetatable = getmetatable

-- Simple class implementation with no inheritance or polymorphism.
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

-- --- System --- --
local System = class()

-- Initializes a System.
function System:init(preupdate, filter, update, add, remove)
    self.preupdate = preupdate
    self.update = update
    self.filter = filter
    self.add = add
    self.remove = remove
end

function System:__tostring()
    return "TinySystem<preupdate: " ..
    self.preupdate ..
    ", update: " ..
    self.update ..
    ", filter: " ..
    self.filter ..
    ">"
end

-- --- World --- --
local World = class()

-- Initializes a World.
function World:init(...)

    -- Table of Entities to status
    self.status = {}

    -- Set of Entities
    self.entities = {}

    -- Number of Entities in World.
    self.entityCount = 0

    -- Number of Systems in World.
    self.systemCount = 0

    -- List of Systems
    self.systems = {}

    -- Table of Systems to whether or not they are active.
    self.activeSystems = {}

    -- Table of Systems to System Indices
    self.systemIndices = {}

    -- Table of Systems to Sets of matching Entities
    self.systemEntities = {}

    -- List of Systems to add next update
    self.systemsToAdd = {}

    -- List of Systems to remove next update
    self.systemsToRemove = {}

    -- Add Systems and Entities
    self:add(...)
    self:manageSystems()
    self:manageEntities()
end

function World:__tostring()
    return "TinyWorld<systemCount: " ..
    self.systemCount ..
    ", entityCount: " ..
    self.entityCount ..
    ">"
end

-- World:add(...)

-- Adds Entities and Systems to the World. New objects will enter the World the
-- next time World:update(dt) is called. Also call this method when an Entity
-- has had its Components changed, such that it matches different Filters.
function World:add(...)
    local args = {...}
    local status = self.status
    local entities = self.entities
    local systemsToAdd = self.systemsToAdd
    for _, obj in ipairs(args) do
        if getmetatable(obj) == System then
            tinsert(systemsToAdd, obj)
        else -- Assume obj is an Entity
            entities[obj] = true
            status[obj] = "add"
        end
    end
end

-- World:free(...)

-- Removes Entities and Systems from the World. Objects will exit the World the
-- next time World:update(dt) is called.
function World:remove(...)
    local args = {...}
    local status = self.status
    local entities = self.entities
    local systemsToRemove = self.systemsToRemove
    for _, obj in ipairs(args) do
        if getmetatable(obj) == System then
            tinsert(systemsToRemove, obj)
        elseif entities[obj] then -- Assume obj is an Entity
            status[obj] = "remove"
        end
    end
end

-- World:updateSystem(system, dt)

-- Updates a System
function World:updateSystem(system, dt)
    local preupdate = system.preupdate
    local update = system.update

    if preupdate then
        preupdate(dt)
    end

    if update then
        local entities = self.entities
        local es = self.systemEntities[system]
        if es then
            for e in pairs(es) do
                update(e, dt)
            end
        end
    end
end

-- World:manageSystems()

-- Adds and removes Systems that have been marked from the world. The user of
-- this library should seldom if ever call this.
function World:manageSystems()

        local systemEntities = self.systemEntities
        local systemIndices = self.systemIndices
        local entities = self.entities
        local systems = self.systems
        local systemsToAdd = self.systemsToAdd
        local systemsToRemove = self.systemsToRemove
        local activeSystems = self.activeSystems

        -- Keep track of the number of Systems in the world
        local deltaSystemCount = 0

        -- Remove all Systems queued for removal
        for i = 1, #systemsToRemove do
            -- Pop system off the remove queue
            local sys = systemsToRemove[i]
            systemsToRemove[i] = nil

            local sysID = systemIndices[sys]
            if sysID then
                tremove(systems, sysID)

                local removeCallback = sys.remove
                if removeCallback then -- call 'remove' on all entities in the System
                    for e in pairs(systemEntities[sys]) do
                        removeCallback(e)
                    end
                end

                systemEntities[sys] = nil
                activeSystems[sys] = nil
                deltaSystemCount = deltaSystemCount - 1
            end
        end

        -- Add Systems queued for addition
        for i = 1, #systemsToAdd do
            -- Pop system off the add queue
            local sys = systemsToAdd[i]
            systemsToAdd[i] = nil

            -- Add system to world
            local es = {}
            systemEntities[sys] = es
            tinsert(systems, sys)
            systemIndices[sys] = #systems
            activeSystems[sys] = true

            local a = sys.filter
            if a then
                for e in pairs(entities) do
                    es[e] = a(e) and true or nil
                end
            end

            deltaSystemCount = deltaSystemCount + 1
        end

        -- Update the number of Systems in the World
        self.systemCount = self.systemCount + deltaSystemCount
end

-- World:manageEntities()

-- Adds and removes Entities that have been marked. The user of this library
-- should seldom if ever call this.
function World:manageEntities()

    local statuses = self.status
    local systemEntities = self.systemEntities
    local entities = self.entities
    local systems = self.systems

    -- Keep track of the number of Entities in the World
    local deltaEntityCount = 0

    -- Add, remove, or change Entities
    for e, s in pairs(statuses) do
        if s == "add" then
            deltaEntityCount = deltaEntityCount + 1
            for sys, es in pairs(systemEntities) do
                local filter = sys.filter
                if filter then
                    local matches = filter(e) and true or nil
                    local addCallback = sys.add
                    if addCallback and matches and not es[e] then
                        addCallback(e)
                    end
                    es[e] = matches
                end
            end
        elseif s == "remove" then
            deltaEntityCount = deltaEntityCount - 1
            entities[e] = nil
            for sys, es in pairs(systemEntities) do
                local removec = sys.remove
                if es[e] and removec then
                    removec(e)
                end
                es[e] = nil
            end
        end
        statuses[e] = nil
    end

    -- Update Entity count
    self.entityCount = self.entityCount + deltaEntityCount

end

-- World:update()

-- Updates the World, frees Entities that have been marked for freeing, adds
-- entities that have been marked for adding, etc.
function World:update(dt)

    self:manageSystems()
    self:manageEntities()

    --  Iterate through Systems IN ORDER
    for _, s in ipairs(self.systems) do
        if self.activeSystems[s] then
            self:updateSystem(s, dt)
        end
    end
end

-- World:clearEntities()

-- Removes all Entities from the World. When World:update(dt) is next called,
-- all Entities will be removed.
function World:clearEntities()
    local status = self.status
    for e in pairs(self.entities) do
        status[e] = "remove"
    end
end

-- World:clearSystems()

-- Removes all Systems from the World. When World:update(dt) is next called,
-- all Systems will be removed.
function World:clearSystems()
    local newSystemsToRemove = {}
    local systems = self.systems
    for i = 1, #systems do
        newSystemsToRemove[i] = systems[i]
    end
    self.systemsToRemove = newSystemsToRemove
end

-- World:setSystemActive(system, active)

-- Sets if a System is active in a world. If the system is active, it will
-- update automatically when World:update(dt) is called. Otherwise, the user
-- must call World:updateSystem(system, dt) to update the unactivated system.
function World:setSystemActive(system, active)
    self.activeSystem[system] = active and true or nil
end

-- --- Top Level module functions --- --

--- Creates a new tiny-ecs World.
function tiny.newWorld(...)
    return World(...)
end

--- Makes a Filter that filters Entities with specified Components.
-- An Entity must have all Components to match the filter.
function tiny.requireAll(...)
    local components = {...}
    local len = #components
    return function(e)
        local c
        for i = 1, len do
            c = components[i]
            if e[c] == nil then
                return false
            end
        end
        return true
    end
end

--- Makes a Filter that filters Entities with specified Components.
-- An Entity must have at least one specified Component to match the filter.
function tiny.requireOne(...)
    local components = {...}
    local len = #components
    return function(e)
        local c
        for i = 1, len do
            c = components[i]
            if e[c] ~= nil then
                return true
            end
        end
        return false
    end
end

--- Creates a System that doesn't update any Entities, but executes a callback
-- once per update.
function tiny.emptySystem(callback)
    return System(callback)
end

--- Creates a System that processes Entities every update. Also provides
-- optional callbacks for when Entities are added or removed from the System.
function tiny.processingSystem(filter, entityCallback, onAdd, onRemove)
    return System(nil, filter, entityCallback, onAdd, onRemove)
end

--- Creates a System.
function tiny.system(callback, filter, entityCallback, onAdd, onRemove)
    return System(callback, filter, entityCallback, onAdd, onRemove)
end

return tiny
