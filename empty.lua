-- empty.lua
-- Placeholder scene between battles

local scene_manager = require('scene')

local empty = {}

function empty.enter()
    print("Entered empty scene (intermission)")
end

function empty.draw()
    love.graphics.clear(0.05, 0.05, 0.05)
    local text = "Intermission – press SPACE to continue"
    local font = love.graphics.getFont()
    local tw = font:getWidth(text)
    local th = font:getHeight()
    love.graphics.setColor(1,1,1,1)
    love.graphics.print(text, love.graphics.getWidth()/2 - tw/2, love.graphics.getHeight()/2 - th/2)
end

function empty.keypressed(key)
    if key == "space" then
        -- For now, return to menu
        local menu_scene = require('menu')
        scene_manager.switch(menu_scene)
    end
end

return empty 