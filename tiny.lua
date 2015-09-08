--[[
Copyright (c) 2015 Calvin Rose

Permission is hereby granted, free of charge, to any person obtaining a copy of
this software and associated documentation files (the "Software"), to deal in
the Software without restriction, including without limitation the rights to
use, copy, modify, merge, publish, distribute, sublicense, and/or sell copies of
the Software, and to permit persons to whom the Software is furnished to do so,
subject to the following conditions:

The above copyright notice and this permission notice shall be included in all
copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY, FITNESS
FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR
COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER
IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN
CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.
]]

--- @module tiny-ecs
-- @author Calvin Rose
-- @license MIT
-- @copyright 2015
local tiny = { _VERSION = "1.2-1" }

-- Local versions of standard lua functions
local tinsert = table.insert
local tremove = table.remove
local tsort = table.sort
local pairs = pairs
local setmetatable = setmetatable
local type = type
local select = select

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
-- Filters take two parameters, the System and the Entity, and return a boolean
-- value indicating if the Entity should be processed by the System.
--
-- Filters must be added to Systems by setting the `filter` field of the System.
-- Filter's returned by tiny-ecs's Filter functions are immutable and can be
-- used by multiple Systems.
--
--    local f1 = tiny.requireAll("position", "velocity", "size")
--    local f2 = tiny.requireAny("position", "velocity", "size")
--
--    local e1 = {
--        position = {2, 3},
--        velocity = {3, 3},
--        size = {4, 4}
--    }
--
--    local entity2 = {
--        position = {4, 5},
--        size = {4, 4}
--    }
--
--    local e3 = {
--        position = {2, 3},
--        velocity = {3, 3}
--    }
--
--    print(f1(nil, e1), f1(nil, e2), f1(nil, e3)) -- prints true, false, false
--    print(f2(nil, e1), f2(nil, e2), f2(nil, e3)) -- prints true, true, true
--
-- Filters can also be passed as arguments to other Filter constructors. This is
-- a powerful way to create complex, custom Filters that select a very specific
-- set of Entities.
--
--    -- Selects Entities with an "image" Component, but not Entities with a
--    -- "Player" or "Enemy" Component.
--    filter = tiny.requireAll("image", tiny.rejectAny("Player", "Enemy"))
--
-- @section Filter

--- Makes a Filter that selects Entities with all specified Components and
-- Filters.
function tiny.requireAll(...)
    local components = {...}
    local len = #components
    return function(system, e)
        local c
        for i = 1, len do
            c = components[i]
            if type(c) == 'function' then
                if not c(system, e) then
                    return false
                end
            elseif e[c] == nil then
                return false
            end
        end
        return true
    end
end

--- Makes a Filter that selects Entities with at least one of the specified
-- Components and Filters.
function tiny.requireAny(...)
    local components = {...}
    local len = #components
    return function(system, e)
        local c
        for i = 1, len do
            c = components[i]
            if type(c) == 'function' then
                if c(system, e) then
                    return true
                end
            elseif e[c] ~= nil then
                return true
            end
        end
        return false
    end
end

--- Makes a Filter that rejects Entities with all specified Components and
-- Filters, and selects all other Entities.
function tiny.rejectAll(...)
    local components = {...}
    local len = #components
    return function(system, e)
        local c
        for i = 1, len do
            c = components[i]
            if type(c) == 'function' then
                if not c(system, e) then
                    return true
                end
            elseif e[c] == nil then
                return true
            end
        end
        return false
    end
end

--- Makes a Filter that rejects Entities with at least one of the specified
-- Components and Filters, and selects all other Entities.
function tiny.rejectAny(...)
    local components = {...}
    local len = #components
    return function(system, e)
        local c
        for i = 1, len do
            c = components[i]
            if type(c) == 'function' then
                if c(system, e) then
                    return false
                end
            elseif e[c] ~= nil then
                return false
            end
        end
        return true
    end
end

