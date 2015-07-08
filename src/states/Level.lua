local sti = require("lib.sti")
local bump = require("lib.bump")
local gamera = require("lib.gamera")
local TimerEvent = require "src.entities.TimerEvent"
local ScreenSplash = require "src.entities.ScreenSplash"
local TransitionScreen = require "src.entities.TransitionScreen"

local Level = class "Level"

local waveTable = {4, 10, 20, 50, 80, 100, 120, 150, 180, 200, 250}
local waveSpawnSpeeds = {1, 1, 1.5, 2, 2, 2.2, 3, 3, 4, 5, 7}

function Level:init(mappath)
	self.mappath = mappath
end

function Level:nextWave()
    self.wave = self.wave + 1
    self.enemiesKilled = 0
    self.totalEnemiesToKill = waveTable[self.wave] or math.huge
    self.enemiesSpawned = 0
    self.spawnInterval = 3 / (waveSpawnSpeeds[self.wave] or 10)
    self.isSpawning = true
    if self.wave == #waveTable + 1 then
        local splash = ScreenSplash(0.5, 0.5, "Kill Them ALL!!")
        world:add(TimerEvent(1, function() world:add(splash) end),
                  TimerEvent(3, function() world:remove(splash) end))
    end
end

function Level:load()
	local tileMap = sti.new(self.mappath)
    local bumpWorld = bump.newWorld(tileMap.tilewidth * 2)
    local w, h = tileMap.tilewidth * tileMap.width, tileMap.tileheight * tileMap.height
    local camera = gamera.new(0, 0, w, h)

    self.wave = 0
    self:nextWave()
    self.score = 0

    self.spawnerCount = 0
    self.spawners = {}

    self.tileMap = tileMap
    self.bumpWorld = bumpWorld
    self.camera = camera

    self.aiSystem = require ("src.systems.AISystem")()

    local r, g, b = tileMap.backgroundcolor[1], tileMap.backgroundcolor[2], tileMap.backgroundcolor[3]

    camera:setScale(2)
    local world = tiny.world(
        require ("src.systems.DrawBackgroundSystem")(r, g, b),
        require ("src.systems.UpdateSystem")(),
        require ("src.systems.PlayerControlSystem")(),
        self.aiSystem,
        require ("src.systems.FadeSystem")(),
        require ("src.systems.PlatformingSystem")(),
        require ("src.systems.BumpPhysicsSystem")(bumpWorld),
        require ("src.systems.CameraTrackingSystem")(camera),
        require ("src.systems.TileMapRenderSystem")(camera, tileMap),
        require ("src.systems.SpriteSystem")(camera, "bg"),
        require ("src.systems.SpriteSystem")(camera, "fg"),
        require ("src.systems.LifetimeSystem")(),
        require ("src.systems.HudSystem")("hudBg"),
        require ("src.systems.HudSystem")("hudFg"),
        require ("src.systems.WaveSystem")(self),
        require ("src.systems.SpawnSystem")(self),
        require ("src.entities.MainHud")(self),
        TransitionScreen()
    )

    local player = nil

    for lindex, layer in ipairs(tileMap.layers) do
		if layer.properties.collidable == "true" then
			-- Entire layer
			if layer.type == "tilelayer" then
                local prefix = layer.properties.oneway == "true" and "o(" or "t("
                for y, tiles in ipairs(layer.data) do
                    for x, tile in pairs(tiles) do
                        bumpWorld:add(
                            prefix..layer.name..", "..x..", "..y..")",
                            x * tileMap.tilewidth  + tile.offset.x,
                            y * tileMap.tileheight + tile.offset.y,
                            tile.width,
                            tile.height
                        )
                    end
                end
			elseif layer.type == "imagelayer" then
                bumpWorld:add(
                    layer.name,
                    layer.x or 0,
                    layer.y or 0,
                    layer.width,
                    layer.height
                )
			end
		end

        if layer.type == "objectgroup" then
            for _, object in ipairs(layer.objects) do
                local ctor = require("src.entities." .. object.type)
                local e = ctor(object)
                if object.type == "Player" then
                    player = e
                end
                world:add(e)
            end
            tileMap:removeLayer(lindex)
        end

	end

    self.aiSystem.target = player

    -- add ends to prevent objects from falling off the edge of the world.
    bumpWorld:add("_leftBlock", -16, 0, 16, h)
    bumpWorld:add("_rightBlock", w, 0, 16, h)
    bumpWorld:add("_topBlock", 0, -16, w, 16)

    -- globals
    _G.camera = camera
    _G.world = world
end

return Level
