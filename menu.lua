local scene_manager = require('scene')
local enemy_select_scene = require('enemy_select')

local menu = {}

-- Button definitions
local buttons = {
    {
        id = "scenarios",
        text = "SCENARIOS",
        action = function() scene_manager.switch(enemy_select_scene) end,
        tooltip = "Play through different kind of scenarios to be familiar with the game and story",
        locked = false
    },
    {
        id = "endless",
        text = "ENDLESS",
        action = function() print("Endless mode not implemented yet") end,
        tooltip = "Play against enemies in a free form battle. Currently LOCKED",
        locked = true
    },
    {
        id = "settings",
        text = "SETTINGS",
        action = function() print("Settings not implemented yet") end,
        tooltip = "Configure game settings and preferences",
        locked = false
    },
    {
        id = "exit",
        text = "EXIT",
        action = function() love.event.quit() end,
        tooltip = "Exit the game",
        locked = false
    }
}

local button_config = {
    width = 200,
    height = 50,
    spacing = 2,
    start_y_offset = 0
}

local title_font = nil
local space_shader = nil
local shader_time = 0
local hovered_button = nil
local tooltip_timer = 0

function menu.enter()
    local sw, sh = love.graphics.getWidth(), love.graphics.getHeight()
    
    local total_height = (#buttons * button_config.height) + ((#buttons - 1) * button_config.spacing)
    local start_y = (sh - total_height) / 2 + button_config.start_y_offset
    
    for i, button in ipairs(buttons) do
        button.x = sw / 2 - button_config.width / 2
        button.y = start_y + (i - 1) * (button_config.height + button_config.spacing)
        button.width = button_config.width
        button.height = button_config.height
        button.hovered = false
    end

    if not title_font then
        title_font = love.graphics.newFont(48)
    end
    
    if not space_shader then
        local shader_code = love.filesystem.read("space.glsl")
        if shader_code then
            space_shader = love.graphics.newShader(shader_code)
        else
            print("Warning: Could not load space.glsl shader")
        end
    end
    
    shader_time = 0
    hovered_button = nil
    tooltip_timer = 0
end

function menu.update(dt)
    local mx, my = love.mouse.getX(), love.mouse.getY()
    
    local prev_hovered = hovered_button
    hovered_button = nil
    
    for _, button in ipairs(buttons) do
        button.hovered = mx >= button.x and mx <= button.x + button.width and
                        my >= button.y and my <= button.y + button.height
        if button.hovered then
            hovered_button = button
        end
    end
    
    if hovered_button == prev_hovered and hovered_button then
        tooltip_timer = tooltip_timer + dt
    else
        tooltip_timer = 0
    end
    
    shader_time = shader_time + dt
end

function menu.draw()
    local sw, sh = love.graphics.getWidth(), love.graphics.getHeight()
    
    if space_shader then
        love.graphics.setShader(space_shader)
        space_shader:send("time", shader_time)
        space_shader:send("resolution", {sw, sh})
        love.graphics.setColor(1, 1, 1, 1)
        love.graphics.rectangle("fill", 0, 0, sw, sh)
        love.graphics.setShader()
    else
        love.graphics.clear(0.1, 0.1, 0.15)
    end

    local default_font = love.graphics.getFont()
    love.graphics.setFont(title_font)
    local title = "KOZMOZ"
    local tw_title = title_font:getWidth(title)
    local th_title = title_font:getHeight()
    
    local title_x = sw / 2 - tw_title / 2
    local title_y = buttons[1].y - th_title - 60
    
    -- Add background for title for better visibility
    love.graphics.setColor(0, 0, 0, 0.6)
    love.graphics.rectangle("fill", title_x - 10, title_y - 10, tw_title + 20, th_title + 20)
    
    love.graphics.setColor(1,1,1,1)
    love.graphics.print(title, title_x, title_y)
    love.graphics.setFont(default_font)

    -- Draw buttons
    -- First, draw unified background for all buttons
    local first_button = buttons[1]
    local last_button = buttons[#buttons]
    local container_height = (last_button.y + last_button.height) - first_button.y
    
    love.graphics.setColor(0.2, 0.2, 0.25, 0.95)
    love.graphics.rectangle("fill", first_button.x, first_button.y, button_config.width, container_height)
    love.graphics.setColor(1, 1, 1, 1)
    love.graphics.rectangle("line", first_button.x, first_button.y, button_config.width, container_height)
    
    for i, button in ipairs(buttons) do
        local button_color, text_color
        
        if button.locked then
            -- Locked button styling
            if button.hovered then
                button_color = {0.25, 0.25, 0.35, 0.6}
            else
                button_color = {0.1, 0.1, 0.15, 0.4} -- Subtle background for locked state
            end
            text_color = {0.5, 0.5, 0.5, 1}
        else
            -- Normal button styling
            if button.hovered then
                button_color = {0.4, 0.4, 0.5, 0.8}
            else
                button_color = {0, 0, 0, 0} -- Transparent, use container background
            end
            text_color = {1, 1, 1, 1}
        end
        
        -- Only draw button background if hovered or locked
        if button.hovered or button.locked then
            love.graphics.setColor(button_color)
            love.graphics.rectangle("fill", button.x, button.y, button.width, button.height)
        end

        local tw, th = default_font:getWidth(button.text), default_font:getHeight()
        love.graphics.setColor(text_color)
        love.graphics.print(button.text, button.x + (button.width - tw) / 2, button.y + (button.height - th) / 2)
        
        -- Draw lock icon for locked buttons
        if button.locked then
            love.graphics.setColor(0.5, 0.5, 0.5, 1)
            local lock_size = 12
            local lock_x = button.x + button.width - lock_size - 8
            local lock_y = button.y + 8
            love.graphics.rectangle("line", lock_x, lock_y, lock_size, lock_size)
            love.graphics.rectangle("fill", lock_x + 2, lock_y + 6, lock_size - 4, lock_size - 6)
        end
        
        -- Draw separator line below button (except for last button)
        if i < #buttons then
            love.graphics.setColor(0.4, 0.4, 0.5, 0.6)
            local sep_y = button.y + button.height + 1
            love.graphics.rectangle("fill", button.x + 10, sep_y, button.width - 20, 1)
        end
    end
    
    -- Draw tooltip
    if hovered_button and tooltip_timer > 0.5 then -- Show tooltip after 0.5 seconds
        local font = love.graphics.getFont()
        local tooltip_text = hovered_button.tooltip
        local tooltip_width = font:getWidth(tooltip_text) + 20
        local tooltip_height = font:getHeight() + 10
        
        local tooltip_x = hovered_button.x + hovered_button.width + 10
        local tooltip_y = hovered_button.y + (hovered_button.height - tooltip_height) / 2
        
        -- Keep tooltip on screen
        if tooltip_x + tooltip_width > sw then
            tooltip_x = hovered_button.x - tooltip_width - 10
        end
        if tooltip_y + tooltip_height > sh then
            tooltip_y = sh - tooltip_height - 10
        end
        if tooltip_y < 0 then
            tooltip_y = 10
        end
        
        -- Draw tooltip background
        love.graphics.setColor(0, 0, 0, 0.9)
        love.graphics.rectangle("fill", tooltip_x, tooltip_y, tooltip_width, tooltip_height)
        love.graphics.setColor(1, 1, 1, 1)
        love.graphics.rectangle("line", tooltip_x, tooltip_y, tooltip_width, tooltip_height)
        
        -- Draw tooltip text
        love.graphics.print(tooltip_text, tooltip_x + 10, tooltip_y + 5)
    end
end

function menu.mousepressed(x, y, button_num)
    if button_num == 1 then
        for _, button in ipairs(buttons) do
            if button.hovered and not button.locked and button.action then
                button.action()
                break
            end
        end
    end
end

return menu 