# tiny-ecs #

[![Build Status](https://travis-ci.org/bakpakin/tiny-ecs.png?branch=master)](https://travis-ci.org/bakpakin/tiny-ecs)[![License](http://img.shields.io/badge/Licence-MIT-brightgreen.svg)](LICENSE)

Tiny-ecs is an Entity Component System for Lua that's simple, flexible, and useful.
Because of Lua's tabular nature, Entity Component Systems are a natural choice
for simulating large and complex systems. For more explanation on Entity
Component Systems, here is some
[basic info](http://en.wikipedia.org/wiki/Entity_component_system "Wikipedia").

Tiny-ecs also works well with objected oriented programming in Lua because
Systems and Entities do not use metatables. This means you can subclass your
Systems and Entities, and use existing Lua class frameworks with tiny-ecs, no problem.
For an example on how to use tiny-ecs with object-oriented Lua, take a look at the
demo branch, specifically the systems and entities sub-directories.

## Overview ##
Tiny-ecs has four important types: Worlds, Filters, Systems, and Entities.
Entities, however, can be any Lua table, and Filters are just functions that
take an Entity as a parameter.

### Entities ###
Entities are simply Lua tables of data that gets processed by Systems. Entities
should contain primarily data rather than code, as it is the Systems's job to
do logic on data. Henceforth, a key-value pair in an Entity will
be referred to as a Component.

### Worlds ###
Worlds are the outermost containers in tiny-ecs that contain both Systems
and Entities. In typical use, only one World is used at a time.

### Systems ###
Systems in tiny-ecs describe how to update Entities. Systems select certain Entities
using a Filter, and then only update those select Entities. Some Systems don't
update Entities, and instead just act as function callbacks every update. Tiny-ecs
provides functions for creating Systems easily, as well as creating Systems that
can be used in an object oriented fashion.

### Filters ###
Filters are used to select Entities. Filters can be any Lua function, but
tiny-ecs provides some functions for generating common ones, like selecting
only Entities that have all required components.

## Example ##
```lua
local tiny = require("tiny")

local talkingSystem = tiny.processingSystem()
talkingSystem.filter = tiny.requireAll("name", "mass", "phrase")
function talkingSystem:process(e, dt)
    e.mass = e.mass + dt * 3
    print(("%s who weighs %d pounds, says %q."):format(e.name, e.mass, e.phrase)
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

## Use It ##
Copy paste tiny.lua into your source folder. For stability and consistent API,
please use a tagged release or use luarocks.

## Luarocks ##
Tiny-ecs is also on [Luarocks](https://luarocks.org/) and can be installed with
`luarocks install tiny-ecs`.

## Demo ##
Check out the [demo](https://github.com/bakpakin/tiny-ecs/tree/demo-commandokibbles), a game
originally written for Ludum Dare 32 with the theme 'An Unconventional Weapon'. The demo uses
[LÖVE](https://love2d.org/), an amazing game framework for Lua.

## Testing ##
Tiny-ecs uses [busted](http://olivinelabs.com/busted/) for testing. Install and run
`busted` from the command line to test.

## Documentation ##
See API [here](http://bakpakin.github.io/tiny-ecs/doc/).
For the most up-to-date documentation, read the source code, or generate the HTML
locally with [LDoc](http://stevedonovan.github.io/ldoc/).
See the original forum thread [here](https://love2d.org/forums/viewtopic.php?f=5&t=79937&p=182589).
