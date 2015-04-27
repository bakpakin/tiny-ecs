local TileMapRenderSystem = tiny.system(class "TileMapRenderSystem")

function TileMapRenderSystem:init(camera, tileMap)
	self.camera = camera
	function self.drawFn(l, t, w, h)
        tileMap:update(dt)
        tileMap:setDrawRange(-l, -t, w, h)
        tileMap:draw()
    end
end

function TileMapRenderSystem:update(entities, dt)
	self.camera:draw(self.drawFn)
end

return TileMapRenderSystem