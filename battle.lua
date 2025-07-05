local battle = {}

require('card')
require('board')
require('hand')
local card_bank = require('card_bank')
local Deck = require('deck')
local Scene = require('scene')

local OccultistEnemyClass = require('occultist_enemy')
local PlayerClass = require('thaumaturge')

local player_hand, player_deck
local player_character, enemy_character
local combine_button = {}
local discard_button = {}

local enemy_message_active = false
local enemy_message_text = ""
local current_turn = 0
local max_turns = 7 -- Maximum turns allowed in battle

local victory_active = false
local victory_text = ""

local defeat_active = false
local defeat_text = ""

local debug_visible = false

-- Animation state variables
local animation_state = {
    active = false,
    phase = "draw", -- "draw", "flip", "complete"
    card_index = 1,
    timer = 0,
    draw_delay = 0.4, -- seconds between drawing cards
    flip_delay = 0.25, -- seconds between flipping cards
    cards_to_draw = 6,
    pending_cards = {} -- cards waiting to be drawn
}



local draw_player_tooltip, draw_debug_panel, draw_enemy_message, draw_victory_popup

local defeat_font = love.graphics.newFont(20)

local function show_enemy_message(msg)
    if msg and msg ~= "" then
        enemy_message_text = msg
        enemy_message_active = true
    end
end

local function start_card_animation()
    animation_state.active = true
    animation_state.phase = "draw"
    animation_state.card_index = 1
    animation_state.timer = 0
    animation_state.pending_cards = {}
    
    -- Prepare cards to be drawn
    for i = 1, animation_state.cards_to_draw do
        local drawn = player_deck:draw_card()
        if drawn then
            drawn.is_face_up = false -- Start face down
            table.insert(animation_state.pending_cards, drawn)
        end
    end
end

local function update_card_animation(dt)
    if not animation_state.active then return end
    
    animation_state.timer = animation_state.timer + dt
    
    if animation_state.phase == "draw" then
        -- Draw cards one by one
        if animation_state.timer >= animation_state.draw_delay then
            if animation_state.card_index <= #animation_state.pending_cards then
                local card = animation_state.pending_cards[animation_state.card_index]
                player_hand:add_card(card)
                print("Card drawn: " .. card.name)
                animation_state.card_index = animation_state.card_index + 1
                animation_state.timer = 0
            else
                -- All cards drawn, start flipping phase
                animation_state.phase = "flip"
                animation_state.card_index = 1
                animation_state.timer = 0
                print("All cards drawn, starting flip phase...")
            end
        end
    elseif animation_state.phase == "flip" then
        -- Flip cards one by one
        if animation_state.timer >= animation_state.flip_delay then
            local hand_cards = player_hand:get_cards()
            if animation_state.card_index <= #hand_cards then
                local card = hand_cards[animation_state.card_index]
                if card and not card.is_face_up then
                    card:flip()
                    print("Card flipped: " .. card.name)
                end
                animation_state.card_index = animation_state.card_index + 1
                animation_state.timer = 0
            else
                -- All cards flipped, animation complete
                animation_state.phase = "complete"
                animation_state.active = false
                print("Card animation complete! Player has control.")
            end
        end
    end
end

local function skip_animation()
    if not animation_state.active then return end
    
    -- Add any remaining cards to hand
    if animation_state.phase == "draw" then
        for i = animation_state.card_index, #animation_state.pending_cards do
            local card = animation_state.pending_cards[i]
            player_hand:add_card(card)
        end
    end
    
    -- Flip all cards to face-up
    local hand_cards = player_hand:get_cards()
    for _, card in ipairs(hand_cards) do
        if not card.is_face_up then
            card.is_face_up = true
            card.is_flipping = false
            card.flip_progress = 0
        end
    end
    
    -- End animation
    animation_state.active = false
    animation_state.phase = "complete"
    print("Animation skipped! Player has control.")
end

local function check_defeat_condition()
    if current_turn >= max_turns then
        defeat_active = true
        defeat_text = "Out of turns! " .. (enemy_character.class_name or "Enemy") .. " has won!"
        return true
    end
    return false
end

