local card_bank = {}

card_bank.face_images = {}

card_bank.card_types = {
    [0] = {
        name = "Empty Talisman",
        description = "A talisman awaiting inscription",
        id = 0,
        type = "Talisman",
        face_image_path = "cards/empty-talisman.png"
    },
    [1] = {
        name = "Seal",
        description = "An arcane seal of unknown power",
        id = 1,
        type = "Phenomena",
        face_image_path = "cards/seal.png"
    },
    [2] = {
        name = "Release Talisman",
        description = "Removes restraints and unleashes energies",
        id = 2,
        type = "Talisman",
        face_image_path = "cards/release-talisman.png"
    },
    [3] = {
        name = "Binding Talisman",
        description = "Restrains and binds supernatural forces",
        id = 3,
        type = "Talisman",
        face_image_path = "cards/binding-talisman.png"
    },
    [4] = {
        name = "Glyph of Curse",
        description = "A glyph that invokes a lingering curse",
        id = 4,
        type = "Phenomena",
        face_image_path = "cards/glyph-of-curse.png"
    },
    [5] = {
        name = "Small Trove",
        description = "Replenishes your supply of talismans",
        id = 5,
        type = "Resource",
        face_image_path = "cards/small-trove.png"
    },
    [6] = {
        name = "Scripture",
        description = "A sacred text that contains the power of the gods",
        id = 6,
        type = "Phenomena",
        face_image_path = "cards/scripture.png"
    },
    [7] = {
        name = "Innervate",
        description = "Restores internal energy for thaumaturgical rites",
        id = 7,
        type = "Phenomena",
        face_image_path = "cards/innervate.png"
    }
}

card_bank.recipes = {}

function card_bank.create_card(id, x, y)
    local card_def = card_bank.card_types[id]
    if not card_def then
        error("Unknown card ID: " .. tostring(id))
    end
    
    local back_image = CardBack
    
    local face_image = card_bank.face_images[id] or CardBack
    
    local card_type_name = card_def.type or "Unknown"
    
    if id == 0 then
        return Card(card_def.name, card_def.description, face_image, back_image, x, y, id, card_type_name)
    elseif id == 1 then
        local spawner = SpawnerCard(card_def.name, card_def.description, face_image, back_image, x, y)
        spawner.type = card_type_name
        return spawner
    end
    
    return Card(card_def.name, card_def.description, face_image, back_image, x, y, id, card_type_name)
end

function card_bank.get_card_type(id)
    return card_bank.card_types[id]
end

function card_bank.register_card_type(id, name, description)
    card_bank.card_types[id] = {
        name = name,
        description = description,
        id = id
    }
end

function card_bank.register_recipe(input_ids, output_id, output_count, custom_fn)
    output_count = output_count or 1
    table.insert(card_bank.recipes, {
        input_ids = input_ids,
        output_id = output_id,
        output_count = output_count,
        custom = custom_fn
    })
end

function card_bank.find_recipe(input_ids)
    table.sort(input_ids)
    
    for _, recipe in ipairs(card_bank.recipes) do
        local sorted_recipe_inputs = {}
        for _, id in ipairs(recipe.input_ids) do
            table.insert(sorted_recipe_inputs, id)
        end
        table.sort(sorted_recipe_inputs)
        
        if #input_ids == #sorted_recipe_inputs then
            local match = true
            for i = 1, #input_ids do
                if input_ids[i] ~= sorted_recipe_inputs[i] then
                    match = false
                    break
                end
            end
            
            if match then
                return recipe
            end
        end
    end
    
    return nil
end

function card_bank.get_all_card_types()
    return card_bank.card_types
end

function card_bank.get_all_recipes()
    return card_bank.recipes
end

function card_bank.load_face_images()
    for id, card_type in pairs(card_bank.card_types) do
        if card_type.face_image_path then
            card_bank.face_images[id] = love.graphics.newImage(card_type.face_image_path)
        end
    end
end

function card_bank.set_face_image(id, image_path)
    if card_bank.card_types[id] then
        card_bank.card_types[id].face_image_path = image_path
        card_bank.face_images[id] = love.graphics.newImage(image_path)
    end
end

local function add_random_talismans(hand, n)
    local talisman_ids = {}
    for id, def in pairs(card_bank.card_types) do
        if def.type == "Talisman" and id ~= 0 then
            table.insert(talisman_ids, id)
        end
    end
    if #talisman_ids == 0 then return end
    for i = 1, n do
        local id = talisman_ids[love.math.random(#talisman_ids)]
        local new_card = card_bank.create_card(id, 0, 0)
        hand:add_card(new_card)
    end
end

-- Seal = Binding Talisman + Binding Talisman + Binding Talisman
-- card_bank.register_recipe({3,3,3}, 1, 1)
card_bank.register_recipe({3,3}, 1, 1)

-- Nothing = Glyph of Curse + Binding Talisman (produces no output)
card_bank.register_recipe({4,3}, 0, 0)

-- 2x Random Talismans = Trove of Talismans + Release Talisman
card_bank.register_recipe({5,2}, 0, 0, function(hand)
    add_random_talismans(hand, 2)
end)

-- Random Talisman = Empty Talisman + Scripture
card_bank.register_recipe({0,6}, 0, 0, function(hand)
    add_random_talismans(hand, 1)
end)

-- Innervate (solo) -> draw 2 cards
card_bank.register_recipe({7}, 0, 0, function(hand, deck)
    if not deck then return end
    for i = 1, 2 do
        local c = deck:draw_card()
        if c then hand:add_card(c) end
    end
end)

return card_bank 