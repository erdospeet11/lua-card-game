-- battle.lua
-- Battle scene extracted from previous main.lua

local battle = {}

-- Bring in required modules
require('card')
require('board')
require('hand')
local card_bank = require('card_bank')
local Deck = require('deck')
local Scene = require('scene')

-- Character modules
local OccultistEnemyClass = require('occultist_enemy')
local PlayerClass = require('thaumaturge')

-- Local state variables
local player_hand, player_deck
local player_character, enemy_character
local combine_button = {}
local discard_button = {}

-- Enemy overlay vars
local enemy_message_active = false
local enemy_message_text = ""
local current_turn = 1

-- Victory popup vars
local victory_active = false
local victory_text = ""

-- Debug panel toggle
local debug_visible = false

-- Floating text window state
local text_window = {
    x = 100, y = 100,
    width = 300, height = 200,
    min_width = 150, min_height = 100,
    text = "",
    cursor_pos = 0,
    focused = false,
    dragging = false,
    resizing = false,
    drag_offset_x = 0,
    drag_offset_y = 0,
    resize_handle_size = 15
}

-- Forward declarations
local draw_player_tooltip, draw_debug_panel, draw_enemy_message, draw_victory_popup, draw_text_window

local defeat_font = love.graphics.newFont(20)

local function show_enemy_message(msg)
    if msg and msg ~= "" then
        enemy_message_text = msg
        enemy_message_active = true
    end
end

---------------------------------------------------------------------
-- SCENE LIFECYCLE --------------------------------------------------
---------------------------------------------------------------------
function battle.enter(enemy_key)
    -- Load assets first
    CardBack = love.graphics.newImage("card-back.png")

    print("Card-back.png dimensions: " .. CardBack:getWidth() .. "x" .. CardBack:getHeight())

    card_bank.load_face_images()

    player_hand = Hand:new()

    -- Deck setup (20 cards total)
    player_deck = Deck:new()

    local function add_multiple(id, count)
        for i = 1, count do
            local card = card_bank.create_card(id, 0, 0)
            player_deck:add_card(card)
        end
    end

    add_multiple(6, 4) -- Scripture
    add_multiple(7, 4) -- Innervate
    add_multiple(2, 4) -- Release Talisman
    add_multiple(3, 4) -- Binding Talisman
    add_multiple(5, 4) -- Small Trove
    player_deck:shuffle()

    for i = 1, 6 do
        local drawn = player_deck:draw_card()
        if drawn then player_hand:add_card(drawn) end
    end

    -- Buttons
    combine_button.width = 120
    combine_button.height = 50
    combine_button.x = love.graphics.getWidth() - combine_button.width - 30
    combine_button.y = love.graphics.getHeight() / 2 - 25
    combine_button.text = "COMBINE"
    combine_button.is_hovered = false

    discard_button.width = combine_button.width
    discard_button.height = combine_button.height
    discard_button.x = combine_button.x
    discard_button.y = combine_button.y + combine_button.height + 15
    discard_button.text = "DISCARD"
    discard_button.is_hovered = false

    -- Characters
    local sw, sh = love.graphics.getWidth(), love.graphics.getHeight()
    player_character = PlayerClass:new(sw / 2, sh - 100, 120, 160, player_deck)

    local enemy_map = {
        occultist = OccultistEnemyClass
    }
    local EnemyClass = enemy_map[enemy_key]
    enemy_character = EnemyClass:new(sw / 2, 120, 120, 160)

    current_turn = 1
end

