-- Deck.lua - simple deck object for storing and drawing cards
local Deck = {}

function Deck:new()
    local self = {}
    setmetatable(self, { __index = Deck })

    -- Internal list of card objects (top of deck is at the end of the table)
    self.cards = {}
    return self
end

-- Add a card object to the bottom of the deck
function Deck:add_card(card)
    table.insert(self.cards, 1, card) -- insert at bottom (index 1)
end

-- Shuffle the deck using Fisher–Yates algorithm
function Deck:shuffle()
    for i = #self.cards, 2, -1 do
        local j = love.math.random(i)
        self.cards[i], self.cards[j] = self.cards[j], self.cards[i]
    end
end

-- Draw a card from the top of the deck (end of the table)
function Deck:draw_card()
    if #self.cards == 0 then return nil end
    return table.remove(self.cards) -- removes last element (top)
end

function Deck:size()
    return #self.cards
end

return Deck 