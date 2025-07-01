local DeckHand = {}

local Deck = require('deck')
local card_bank = require('card_bank')

DeckHand.starting_decks = {
    Thaumaturge = {
        [1] = 52,
        [2] = 10,
    },
}

function DeckHand.create_starting_deck(class_name)
    local template = DeckHand.starting_decks[class_name]

    if not template then
        print(string.format("[DeckHand] No starting deck defined for class '%s'. Returning empty deck.", tostring(class_name)))
        return Deck()
    end

    local deck = Deck()
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