function battle.update(dt)
    player_hand:update(dt)

    local mx, my = love.mouse.getX(), love.mouse.getY()
    player_character:update(dt, mx, my)
    if enemy_character.update then enemy_character:update(dt, mx, my) end

    combine_button.is_hovered = mx >= combine_button.x and mx <= combine_button.x + combine_button.width and
                               my >= combine_button.y and my <= combine_button.y + combine_button.height

    discard_button.is_hovered = mx >= discard_button.x and mx <= discard_button.x + discard_button.width and
                               my >= discard_button.y and my <= discard_button.y + discard_button.height

    -- Handle text window dragging
    if text_window.dragging then
        text_window.x = mx - text_window.drag_offset_x
        text_window.y = my - text_window.drag_offset_y
    end

    -- Handle text window resizing
    if text_window.resizing then
        local new_width = mx - text_window.x
        local new_height = my - text_window.y
        text_window.width = math.max(text_window.min_width, new_width)
        text_window.height = math.max(text_window.min_height, new_height)
    end
end

function battle.draw()
    love.graphics.clear(0.1, 0.1, 0.1)

    enemy_character:draw()
    -- Show tooltip on hover
    if enemy_character.is_hovered then draw_enemy_hover() end
    player_character:draw()

    player_hand:draw()

    -- Buttons
    local function draw_combine_button()
        if combine_button.is_hovered then
            love.graphics.setColor(0.3, 0.3, 0.3, 0.9)
        else
            love.graphics.setColor(0.2, 0.2, 0.2, 0.8)
        end
        love.graphics.rectangle("fill", combine_button.x, combine_button.y, combine_button.width, combine_button.height)
        love.graphics.setColor(1,1,1,1)
        love.graphics.rectangle("line", combine_button.x, combine_button.y, combine_button.width, combine_button.height)
        local font = love.graphics.getFont()
        local tw = font:getWidth(combine_button.text)
        local th = font:getHeight()
        love.graphics.print(combine_button.text, combine_button.x + (combine_button.width - tw)/2, combine_button.y + (combine_button.height - th)/2)
        love.graphics.setColor(1,1,1,1)
    end

    local function draw_discard_button()
        if discard_button.is_hovered then
            love.graphics.setColor(0.3, 0.3, 0.3, 0.9)
        else
            love.graphics.setColor(0.2, 0.2, 0.2, 0.8)
        end
        love.graphics.rectangle("fill", discard_button.x, discard_button.y, discard_button.width, discard_button.height)
        love.graphics.setColor(1,1,1,1)
        love.graphics.rectangle("line", discard_button.x, discard_button.y, discard_button.width, discard_button.height)
        local font = love.graphics.getFont()
        local tw = font:getWidth(discard_button.text)
        local th = font:getHeight()
        love.graphics.print(discard_button.text, discard_button.x + (discard_button.width - tw)/2, discard_button.y + (discard_button.height - th)/2)
        love.graphics.setColor(1,1,1,1)
    end

    draw_combine_button()
    draw_discard_button()

    -- Panels
    if debug_visible then draw_debug_panel() end
    draw_text_window()
    if player_character.is_hovered then draw_player_tooltip() end
    if enemy_message_active then draw_enemy_message() end
    if victory_active then draw_victory_popup() end

    -- Defeat condition text (top-right)
    love.graphics.setColor(1,1,1,1)
    local condition = enemy_character.defeat_text or ""
    if condition ~= "" then
        local default_font = love.graphics.getFont()
        love.graphics.setFont(defeat_font)
        local title = "To defeat " .. (enemy_character.class_name or "Enemy")
        local tw_title = defeat_font:getWidth(title)
        love.graphics.print(title, love.graphics.getWidth() - tw_title - 20, 20)

        local bullet = "- " .. condition
        local tw_bullet = defeat_font:getWidth(bullet)
        local line_height = defeat_font:getHeight()
        love.graphics.print(bullet, love.graphics.getWidth() - tw_bullet - 20, 20 + line_height + 5)
        love.graphics.setFont(default_font)
    end
end