--- System functions.
-- A System is a wrapper around function callbacks for manipulating Entities.
-- Systems are implemented as tables that contain at least one method;
-- an update function that takes parameters like so:
--
--   * `function system:update(dt)`.
--
-- There are also a few other optional callbacks:
--
--   * `function system:filter(entity)` - Returns true if this System should
-- include this Entity, otherwise should return false. If this isn't specified,
-- no Entities are included in the System.
--   * `function system:onAdd(entity)` - Called when an Entity is added to the
-- System.
--   * `function system:onRemove(entity)` - Called when an Entity is removed
-- from the System.
--   * `function system:onModify(dt)` - Called when the System is modified by
-- adding or removing Entities from the System.
--   * `function system:onAddToWorld(world)` - Called when the System is added
-- to the World, before any entities are added to the system.
--   * `function system:onRemoveFromWorld(world)` - Called when the System is
-- removed from the world, after all Entities are removed from the System.
--
-- For Filters, it is convenient to use `tiny.requireAll` or `tiny.requireAny`,
-- but one can write their own filters as well. Set the Filter of a System like
-- so:
--    system.filter = tiny.requireAll("a", "b", "c")
-- or
--    function system:filter(entity)
--        return entity.myRequiredComponentName ~= nil
--    end
--
-- All Systems also have a few important fields that are initialized when the
-- system is added to the World. A few are important, and few should be less
-- commonly used.
--
--   * The `world` field points to the World that the System belongs to. Useful
-- for adding and removing Entities from the world dynamically via the System.
--   * The `active` flag is whether or not the System is updated automatically.
-- Inactive Systems should be updated manually or not at all via
-- `system:update(dt)`. Defaults to true.
--   * The `entities` field is an ordered list of Entities in the System. This
-- list can be used to quickly iterate through all Entities in a System.
--   * The `interval` field is an optional field that makes Systems update at
-- certain intervals using buffered time, regardless of World update frequency.
-- For example, to make a System update once a second, set the System's interval
-- to 1.
--   * The `index` field is the System's index in the World. Lower indexed
-- Systems are processed before higher indices. The `index` is a read only
-- field; to set the `index`, use `tiny.setSystemIndex(world, system)`.
--   * The `indices` field is a table of Entity keys to their indices in the
-- `entities` list. Most Systems can ignore this.
--   * The `modified` flag is an indicator if the System has been modified in
-- the last update. If so, the `onModify` callback will be called on the System
-- in the next update, if it has one. This is usually managed by tiny-ecs, so
-- users should mostly ignore this, too.
--
-- @section System

-- Use an empty table as a key for identifying Systems. Any table that contains
-- this key is considered a System rather than an Entity.
local systemTableKey = { "SYSTEM_TABLE_KEY" }

-- Checks if a table is a System.
local function isSystem(table)
    return table[systemTableKey]
end

-- Update function for all Processing Systems.
local function processingSystemUpdate(system, dt)
    local preProcess = system.preProcess
    local process = system.process
    local postProcess = system.postProcess

    if preProcess then
        preProcess(system, dt)
    end

    if process then
        local entities = system.entities
        local len = #entities
        for i = 1, len do
            local entity = entities[i]
            process(system, entity, dt)
        end
    end

    if postProcess then
        postProcess(system, dt)
    end
end

-- Sorts Systems by a function system.sort(entity1, entity2) on modify.
local function sortedSystemOnModify(system, dt)
    local entities = system.entities
    local indices = system.indices
    local sortDelegate = system.sortDelegate
    if not sortDelegate then
        local compare = system.compare
        sortDelegate = function(e1, e2)
            return compare(system, e1, e2)
        end
        system.sortDelegate = sortDelegate
    end
    tsort(entities, sortDelegate)
    for i = 1, #entities do
        local entity = entities[i]
        indices[entity] = i
    end
end

--- Creates a new System or System class from the supplied table. If `table` is
-- nil, creates a new table.
function tiny.system(table)
    table = table or {}
    table[systemTableKey] = true
    return table
end

--- Creates a new Processing System or Processing System class. Processing
-- Systems process each entity individual, and are usually what is needed.
-- Processing Systems have three extra callbacks besides those inheritted from
-- vanilla Systems.
--
--     function system:preProcess(dt) -- Called before iteration.
--     function system:process(entity, dt) -- Process each entity.
--     function system:postProcess(dt) -- Called after iteration.
--
-- Processing Systems have their own `update` method, so don't implement a
-- a custom `update` callback for Processing Systems.
-- @see system
function tiny.processingSystem(table)
    table = table or {}
    table[systemTableKey] = true
    table.update = processingSystemUpdate
    return table
