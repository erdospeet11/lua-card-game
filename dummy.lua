-- dummy.lua
-- A passive enemy that takes no action on its turn

local Enemy = require('enemy')

local Dummy = setmetatable({}, { __index = Enemy })
Dummy.__index = Dummy

function Dummy:new(x, y, width, height)
    local obj = Enemy.new(self, x, y, width, height)
    obj.class_name = "Dummy"
    -- Override default objective if needed; stays undefeated by default
    return obj
end

-- Override reaction to player combinations (do nothing)
function Dummy:on_player_combine(player_hand, player_deck)
    -- Dummy enemy does not retaliate
    return nil
end

-- Override end-of-turn behaviour (do nothing)
function Dummy:on_turn_end(player_hand, player_deck)
    -- Dummy enemy does not act
    return nil
end

return Dummy 