local assets =  require "src.assets"
local Explosion =  require "src.entities.Explosion"

local Bullet = class("Bullet")

Bullet.speed = 480
Bullet.sprite = assets.img_bullet

function Bullet:init(x, y, direction)
    self.pos = {x = x, y = y}
    self.vel = {x = self.speed * math.cos(direction), y = self.speed * math.sin(direction)}
    self.offset = {x = 4, y = 4}
    self.hitbox = {w = 4, h = 4}
    self.bullet = true
    self.drot = math.random() - 0.5
    self.rot = direction
    self.isBullet = true
    self.isSolid = true
    self.gravity = 1300
    self.bg = true
end

function Bullet:explode()
    world:remove(self)
    world:add(Explosion(self.pos.x - 32, self.pos.y - 60))
    assets.snd_thud:play()
end

function Bullet:update(dt)
    self.rot = self.rot + self.drot * dt * 10
end

function Bullet:onCollision(col)
    self:explode()
    if col.other.isEnemy and col.other.gotHit then
        col.other:gotHit()
    end
end


return Bullet
