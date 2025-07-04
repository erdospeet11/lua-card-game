local Player = require('player')
local lg = love.graphics

local Thaumaturge = Player:subclass('Thaumaturge')

function Thaumaturge:initialize(x, y, width, height, deck_ref)
    Player.initialize(self, x, y, width, height)
    self.class_name = "Thaumaturge"
    self.deck_ref = deck_ref
end

function Thaumaturge:draw()
    if CardBack then
        -- Maintain aspect ratio by using the smaller scale factor
        local scale_x = self.width / CardBack:getWidth()
        local scale_y = self.height / CardBack:getHeight()
        local scale = math.min(scale_x, scale_y)
        
        -- Calculate centered position
        local scaled_width = CardBack:getWidth() * scale
        local scaled_height = CardBack:getHeight() * scale
        local draw_x = self.x - scaled_width/2
        local draw_y = self.y - scaled_height/2
        
        lg.setColor(1,1,1,1)
        lg.draw(CardBack, draw_x, draw_y, 0, scale, scale)
    else
        Player.draw(self)
    end
end

return Thaumaturge