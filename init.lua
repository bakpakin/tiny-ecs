-- Helper Lua file for easy require if tiny-ecs is used as a git submodule or
-- folder. Not needed in many cases, including luarocks distribution.

local directory = (...):match("(.-)[^%.]+$")
return require(directory .. 'tiny')
