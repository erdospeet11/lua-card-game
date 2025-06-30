local DeckHand = {}

local Deck = require('deck')
local card_bank = require('card_bank')

-- Table mapping class names to a map of { card_id = quantity }
DeckHand.starting_decks = {
    Thaumaturge = {
        [1] = 52, -- Spawner card (example)
        [2] = 10, -- Charm card (example)
    },
    -- Add additional classes here, e.g.
    -- Warrior = { [3] = 40, [4] = 22 }
}

---
-- Creates and returns a new shuffled Deck populated with the starting cards for the
-- specified character class.
-- @param class_name string  Name of the class (must match key in starting_decks).
-- @return Deck            A Deck instance populated with the appropriate cards.
function DeckHand.create_starting_deck(class_name)
    local template = DeckHand.starting_decks[class_name]

    -- Fallback: empty template if class not found
    if not template then
        print(string.format("[DeckHand] No starting deck defined for class '%s'. Returning empty deck.", tostring(class_name)))
        return Deck:new()
    end

    local deck = Deck:new()
    for card_id, qty in pairs(template) do
        for i = 1, qty do
            local card = card_bank.create_card(card_id, 0, 0)
            deck:add_card(card)
        end
    end

    deck:shuffle()
    return deck
end

return DeckHand 