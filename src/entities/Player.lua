local assets =  require "src.assets"
local anim8 = require "lib.anim8"
local Bullet = require "src.entities.Bullet"
local TimerEvent = require "src.entities.TimerEvent"
local ScreenSplash = require "src.entities.ScreenSplash"
local gamestate = require "lib.gamestate"

local Player = class("Player")

function Player:draw(dt)
    if self.hasGun then
        local p = self.animation.position
        local dy = (p ~= 2 and p ~= 3) and 0 or -1
        local dx = self.platforming.direction == 'l' and 2 or -2
        love.graphics.draw(assets.img_gun, self.pos.x + 16 + dx, self.pos.y + 10 + dy, self.gunAngle - math.pi / 4)
    end
end

function Player:onHit()
    self.isAlive = nil
    self.lifetime = 0.25
    self.fadeTime = 0.25
    self.alpha = 1
    self.ai = nil
    self.platforming.moving = false
    self.vel.y = -300
    self.vel.x = (math.random() - 0.5) * 400
    self.controlable = nil
    assets.snd_meow:play()
    world:add(self)
    local n = gamestate.current().score
    local message = "You Died."
    if n == 0 then message = "You Failed Pretty Hard."
    elseif n < 10 then message = "You Killed Some Pigs and They Killed you Back."
    elseif n < 30 then message = "That's a lot of Bacon."
    elseif n < 100 then message = "You a crazy Pig Killer."
    else message = "Pigpocolypse." end

    world:add(TimerEvent(1.2, function() world:add(ScreenSplash(0.5, 0.4, message .. " Press Space to Try Again.", 800)) end))
    gamestate.current().isSpawning = false
    gamestate.current().restartOnSpace = true
end

function Player:onCollision(col)
    if self.isAlive and col.other.isEnemy and col.other.isAlive then
        self:onHit()
    end
end

function Player:init(args)
    self.cameraTrack = {xoffset = 16, yoffset = -35}
    self.pos = {x = args.x, y = args.y}
    self.vel = {x = 0, y = 0}
    self.gravity = 1300
    self.platforming = {
        acceleration = 1000,
        speed = 130,
        jump = 380,
        friction = 2000,
        direction = 'r'
    }
    self.isAlive = true
    self.isPlayer = true
    self.isSolid = true
    self.controlable = true
    self.hitbox = {w = 32, h = 32}
    self.checkCollisions = true
    self.sprite = assets.img_catandcannon
    self.fg = true
    local g = anim8.newGrid(32, 32, assets.img_cat:getWidth(), assets.img_cat:getHeight())
    self.animation_stand = anim8.newAnimation(g('1-1', 1), 0.1)
    self.animation_walk = anim8.newAnimation(g('2-5', 1), 0.1)
    self.animation = self.animation_stand
    self.health = 100
    self.maxHealth = 100
    self.shotTimer = 0
    self.shotInterval = 0.45
    self.gunAngle = 2 * math.pi
    self.hasGun = true
end

return Player
