local middleclass = require('middle_class')

local Deck = middleclass.class('Deck')

function Deck:initialize()
    self.cards = {}
end

function Deck:add_card(card)
    table.insert(self.cards, 1, card)
end

function Deck:shuffle()
    for i = #self.cards, 2, -1 do
        local j = love.math.random(i)
        self.cards[i], self.cards[j] = self.cards[j], self.cards[i]
    end
end

function Deck:draw_card()
    if #self.cards == 0 then return nil end
    return table.remove(self.cards)
end

function Deck:size()
    return #self.cards
end

return Deck 