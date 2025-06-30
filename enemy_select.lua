-- enemy_select.lua
-- Scene to choose an enemy to battle

local Scene = require('scene')
local BattleScene = require('battle')

local enemy_select = {}

local buttons = {}
local GRID_COLS, GRID_ROWS = 3, 3
local BTN_W, BTN_H = 150, 60
local GAP = 20

local function create_buttons()
    buttons = {}
    local total_w = GRID_COLS * BTN_W + (GRID_COLS-1)*GAP
    local total_h = GRID_ROWS * BTN_H + (GRID_ROWS-1)*GAP
    local start_x = love.graphics.getWidth()/2 - total_w/2
    local start_y = love.graphics.getHeight()/2 - total_h/2
    local idx = 1
    for r=1,GRID_ROWS do
        for c=1,GRID_COLS do
            local btn = {
                x = start_x + (c-1)*(BTN_W+GAP),
                y = start_y + (r-1)*(BTN_H+GAP),
                width = BTN_W,
                height = BTN_H,
                text = "", hovered=false, id=idx
            }
            -- Assign labels
            if idx==1 then btn.text="Dummy" btn.enemy_key="dummy"
            elseif idx==2 then btn.text="Occultist" btn.enemy_key="occultist"
            else btn.text="" btn.enemy_key=nil end
            table.insert(buttons, btn)
            idx = idx + 1
        end
    end
end

function enemy_select.enter()
    create_buttons()
end

function enemy_select.update(dt)
    local mx,my = love.mouse.getX(), love.mouse.getY()
    for _,b in ipairs(buttons) do
        b.hovered = mx>=b.x and mx<=b.x+b.width and my>=b.y and my<=b.y+b.height
    end
end

function enemy_select.draw()
    love.graphics.clear(0.12,0.12,0.15)
    local font = love.graphics.getFont()
    for _,b in ipairs(buttons) do
        if b.hovered then love.graphics.setColor(0.35,0.35,0.4,0.9) else love.graphics.setColor(0.25,0.25,0.3,0.8) end
        love.graphics.rectangle("fill", b.x, b.y, b.width, b.height)
        love.graphics.setColor(1,1,1,1)
        love.graphics.rectangle("line", b.x, b.y, b.width, b.height)
        local tw = font:getWidth(b.text)
        local th = font:getHeight()
        love.graphics.print(b.text, b.x + (b.width-tw)/2, b.y + (b.height-th)/2)
    end
end

function enemy_select.mousepressed(x,y,button)
    if button==1 then
        for _,b in ipairs(buttons) do
            if x>=b.x and x<=b.x+b.width and y>=b.y and y<=b.y+b.height then
                if b.enemy_key then
                    Scene.switch(BattleScene, b.enemy_key)
                end
                return
            end
        end
    end
end

return enemy_select 