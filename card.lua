local middleclass = require('middle_class')

local Card = middleclass.class('Card')

function Card:initialize(name, description, face_image, back_image, x, y, id, card_type)
    self.id = id or 0
    self.type = card_type or "Unknown"
    self.name = name
    self.description = description
    self.face_image = face_image
    self.back_image = back_image
    self.x = x or 0
    self.y = y or 0
    self.original_y = y or 0
    self.is_hovered = false
    self.is_clicked = false
    self.width = 80 * 1.5
    self.height = 140 * 1.5
    
    self.scale_x = self.width / face_image:getWidth()
    self.scale_y = self.height / face_image:getHeight()
    
    self.is_flipping = false
    self.flip_progress = 0
    self.is_face_up = true
    self.flip_speed = 3
end

function Card:draw()
    local flip_scale = 1.0
    local current_image = self.face_image
    
    if self.is_flipping then
        if self.flip_progress <= 0.5 then
            flip_scale = 1.0 - (self.flip_progress * 2)
            current_image = self.is_face_up and self.face_image or self.back_image
        else
            flip_scale = (self.flip_progress - 0.5) * 2
            current_image = self.is_face_up and self.back_image or self.face_image
        end
    else
        current_image = self.is_face_up and self.face_image or self.back_image
    end
    
    local center_x = self.x + (self.width / 2)
    love.graphics.draw(
        current_image,
        center_x,
        self.y,
        0,
        self.scale_x * flip_scale,
        self.scale_y,
        current_image:getWidth() / 2,
        0
    )
    
    if self.is_hovered then
        local tooltip_text = string.format("%s\n(%s)\n%s", self.name, self.type or "", self.description)
        local font = love.graphics.getFont()
        
        local lines = {}
        for line in tooltip_text:gmatch("[^\n]+") do
            table.insert(lines, line)
        end
        
        local max_width = 0
        for _, line in ipairs(lines) do
            local line_width = font:getWidth(line)
            if line_width > max_width then
                max_width = line_width
            end
        end
        
        local tooltip_width = max_width + 10
        local tooltip_height = font:getHeight() * #lines + 10
        
        local tooltip_x = self.x + (self.width / 2) - (tooltip_width / 2)
        local tooltip_y = self.y - tooltip_height - 10

        love.graphics.setColor(0, 0, 0, 0.8)
        love.graphics.rectangle("fill", tooltip_x, tooltip_y, tooltip_width, tooltip_height)
        
        love.graphics.setColor(1, 1, 1, 1)
        love.graphics.rectangle("line", tooltip_x, tooltip_y, tooltip_width, tooltip_height)
        
        love.graphics.print(tooltip_text, tooltip_x + 5, tooltip_y + 5)
        love.graphics.setColor(1, 1, 1, 1)
    end
end

function Card:hover()
    self.is_hovered = true
end

function Card:unhover()
    self.is_hovered = false
end

function Card:click()
    self.is_clicked = not self.is_clicked
    if self.is_clicked then
        self.y = self.original_y - 30
    else
        self.y = self.original_y
    end
    print("Card clicked: " .. self.name)
end

function Card:flip()
    if not self.is_flipping then
        self.is_flipping = true
        self.flip_progress = 0
        print("Card flipped: " .. self.name)
    end
end

function Card:on_combine(hand)
    print("Card " .. self.name .. " was combined (no effect)")
    return false
end

function Card:in_bounds(mx, my)
    return mx >= self.x and mx <= self.x + self.width and 
           my >= self.y and my <= self.y + self.height
end

function Card:update(dt)
    local mx, my = love.mouse.getX(), love.mouse.getY()
    
    if self:in_bounds(mx, my) then
        self:hover()
    else
        self:unhover()
    end
    
    if self.is_flipping then
        self.flip_progress = self.flip_progress + dt * self.flip_speed
        
        if self.flip_progress >= 1.0 then
            self.flip_progress = 0
            self.is_flipping = false
            self.is_face_up = not self.is_face_up
        end
    end
end

local SpawnerCard = Card:subclass('SpawnerCard')

function SpawnerCard:initialize(name, description, face_image, back_image, x, y)
    Card.initialize(self, name, description, face_image, back_image, x, y, 1, "Phenomena")
end

function SpawnerCard:on_combine(hand)
    print("SpawnerCard " .. self.name .. " spawning 2 blank cards!")

    local card_bank = require('card_bank')
    for i = 1, 2 do
        local new_card = card_bank.create_card(0, 0, 0)
        hand:add_card(new_card)
    end
    return true
end

_G.Card = Card
_G.SpawnerCard = SpawnerCard

return Card