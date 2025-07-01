local middleclass = require('middle_class')

local Player = middleclass.class('Player')

function Player:initialize(x, y, width, height)
    self.x = x or 0
    self.y = y or 0
    self.width = width or 100
    self.height = height or 150
    self.class_name = "Unknown"
    self.is_hovered = false
    self.deck_ref = nil
end

function Player:draw()
    love.graphics.setColor(1, 1, 1, 1)
    love.graphics.rectangle("fill", self.x - self.width / 2, self.y - self.height / 2, self.width, self.height)
end

function Player:is_mouse_over(mx, my)
    return mx >= self.x - self.width / 2 and mx <= self.x + self.width / 2 and
           my >= self.y - self.height / 2 and my <= self.y + self.height / 2
end

function Player:update(dt, mx, my)
    if mx and my then
        self.is_hovered = self:is_mouse_over(mx, my)
    end
end

return Player 