end

--- Creates a new Sorted System or Sorted System class. Sorted Systems sort
-- their Entities according to a user-defined method, `system:compare(e1, e2)`,
-- which should return true if `e1` should come before `e2` and false otherwise.
-- Sorted Systems also override the default System's `onModify` callback, so be
-- careful if defining a custom callback. However, for processing the sorted
-- entities, consider `tiny.sortedProcessingSystem(table)`.
-- @see system
function tiny.sortedSystem(table)
    table = table or {}
    table[systemTableKey] = true
    table.onModify = sortedSystemOnModify
    return table
end

--- Creates a new Sorted Processing System or Sorted Processing System class.
-- Sorted Processing Systems have both the aspects of Processing Systems and
-- Sorted Systems.
-- @see system
-- @see processingSystem
-- @see sortedSystem
function tiny.sortedProcessingSystem(table)
    table = table or {}
    table[systemTableKey] = true
    table.update = processingSystemUpdate
    table.onModify = sortedSystemOnModify
    return table
end

--- World functions.
-- A World is a container that manages Entities and Systems. Typically, a
-- program uses one World at a time.
--
-- For all World functions except `tiny.world(...)`, object-oriented syntax can
-- be used instead of the documented syntax. For example,
-- `tiny.add(world, e1, e2, e3)` is the same as `world:add(e1, e2, e3)`.
-- @section World

-- Forward declaration
local worldMetaTable

--- Creates a new World.
-- Can optionally add default Systems and Entities. Returns the new World along
-- with default Entities and Systems.
function tiny.world(...)
    local ret = setmetatable({

        -- List of Entities to add
        entitiesToAdd = {},

        -- List of Entities to remove
        entitiesToRemove = {},

        -- List of Entities to change
        entitiesToChange = {},

        -- List of Entities to add
        systemsToAdd = {},

        -- List of Entities to remove
        systemsToRemove = {},

        -- Set of Entities
        entities = {},

        -- Number of Entities in World
        entityCount = 0,

        -- List of Systems
        systems = {}
    }, worldMetaTable)

    tiny_add(ret, ...)
    tiny_manageSystems(ret)
    tiny_manageEntities(ret)

    return ret, ...
end