-- draw_player_tooltip
function draw_player_tooltip()
    local font = love.graphics.getFont()
    local lines = {}
    table.insert(lines, player_character.class_name or "Player")
    if player_character.deck_ref then
        local deck = player_character.deck_ref
        table.insert(lines, string.format("Deck size: %d", deck:size()))
        local aggregated = {}
        for _, card in ipairs(deck.cards) do
            local id = card.id
            if aggregated[id] then aggregated[id].count = aggregated[id].count + 1 else aggregated[id] = {name=card.name, count=1} end
        end
        table.insert(lines, "Cards:")
        local ids = {}
        for id in pairs(aggregated) do table.insert(ids,id) end
        table.sort(ids)
        for _, id in ipairs(ids) do
            local entry = aggregated[id]
            table.insert(lines, string.format("%s x%d", entry.name, entry.count))
        end
    end
    local max_w = 0
    for _,ln in ipairs(lines) do
        local w = font:getWidth(ln)
        if w>max_w then max_w=w end
    end
    local lh = font:getHeight()
    local pw, ph = max_w+20, lh*#lines+20
    local tx = player_character.x - pw/2
    local ty = player_character.y - player_character.height/2 - ph - 10
    love.graphics.setColor(0,0,0,0.8)
    love.graphics.rectangle("fill", tx,ty,pw,ph)
    love.graphics.setColor(1,1,1,1)
    love.graphics.rectangle("line",tx,ty,pw,ph)
    local y=ty+10
    for _,ln in ipairs(lines) do
        love.graphics.print(ln, tx+10, y); y=y+lh end
    love.graphics.setColor(1,1,1,1)
end

-- draw_debug_panel
function draw_debug_panel()
    local font = love.graphics.getFont()
    local lines = {
        "DEBUG INFO",
        string.format("Deck size: %d", player_deck and player_deck:size() or 0),
        string.format("Hand size: %d", player_hand:get_card_count())
    }
    if player_deck then
        local aggregated = {}
        for _, card in ipairs(player_deck.cards) do
            local id = card.id
            if aggregated[id] then aggregated[id].count = aggregated[id].count + 1 else aggregated[id] = {name=card.name, count=1} end
        end
        table.insert(lines, "Cards in deck:")
        local ids = {}
        for id in pairs(aggregated) do table.insert(ids,id) end
        table.sort(ids)
        for _,id in ipairs(ids) do
            local e = aggregated[id]
            table.insert(lines, string.format("  %s x%d", e.name, e.count))
        end
    end
    local max_w=0
    for _,ln in ipairs(lines) do local w=font:getWidth(ln); if w>max_w then max_w=w end end
    local lh=font:getHeight()
    local pw,ph=max_w+20, lh*#lines+20
    love.graphics.setColor(0,0,0,0.7)
    love.graphics.rectangle("fill",10,10,pw,ph)
    love.graphics.setColor(1,1,1,1)
    love.graphics.rectangle("line",10,10,pw,ph)
    local y=20
    for _,ln in ipairs(lines) do love.graphics.print(ln,20,y); y=y+lh end
    love.graphics.setColor(1,1,1,1)
end

-- draw_enemy_message
function draw_enemy_message()
    local font = love.graphics.getFont()
    local text = enemy_message_text or ""
    local tw, th = font:getWidth(text), font:getHeight()
    local pad=15
    local pw, ph = tw+pad*2, th+pad*2
    local x = love.graphics.getWidth()/2 - pw/2
    local y = 180
    love.graphics.setColor(0,0,0,0.8)
    love.graphics.rectangle("fill",x,y,pw,ph)
    love.graphics.setColor(1,1,1,1)
    love.graphics.rectangle("line",x,y,pw,ph)
    love.graphics.print(text, x+pad, y+pad)
end

-- Tooltip for enemy
function draw_enemy_hover()
    local font = love.graphics.getFont()
    local text = enemy_character.class_name or "Enemy"
    local w = font:getWidth(text)
    local h = font:getHeight()
    local padding = 10
    local pw, ph = w + padding*2, h + padding*2
    local tx = enemy_character.x - pw/2
    local ty = enemy_character.y + enemy_character.height/2 + 10
    love.graphics.setColor(0,0,0,0.8)
    love.graphics.rectangle("fill", tx, ty, pw, ph)
    love.graphics.setColor(1,1,1,1)
    love.graphics.rectangle("line", tx, ty, pw, ph)
    love.graphics.print(text, tx + padding, ty + padding)
