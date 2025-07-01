local middleclass = require('middle_class')

local Hand = middleclass.class('Hand')

function Hand:initialize()
    self.cards = {}
end

function Hand:add_card(card)
    table.insert(self.cards, card)
    self:reposition_cards()
end

function Hand:remove_card(index)
    if index > 0 and index <= #self.cards then
        table.remove(self.cards, index)
        self:reposition_cards()
    end
end

function Hand:get_cards()
    return self.cards
end

function Hand:get_card_count()
    return #self.cards
end

function Hand:clear()
    self.cards = {}
end

function Hand:reposition_cards()
    local card_count = #self.cards
    if card_count == 0 then return end
    
    local base_spacing = 160
    local min_spacing = 80
    local max_cards_for_full_spacing = 5
    
    local card_spacing
    if card_count <= max_cards_for_full_spacing then
        card_spacing = base_spacing
    else
        card_spacing = math.max(min_spacing, base_spacing - (card_count - max_cards_for_full_spacing) * 10)
    end
    
    local card_width = (self.cards[1] and self.cards[1].width) or 120
    
    local bundle_width = (card_count - 1) * card_spacing + card_width
    local screen_center_x = love.graphics.getWidth() / 2
    local bundle_start_x = screen_center_x - (bundle_width / 2)
    local bundle_y = love.graphics.getHeight() / 2 - 100
    
    for i, card in ipairs(self.cards) do
        local card_x = bundle_start_x + (i-1) * card_spacing
        card.x = card_x
        card.y = bundle_y
        card.original_y = bundle_y
        
        if card.is_clicked then
            card.y = card.original_y - 30
        end
    end
end

function Hand:draw()
    for _, card in ipairs(self.cards) do
        card:draw()
    end
end

function Hand:update(dt)
    for _, card in ipairs(self.cards) do
        card:update(dt)
    end
end

function Hand:mouse_pressed(x, y, button)
    if button == 1 then
        for _, card in ipairs(self.cards) do
            if card:in_bounds(x, y) then
                card:click()
                return true
            end
        end
    elseif button == 2 then
        for _, card in ipairs(self.cards) do
            if card:in_bounds(x, y) then
                card:flip()
                return true
            end
        end
    end
    return false
end

_G.Hand = Hand

return Hand 