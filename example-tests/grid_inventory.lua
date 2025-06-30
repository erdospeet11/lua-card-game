-- main.lua
-- Simple inventory grid with one draggable item ---------------------------------

-------------------------------------------------------------------
-- CONFIGURATION
-------------------------------------------------------------------
local GRID_ROWS      = 4            -- number of rows
local GRID_COLS      = 5            -- number of columns
local SLOT_SIZE      = 80           -- pixel size of each square slot
local SLOT_PADDING   = 8            -- space between slots (both axes)
local INV_ORIGIN_X   = 100          -- top-left corner of inventory grid
local INV_ORIGIN_Y   = 100

-------------------------------------------------------------------
-- ITEM STATE
-------------------------------------------------------------------
local item = {
    slotRow = 1,           -- initial slot (row)
    slotCol = 1,           -- initial slot (column)
    dragging = false,      -- are we currently dragging?
    dragOffsetX = 0,       -- offset between mouse and item top-left while dragging
    dragOffsetY = 0,
    origRow = 1,           -- slot row before drag begins (for reverting)
    origCol = 1,
    present  = true,       -- whether the item exists (false after DROP)
}

-------------------------------------------------------------------
-- CONTEXT MENU STATE
-------------------------------------------------------------------
local menu = {
    visible = false,
    x = 0,
    y = 0,
    optionHeight = 24,
    width = 100,
}
function menu:getHeight()
    return self.optionHeight * 2
end

-------------------------------------------------------------------
-- HELPER FUNCTIONS
-------------------------------------------------------------------
-- Converts slot coordinates (row, col) to top-left screen position
local function slotToPos(row, col)
    local x = INV_ORIGIN_X + (col - 1) * (SLOT_SIZE + SLOT_PADDING)
    local y = INV_ORIGIN_Y + (row - 1) * (SLOT_SIZE + SLOT_PADDING)
    return x, y
end

-- Determines which slot (row,col) a screen coordinate is over; returns nil if none
local function posToSlot(x, y)
    for row = 1, GRID_ROWS do
        for col = 1, GRID_COLS do
            local sx, sy = slotToPos(row, col)
            if x >= sx and x < sx + SLOT_SIZE and y >= sy and y < sy + SLOT_SIZE then
                return row, col
            end
        end
    end
    return nil
end

-------------------------------------------------------------------
-- LOVE CALLBACKS
-------------------------------------------------------------------
function love.load()
    love.window.setTitle("Inventory Drag-and-Drop Demo")
    love.window.setMode(800, 600)
end

function love.draw()
    love.graphics.setBackgroundColor(0.15, 0.15, 0.18)

    -- Draw grid slots
    for row = 1, GRID_ROWS do
        for col = 1, GRID_COLS do
            local x, y = slotToPos(row, col)
            love.graphics.setColor(0.25, 0.25, 0.3)
            love.graphics.rectangle("fill", x, y, SLOT_SIZE, SLOT_SIZE, 6, 6)
            love.graphics.setColor(0.5, 0.5, 0.6)
            love.graphics.setLineWidth(2)
            love.graphics.rectangle("line", x, y, SLOT_SIZE, SLOT_SIZE, 6, 6)
        end
    end

    -- Draw item (white rectangle)
    if item.present then
        local drawX, drawY
        if item.dragging then
            local mx, my = love.mouse.getPosition()
            drawX = mx - item.dragOffsetX
            drawY = my - item.dragOffsetY
        else
            drawX, drawY = slotToPos(item.slotRow, item.slotCol)
        end

        love.graphics.setColor(1, 1, 1)
        love.graphics.rectangle("fill", drawX + 8, drawY + 8, SLOT_SIZE - 16, SLOT_SIZE - 16, 4, 4)
        love.graphics.setColor(0.1, 0.1, 0.1)
        love.graphics.setLineWidth(2)
        love.graphics.rectangle("line", drawX + 8, drawY + 8, SLOT_SIZE - 16, SLOT_SIZE - 16, 4, 4)
    end

    -- Draw context menu if visible
    if menu.visible then
        love.graphics.setColor(0.05, 0.05, 0.08, 0.95)
        love.graphics.rectangle("fill", menu.x, menu.y, menu.width, menu:getHeight(), 4, 4)
        love.graphics.setColor(0.8, 0.8, 0.9)
        love.graphics.setLineWidth(2)
        love.graphics.rectangle("line", menu.x, menu.y, menu.width, menu:getHeight(), 4, 4)

        -- Draw options text
        love.graphics.setColor(1,1,1)
        love.graphics.printf("USE", menu.x, menu.y + 4, menu.width, "center")
        love.graphics.printf("DROP", menu.x, menu.y + 4 + menu.optionHeight, menu.width, "center")
    end

    -- Helper text
    love.graphics.setColor(1, 1, 1)
    love.graphics.print("Left-drag to move item. Right-click item for menu.", 10, 10)
end

function love.mousepressed(x, y, button)
    -- If context menu is open, handle clicks inside it first
    if menu.visible then
        if button == 1 then
            -- Determine which option selected
            if x >= menu.x and x <= menu.x + menu.width and y >= menu.y and y <= menu.y + menu:getHeight() then
                local optionIndex = math.floor((y - menu.y) / menu.optionHeight) + 1
                if optionIndex == 1 then -- USE
                    print("USE action triggered")
                elseif optionIndex == 2 then -- DROP
                    print("DROP action triggered")
                    item.present = false
                end
            end
            menu.visible = false
        elseif button == 2 then
            menu.visible = false
        end
        return
    end

    if button == 1 and not item.dragging and item.present then
        -- Check if click hits the item in its current position
        local ix, iy = slotToPos(item.slotRow, item.slotCol)
        local innerX, innerY = ix + 8, iy + 8
        local innerSize = SLOT_SIZE - 16
        if x >= innerX and x <= innerX + innerSize and y >= innerY and y <= innerY + innerSize then
            -- Begin drag
            item.dragging = true
            item.dragOffsetX = x - ix
            item.dragOffsetY = y - iy
            item.origRow = item.slotRow
            item.origCol = item.slotCol
        end
    elseif button == 2 and item.present then -- right click
        -- Open context menu if right-click over slot containing item
        local row, col = posToSlot(x, y)
        if row and col and row == item.slotRow and col == item.slotCol then
            menu.visible = true
            menu.x = x
            menu.y = y
        else
            menu.visible = false
        end
    end
end

function love.mousereleased(x, y, button)
    if button == 1 and item.dragging then
        -- Attempt to place in slot under cursor
        local row, col = posToSlot(x, y)
        if row and col then
            item.slotRow = row
            item.slotCol = col
        else
            -- Revert to original slot
            item.slotRow = item.origRow
            item.slotCol = item.origCol
        end
        item.dragging = false
    elseif button == 1 and not menu.visible then
        -- Left click outside menu closes it (in case it was open by other means)
        menu.visible = false
    end
end 