end

-- draw_victory_popup
function draw_victory_popup()
    local font = love.graphics.getFont()
    local text = victory_text ~= "" and victory_text or "Victory!"
    local tw, th = font:getWidth(text), font:getHeight()
    local pad = 20
    local pw, ph = tw + pad*2, th + pad*2
    local x = love.graphics.getWidth()/2 - pw/2
    local y = love.graphics.getHeight()/2 - ph/2

    love.graphics.setColor(0,0,0,0.85)
    love.graphics.rectangle("fill", x, y, pw, ph)
    love.graphics.setColor(1,1,1,1)
    love.graphics.rectangle("line", x, y, pw, ph)
    love.graphics.print(text, x + pad, y + pad)
end

-- draw_text_window
function draw_text_window()
    local font = love.graphics.getFont()
    
    -- Window background
    if text_window.focused then
        love.graphics.setColor(0.2, 0.2, 0.3, 0.9)
    else
        love.graphics.setColor(0.15, 0.15, 0.2, 0.8)
    end
    love.graphics.rectangle("fill", text_window.x, text_window.y, text_window.width, text_window.height)
    
    -- Window border
    if text_window.focused then
        love.graphics.setColor(0.6, 0.6, 0.8, 1)
    else
        love.graphics.setColor(0.4, 0.4, 0.5, 1)
    end
    love.graphics.setLineWidth(2)
    love.graphics.rectangle("line", text_window.x, text_window.y, text_window.width, text_window.height)
    
    -- Title bar
    love.graphics.setColor(0.3, 0.3, 0.4, 1)
    love.graphics.rectangle("fill", text_window.x, text_window.y, text_window.width, 25)
    love.graphics.setColor(1, 1, 1, 1)
    love.graphics.print("Notes", text_window.x + 5, text_window.y + 5)
    
    -- Text area
    local text_area_x = text_window.x + 5
    local text_area_y = text_window.y + 30
    local text_area_w = text_window.width - 10
    local text_area_h = text_window.height - 35
    
    -- Clip text to window bounds
    love.graphics.setScissor(text_area_x, text_area_y, text_area_w, text_area_h)
    
    -- Draw text
    love.graphics.setColor(1, 1, 1, 1)
    love.graphics.printf(text_window.text, text_area_x, text_area_y, text_area_w)
    
    -- Draw cursor if focused
    if text_window.focused then
        -- Calculate cursor position accounting for newlines
        local text_before_cursor = string.sub(text_window.text, 1, text_window.cursor_pos)
        
        -- Count newlines to determine line number
        local cursor_line = 0
        for i = 1, #text_before_cursor do
            if string.sub(text_before_cursor, i, i) == "\n" then
                cursor_line = cursor_line + 1
            end
        end
        
        -- Find the start of current line
        local line_start = 1
        local newline_pos = text_before_cursor:find("\n[^\n]*$")
        if newline_pos then
            line_start = newline_pos + 1
        end
        
        local current_line_text = string.sub(text_before_cursor, line_start)
        
        local cursor_x = text_area_x + font:getWidth(current_line_text)
        local cursor_y = text_area_y + cursor_line * font:getHeight()
        
        love.graphics.setColor(1, 1, 1, 0.8)
        love.graphics.rectangle("fill", cursor_x, cursor_y, 2, font:getHeight())
    end
    
    love.graphics.setScissor()
    
    -- Resize handle
    local handle_x = text_window.x + text_window.width - text_window.resize_handle_size
    local handle_y = text_window.y + text_window.height - text_window.resize_handle_size
    love.graphics.setColor(0.5, 0.5, 0.6, 0.8)
    love.graphics.rectangle("fill", handle_x, handle_y, text_window.resize_handle_size, text_window.resize_handle_size)
    
    love.graphics.setColor(1, 1, 1, 1)
