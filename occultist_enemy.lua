local Enemy = require('enemy')
local lg = love.graphics

local OccultistEnemy = Enemy:subclass('OccultistEnemy')

function OccultistEnemy:initialize(x, y, width, height, required_seals)
    required_seals = required_seals or 1

    Enemy.initialize(self, x, y, width, height)
    self.class_name = "Occultist"
    self.required_seals = required_seals

    self:set_objective(function(hand, deck)
        local count = 0
        for _, c in ipairs(hand:get_cards()) do
            if c.id == 1 then count = count + 1 end
        end
        if deck and deck.cards then
            for _, c in ipairs(deck.cards) do
                if c.id == 1 then count = count + 1 end
            end
        end
        return count >= required_seals
    end)

    self:set_defeat_text(tostring(required_seals) .. "x Seal")

    if not OccultistEnemy.static._sprite then
        OccultistEnemy.static._sprite = lg.newImage("characters/occultist.png")
    end
    self.sprite = OccultistEnemy.static._sprite
end

function OccultistEnemy:is_defeated(hand, deck)
    if self.defeated then return true end
    local ok = self.objective_fn and self.objective_fn(hand, deck)
    if ok then
        self.defeated = true
        print("Occultist defeated – " .. tostring(self.required_seals) .. " Seal(s) obtained.")
        return true
    end
    return false
end

function OccultistEnemy:draw()
    if self.sprite then
        local sx = self.width / self.sprite:getWidth()
        local sy = self.height / self.sprite:getHeight()
        lg.setColor(1,1,1,1)
        lg.draw(self.sprite, self.x - self.width/2, self.y - self.height/2, 0, sx, sy)
    else
        Enemy.draw(self)
    end
end

return OccultistEnemy 