function battle.enter(enemy_key)
    CardBack = love.graphics.newImage("card-back.png")

    print("Card-back.png dimensions: " .. CardBack:getWidth() .. "x" .. CardBack:getHeight())

    card_bank.load_face_images()

    player_hand = Hand()

    player_deck = Deck()

    local function add_multiple(id, count)
        for i = 1, count do
            local card = card_bank.create_card(id, 0, 0)
            player_deck:add_card(card)
        end
    end

    add_multiple(6, 4)
    add_multiple(7, 4)
    add_multiple(2, 4)
    add_multiple(3, 4)
    add_multiple(5, 4)
    player_deck:shuffle()

    -- Start the card drawing animation instead of drawing immediately
    start_card_animation()

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

    local sw, sh = love.graphics.getWidth(), love.graphics.getHeight()
    player_character = PlayerClass(sw / 2, sh - 100, 120, 160, player_deck)

    local enemy_map = {
        occultist = OccultistEnemyClass
    }
    local EnemyClass = enemy_map[enemy_key]
    enemy_character = EnemyClass(sw / 2, 120, 120, 160)

    current_turn = 0  -- Start at 0, first combination brings it to turn 1
    max_turns = 7  -- Default turn limit
    
    -- Set enemy-specific turn limit if available
    if enemy_character.turn_limit then
        max_turns = enemy_character.turn_limit
    end
    
    victory_active = false
    defeat_active = false
    
    print("Battle started! You have " .. max_turns .. " turns to defeat " .. (enemy_character.class_name or "Enemy"))
end

function battle.update(dt)
    -- Update card animation
    update_card_animation(dt)
    
    player_hand:update(dt, animation_state.active)

    local mx, my = love.mouse.getX(), love.mouse.getY()
    player_character:update(dt, mx, my)
    if enemy_character.update then enemy_character:update(dt, mx, my) end

    -- Only update button hover states if animation is complete
    if not animation_state.active then
        combine_button.is_hovered = mx >= combine_button.x and mx <= combine_button.x + combine_button.width and
                                   my >= combine_button.y and my <= combine_button.y + combine_button.height

        discard_button.is_hovered = mx >= discard_button.x and mx <= discard_button.x + discard_button.width and
                                   my >= discard_button.y and my <= discard_button.y + discard_button.height
    else
        combine_button.is_hovered = false
        discard_button.is_hovered = false
    end


end

function battle.draw()
    love.graphics.clear(0.1, 0.1, 0.1)

    enemy_character:draw()
    if enemy_character.is_hovered then draw_enemy_hover() end
    player_character:draw()

    player_hand:draw()
    
    -- Draw turn counter in top left
    local font = love.graphics.getFont()
    local remaining_turns = math.max(0, max_turns - current_turn)
    local turn_text = string.format("Remaining Turns: %d/%d", remaining_turns, max_turns)
    
    love.graphics.setColor(0, 0, 0, 0.7)
    love.graphics.rectangle("fill", 10, 10, font:getWidth(turn_text) + 20, font:getHeight() + 10)
    love.graphics.setColor(1, 1, 1, 1)
    love.graphics.rectangle("line", 10, 10, font:getWidth(turn_text) + 20, font:getHeight() + 10)
    
    if remaining_turns <= 2 then
        love.graphics.setColor(1, 0.3, 0.3, 1) -- Red warning color
    else
        love.graphics.setColor(1, 1, 1, 1)
    end
    love.graphics.print(turn_text, 20, 15)
    love.graphics.setColor(1, 1, 1, 1)
    
    -- Draw animation indicator
    if animation_state.active then
        local font = love.graphics.getFont()
        local text = ""
        if animation_state.phase == "draw" then
            text = "Drawing cards..."
        elseif animation_state.phase == "flip" then
            text = "Revealing cards..."
        end
        
        local skip_text = "Press SPACE to skip"
        
        local tw = math.max(font:getWidth(text), font:getWidth(skip_text))
        local th = font:getHeight()
        local x = love.graphics.getWidth() / 2 - tw / 2
        local y = 50
        
        love.graphics.setColor(0, 0, 0, 0.7)
        love.graphics.rectangle("fill", x - 10, y - 5, tw + 20, th * 2 + 15)
        love.graphics.setColor(1, 1, 1, 1)
        love.graphics.rectangle("line", x - 10, y - 5, tw + 20, th * 2 + 15)
        
        love.graphics.print(text, x + (tw - font:getWidth(text)) / 2, y)
        love.graphics.setColor(0.8, 0.8, 0.8, 1)
        love.graphics.print(skip_text, x + (tw - font:getWidth(skip_text)) / 2, y + th + 5)
        love.graphics.setColor(1, 1, 1, 1)
    end

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

    if debug_visible then draw_debug_panel() end
    -- Only show tooltips if animation is not active
    if not animation_state.active and player_character.is_hovered then draw_player_tooltip() end
    if enemy_message_active then draw_enemy_message() end
    if victory_active then draw_victory_popup() end
    if defeat_active then draw_defeat_popup() end

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

