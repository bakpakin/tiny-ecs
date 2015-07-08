local SpriteSystem = tiny.processingSystem(class "SpriteSystem")

function SpriteSystem:init(camera, layerFlag)
    self.camera = camera
    self.filter = tiny.requireAll("sprite", "pos", layerFlag)
end

function SpriteSystem:preProcess(dt)
    self.camera:apply()
end

function SpriteSystem:postProcess(dt)
    self.camera:remove()
    love.graphics.setColor(255, 255, 255, 255)
end

function SpriteSystem:process(e, dt)
    local an = e.animation
    local alpha = e.alpha or 1
    local pos, sprite, scale, rot, offset = e.pos, e.sprite, e.scale, e.rot, e.offset
    local sx, sy, r, ox, oy = scale and scale.x or 1, scale and scale.y or 1, rot or 0, offset and offset.x or 0, offset and offset.y or 0
    love.graphics.setColor(255, 255, 255, math.max(0, math.min(1, alpha)) * 255)
    if an then
        an.flippedH = e.flippedH or false
        an.flippedV = e.flippedV or false
        an:update(dt)
        an:draw(sprite, pos.x, pos.y, r, sx, sy, ox, oy)
    else
        love.graphics.draw(sprite, pos.x, pos.y, r, sx, sy, ox, oy)
    end
    if e.draw then
        e:draw(dt)
    end
end

return SpriteSystem
