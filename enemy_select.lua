local Scene       = require('scene')
local BattleScene = require('battle')

local enemy_select = {}

----------------------------------------------------------
-- CONFIGURATION
----------------------------------------------------------
local BUTTON_WIDTH       = 300
local BUTTON_HEIGHT      = 80
local BUTTON_MARGIN      = 12
local CONTAINER_PADDING  = 24
local VISIBLE_COUNT      = 4
local SLIDER_WIDTH       = 12

local COLORS = {
    background       = {0.15, 0.15, 0.18},
    container        = {0.22, 0.22, 0.28},
    containerLine    = {0.5,  0.5,  0.6 },
    buttonIdleTint   = {1, 1, 1, 0.3},
    buttonHoverTint  = {1, 1, 1, 0.55},
    battleBtnIdle    = {0.35, 0.35, 0.45},
    battleBtnHover   = {0.55, 0.55, 0.7 },
}

local descriptions = {
    [[Riverton, 2027 A.D.

District 04 has been overrun by the Everblood Cult—an extremist group blending occult rituals with unstable technology. Their presence has disrupted the fragile balance in Riverton, drawing attention from both local authorities and higher powers.

You are a thaumaturge, trained to identify and neutralize dangerous tech. Your mission is to investigate the cult's hideout, locate any devices or artifacts that pose a threat to public safety, and seal them before they can spread further harm.

Tensions are rising, and the invasion of Erebos looms on the horizon. What you uncover here could determine what comes next.]],
    [[Locked]],
    [[Locked]],
    [[Locked]],
    [[Locked]],
    [[Locked]],
    [[Locked]],
    [[Locked]],
    [[Locked]],
    [[Locked]],
}

local TOTAL_BUTTONS = #descriptions

local titles = {}
for i, desc in ipairs(descriptions) do
    local first_line = desc:match("(.-)\n") or string.format("Scenario %d", i)
    titles[i] = first_line
end

local scenario_enemy = {
    [1] = "occultist"
}

local buttons = {}
local container = {x = 0, y = 0, w = 0, h = 0}
local scrollY = 0
local draggingSlider = false
local sliderGrabOffset = 0
local currentIdx = nil

local battleButton = {w = 220, h = 60, x = 0, y = 0, hover = false}

local rivertonTexture, defaultTexture

local function build_buttons()
    buttons = {}
    for i = 1, TOTAL_BUTTONS do
        buttons[i] = {index = i, hover = false, drawY = 0}
    end
end

function enemy_select.enter()
    local sw, sh = love.graphics.getWidth(), love.graphics.getHeight()

    container.w = BUTTON_WIDTH + CONTAINER_PADDING * 2 + SLIDER_WIDTH
    container.h = VISIBLE_COUNT * BUTTON_HEIGHT + (VISIBLE_COUNT - 1) * BUTTON_MARGIN + CONTAINER_PADDING * 2
    container.x = 40
    container.y = (sh - container.h) / 2

    build_buttons()

    local startY = container.y + CONTAINER_PADDING
    for i, btn in ipairs(buttons) do
        btn.x = container.x + CONTAINER_PADDING
        btn.baseY = startY + (i - 1) * (BUTTON_HEIGHT + BUTTON_MARGIN)
        btn.w = BUTTON_WIDTH
        btn.h = BUTTON_HEIGHT
    end

    scrollY = 0
    currentIdx = nil
    draggingSlider = false

    if not rivertonTexture then
        pcall(function() rivertonTexture = love.graphics.newImage("scenarios/riverton.png") end)
    end
    if not defaultTexture then
        pcall(function() defaultTexture = love.graphics.newImage("landscape.jpg") end)
    end
end

