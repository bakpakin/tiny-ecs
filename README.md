# tiny-ecs #
Tiny-ecs is an Entity Component System for lua that's simple, flexible, and useful.
Because of lua's tabular nature, Entity Component Systems are a natural choice
for simulating large and complex systems. For more explanation on Entity
Component Systems, here is some
[basic info](http://en.wikipedia.org/wiki/Entity_component_system "Wikipedia").

## Use It ##
Copy paste tiny.lua into your source folder.

## Overview ##
Tiny-ecs has four important types: Worlds, Filters, Systems, and Entities.
Entities, however, can be any lua table, and Filters are just functions that
take an Entity as a parameter.

### Entities ###
Entities are simply lua tables of data that gets processed by Systems. Entities
should contain primarily data rather that code, as it is the Systems's job to
do logic on data. Henceforth, a key-value pair in an Entity will
be referred to as a Component.

### Worlds ###
Worlds are the outermost containers in tiny-ecs that contain both Systems
and Entities. In typical use, only one World is used at a time.

### Systems ###
Systems in tiny-ecs describe how to update Entities. Systems select certain Entities
using a Filter, and then only update those select Entities. Some Systems don't
update Entities, and instead just act as function callbacks every update. Tiny-ecs
provides functions for creating Systems easily.

### Filters ###
Filters are used to select Entities. Filters can be any lua function, but
tiny-ecs provides some functions for generating common ones, like selecting
only Entities that have all required components.

## Example ##
```lua
local tiny = require("tiny")

local talkingSystem = tiny.system()
talkingSystem.filter = tiny.requireAll("name", "mass", "phrase")
function talkingSystem:update(world, entities, dt)
    for p in pairs(entities) do
        p.mass = p.mass + dt * 3
        print(p.name .. ", who weighs " .. p.mass .. " pounds, says, \"" .. p.phrase .. "\"")
    end
end

local joe = {
    name = "Joe",
    phrase = "I'm a plumber.",
    mass = 150,
    hairColor = "brown"
}

local world = tiny.world(talkingSystem, joe)

for i = 1, 20 do
    world:update(1)
end
```

## Testing ##
Tiny-ecs uses [busted](http://olivinelabs.com/busted/) for testing. Install and run
`busted` from the command line to test.

## Documentation ##
See API [here](http://bakpakin.github.io/tiny-ecs/doc/).
Documentation can be generated locally with [LDoc](http://stevedonovan.github.io/ldoc/).

## TODO ##

* More testing
* Performance testing / optimization
* Improve Documentation
* Add more complete examples
