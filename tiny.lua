--- @module tiny-ecs
-- @author Calvin Rose
local tiny = {}

--- Tiny-ecs Version, a period-separated three number string like "1.2.3"
tiny._VERSION = "0.3.0"

local tinsert = table.insert
local tremove = table.remove
local tconcat = table.concat
local pairs = pairs
local ipairs = ipairs
local setmetatable = setmetatable
local getmetatable = getmetatable
local type = type

-- Local versions of the library functions
local tiny_system
local tiny_manageEntities
local tiny_manageSystems
local tiny_updateSystem
local tiny_add
local tiny_remove

--- Filter functions.
-- A Filter is a function that selects which Entities apply to a System.
-- @section Filter

--- Makes a Filter that filters Entities with specified Components.
-- An Entity must have all Components to match the filter.
-- @param ... List of Components
function tiny.requireAll(...)
    local components = {...}
    local len = #components
    return function(e)
        local c
        for i = 1, len do
            c = components[i]
            if type(c) == 'function' then
                if not c(e) then
                    return false
                end
            elseif e[c] == nil then
                return false
            end
        end
        return true
    end
end

--- Makes a Filter that filters Entities with specified Components.
-- An Entity must have at least one specified Component to match the filter.
-- @param ... List of Components
function tiny.requireOne(...)
    local components = {...}
    local len = #components
    return function(e)
        local c
        for i = 1, len do
            c = components[i]
            if type(c) == 'function' then
                if c(e) then
                    return true
                end
            elseif e[c] ~= nil then
                return true
            end
        end
        return false
    end
end

--- System functions.
-- A System a wrapper around function callbacks for manipulating Entities.
-- @section System

local systemMetaTable = {}

--- Creates a System.
-- @param callback Function of one argument, delta time, that is called once
-- per world update
-- @param filter Function of one argument, an Entity, that returns a boolean
-- @param entityCallback Function of two arguments, an Entity and delta time
-- @param onAdd Optional callback for when Enities are added to the System that
-- takes one argument, an Entity
-- @param onRemove Similar to onAdd, but is instead called when an Entity is
-- removed from the System
-- @param postCallback similar to callback, but is called after Entites are
-- processed
function tiny.system(callback, filter, entityCallback, onAdd, onRemove, postCallback)
    local ret = {
        callback = callback,
        filter = filter,
        entityCallback = entityCallback,
        onAdd = onAdd,
        onRemove = onRemove,
        postCallback = postCallback
    }
    setmetatable(ret, systemMetaTable)
    return ret
end
tiny_system = tiny.system

--- Creates a System that processes Entities every update. Also provides
-- optional callbacks for when Entities are added or removed from the System.
-- @param filter Function of one argument, an Entity, that returns a boolean
-- @param entityCallback Function of two arguments, an Entity and delta time
-- @param onAdd Optional callback for when Entities are added to the System that
-- takes one argument, an Entity
-- @param onRemove Similar to onAdd, but is instead called when an Entity is
-- removed from the System
-- @param postCallback similar to callback, but is called after Entites are
-- processed
function tiny.processingSystem(filter, entityCallback, onAdd, onRemove, postCallback)
    return tiny_system(nil, filter, entityCallback, onAdd, onRemove, postCallback)
end

local worldMetaTable = { __index = tiny }

--- World functions.
-- A World is a container that manages Entities and Systems. The tiny-ecs module
-- is set to be the `__index` of all World tables, so the often clearer syntax of
-- World:method can be used for any function in the library. For example,
-- `tiny.add(world, e1, e2, e3)` is the same as `world:add(e1, e2, e3).`
-- @section World

--- Creates a new World.
-- Can optionally add default Systems and Entities.
-- @param ... Systems and Entities to add to the World
-- @return A new World
function tiny.world(...)

    local ret = {

        -- Table of Entities to status
        -- Statuses: remove, add
        entityStatus = {},

        -- Table of Systems to status
        -- Statuses: remove, add
        systemStatus = {},

        -- Set of Entities -- active are true, inactive are false
        entities = {},

        -- Number of Entities in World.
        entityCount = 0,

        -- Number of Systems in World.
        systemCount = 0,

        -- List of Systems
        systems = {},

        -- Table of Systems to whether or not they are active.
        activeSystems = {},

        -- Table of Systems to System Indices
        systemIndices = {},

        -- Table of Systems to Sets of matching Entities
        systemEntities = {}
    }

    tiny.add(ret, ...)
    tiny.manageSystems(ret)
    tiny.manageEntities(ret)

    setmetatable(ret, worldMetaTable)
    return ret

end

--- Adds Entities and Systems to the World.
-- New objects will enter the World the next time World:update(dt) is called.
-- Also call this method when an Entity has had its Components changed, such
-- that it matches different Filters.
-- @param world
-- @param ... Systems and Entities
function tiny.add(world, ...)
    local args = {...}
    local entityStatus = world.entityStatus
    local systemStatus = world.systemStatus
    local systemIndices = world.systemIndices
    local systemCount = world.systemCount
    for _, obj in ipairs(args) do
        if getmetatable(obj) == systemMetaTable then
            systemStatus[obj] = "add"
            systemCount = systemCount + 1
            systemIndices[obj] = systemCount
        else -- Assume obj is an Entity
            entityStatus[obj] = "add"
        end
    end
end
tiny_add = tiny.add

--- Removes Entities and Systems from the World. Objects will exit the World the
-- next time World:update(dt) is called.
-- @param world
-- @param ... Systems and Entities
function tiny.remove(world, ...)
    local args = {...}
    local entityStatus = world.entityStatus
    local systemStatus = world.systemStatus
    for _, obj in ipairs(args) do
        if getmetatable(obj) == systemMetaTable then
            systemStatus[obj] = "remove"
        else -- Assume obj is an Entity
            entityStatus[obj] = "remove"
        end
    end