--- Adds an Entity to the world.
-- Also call this on Entities that have changed Components such that they
-- match different Filters. Returns the Entity.
function tiny.addEntity(world, entity)
    if world.entities[entity] then
        local e2c = world.entitiesToChange
        e2c[#e2c + 1] = entity
    else
        local e2a = world.entitiesToAdd
        e2a[#e2a + 1] = entity
    end
    return entity
end
tiny_addEntity = tiny.addEntity

--- Adds a System to the world. Returns the System.
function tiny.addSystem(world, system)
    assert(system.world == nil, "System already belongs to a World.")
    local s2a = world.systemsToAdd
    s2a[#s2a + 1] = system
    system.world = world
    return system
end
tiny_addSystem = tiny.addSystem

--- Shortcut for adding multiple Entities and Systems to the World. Returns all
-- added Entities and Systems.
function tiny.add(world, ...)
    for i = 1, select("#", ...) do
        local obj = select(i, ...)
        if obj then
            if isSystem(obj) then
                tiny_addSystem(world, obj)
            else -- Assume obj is an Entity
                tiny_addEntity(world, obj)
            end
        end
    end
    return ...
end
tiny_add = tiny.add

--- Removes an Entity to the World. Returns the Entity.
function tiny.removeEntity(world, entity)
    local e2r = world.entitiesToRemove
    e2r[#e2r + 1] = entity
    return entity
end
tiny_removeEntity = tiny.removeEntity

--- Removes a System from the world. Returns the System.
function tiny.removeSystem(world, system)
    assert(system.world == world, "System does not belong to this World.")
    local s2r = world.systemsToRemove
    s2r[#s2r + 1] = system
    return system
end
tiny_removeSystem = tiny.removeSystem

--- Shortcut for removing multiple Entities and Systems from the World. Returns
-- all removed Systems and Entities
function tiny.remove(world, ...)
    for i = 1, select("#", ...) do
        local obj = select(i, ...)
        if obj then
            if isSystem(obj) then
                tiny_removeSystem(world, obj)
            else -- Assume obj is an Entity
                tiny_removeEntity(world, obj)
            end
        end
    end
    return ...
end
tiny_remove = tiny.remove

-- Adds and removes Systems that have been marked from the World.
function tiny_manageSystems(world)
    local s2a, s2r = world.systemsToAdd, world.systemsToRemove

    -- Early exit
    if #s2a == 0 and #s2r == 0 then
        return
    end

    world.systemsToAdd = {}
    world.systemsToRemove = {}

    local entities = world.entities
    local systems = world.systems

    -- Remove Systems
    for i = 1, #s2r do
        local system = s2r[i]
        local index = system.index
        local onRemove = system.onRemove
        if onRemove then
            local entityList = system.entities
            for j = 1, #entityList do
                onRemove(system, entityList[j])
            end
        end
        tremove(systems, index)
        for j = index, #systems do
            systems[j].index = j
        end
        local onRemoveFromWorld = system.onRemoveFromWorld
        if onRemoveFromWorld then
            onRemoveFromWorld(system, world)
        end
        s2r[i] = nil

        -- Clean up System
        system.world = nil
        system.entities = nil
        system.indices = nil
        system.index = nil
    end

    -- Add Systems
    for i = 1, #s2a do
        local system = s2a[i]
        if systems[system.index] ~= system then
            local entityList = {}
            local entityIndices = {}
            system.entities = entityList
            system.indices = entityIndices
            if system.active == nil then
                system.active = true
            end
            system.modified = true
            system.world = world
            local index = #systems + 1
            system.index = index
            systems[index] = system
            local onAddToWorld = system.onAddToWorld
            if onAddToWorld then
                onAddToWorld(system, world)
            end

            -- Try to add Entities
            local onAdd = system.onAdd
            local filter = system.filter
            if filter then
                for entity in pairs(entities) do
                    if filter(system, entity) then
                        local entityIndex = #entityList + 1
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

-- Adds, removes, and changes Entities that have been marked.
function tiny_manageEntities(world)

    local e2a = world.entitiesToAdd
    local e2r = world.entitiesToRemove
    local e2c = world.entitiesToChange

    -- Early exit
    if #e2a == 0 and #e2r == 0 and #e2c == 0 then
        return
    end

    world.entitiesToChange = {}
    world.entitiesToAdd = {}
    world.entitiesToRemove = {}

    local entities = world.entities
    local systems = world.systems
    local entityCount = world.entityCount

    -- Change Entities
    for i = 1, #e2c do
        local entity = e2c[i]
        if entities[entity] then
            for j = 1, #systems do
                local system = systems[j]
                local ses = system.entities
                local seis = system.indices
                local index = seis[entity]
                local filter = system.filter
                if filter and filter(system, entity) then
                    if not index then
                        system.modified = true
                        index = #ses + 1
                        ses[index] = entity
                        seis[entity] = index
                        local onAdd = system.onAdd
                        if onAdd then
                            onAdd(system, entity)
                        end
                    end
                elseif index then
                    system.modified = true
                    local tmpEntity = ses[#ses]
                    ses[index] = tmpEntity
                    seis[tmpEntity] = index
                    seis[entity] = nil
                    ses[#ses] = nil
                    local onRemove = system.onRemove
                    if onRemove then
                        onRemove(system, entity)
                    end
                end
            end
        end
        e2c[i] = nil
    end

    -- Remove Entities
    for i = 1, #e2r do
        local entity = e2r[i]
        if entities[entity] then
            entities[entity] = nil
            entityCount = entityCount - 1
            for j = 1, #systems do
                local system = systems[j]
                local ses = system.entities
                local seis = system.indices
                local index = seis[entity]
                if index then
                    system.modified = true
                    local tmpEntity = ses[#ses]
                    ses[index] = tmpEntity
                    seis[tmpEntity] = index
                    seis[entity] = nil
                    ses[#ses] = nil
                    local onRemove = system.onRemove
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
        local entity = e2a[i]
        if not entities[entity] then
            entities[entity] = true
            entityCount = entityCount + 1
            for j = 1, #systems do
                local system = systems[j]
                local ses = system.entities
                local seis = system.indices
                local filter = system.filter
                if filter and filter(system, entity) then
                    system.modified = true
                    local index = #ses + 1
                    ses[index] = entity
                    seis[entity] = index
                    local onAdd = system.onAdd
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

--- Manages Entities and Systems marked for deletion or addition. Call this
-- before modifying Systems and Entities outside of a call to `tiny.update`.
-- Do not call this within a call to `tiny.update`.
function tiny.refresh(world)
    tiny_manageSystems(world)
    tiny_manageEntities(world)
end

--- Updates the World by dt (delta time). Takes an optional parameter, `filter`,
-- which is a Filter that selects Systems from the World, and updates only those
-- Systems. If `filter` is not supplied, all Systems are updated. Put this
-- function in your main loop.
function tiny.update(world, dt, filter)

    tiny_manageSystems(world)
    tiny_manageEntities(world)

    local systems = world.systems

    --  Iterate through Systems IN ORDER
    for i = 1, #systems do
        local system = systems[i]
        if system.active and ((not filter) or filter(world, system)) then

            -- Call the modify callback on Systems that have been modified.
            local onModify = system.onModify
            if onModify and system.modified then
                onModify(system, dt)
            end

            -- Update Systems that have an update method (most Systems)
            local update = system.update
            if update then
                local interval = system.interval
                if interval then
                    local bufferedTime = (system.bufferedTime or 0) + dt
                    while bufferedTime >= interval do
                        bufferedTime = bufferedTime - interval
                        if update then
                            update(system, interval)
                        end
                    end
                    system.bufferedTime = bufferedTime
                else
                    update(system, dt)
                end
            end

            system.modified = false
        end
    end
end

--- Removes all Entities from the World.
function tiny.clearEntities(world)
    for e in pairs(world.entities) do
        tiny_removeEntity(world, e)
    end
end

--- Removes all Systems from the World.
function tiny.clearSystems(world)
    local systems = world.systems
    for i = #systems, 1, -1 do
        tiny_removeSystem(world, systems[i])
    end
end

--- Gets number of Entities in the World.
function tiny.getEntityCount(world)
    return world.entityCount
end

--- Gets number of Systems in World.
function tiny.getSystemCount(world)
    return #(world.systems)
end

--- Gets the index of the System in the World.
-- A simpler alternative is `system.index`.
function tiny.getSystemIndex(world, system)
    return system.index
end

--- Sets the index of a System in the World, and returns the old index. Changes
-- the order in which they Systems processed, because lower indexed Systems are
-- processed first. Returns the old system.index.
function tiny.setSystemIndex(world, system, index)
    local oldIndex = system.index
    local systems = world.systems

    if index < 0 then
        index = tiny.getSystemCount(world) + 1 + index
    end

    tremove(systems, oldIndex)
    tinsert(systems, index, system)

    for i = oldIndex, index, index >= oldIndex and 1 or -1 do
        systems[i].index = i
    end

    return oldIndex
end

-- Construct world metatable.
worldMetaTable = {
    __index = {
        add = tiny.add,
        addEntity = tiny.addEntity,
        addSystem = tiny.addSystem,
        remove = tiny.remove,
        removeEntity = tiny.removeEntity,
        removeSystem = tiny.removeSystem,
        refresh = tiny.refresh,
        update = tiny.update,
        clearEntities = tiny.clearEntities,
        clearSystems = tiny.clearSystems,
        getEntityCount = tiny.getEntityCount,
        getSystemCount = tiny.getSystemCount,
        getSystemIndex = tiny.getSystemIndex,
        setSystemIndex = tiny.setSystemIndex
    },
    __tostring = function(self)
        return "<tiny-ecs_World>"
    end
}

return tiny
