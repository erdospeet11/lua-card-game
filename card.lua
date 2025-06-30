Card = {}

function Card:new(name, description, face_image, back_image, x, y, id, card_type)
    local self = {}
    setmetatable(self, {__index = Card})
    self.id = id or 0  -- Card ID (0 = blank card by default)
    self.type = card_type or "Unknown"  -- Card type/category
    self.name = name
    self.description = description
    self.face_image = face_image  -- Front of the card
    self.back_image = back_image  -- Back of the card
    self.x = x or 0
    self.y = y or 0
    self.original_y = y or 0  -- Store original position
    self.is_hovered = false
    self.is_clicked = false
    -- Desired card visual dimensions
    self.width = 80 * 1.5  -- Final card width in pixels (narrower than before)
    self.height = 140 * 1.5-- Final card height in pixels (taller for better readability)
    
    -- Calculate image scaling based on desired size
    self.scale_x = self.width / face_image:getWidth()
    self.scale_y = self.height / face_image:getHeight()
    
    -- Flip animation properties
    self.is_flipping = false
    self.flip_progress = 0  -- 0 to 1, where 0.5 is the midpoint
    self.is_face_up = true  -- True = showing face, False = showing back
    self.flip_speed = 3  -- How fast the flip animation is
    
    return self
end

function Card:draw()
    -- Calculate flip transformation
    local flip_scale = 1.0
    local current_image = self.face_image
    
    if self.is_flipping then
        -- During flip, scale horizontally based on progress
        -- 0.0 -> 1.0 -> 0.0 -> 1.0 creates the flip effect
        if self.flip_progress <= 0.5 then
            -- First half: shrink to 0 width
            flip_scale = 1.0 - (self.flip_progress * 2)
            current_image = self.is_face_up and self.face_image or self.back_image
        else
            -- Second half: expand from 0 width with new image
            flip_scale = (self.flip_progress - 0.5) * 2
            current_image = self.is_face_up and self.back_image or self.face_image
        end
    else
        -- Not flipping, show appropriate side
        current_image = self.is_face_up and self.face_image or self.back_image
    end
    
    -- Draw the card with flip scaling
    local center_x = self.x + (self.width / 2)
    love.graphics.draw(
        current_image,
        center_x,
        self.y,
        0,
        self.scale_x * flip_scale,  -- Horizontal scale (with flip)
        self.scale_y,               -- Vertical scale matches desired height
        current_image:getWidth() / 2,
        0
    )  -- Origin at card's horizontal centre, top edge vertically
    
    -- Draw tooltip on hover
    if self.is_hovered then
        local tooltip_text = string.format("%s\n(%s)\n%s", self.name, self.type or "", self.description)
        local font = love.graphics.getFont()
        
        -- Calculate dynamic tooltip size based on text
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
        
        local tooltip_width = max_width + 10  -- Add padding
        local tooltip_height = font:getHeight() * #lines + 10  -- Add padding
        
        -- Center the tooltip above the card
        local tooltip_x = self.x + (self.width / 2) - (tooltip_width / 2)
        local tooltip_y = self.y - tooltip_height - 10
        
        -- Tooltip background
        love.graphics.setColor(0, 0, 0, 0.8)
        love.graphics.rectangle("fill", tooltip_x, tooltip_y, tooltip_width, tooltip_height)
        
        -- Tooltip border
        love.graphics.setColor(1, 1, 1, 1)
        love.graphics.rectangle("line", tooltip_x, tooltip_y, tooltip_width, tooltip_height)
        
        -- Tooltip text
        love.graphics.print(tooltip_text, tooltip_x + 5, tooltip_y + 5)
        love.graphics.setColor(1, 1, 1, 1)  -- Reset color
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
        self.y = self.original_y - 30  -- Move up when clicked
    else
        self.y = self.original_y  -- Move down when clicked again
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
    -- Default combine behavior - does nothing and should not be consumed
    print("Card " .. self.name .. " was combined (no effect)")
    return false -- not consumed
end

function Card:in_bounds(mx, my)
    return mx >= self.x and mx <= self.x + self.width and 
           my >= self.y and my <= self.y + self.height
end

function Card:update(dt)
    local mx, my = love.mouse.getX(), love.mouse.getY()
    
    -- Handle hover
    if self:in_bounds(mx, my) then
        self:hover()
    else
        self:unhover()
    end
    
    -- Handle flip animation
    if self.is_flipping then
        self.flip_progress = self.flip_progress + dt * self.flip_speed
        
        if self.flip_progress >= 1.0 then
            -- Flip animation complete
            self.flip_progress = 0
            self.is_flipping = false
            self.is_face_up = not self.is_face_up  -- Toggle the side
        end
    end
end

-- SpawnerCard - Special card that spawns 2 cards when combined
SpawnerCard = {}
setmetatable(SpawnerCard, {__index = Card})  -- Inherit from Card

function SpawnerCard:new(name, description, face_image, back_image, x, y)
    local self = Card:new(name, description, face_image, back_image, x, y, 1)  -- ID 1 for spawner cards
    setmetatable(self, {__index = SpawnerCard})
    return self
end

function SpawnerCard:on_combine(hand)
    print("SpawnerCard " .. self.name .. " spawning 2 blank cards!")

    local card_bank = require('card_bank')
    for i = 1, 2 do
        local new_card = card_bank.create_card(0, 0, 0)
        hand:add_card(new_card)
    end
    return true -- spawner card is consumed
end