function enemy_select.update(dt)
    local mx, my = love.mouse.getPosition()

    if draggingSlider then
        local trackY = container.y + CONTAINER_PADDING
        local trackH = container.h - CONTAINER_PADDING * 2
        local knobH = math.max(20, trackH * (VISIBLE_COUNT / TOTAL_BUTTONS))
        local newY = my - sliderGrabOffset
        newY = math.max(trackY, math.min(trackY + trackH - knobH, newY))
        local t = (newY - trackY) / (trackH - knobH)
        local maxScroll = (TOTAL_BUTTONS - VISIBLE_COUNT) * (BUTTON_HEIGHT + BUTTON_MARGIN)
        scrollY = t * maxScroll
    end

    for _, btn in ipairs(buttons) do
        local drawY = btn.baseY - scrollY
        btn.drawY = drawY
        btn.hover = mx >= btn.x and mx <= btn.x + btn.w and my >= drawY and my <= drawY + btn.h
    end

    if currentIdx then
        local textX = container.x + container.w + 40
        local rightPadding = 40
        local textW = love.graphics.getWidth() - textX - rightPadding
        local btnBottomY = container.y + container.h
        battleButton.x = textX + (textW - battleButton.w) / 2
        battleButton.y = btnBottomY - battleButton.h

        battleButton.hover = (mx >= battleButton.x and mx <= battleButton.x + battleButton.w) and (my >= battleButton.y and my <= battleButton.y + battleButton.h)
    else
        battleButton.hover = false
    end
end

function enemy_select.draw()
    love.graphics.setBackgroundColor(COLORS.background)

    love.graphics.setColor(COLORS.container)
    love.graphics.rectangle("fill", container.x, container.y, container.w, container.h, 8, 8)
    love.graphics.setColor(COLORS.containerLine)
    love.graphics.setLineWidth(2)
    love.graphics.rectangle("line", container.x, container.y, container.w, container.h, 8, 8)

    local clipX = container.x + CONTAINER_PADDING
    local clipY = container.y + CONTAINER_PADDING
    local clipW = BUTTON_WIDTH
    local clipH = container.h - CONTAINER_PADDING * 2
    love.graphics.setScissor(clipX, clipY, clipW, clipH)

    for _, btn in ipairs(buttons) do
        local y = btn.drawY
        if y + btn.h >= clipY and y <= clipY + clipH then
            local tex = (btn.index == 1) and rivertonTexture or defaultTexture
            if tex then
                local sx = math.max(btn.x, clipX)
                local sy = math.max(y, clipY)
                local ex = math.min(btn.x + btn.w, clipX + clipW)
                local ey = math.min(y + btn.h, clipY + clipH)
                local sw = ex - sx
                local sh = ey - sy
                if sw > 0 and sh > 0 then
                    love.graphics.setScissor(sx, sy, sw, sh)
                end
                love.graphics.setColor(1, 1, 1)
                local texW, texH = tex:getDimensions()
                local scale = math.max(btn.w / texW, btn.h / texH)
                local drawW = texW * scale
                local drawH = texH * scale
                local offsetX = btn.x + (btn.w - drawW) / 2
                local offsetY = y + (btn.h - drawH) / 2
                love.graphics.draw(tex, offsetX, offsetY, 0, scale, scale)
                love.graphics.setScissor(clipX, clipY, clipW, clipH)
            else
                love.graphics.setColor(0.45, 0.45, 0.55)
                love.graphics.rectangle("fill", btn.x, y, btn.w, btn.h, 6, 6)
            end

            if btn.hover then
                love.graphics.setColor(COLORS.buttonHoverTint)
            else
                love.graphics.setColor(COLORS.buttonIdleTint)
            end
            love.graphics.rectangle("fill", btn.x, y, btn.w, btn.h, 6, 6)

            love.graphics.setColor(0, 0, 0, 0.6)
            love.graphics.setLineWidth(1)
            love.graphics.rectangle("line", btn.x, y, btn.w, btn.h, 6, 6)

            local title = titles[btn.index] or ("Scenario " .. btn.index)
            local font = love.graphics.getFont()
            local tw = font:getWidth(title)
            local th = font:getHeight()
            local textX = btn.x + (btn.w - tw) / 2
            local textY = y + (btn.h - th) / 2

            local pad = 4
            love.graphics.setColor(0, 0, 0, 0.7)
            love.graphics.rectangle("fill", textX - pad, textY - pad, tw + pad * 2, th + pad * 2)

            love.graphics.setColor(1, 1, 1)
            love.graphics.print(title, textX, textY)
        end
    end

    love.graphics.setScissor()

    local trackX = container.x + container.w - SLIDER_WIDTH - CONTAINER_PADDING / 2
    local trackY = container.y + CONTAINER_PADDING
    local trackH = container.h - CONTAINER_PADDING * 2
    love.graphics.setColor(0, 0, 0, 0.2)
    love.graphics.rectangle("fill", trackX, trackY, SLIDER_WIDTH, trackH, 6, 6)

    local knobH = math.max(20, trackH * (VISIBLE_COUNT / TOTAL_BUTTONS))
    local maxScroll = (TOTAL_BUTTONS - VISIBLE_COUNT) * (BUTTON_HEIGHT + BUTTON_MARGIN)
    local t = (maxScroll == 0) and 0 or (scrollY / maxScroll)
    local knobY = trackY + (trackH - knobH) * t
    love.graphics.setColor(0.6, 0.6, 0.7)
    love.graphics.rectangle("fill", trackX, knobY, SLIDER_WIDTH, knobH, 6, 6)
    love.graphics.setColor(0.3, 0.3, 0.4)
    love.graphics.setLineWidth(1)
    love.graphics.rectangle("line", trackX, knobY, SLIDER_WIDTH, knobH, 6, 6)

    if currentIdx then
        local desc = descriptions[currentIdx] or "No description."
        local textX = container.x + container.w + 40
        local textY = container.y
        local textW = love.graphics.getWidth() - textX - 40
        love.graphics.setColor(1, 1, 1)
        love.graphics.printf(desc, textX, textY, textW)

        if battleButton.hover then
            love.graphics.setColor(COLORS.battleBtnHover)
        else
            love.graphics.setColor(COLORS.battleBtnIdle)
        end
        love.graphics.rectangle("fill", battleButton.x, battleButton.y, battleButton.w, battleButton.h, 8, 8)
        love.graphics.setColor(0, 0, 0, 0.6)
        love.graphics.setLineWidth(2)
        love.graphics.rectangle("line", battleButton.x, battleButton.y, battleButton.w, battleButton.h, 8, 8)
        love.graphics.setColor(0, 0, 0)
        local label = "Commence Battle"
        local font = love.graphics.getFont()
        local tw = font:getWidth(label)
        local th = font:getHeight()
        love.graphics.print(label, battleButton.x + (battleButton.w - tw) / 2, battleButton.y + (battleButton.h - th) / 2)
    end
