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
local space_shader = nil
local shader_time = 0

function menu.enter()
    local sw, sh = love.graphics.getWidth(), love.graphics.getHeight()
    button.x = sw / 2 - button.width / 2
    button.y = sh / 2 - button.height / 2
    button.hovered = false

    if not title_font then
        title_font = love.graphics.newFont(48)
    end
    
    -- Load the space shader
    if not space_shader then
        local shader_code = love.filesystem.read("space.glsl")
        if shader_code then
            space_shader = love.graphics.newShader(shader_code)
        else
            print("Warning: Could not load space.glsl shader")
        end
    end
    
    shader_time = 0
end

function menu.update(dt)
    local mx, my = love.mouse.getX(), love.mouse.getY()
    button.hovered = mx >= button.x and mx <= button.x + button.width and
                     my >= button.y and my <= button.y + button.height
    
    -- Update shader time for animation
    shader_time = shader_time + dt
end

function menu.draw()
    local sw, sh = love.graphics.getWidth(), love.graphics.getHeight()
    
    -- Draw space shader background
    if space_shader then
        love.graphics.setShader(space_shader)
        space_shader:send("time", shader_time)
        space_shader:send("resolution", {sw, sh})
        love.graphics.setColor(1, 1, 1, 1)
        love.graphics.rectangle("fill", 0, 0, sw, sh)
        love.graphics.setShader() -- Reset shader
    else
        -- Fallback background
        love.graphics.clear(0.1, 0.1, 0.15)
    end

    local default_font = love.graphics.getFont()
    love.graphics.setFont(title_font)
    local title = "KOZMOZ"
    local tw_title = title_font:getWidth(title)
    local th_title = title_font:getHeight()
    
    -- Add background for title for better visibility
    love.graphics.setColor(0, 0, 0, 0.6)
    love.graphics.rectangle("fill", button.x + (button.width - tw_title)/2 - 10, button.y - th_title - 50, tw_title + 20, th_title + 20)
    
    love.graphics.setColor(1,1,1,1)
    love.graphics.print(title, button.x + (button.width - tw_title)/2, button.y - th_title - 40)
    love.graphics.setFont(default_font)

    if button.hovered then
        love.graphics.setColor(0.5, 0.5, 0.6, 0.95)
    else
        love.graphics.setColor(0.3, 0.3, 0.4, 0.9)
    end
    love.graphics.rectangle("fill", button.x, button.y, button.width, button.height)

    love.graphics.setColor(1, 1, 1, 1)
    love.graphics.rectangle("line", button.x, button.y, button.width, button.height)

    local tw, th = default_font:getWidth(button.text), default_font:getHeight()
    love.graphics.print(button.text, button.x + (button.width - tw) / 2, button.y + (button.height - th) / 2)
end

function menu.mousepressed(x, y, button_num)
    if button_num == 1 and button.hovered then
        -- battle scene
        scene_manager.switch(enemy_select_scene)
    end
end

return menu 