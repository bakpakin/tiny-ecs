local CameraTrackingSystem = tiny.processingSystem(class "CameraTrackingSystem")

CameraTrackingSystem.filter = tiny.requireAll("cameraTrack", "pos")

function CameraTrackingSystem:init(camera)
    self.camera = camera
end

local function round(x)
    return math.floor(x * 32 + 16) / 32
end

function CameraTrackingSystem:process(e, dt)
    local xo, yo = e.cameraTrack.xoffset, e.cameraTrack.yoffset
    local x, y = e.pos.x + xo, e.pos.y + yo
    local xp, yp = self.camera:getPosition()
    local lerp = 0.1
    self.camera:setPosition(round(xp + (x - xp) * lerp), round(yp + (y - yp) * lerp))
end

function CameraTrackingSystem:onAdd(e)
    local xo, yo = e.cameraTrack.xoffset, e.cameraTrack.yoffset
    local x, y = e.pos.x + xo, e.pos.y + yo
    self.camera:setPosition(round(x), round(y))
end

return CameraTrackingSystem