end

function enemy_select.mousepressed(x, y, button)
    if button == 1 then
        if currentIdx and battleButton.hover then
            local enemy_key = scenario_enemy[currentIdx]
            if enemy_key then
                Scene.switch(BattleScene, enemy_key)
            else
                print("Scenario not implemented yet.")
            end
            return
        end

        local trackX = container.x + container.w - SLIDER_WIDTH - CONTAINER_PADDING / 2
        local trackY = container.y + CONTAINER_PADDING
        local trackH = container.h - CONTAINER_PADDING * 2
        local knobH = math.max(20, trackH * (VISIBLE_COUNT / TOTAL_BUTTONS))
        local maxScroll = (TOTAL_BUTTONS - VISIBLE_COUNT) * (BUTTON_HEIGHT + BUTTON_MARGIN)
        local t = (maxScroll == 0) and 0 or (scrollY / maxScroll)
        local knobY = trackY + (trackH - knobH) * t
        if x >= trackX and x <= trackX + SLIDER_WIDTH and y >= knobY and y <= knobY + knobH then
            draggingSlider = true
            sliderGrabOffset = y - knobY
            return
        end

        for _, btn in ipairs(buttons) do
            if x >= btn.x and x <= btn.x + btn.w and y >= btn.drawY and y <= btn.drawY + btn.h then
                currentIdx = btn.index
                return
            end
        end
    end
end

function enemy_select.mousereleased(_, _, button)
    if button == 1 then
        draggingSlider = false
    end
end

function enemy_select.wheelmoved(_, dy)
    if dy ~= 0 then
        local maxScroll = (TOTAL_BUTTONS - VISIBLE_COUNT) * (BUTTON_HEIGHT + BUTTON_MARGIN)
        if maxScroll <= 0 then return end
        scrollY = scrollY - dy * BUTTON_HEIGHT
        scrollY = math.max(0, math.min(maxScroll, scrollY))
    end
end

return enemy_select 