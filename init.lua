-- Helper Lua file for easy require if tiny-ecs is used as a git submodule or
-- folder. Not needed in many cases, including luarocks distribution.

local args = {...}
local directory = args[1]
return require(directory .. '.tiny')
