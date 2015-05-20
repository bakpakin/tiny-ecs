local assets = require "src.assets"
local anim8 = require "lib.anim8"
local Explosion = require "src.entities.Explosion"
local gamestate = require "lib.gamestate"

local Pig = class "Pig"

Pig.sprite = assets.img_pig

function Pig:init(x, y, target)
	self.pos = {x = x, y = y}
	self.vel = {x = 0, y = 0}
    self.gravity = 1300

    self.isAlive = true
    self.isEnemy = true
    self.isSolid = true

	self.platforming = {
        acceleration = 1000,
        speed = 60,
        jump = 250,
        friction = 2000,
        direction = 'r'
    }

    self.ai = {

	}

	self.hitbox = {w = 30, h = 21}
	self.health = 50
    self.maxHealth = 50

    local g = anim8.newGrid(30, 21, assets.img_pig:getWidth(), assets.img_pig:getHeight())
    self.animation_stand = anim8.newAnimation(g('1-1', 1), 0.1)
    self.animation_walk = anim8.newAnimation(g('2-5', 1), 0.1)
    self.animation = self.animation_stand
    self.fg = true
end

function Pig:gotHit()
    if self.isAlive then
        self.isAlive = nil
    	self.lifetime = 0.25
        self.fadeTime = 0.25
        self.alpha = 1
        self.ai = nil
        self.platforming.moving = false
        self.vel.y = -300
        self.vel.x = 0
        assets.snd_oink:play()
        assets.snd_yay:play()
        world:add(self)
        gamestate.current().score = gamestate.current().score + 1
    end
end

return Pig