--- @module tiny-ecs
-- @author Calvin Rose
local tiny = { _VERSION = "1.0.1" }

require "luarocks.loader"
local inspect = require "inspect"

-- Local versions of standard lua functions
local tinsert = table.insert
local tremove = table.remove
local pairs = pairs
local ipairs = ipairs
local setmetatable = setmetatable
local type = type

-- Local versions of the library functions
local tiny_manageEntities
local tiny_manageSystems
local tiny_addEntity
local tiny_addSystem
local tiny_add
local tiny_removeEntity
local tiny_removeSystem
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
    return function(_, e)
        local c
        for i = 1, len do
            c = components[i]
            if type(c) == 'function' then
                if not c(_, e) then
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
    return function(_, e)
        local c
        for i = 1, len do
            c = components[i]
            if type(c) == 'function' then
                if c(_, e) then
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
-- A System is a wrapper around function callbacks for manipulating Entities.
-- @section System

-- Use an empty table as a key for identifying Systems. Any table that contains
-- this key is considered a System rather than an Entity.
local systemTableKey = { "SYSTEM_TABLE_KEY" }

-- Check if tables are systems.
local function isSystem(table)
    return table[systemTableKey]
end

--- Creates a System. Systems are tables that contain at least one field; 
-- an update function that takes parameters like so: 
-- `function system:update(entities, dt)`. `entities` is an unordered table of 
-- Entities with Entities as KEYS, and `dt` is the delta time. There are also a 
-- few other optional callbacks:
-- `function system:filter(entity)` - returns a boolean,
-- `function system:onAdd(entity)` - returns nil,
-- `function system:onRemove(entity)` - returns nil.
-- For Filters, it is conveient to use `tiny.requireAll` or `tiny.requireOne`,
-- but one can write their own filters as well.
-- @param table A table to be used as a System, or `nil` to create a new System.
function tiny.system(table)
    if table == nil then
        table = {}
    end
    table[systemTableKey] = true
    return table
end

-- Update function for all Processing Systems.
local function processingSystemUpdate(system, entities, dt)
    local preProcess = system.preProcess
    local process = system.process
    local postProcess = system.postProcess
    local entity

    if preProcess then
        preProcess(system, entities, dt)
    end

    if process then
        local len = #entities
        for i = 1, len do
            entity = entities[i]
            process(system, entity, dt)
        end
    end

    if postProcess then
        postProcess(system, entities, dt)
    end
end

--- Creates a Processing System. A Processing System iterates through its 
-- Entities in no particluar order, and updates them individually. It has two 
-- important fields, `function system:process(entity, dt)`, and `function 
-- system:filter(entity)`. `entities` is Entities, 
-- and `dt` is the delta time. There are also a few other 
-- optional callbacks:
-- `function system:preProcess(entities, dt)` - returns nil,
-- `function system:postProcess(entities, dt)` - returns nil,
-- `function system:onAdd(entity)` - returns nil,
-- `function system:onRemove(entity)` - returns nil.
-- For Filters, it is conveient to use `tiny.requireAll` or `tiny.requireOne`,
-- but one can write their own filters as well.
-- @param table A table to be used as a System, or `nil` to create a new 
-- Processing System.
function tiny.processingSystem(table)
    if table == nil then
        table = {}
    end
    table[systemTableKey] = true
    table.update = processingSystemUpdate
    return table
end

--- World functions.
-- A World is a container that manages Entities and Systems. The tiny-ecs module
-- is set to be the `__index` of all World tables, so the often clearer syntax of
-- World:method can be used for any function in the library. For example,
-- `tiny.add(world, e1, e2, e3)` is the same as `world:add(e1, e2, e3).`
-- @section World

local worldMetaTable = { __index = tiny }

--- Creates a new World.
-- Can optionally add default Systems and Entities.
-- @param ... Systems and Entities to add to the World
-- @return A new World
function tiny.world(...)

    local ret = {

        -- List of Entities to add
        entitiesToAdd = {},

        -- List of Entities to remove
        entitiesToRemove = {},

        -- List of Entities to add
        systemsToAdd = {},

        -- List of Entities to remove
        systemsToRemove = {},

        -- Set of Entities 
        entities = {},

        -- Number of Entities in World.
        entityCount = 0,

        -- List of Systems
        systems = {},

        -- Table of Systems to whether or not they are active.
        activeSystems = {},

        -- Table of Systems to System Indices
        systemIndices = {},

        -- Table of Systems to Lists of matching Entities
        systemEntities = {},

        -- Table of Systems to Tables of Entities to their Indices
        systemEntityIndices = {}
    }

    tiny_add(ret, ...)
    tiny_manageSystems(ret)
    tiny_manageEntities(ret)

    return setmetatable(ret, worldMetaTable)

