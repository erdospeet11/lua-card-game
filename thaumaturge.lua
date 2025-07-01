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
        local sx = self.width / CardBack:getWidth()
        local sy = self.height / CardBack:getHeight()
        lg.setColor(1,1,1,1)
        lg.draw(CardBack, self.x - self.width/2, self.y - self.height/2, 0, sx, sy)
    else
        Player.draw(self)
    end
end

return Thaumaturge