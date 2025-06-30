-- enemy_select.lua
-- Scenario selection scene with scrollable list of scenarios.
-- First scenario starts a battle against the Occultist enemy.

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
local VISIBLE_COUNT      = 4        -- how many buttons visible at once
local SLIDER_WIDTH       = 12

-- Colours (r,g,b,a)
local COLORS = {
    background       = {0.15, 0.15, 0.18},
    container        = {0.22, 0.22, 0.28},
    containerLine    = {0.5,  0.5,  0.6 },
    buttonIdleTint   = {1, 1, 1, 0.3},
    buttonHoverTint  = {1, 1, 1, 0.55},
    battleBtnIdle    = {0.35, 0.35, 0.45},
    battleBtnHover   = {0.55, 0.55, 0.7 },
}

----------------------------------------------------------
-- DATA
----------------------------------------------------------
local descriptions = {
    [[Riverton, 2027 A.D.

District 04 has been overrun by the Everblood Cult—an extremist group blending occult rituals with unstable technology. Their presence has disrupted the fragile balance in Riverton, drawing attention from both local authorities and higher powers.

You are a thaumaturge, trained to identify and neutralize dangerous tech. Your mission is to investigate the cult's hideout, locate any devices or artifacts that pose a threat to public safety, and seal them before they can spread further harm.

Tensions are rising, and the invasion of Erebos looms on the horizon. What you uncover here could determine what comes next.]],
    [[Athens, 430 B.C.

The Peloponnesian War rages just beyond the Long Walls. Inside, a choking plague turns bustling agoras into funeral processions. Philosophers debate fate and duty, their words echoing off empty stoa. Hoplites sharpen spears on the Pnyx, yet dread rather than glory hangs over the polis.]],
    [[Alexandria, 30 B.C.

Pharos lighthouse still blazes, guiding ships to the greatest library the world has known, but scrolls are being packed for flight. Cleopatra, last of the Ptolemies, weighs surrender against legend as Octavian's legions draw near. Palm-lined streets bustle, unaware how close they stand to empire's twilight.]],
    [[Sparta, 480 B.C.

Bronze shields clatter in rigorous cadence. Blood-red cloaks billow as King Leonidas chooses three-hundred warriors for a desperate stand at Thermopylae. Mothers mix pride with foreboding; helots whisper of prophecy. The scent of olive groves cannot mask the iron tang of destiny.]],
    [[Babylon, 600 B.C.

Nebuchadnezzar II oversees terraced gardens that defy desert winds—hanging wonders dripping with jasmine and cypress. Along the Processional Way, blue-glazed lions guard Ishtar Gate while astronomers chart wandering stars atop ziggurats, convinced they converse with gods themselves.]],
    [[Constantinople, 1453 A.D.

Gunpowder smoke clouds the Golden Horn. Inside Hagia Sophia candles burn day and night as citizens pray for deliverance. Outside, Mehmet's cannons hammer ancient walls that once defied a thousand sieges. The last ember of Rome flickers, poised between legend and conquest.]],
    [[Paris, 1789 A.D.

Bread lines snake beneath Gothic spires; words like "liberté" ignite salons and taverns alike. The Bastille's shadow looms, both prison and symbol. Aristocrats plan midnight departures while pamphleteers ink manifestos promising a dawn of equality—by guillotine if need be.]],
    [[London, 1666 A.D.

Summer drought has turned timber houses into tinder. From Pudding Lane a spark leaps, racing across thatched roofs. Samuel Pepys scribbles frantically as firestorms light the night sky. On the Thames, panicked barges ferry goods while St. Paul's future hangs in ash-choked air.]],
    [[New York, 1920 A.D.

Prohibition's ban can't silence Harlem's trumpets. Elevated trains rattle above streets where flappers dodge Model-T traffic. Rum-runners offload crates on foggy piers, and somewhere in a smoke-filled backroom, a young Fitzgerald drafts the Jazz Age into immortality.]],
    [[Kyoto, 1600 A.D.

Maple leaves drift through crimson gates of Fushimi Castle as Tokugawa forces march west. Tea masters prepare ceremonies in fragile stillness, unaware that Sekigahara's battle will redraw the realm by dawn. Lanterns glow along silent canals, reflecting an era's final breaths.]],
}

local TOTAL_BUTTONS = #descriptions

-- Pre-computed titles (first line of each description)
local titles = {}
for i, desc in ipairs(descriptions) do
    local first_line = desc:match("(.-)\n") or string.format("Scenario %d", i)
    titles[i] = first_line
end

-- scenario to enemy map: only first scenario implemented
local scenario_enemy = {
    [1] = "occultist"
}

-- runtime state
local buttons = {}
local container = {x = 0, y = 0, w = 0, h = 0}
local scrollY = 0
local draggingSlider = false
local sliderGrabOffset = 0
local currentIdx = nil        -- currently selected scenario index

-- battle button properties
local battleButton = {w = 220, h = 60, x = 0, y = 0, hover = false}

-- texture placeholders (filled in enter)
local rivertonTexture, defaultTexture

----------------------------------------------------------
-- Helper functions
----------------------------------------------------------
local function build_buttons()
    buttons = {}
    for i = 1, TOTAL_BUTTONS do
        buttons[i] = {index = i, hover = false, drawY = 0}
    end
end

----------------------------------------------------------
-- Scene lifecycle
----------------------------------------------------------
function enemy_select.enter()
    local sw, sh = love.graphics.getWidth(), love.graphics.getHeight()

    -- Build UI geometry.
    container.w = BUTTON_WIDTH + CONTAINER_PADDING * 2 + SLIDER_WIDTH
    container.h = VISIBLE_COUNT * BUTTON_HEIGHT + (VISIBLE_COUNT - 1) * BUTTON_MARGIN + CONTAINER_PADDING * 2
    container.x = 40
    container.y = (sh - container.h) / 2

    build_buttons()

    -- Pre-compute button base positions
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

    -- Load textures once
    if not rivertonTexture then
        pcall(function() rivertonTexture = love.graphics.newImage("scenarios/riverton.png") end)
    end
    if not defaultTexture then
        pcall(function() defaultTexture = love.graphics.newImage("landscape.jpg") end)
    end
end

function enemy_select.update(dt)
    local mx, my = love.mouse.getPosition()

    -- Slider dragging
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

    -- Update hover states on buttons
    for _, btn in ipairs(buttons) do
        local drawY = btn.baseY - scrollY
        btn.drawY = drawY
        btn.hover = mx >= btn.x and mx <= btn.x + btn.w and my >= drawY and my <= drawY + btn.h
    end

    -- Update battle button hover when description shown
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

    -- Container background
    love.graphics.setColor(COLORS.container)
    love.graphics.rectangle("fill", container.x, container.y, container.w, container.h, 8, 8)
    love.graphics.setColor(COLORS.containerLine)
    love.graphics.setLineWidth(2)
    love.graphics.rectangle("line", container.x, container.y, container.w, container.h, 8, 8)

    -- Scissor inside container (exclude slider)
    local clipX = container.x + CONTAINER_PADDING
    local clipY = container.y + CONTAINER_PADDING
    local clipW = BUTTON_WIDTH
    local clipH = container.h - CONTAINER_PADDING * 2
    love.graphics.setScissor(clipX, clipY, clipW, clipH)

    -- Draw buttons
    for _, btn in ipairs(buttons) do
        local y = btn.drawY
        if y + btn.h >= clipY and y <= clipY + clipH then
            -- Draw texture background if available
            local tex = (btn.index == 1) and rivertonTexture or defaultTexture
            if tex then
                -- Clip to the intersection of button rect and container clip so nothing bleeds while scrolling
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
                local scale = math.max(btn.w / texW, btn.h / texH) -- cover
                local drawW = texW * scale
                local drawH = texH * scale
                local offsetX = btn.x + (btn.w - drawW) / 2
                local offsetY = y + (btn.h - drawH) / 2
                love.graphics.draw(tex, offsetX, offsetY, 0, scale, scale)
                -- Restore container scissor
                love.graphics.setScissor(clipX, clipY, clipW, clipH)
            else
                love.graphics.setColor(0.45, 0.45, 0.55)
                love.graphics.rectangle("fill", btn.x, y, btn.w, btn.h, 6, 6)
            end

            -- Overlay tint for hover/idle
            if btn.hover then
                love.graphics.setColor(COLORS.buttonHoverTint)
            else
                love.graphics.setColor(COLORS.buttonIdleTint)
            end
            love.graphics.rectangle("fill", btn.x, y, btn.w, btn.h, 6, 6)

            -- Outline
            love.graphics.setColor(0, 0, 0, 0.6)
            love.graphics.setLineWidth(1)
            love.graphics.rectangle("line", btn.x, y, btn.w, btn.h, 6, 6)

            -- Title text (centered)
            local title = titles[btn.index] or ("Scenario " .. btn.index)
            local font = love.graphics.getFont()
            local tw = font:getWidth(title)
            local th = font:getHeight()
            local textX = btn.x + (btn.w - tw) / 2
            local textY = y + (btn.h - th) / 2

            -- Draw background rectangle behind text
            local pad = 4
            love.graphics.setColor(0, 0, 0, 0.7)
            love.graphics.rectangle("fill", textX - pad, textY - pad, tw + pad * 2, th + pad * 2)

            -- Draw text (white for readability)
            love.graphics.setColor(1, 1, 1)
            love.graphics.print(title, textX, textY)
        end
    end

    love.graphics.setScissor() -- disable scissor

    -- Slider track
    local trackX = container.x + container.w - SLIDER_WIDTH - CONTAINER_PADDING / 2
    local trackY = container.y + CONTAINER_PADDING
    local trackH = container.h - CONTAINER_PADDING * 2
    love.graphics.setColor(0, 0, 0, 0.2)
    love.graphics.rectangle("fill", trackX, trackY, SLIDER_WIDTH, trackH, 6, 6)

    -- Slider knob
    local knobH = math.max(20, trackH * (VISIBLE_COUNT / TOTAL_BUTTONS))
    local maxScroll = (TOTAL_BUTTONS - VISIBLE_COUNT) * (BUTTON_HEIGHT + BUTTON_MARGIN)
    local t = (maxScroll == 0) and 0 or (scrollY / maxScroll)
    local knobY = trackY + (trackH - knobH) * t
    love.graphics.setColor(0.6, 0.6, 0.7)
    love.graphics.rectangle("fill", trackX, knobY, SLIDER_WIDTH, knobH, 6, 6)
    love.graphics.setColor(0.3, 0.3, 0.4)
    love.graphics.setLineWidth(1)
    love.graphics.rectangle("line", trackX, knobY, SLIDER_WIDTH, knobH, 6, 6)

    -- Description on right side
    if currentIdx then
        local desc = descriptions[currentIdx] or "No description."
        local textX = container.x + container.w + 40
        local textY = container.y
        local textW = love.graphics.getWidth() - textX - 40
        love.graphics.setColor(1, 1, 1)
        love.graphics.printf(desc, textX, textY, textW)

        -- Battle button
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

----------------------------------------------------------
-- Input handlers
----------------------------------------------------------
function enemy_select.mousepressed(x, y, button)
    if button == 1 then
        -- Check battle button first if visible
        if currentIdx and battleButton.hover then
            local enemy_key = scenario_enemy[currentIdx]
            if enemy_key then
                Scene.switch(BattleScene, enemy_key)
            else
                print("Scenario not implemented yet.")
            end
            return
        end

        -- Slider knob check
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

        -- Check buttons list
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
        scrollY = scrollY - dy * BUTTON_HEIGHT -- one button per wheel notch
        scrollY = math.max(0, math.min(maxScroll, scrollY))
    end
end

return enemy_select 