end

--- Adds an Entity to the world.
-- The new Entity will enter the world next time World:update is called.
-- Also call this on Entities that have changed Components such that it 
-- matches different systems.
-- @param world
-- @param entity
function tiny.addEntity(world, entity)
    local e2a = world.entitiesToAdd
    e2a[#e2a + 1] = entity
    if world.entities[entity] then
        tiny_removeEntity(world, entity)
    end
end
tiny_addEntity = tiny.addEntity

--- Adds a System to the world.
-- The new System will enter the world next time World:update is called.
-- @param world
-- @param system
function tiny.addSystem(world, system)
    local s2a = world.systemsToAdd
    s2a[#s2a + 1] = system
end
tiny_addSystem = tiny.addSystem

--- Shortcut for adding multiple Entities and Systems to the World.
-- New objects will enter the World the next time World:update(dt) is called.
-- Also call this method when an Entity has had its Components changed, such
-- that it matches different Filters.
-- @param world
-- @param ... Systems and Entities
function tiny.add(world, ...)
    local args = {...}
    for _, obj in ipairs(args) do
        if isSystem(obj) then
            tiny_addSystem(world, obj)
        else -- Assume obj is an Entity
            tiny_addEntity(world, obj)
        end
    end
end
tiny_add = tiny.add

--- Removes an Entity to the World.
-- The Entity will exit the World next time World:update is called.
-- Also call this on Entities that have changed Components such that it 
-- matches different systems.
-- @param world
-- @param entity
function tiny.removeEntity(world, entity)
    local e2r = world.entitiesToRemove
    e2r[#e2r + 1] = entity
end
tiny_removeEntity = tiny.removeEntity

--- Removes a System from the world.
-- The System will exit the World next time World:update is called.
-- @param world
-- @param system
function tiny.removeSystem(world, system)
    local s2r = world.systemsToRemove
    s2r[#s2r + 1] = system
end
tiny_removeSystem = tiny.removeSystem

--- Shortcut for removing multiple Entities and Systems from the World. 
-- Objects will exit the World the next time World:update(dt) is called.
-- @param world
-- @param ... Systems and Entities
function tiny.remove(world, ...)
    local args = {...}
    for _, obj in ipairs(args) do
        if isSystem(obj) then
            tiny_removeSystem(world, obj)
        else -- Assume obj is an Entity
           tiny_removeEntity(world, obj)
        end
    end
end
tiny_remove = tiny.remove

--- Updates a System.
-- @param world
-- @param system A System in the World to update
-- @param dt Delta time
function tiny.updateSystem(world, system, dt)
    local es = world.systemEntities[system]
    system:update(es, dt)
end

--- Adds and removes Systems that have been marked from the World.
-- The user of this library should seldom if ever call this.
-- @param world
function tiny.manageSystems(world)

        local s2a, s2r = world.systemsToAdd, world.systemsToRemove

        -- Early exit
        if #s2a == 0 and #s2r == 0 then
            return
        end

        local systemIndices = world.systemIndices
        local entities = world.entities
        local systems = world.systems
        local activeSystems = world.activeSystems
        local systemEntities = world.systemEntities
        local systemEntityIndices = world.systemEntityIndices

        local system, index, filter, entityList, entityIndices, entityIndex, onRemove, onAdd

        -- Remove Systems
        for i = 1, #s2r do
            system = s2r[i]
            index = systemIndices[system]
            if index then

                onRemove = system.onRemove
                if onRemove then
                    entityList = systemEntities[system]
                    for j = 1, #entityList do
                        onRemove(system, entityList[j])
                    end
                end

                for j = index + 1, #systems do
                    systemIndices[systems[j]] = j - 1
                end

                systemIndices[system] = nil
                activeSystems[system] = nil
                systemEntities[system] = nil
                systemEntityIndices[system] = nil

                tremove(systems, index)

            end
            s2r[i] = nil
        end

        -- Add Systems
        for i = 1, #s2a do
            system = s2a[i]
            if not systemIndices[system] then
                index = #systems + 1
                systemIndices[system] = index
                systems[index] = system
                activeSystems[system] = true

                entityList = {}
                systemEntities[system] = entityList
                entityIndices = {}
                systemEntityIndices[system] = entityIndices

                -- Try to add Entities
                onAdd = system.onAdd
                filter = system.filter
                if filter then
                    for entity in pairs(entities) do
                        if filter(system, entity) then
                            entityIndex = #entityList + 1
                            entityList[entityIndex] = entity
                            entityIndices[entity] = entityIndex
                            if onAdd then
                                onAdd(system, entity)
                            end
                        end
                    end
                end
            end
            s2a[i] = nil
        end

end
tiny_manageSystems = tiny.manageSystems

--- Adds and removes Entities that have been marked.
-- The user of this library should seldom if ever call this.
-- @param world
function tiny.manageEntities(world)

    local e2a, e2r = world.entitiesToAdd, world.entitiesToRemove

    -- Early exit
    if #e2a == 0 and #e2r == 0 then
        return
    end

    local entityStatus = world.entityStatus
    local systemEntities = world.systemEntities
    local entities = world.entities
    local systems = world.systems
    local entityCount = world.entityCount
    local systemEntityIndices = world.systemEntityIndices
    local entity, system, index, onRemove, onAdd, ses, seis, filter, tmpEntity

    -- Remove Entities
    for i = 1, #e2r do
        entity = e2r[i]
        if entities[entity] then
            entities[entity] = nil

            for j = 1, #systems do
                system = systems[j]
                ses = systemEntities[system]
                seis = systemEntityIndices[system]
                index = seis[entity]

                if index then
                    tmpEntity = ses[#ses]
                    ses[index] = tmpEntity
                    seis[tmpEntity] = index
                    seis[entity] = nil
                    ses[#ses] = nil
                    entityCount = entityCount - 1
                    onRemove = system.onRemove
                    if onRemove then
                        onRemove(system, entity)
                    end
                end

            end

        end
        e2r[i] = nil
    end


    -- Add Entities
    for i = 1, #e2a do
        entity = e2a[i]
        if not entities[entity] then
            entities[entity] = true

            for j = 1, #systems do
                system = systems[j]
                ses = systemEntities[system]
                seis = systemEntityIndices[system]
                filter = system.filter
                if filter and filter(system, entity) then
                    index = #ses + 1
                    ses[index] = entity
                    seis[entity] = index
                    entityCount = entityCount + 1
                    onAdd = system.onAdd
                    if onAdd then
                        onAdd(system, entity)
                    end
                end

            end

        end
        e2a[i] = nil
    end

    -- Update Entity count
    world.entityCount = entityCount

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

    local activeSystems = world.activeSystems
    local systems = world.systems
    local systemEntities = world.systemEntities
    local system

    --  Iterate through Systems IN ORDER
    for i = 1, #systems do
        system = systems[i]
        if activeSystems[system] then
            system:update(systemEntities[system], dt)
        end
    end
end

--- Removes all Entities from the World.
-- When World:update(dt) is next called,
-- all Entities will be removed.
-- @param world
function tiny.clearEntities(world)
    for e in pairs(world.entities) do
        tiny_removeEntity(world, e)
    end
end

--- Removes all Systems from the World.
-- When World:update(dt) is next called,
-- all Systems will be removed.
-- @param world
function tiny.clearSystems(world)
    local systems = world.systems
    for i = #systems, 1, -1 do
        tiny_removeSystem(world, systems[i])
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
    return #(world.systems)
end

--- Gets the index of a System in the world. Lower indexed Systems are processed
-- before higher indexed systems.
-- @param world
-- @param system
function tiny.getSystemIndex(world, system)
    return world.systemIndices[system]
end

--- Sets the index of a System in the world. Changes the order in
-- which they Systems processed, because lower indexed Systems are processed 
-- first.
-- @param world
-- @param system
-- @param index
function tiny.setSystemIndex(world, system, index)
    local oldIndex = world.systemIndices[system]
    local systems = world.systems
    tremove(systems, oldIndex)
    tinsert(systems, index, system)
    world.systemIndices[system] = index
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
