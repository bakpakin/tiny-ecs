local BumpPhysicsSystem = tiny.processingSystem(class "BumpPhysicsSystem")

function BumpPhysicsSystem:init(bumpWorld)
    self.bumpWorld = bumpWorld
end

BumpPhysicsSystem.filter = tiny.requireAll("pos", "vel", "hitbox")

local oneWayPrefix = "o"
oneWayPrefix = oneWayPrefix:byte(1)
local function collisionFilter(e1, e2)
    if e1.isPlayer then
        if e2.isBullet then return nil end
        if e2.isEnemy then return 'cross' end
    elseif e1.isEnemy then
        if e2.isBullet then return nil end
        if e2.isEnemy then return nil end
        if e2.isPlayer then return 'cross' end
    elseif e1.isBullet then
        if e2.isPlayer or e2.isBullet then return nil end
    end 
    if e1.isSolid then
        if type(e2) == "string" then -- tile collision
            if e2:byte(1) == oneWayPrefix then -- one way tile
                if e1.isBullet then
                    return 'onewayplatformTouch'
                else
                    return 'onewayplatform'
                end
            else
                return 'slide'
            end
        elseif e2.isSolid then
            return 'slide'
        elseif e2.isBouncy then
            return 'bounce'
        else
            return 'cross'
        end
    end
    return nil
end

function BumpPhysicsSystem:process(e, dt)
    local pos = e.pos
    local vel = e.vel
    local gravity = e.gravity or 0
    vel.y = vel.y + gravity * dt
    local cols, len
    pos.x, pos.y, cols, len = self.bumpWorld:move(e, pos.x + vel.x * dt, pos.y + vel.y * dt, collisionFilter)
    e.grounded = false
    for i = 1, len do
        local col = cols[i]
        local collided = true
        if col.type == "touch" then
            vel.x, vel.y = 0, 0
        elseif col.type == "slide" then
            if col.normal.x == 0 then
                vel.y = 0
                if col.normal.y < 0 then
                    e.grounded = true
                end
            else
                vel.x = 0
            end
        elseif col.type == "onewayplatform" then
            if col.didTouch then
                vel.y = 0
                e.grounded = true
            else
                collided = false
            end
        elseif col.type == "onewayplatformTouch" then
            if col.didTouch then
                vel.y = 0
                e.grounded = true
            else
                collided = false
            end
        elseif col.type == "bounce" then
            if col.normal.x == 0 then
                vel.y = -vel.y
                e.grounded = true
            else
                vel.x = -vel.x
            end
        end

        if e.onCollision and collided then 
            e:onCollision(col) 
        end
    end
end

function BumpPhysicsSystem:onAdd(e)
    local pos = e.pos
    local hitbox = e.hitbox
    self.bumpWorld:add(e, pos.x, pos.y, hitbox.w, hitbox.h)
end

function BumpPhysicsSystem:onRemove(e)
    self.bumpWorld:remove(e)
end

return BumpPhysicsSystem