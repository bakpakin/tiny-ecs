# Jojo #
Jojo is an Entity Component System for lua that's simple, flexible, and useful.
Because of lua's tabular nature, Entity Component Systems are a natural choice
for simulating large and complex systems. For more explanation on Entity
Component Systems, here is some
[basic info](http://en.wikipedia.org/wiki/Entity_component_system "Wikipedia").

## Use It ##
Copy paste jojo.lua into your source folder.

## Overview ##
Jojo has four important types: Worlds, Aspects, Systems, and Entities.
Entities, however, can be any lua table.

### Entities ###
Entities are simply lua tables of data that gets processed by Systems. Entities
should contain primarily data rather that code, as it is the Systems's job to
do logic on data. Henceforth, a key-value pair in an Entity will
be referred to as a Component.

### Worlds ###
Worlds are the outermost containers in Jojo that contain both Systems
and Entities. In typical use, only one World is used at a time.

### Systems ###
Systems in Jojo describe how to update Entities. Systems select certain Entities
using an aspect, and then only update those select Entities. Systems have three
parts: a one-time update function, a per Entity update function, and an Aspect.
The one-time update function is called once per World update, and the per Entity
update function is called once per Entity per World update. The Aspect is used
to select which Entities the System will update.

### Aspects ###
Aspects are used to select Entities by the presence or absence of specific
Components. If an Entity contains all Components required by an Aspect, and
doesn't contain Components that are excluded by the Aspect, it is said to match
the Aspect. Aspects can also be composed into more complicated Aspects that
are equivalent to the union of all sub-Aspects.

## Example ##
```lua
local jojo = require("jojo")

local World = jojo.World
local Aspect = jojo.Aspect
local System = jojo.System

local personAspect = Aspect({"name", "mass", "phrase"})
local talkingSystem = System(
    function (delta)
        print("Talking system has started.")
    end,
    function (p, delta)
        print(p.name .. ", who weighs " .. p.mass .. " pounds, says, \"" .. p.phrase .. "\"")
    end,
    personAspect
)

local world = World(talkingSystem)

local joe = {
    name = "Joe",
    phrase = "I'm a plumber.",
    mass = 250,
    hairColor = "brown"
}

world:add(joe)

world:update(1)
```

## Testing ##
To test Jojo, simply clone the project, cd into the project directory, and
run `lua jojotest.lua` from command line.

## TODO ##

* Dynamically add and remove systems
* More testing
* Performance testing / optimization
* API outside of source code