function draw_defeat_popup()
    local font = love.graphics.getFont()
    local text = defeat_text ~= "" and defeat_text or "Defeat!"
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

function battle.mousepressed(x,y,button)
    -- Block all input during animation
    if animation_state.active then
        return
    end
    
    if victory_active then
        if button==1 then
            victory_active=false
            local MenuScene = require('menu')
            Scene.switch(MenuScene)
        end
        return
    end
    
    if defeat_active then
        if button==1 then
            defeat_active=false
            local MenuScene = require('menu')
            Scene.switch(MenuScene)
        end
        return
    end
    
    if enemy_message_active then enemy_message_active=false return end
    
    if button==1 then        
        if x>=combine_button.x and x<=combine_button.x+combine_button.width and y>=combine_button.y and y<=combine_button.y+combine_button.height then
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
                if recipe.custom then
                    recipe.custom(player_hand, player_deck)
                end

                local count = recipe.output_count or 0
                if count > 0 and recipe.output_id then
                    for i=1,count do
                        local new_card = card_bank.create_card(recipe.output_id,0,0)
                        player_hand:add_card(new_card)
                    end
                end
                to_remove = selected_cards
            else
                for _,card in ipairs(selected_cards) do
                    local consumed = card:on_combine(player_hand)
                    if consumed then table.insert(to_remove, card) end
                end
            end
            for i = #to_remove, 1, -1 do
                local card_obj = to_remove[i]
                for idx, hcard in ipairs(player_hand:get_cards()) do
                    if hcard == card_obj then
                        player_hand:remove_card(idx)
                        break
                    end
                end
            end
            for _, hcard in ipairs(player_hand:get_cards()) do
                if hcard.is_clicked then
                    hcard.is_clicked = false
                    hcard.y = hcard.original_y
                end
            end
            player_hand:reposition_cards()
            
            -- Increment turn after combination
            current_turn = current_turn + 1
            print("Turn " .. current_turn .. " of " .. max_turns)
            
            -- Check for defeat first (out of turns)
            if check_defeat_condition() then
                return
            end
            
            if enemy_character and enemy_character.on_player_combine then
                local msg = enemy_character:on_player_combine(player_hand, player_deck)
                show_enemy_message(msg)
            end

            if enemy_character and enemy_character.is_defeated and enemy_character:is_defeated(player_hand, player_deck) then
                victory_text = enemy_character.class_name .. " defeated! Click to continue."
                victory_active = true
                return
            end

            local msg
            if enemy_character and enemy_character.on_turn_end then
                msg = enemy_character:on_turn_end(player_hand, player_deck)
                show_enemy_message(msg)
            end

            if enemy_character and enemy_character.is_defeated and enemy_character:is_defeated(player_hand, player_deck) then
                victory_text = enemy_character.class_name .. " defeated! Click to continue."
                victory_active = true
            end
            return
        end
        if x>=discard_button.x and x<=discard_button.x+discard_button.width and y>=discard_button.y and y<=discard_button.y+discard_button.height then
            local cards_in_hand = player_hand:get_cards()
            local selected_indices = {}
            for i,card in ipairs(cards_in_hand) do if card.is_clicked then table.insert(selected_indices, i) end end
            local discard_count = #selected_indices
            for i=#selected_indices,1,-1 do player_hand:remove_card(selected_indices[i]) end
            for i=1,discard_count do local new=player_deck:draw_card(); if new then player_hand:add_card(new) end end
            return
        end
        player_hand:mouse_pressed(x,y,button)
    elseif button==2 then
        player_hand:mouse_pressed(x,y,button)
    end
end

function battle.keypressed(key)
    -- Allow skipping animation with spacebar
    if animation_state.active and key == "space" then
        skip_animation()
        return
    end
    
    -- Block other keyboard input during animation (except debug keys)
    if animation_state.active and key ~= "f1" then
        return
    end
    
    if enemy_message_active and key ~= "e" then enemy_message_active=false return end
    
    if key == "f1" then
        debug_visible = not debug_visible
        return
    end
    

end

function battle.mousereleased(x, y, button)
    -- No special handling needed currently
end

function battle.textinput(text)
    -- No text input handling needed currently
end

-- Function to check if animation is active (for external use)
function battle.is_animation_active()
    return animation_state.active
end

-- Function to get current animation phase (for external use)
function battle.get_animation_phase()
    return animation_state.phase
end

return battle 