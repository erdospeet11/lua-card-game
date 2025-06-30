local Player = {}
Player.__index = Player

-- Constructor
function Player:new(x, y, width, height)
    local obj = {
        x = x or 0,
        y = y or 0,
        width = width or 100,
        height = height or 150,
        class_name = "Unknown",
        is_hovered = false,
        deck_ref = nil -- optional reference to a Deck object (for tooltips)
    }
    setmetatable(obj, self)
    return obj
end

-- Draw the player as a white rectangle (outline only)
function Player:draw()
    love.graphics.setColor(1, 1, 1, 1)
    love.graphics.rectangle("fill", self.x - self.width / 2, self.y - self.height / 2, self.width, self.height)
end

-- Helper to determine if point (mx,my) is inside this character rect
function Player:is_mouse_over(mx, my)
    return mx >= self.x - self.width / 2 and mx <= self.x + self.width / 2 and
           my >= self.y - self.height / 2 and my <= self.y + self.height / 2
end

-- Update hover state
function Player:update(dt, mx, my)
    if mx and my then
        self.is_hovered = self:is_mouse_over(mx, my)
    end
end

return Player 