end

---------------------------------------------------------------------
-- INPUT HANDLERS ----------------------------------------------------
---------------------------------------------------------------------

function battle.mousepressed(x,y,button)
    if victory_active then
        if button==1 then
            victory_active=false
            local MenuScene = require('menu')
            Scene.switch(MenuScene)
        end
        return
    end
    if enemy_message_active then enemy_message_active=false return end
    
    if button==1 then
        -- Check text window interactions first
        local in_window = x >= text_window.x and x <= text_window.x + text_window.width and
                         y >= text_window.y and y <= text_window.y + text_window.height
        
        -- Check resize handle
        local handle_x = text_window.x + text_window.width - text_window.resize_handle_size
        local handle_y = text_window.y + text_window.height - text_window.resize_handle_size
        local in_handle = x >= handle_x and x <= handle_x + text_window.resize_handle_size and
                         y >= handle_y and y <= handle_y + text_window.resize_handle_size
        
        if in_handle then
            text_window.resizing = true
            text_window.focused = true
            return
        elseif in_window then
            -- Check if clicking on title bar for dragging
            if y >= text_window.y and y <= text_window.y + 25 then
                text_window.dragging = true
                text_window.drag_offset_x = x - text_window.x
                text_window.drag_offset_y = y - text_window.y
            end
            text_window.focused = true
            -- Set cursor position based on click
            local text_area_x = text_window.x + 5
            local click_x = x - text_area_x
            local font = love.graphics.getFont()
            text_window.cursor_pos = 0
            for i = 1, #text_window.text do
                local width = font:getWidth(string.sub(text_window.text, 1, i))
                if width > click_x then
                    break
                end
                text_window.cursor_pos = i
            end
            return
        else
            -- Clicked outside window, lose focus
            text_window.focused = false
        end
        
        -- combine button
        if x>=combine_button.x and x<=combine_button.x+combine_button.width and y>=combine_button.y and y<=combine_button.y+combine_button.height then
            -- Similar logic as before
            print("Combine button clicked!")
            local cards_in_hand = player_hand:get_cards()
            local selected_cards = {}
            for _,card in ipairs(cards_in_hand) do if card.is_clicked then table.insert(selected_cards, card) end end
            print("Selected cards: "..#selected_cards)
            local selected_ids = {}
            for _,card in ipairs(selected_cards) do table.insert(selected_ids, card.id) end
            local recipe = card_bank.find_recipe(selected_ids)
            local to_remove = {}
            if recipe then
                -- If recipe defines custom resolution, execute it
                if recipe.custom then
                    recipe.custom(player_hand, player_deck)
                end

                -- Standard output
                local count = recipe.output_count or 0
                if count > 0 and recipe.output_id then
                    for i=1,count do
                        local new_card = card_bank.create_card(recipe.output_id,0,0)
                        player_hand:add_card(new_card)
                    end
                end
                -- All selected cards consumed
                to_remove = selected_cards
            else
                -- Call per-card combine, respect consume flag
                for _,card in ipairs(selected_cards) do
                    local consumed = card:on_combine(player_hand)
                    if consumed then table.insert(to_remove, card) end
                end
            end
            -- remove consumed cards
            for i = #to_remove, 1, -1 do
                local card_obj = to_remove[i]
                -- find index in current hand
                for idx, hcard in ipairs(player_hand:get_cards()) do
                    if hcard == card_obj then
                        player_hand:remove_card(idx)
                        break
                    end
                end
            end
            -- Deselect any remaining selected cards and reset their position
            for _, hcard in ipairs(player_hand:get_cards()) do
                if hcard.is_clicked then
                    hcard.is_clicked = false
                    hcard.y = hcard.original_y
                end
            end
            player_hand:reposition_cards()
            -- enemy reaction
            if enemy_character and enemy_character.on_player_combine then
                local msg = enemy_character:on_player_combine(player_hand, player_deck)
                show_enemy_message(msg)
            end

            -- Check defeat condition
            if enemy_character and enemy_character.is_defeated and enemy_character:is_defeated(player_hand, player_deck) then
                victory_text = enemy_character.class_name .. " defeated! Click to continue."
                victory_active = true
            end

            -- End player turn after combine
            current_turn = current_turn + 1
            local msg
            if enemy_character and enemy_character.on_turn_end then
                msg = enemy_character:on_turn_end(player_hand, player_deck)
                show_enemy_message(msg)
            end

            -- Check defeat condition again after enemy turn
            if enemy_character and enemy_character.is_defeated and enemy_character:is_defeated(player_hand, player_deck) then
                victory_text = enemy_character.class_name .. " defeated! Click to continue."
                victory_active = true
            end
            return
        end
        -- discard button
        if x>=discard_button.x and x<=discard_button.x+discard_button.width and y>=discard_button.y and y<=discard_button.y+discard_button.height then
            local cards_in_hand = player_hand:get_cards()
            local selected_indices = {}
            for i,card in ipairs(cards_in_hand) do if card.is_clicked then table.insert(selected_indices, i) end end
            local discard_count = #selected_indices
            for i=#selected_indices,1,-1 do player_hand:remove_card(selected_indices[i]) end
            for i=1,discard_count do local new=player_deck:draw_card(); if new then player_hand:add_card(new) end end
            return
        end
        -- else pass to cards
        player_hand:mouse_pressed(x,y,button)
    elseif button==2 then
        player_hand:mouse_pressed(x,y,button)
    end
end

function battle.keypressed(key)
    if enemy_message_active and key ~= "e" then enemy_message_active=false return end
    
    -- F1 toggles debug panel
    if key == "f1" then
        debug_visible = not debug_visible
        return
    end
    
    -- Handle text input when window is focused
    if text_window.focused then
        if key == "backspace" then
            if text_window.cursor_pos > 0 then
                text_window.text = string.sub(text_window.text, 1, text_window.cursor_pos - 1) .. 
                                  string.sub(text_window.text, text_window.cursor_pos + 1)
                text_window.cursor_pos = text_window.cursor_pos - 1
            end
            return
        elseif key == "delete" then
            if text_window.cursor_pos < #text_window.text then
                text_window.text = string.sub(text_window.text, 1, text_window.cursor_pos) .. 
                                  string.sub(text_window.text, text_window.cursor_pos + 2)
            end
            return
        elseif key == "left" then
            text_window.cursor_pos = math.max(0, text_window.cursor_pos - 1)
            return
        elseif key == "right" then
            text_window.cursor_pos = math.min(#text_window.text, text_window.cursor_pos + 1)
            return
        elseif key == "home" then
            text_window.cursor_pos = 0
            return
        elseif key == "end" then
            text_window.cursor_pos = #text_window.text
            return
        elseif key == "return" or key == "enter" then
            local before = string.sub(text_window.text, 1, text_window.cursor_pos)
            local after = string.sub(text_window.text, text_window.cursor_pos + 1)
            text_window.text = before .. "\n" .. after
            text_window.cursor_pos = text_window.cursor_pos + 1
            return
        end
    end
end

function battle.mousereleased(x, y, button)
    if button == 1 then
        text_window.dragging = false
        text_window.resizing = false
    end
end

function battle.textinput(text)
    if text_window.focused then
        local before = string.sub(text_window.text, 1, text_window.cursor_pos)
        local after = string.sub(text_window.text, text_window.cursor_pos + 1)
        text_window.text = before .. text .. after
        text_window.cursor_pos = text_window.cursor_pos + #text
    end
end

return battle 