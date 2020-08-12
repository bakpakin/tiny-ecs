local gamestate = require "lib.gamestate"
local Level = require "src.states.Level"
local TimerEvent = require "src.entities.TimerEvent"
local ScreenSplash = require "src.entities.ScreenSplash"
local TransitionScreen = require "src.entities.TransitionScreen"
local Level = require "src.states.Level"
local assets = require "src.assets"
local sti = require("lib.sti")
local gamera = require("lib.gamera")

local Intro = class "Intro"

function Intro:load()

	local tileMap = sti.new("assets/intro")
    local w, h = tileMap.tilewidth * tileMap.width, tileMap.tileheight * tileMap.height
    local camera = gamera.new(0, 0, w, h)
    camera:setPosition(600, 600)
    camera:setScale(2)

	self.time = 0
	self.world = tiny.world(
		require ("src.systems.DrawBackgroundSystem")(140, 205, 255),
        require ("src.systems.FadeSystem")(),
        require ("src.systems.LifetimeSystem")(),
        require ("src.systems.TileMapRenderSystem")(camera, tileMap),
        require ("src.systems.SpriteSystem")(camera, "bg"),
        require ("src.systems.SpriteSystem")(camera, "fg"),
        require ("src.systems.HudSystem")("hudBg"),
        require ("src.systems.HudSystem")("hudFg"),
        TransitionScreen(),
        ScreenSplash(0.5, 0.2, "Commando Kibbles"),
        ScreenSplash(0, 0, "Created by bakpakin for Ludum Dare 32", 300, assets.fnt_reallysmallhud, "left", 20, 20),
        ScreenSplash(0.5, 0.36, "Press Space to Start", 500, assets.fnt_smallhud),
        ScreenSplash(0.5, 0.45, "Controls:\nMove - WASD\nRotate Cannon - Arrow Keys\nFire - Down\nToggle Fullscreen - \\\nToggle Music - M\nPause - P\nEscape - Quit", 800, assets.fnt_reallysmallhud)
	)
	_G.world = self.world
    _G.camera = camera
end

function Intro:update(dt)
	self.time = self.time + dt
	if love.keyboard.isDown("space") and self.time > 0.55 then
		world:add(TransitionScreen(true, Level("assets/lvl1")))
	end
end

function Intro:draw()

end

return Intro
