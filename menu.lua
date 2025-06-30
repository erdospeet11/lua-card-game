-- menu.lua
-- Simple start menu scene with a BATTLE button

local scene_manager = require('scene')
local enemy_select_scene = require('enemy_select')

local menu = {}

-- Button definition
local button = {
    x = 0,
    y = 0,
    width = 200,
    height = 60,
    text = "SCENARIOS",
    hovered = false
}

local title_font = nil

function menu.enter()
    -- Position button centred
    local sw, sh = love.graphics.getWidth(), love.graphics.getHeight()
    button.x = sw / 2 - button.width / 2
    button.y = sh / 2 - button.height / 2
    button.hovered = false

    -- Create title font once (48px)
    if not title_font then
        title_font = love.graphics.newFont(48)
    end
end

function menu.update(dt)
    local mx, my = love.mouse.getX(), love.mouse.getY()
    button.hovered = mx >= button.x and mx <= button.x + button.width and
                     my >= button.y and my <= button.y + button.height
end

function menu.draw()
    -- Background
    love.graphics.clear(0.1, 0.1, 0.15)

    -- Title text
    local default_font = love.graphics.getFont()
    love.graphics.setFont(title_font)
    local title = "KOZMOZ"
    local tw_title = title_font:getWidth(title)
    local th_title = title_font:getHeight()
    love.graphics.setColor(1,1,1,1)
    love.graphics.print(title, button.x + (button.width - tw_title)/2, button.y - th_title - 40)
    love.graphics.setFont(default_font)

    -- Button background
    if button.hovered then
        love.graphics.setColor(0.4, 0.4, 0.4, 0.9)
    else
        love.graphics.setColor(0.3, 0.3, 0.3, 0.8)
    end
    love.graphics.rectangle("fill", button.x, button.y, button.width, button.height)

    -- Button border
    love.graphics.setColor(1, 1, 1, 1)
    love.graphics.rectangle("line", button.x, button.y, button.width, button.height)

    -- Button text
    local tw, th = default_font:getWidth(button.text), default_font:getHeight()
    love.graphics.print(button.text, button.x + (button.width - tw) / 2, button.y + (button.height - th) / 2)
end

function menu.mousepressed(x, y, button_num)
    if button_num == 1 and button.hovered then
        -- Switch to battle scene
        scene_manager.switch(enemy_select_scene)
    end
end

function menu.keypressed(key)
    -- Quick keyboard shortcut to start battle
    if key == "b" then
        scene_manager.switch(enemy_select_scene)
    end
end

return menu 