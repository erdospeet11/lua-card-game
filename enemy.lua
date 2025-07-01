local middleclass = require('middle_class')

local Enemy = middleclass.class('Enemy')

function Enemy:initialize(x, y, width, height)
    self.x = x or 0
    self.y = y or 0
    self.width = width or 100
    self.height = height or 150
    self.class_name = "Enemy"
    self.is_hovered = false
    
    self.objective_fn = function()
        return false
    end

    self.defeated = false

    self.defeat_text = ""

    self.negative_effects = {
        "add_blank_card_hand",
        "add_blank_card_deck",
        "remove_random_hand",
        "remove_random_deck"
    }
    
    self._card_bank = require('card_bank')
end

function Enemy:draw()
    love.graphics.setColor(1, 1, 1, 1)
    love.graphics.rectangle("fill", self.x - self.width / 2, self.y - self.height / 2, self.width, self.height)
end

function Enemy:set_objective(fn)
    if type(fn) == "function" then
        self.objective_fn = fn
    end
end

function Enemy:set_defeat_text(text)
    self.defeat_text = text or ""
end

function Enemy:is_defeated(player_hand, player_deck)
    if self.defeated then return true end
    local ok = false
    if self.objective_fn then
        ok = self.objective_fn(player_hand, player_deck)
    end
    self.defeated = ok
    return ok
end

function Enemy:apply_negative_effect(player_hand, player_deck)
    if self.defeated then return end

    local effects = self.negative_effects
    if not effects or #effects == 0 then return end

    local choice = effects[love.math.random(#effects)]
    local message = ""
    if choice == "add_blank_card_hand" then
        local new_card = self._card_bank.create_card(0, 0, 0)
        player_hand:add_card(new_card)
        message = "Enemy adds a useless blank card to your hand!"
    elseif choice == "add_blank_card_deck" then
        local new_card = self._card_bank.create_card(0, 0, 0)
        player_deck:add_card(new_card)
        message = "Enemy shuffles a blank card into your deck!"
    elseif choice == "remove_random_hand" then
        if player_hand:get_card_count() > 0 then
            local idx = love.math.random(player_hand:get_card_count())
            player_hand:remove_card(idx)
            message = "Enemy removes a random card from your hand!"
        else
            message = "Enemy tried to remove a card from your hand, but it was empty."
        end
    elseif choice == "remove_random_deck" then
        if player_deck:size() > 0 then
            local idx = love.math.random(player_deck:size())
            table.remove(player_deck.cards, idx)
            message = "Enemy removes a random card from your deck!"
        else
            message = "Enemy tried to remove a card from your deck, but it was empty."
        end
    end

    print(message)
    return message
end

function Enemy:on_player_combine(player_hand, player_deck)
    if self:is_defeated(player_hand, player_deck) then return nil end
    return self:apply_negative_effect(player_hand, player_deck)
end

function Enemy:on_turn_end(player_hand, player_deck)
    if self:is_defeated(player_hand, player_deck) then return nil end
    return self:apply_negative_effect(player_hand, player_deck)
end

function Enemy:is_mouse_over(mx, my)
    return mx >= self.x - self.width / 2 and mx <= self.x + self.width / 2 and
           my >= self.y - self.height / 2 and my <= self.y + self.height / 2
end

function Enemy:update(dt, mx, my)
    if mx and my then
        self.is_hovered = self:is_mouse_over(mx, my)
    end
end

return Enemy 