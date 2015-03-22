local jojo = {
    _VERSION = "0.0.1",
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
        if a[4] then
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
    if self[4] then return false end
    local rs, es, os = self[1], self[2], self[3]
    for i = 1, #rs do
        local r = rs[i]
        if entity[r] == nil then return false end
    end
    for i = 1, #es do
        local e = es[i]
        if entity[e] ~= nil then return false end
    end
    if #os >= 1 then
        for i = 1, #os do
            local o = os[i]
            if entity[o] ~= nil then return true end
        end
        return false
    end
    return true
end

-- Aspect:trace()

-- Prints out a description of this Aspect.
function Aspect:trace()
    if self[4] then
        print("Empty Aspect.")
    else
        print("Required Components:", tconcat(self[1], ", "))
        print("Excluded Components:", tconcat(self[2], ", "))
        print("One Req. Components:", tconcat(self[3], ", "))
    end
end

----- System -----

-- System(preupdate, update, [aspect])

-- Creates a new System with the given aspect and update callback. The update
-- callback should be a function of one parameter, an entity. If no aspect is
-- provided the empty Aspect, which matches no Entity, is used. Preupdate is a
-- function of no arguments that is called once per system update before the
-- entities are updated.
function System:init(preupdate, update, aspect)
    self.preupdate = preupdate
    self.update = update
    self.aspect = aspect or Aspect()
    self.active = true
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

        -- List of Systems
        self.systems = args

        -- Accumulated time for each System.
        self.times = {}

        -- Next available entity ID
        self.nextID = 0

        -- Table of System indices to Sets of matching Entity IDs
        local aspectEntities = {}
        self.aspectEntities = aspectEntities
        for i, sys in ipairs(args) do
            aspectEntities[i] = {}
        end

end

-- World:add(...)

-- Adds Entities to the World. An Entity is just a table of Components.
function World:add(...)
    local args = {...}
    local status = self.status
    local entities = self.entities
    for _, e in ipairs(args) do
        local id = self.nextID
        self.nextID = id + 1
        e._id = id
        entities[id] = e
        status[id] = "add"
    end
end

-- World:changed(...)

-- Call this function on any Entities that have changed such that they would
-- now match different systems.
function World:changed(...)
    local args = {...}
    local status = self.status
    for _, e in ipairs(args) do
        status[e._id] = "add"
    end
end

-- World:free(...)

-- Frees Entities from the World.
function World:free(...)
    local args = {...}
    local status = self.status
    for _, e in ipairs(args) do
        status[e._id] = "free"
    end
end

-- World:update()

-- Updates the World.
function World:update(dt)

    local statuses = self.status
    local aspectEntities = self.aspectEntities
    local entities = self.entities
    local systems = self.systems

    for eid, s in pairs(statuses) do
        if s == "add" then
            local e = entities[eid]
            for sysi, set in pairs(aspectEntities) do
                local a = systems[sysi].aspect
                set[eid] = a:matches(e) and true or nil
            end
            statuses[eid] = nil
        end
    end

    for sysi, s in ipairs(self.systems) do
        local preupdate = s.preupdate
        if s.active and preupdate then
            preupdate(dt)
        end
        local eids = aspectEntities[sysi]
        local u = s.update
        for eid in pairs(eids) do
            local status = statuses[eid]
            if status == "free" then
                eids[eid] = nil
            end
            u(entities[eid], dt)
        end
    end

    for eid, s in pairs(statuses) do
        if s == "free" then
            entities[eid].id = nil
            entities[eid] = nil
        end
        statuses[eid] = nil
    end

end

return jojo