end
tiny_remove = tiny.remove

--- Updates a System.
-- @param world
-- @param system A System in the World to update
-- @param dt Delta time
function tiny.updateSystem(world, system, dt)
    local callback = system.callback
    local entityCallback = system.entityCallback
    local postCallback = system.postCallback

    if callback then
        callback(dt)
    end

    if entityCallback then
        local entities = world.entities
        local es = world.systemEntities[system]
        if es then
            for e in pairs(es) do
                entityCallback(e, dt)
            end
        end
    end

    if postCallback then
        postCallback(dt)
    end

end
tiny_updateSystem = tiny.updateSystem

--- Adds and removes Systems that have been marked from the World.
-- The user of this library should seldom if ever call this.
-- @param world
function tiny.manageSystems(world)

        local systemEntities = world.systemEntities
        local systemIndices = world.systemIndices
        local entities = world.entities
        local systems = world.systems
        local systemStatus = world.systemStatus
        local activeSystems = world.activeSystems

        -- Keep track of the number of Systems in the world
        local deltaSystemCount = 0

        for system, status in pairs(systemStatus) do

            if status == "add" then
                local es = {}
                systemEntities[system] = es
                systems[systemIndices[system]] = system
                activeSystems[system] = true
                local filter = system.filter
                if filter then
                    for e in pairs(entities) do
                        es[e] = filter(e) and true or nil
                    end
                end
                deltaSystemCount = deltaSystemCount + 1
            elseif status == "remove" then
                local index = systemIndices[system]
                tremove(systems, index)
                local onRemove = system.onRemove
                if onRemove then
                    for e in pairs(systemEntities[sys]) do
                        onRemove(e)
                    end
                end
                systemEntities[system] = nil
                activeSystems[system] = nil
                deltaSystemCount = deltaSystemCount - 1
            end

            systemStatus[system] = nil
        end

        -- Update the number of Systems in the World
        world.systemCount = world.systemCount + deltaSystemCount
end
tiny_manageSystems = tiny.manageSystems

--- Adds and removes Entities that have been marked.
-- The user of this library should seldom if ever call this.
-- @param world
function tiny.manageEntities(world)

    local entityStatus = world.entityStatus
    local systemEntities = world.systemEntities
    local entities = world.entities
    local systems = world.systems

    -- Keep track of the number of Entities in the World
    local deltaEntityCount = 0

    -- Add, remove, or change Entities
    for e, s in pairs(entityStatus) do
        if s == "add" then
            if not entities[e] then
                deltaEntityCount = deltaEntityCount + 1
            end
            entities[e] = true
            for sys, es in pairs(systemEntities) do
                local filter = sys.filter
                if filter then
                    local matches = filter(e) and true or nil
                    local onRemove = sys.onRemove
                    if not matches and es[e] and onRemove then
                        onRemove(e)
                    end
                    local onAdd = sys.onAdd
                    if onAdd and matches and not es[e] then
                        onAdd(e)
                    end
                    es[e] = matches
                end
            end
        elseif s == "remove" then
            if entities[e] then
                deltaEntityCount = deltaEntityCount - 1
            end
            entities[e] = nil
            for sys, es in pairs(systemEntities) do
                local onRemove = sys.onRemove
                if es[e] and onRemove then
                    onRemove(e)
                end
                es[e] = nil
            end
        end
        entityStatus[e] = nil
    end

    -- Update Entity count
    world.entityCount = world.entityCount + deltaEntityCount

end
tiny_manageEntities = tiny.manageEntities

--- Updates the World.
-- Frees Entities that have been marked for freeing, adds
-- entities that have been marked for adding, etc.
-- @param world
-- @param dt Delta time
function tiny.update(world, dt)

    tiny_manageSystems(world)
    tiny_manageEntities(world)

    --  Iterate through Systems IN ORDER
    for _, s in ipairs(world.systems) do
        if world.activeSystems[s] then
            tiny_updateSystem(world, s, dt)
        end
    end
end

--- Removes all Entities from the World.
-- When World:update(dt) is next called,
-- all Entities will be removed.
-- @param world
function tiny.clearEntities(world)
    local entityStatus = world.entityStatus
    for e in pairs(world.entities) do
        entityStatus[e] = "remove"
    end
end

--- Removes all Systems from the World.
-- When World:update(dt) is next called,
-- all Systems will be removed.
-- @param world
function tiny.clearSystems(world)
    local systemStatus = world.systemStatus
    for _, s in ipairs(world.systems) do
        systemStatus[s] = "remove"
    end
end

--- Gets count of Entities in World.
-- @param world
function tiny.getEntityCount(world)
    return world.entityCount
end

--- Gets count of Systems in World.
-- @param world
function tiny.getSystemCount(world)
    return world.systemCount
end

--- Activates Systems in the World.
-- Activated Systems will be update whenever tiny.update(world, dt) is called.
-- @param world
-- @param ... Systems to activate. The Systems must already be added to the
-- World.
function tiny.activate(world, ...)
    local args = {...}
    for _, obj in ipairs(args) do
        world.activeSystems[obj] = true
    end
end

--- Deactivates Systems in the World.
-- Deactivated Systems must be update manually, and will not update when the
-- rest of World updates. They will, however, process new Entities added while
-- the System is deactivated.
-- @param world
-- @param ... Systems to deactivate. The Systems must already be added to the
-- World.
function tiny.deactivate(world, ...)
    local args = {...}
    for _, obj in ipairs(args) do
        world.activeSystems[obj] = nil
    end
end

return tiny
