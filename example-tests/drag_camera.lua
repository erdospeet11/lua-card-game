-- main.lua

--------------------------------------------------
-- Configuration
--------------------------------------------------
-- (circle/line constants removed)

local WORLD_WIDTH      = 3000  -- width  of the virtual world (px)
local WORLD_HEIGHT     = 3000  -- height of the virtual world (px) to allow vertical scrolling

local RECT_COUNT       = 40    -- number of random rectangles to sprinkle around the scene
local RECT_MIN_SIZE    = 60
local RECT_MAX_SIZE    = 150

-- (tooltip constants removed)

--------------------------------------------------
-- Runtime state
--------------------------------------------------
-- Camera
local camera = { x = 0, y = 0 }
local isDragging   = false
local dragStartX, dragStartY
local camStartX, camStartY
camera.scale = 1  -- zoom factor (1 = 100%)

-- (animation variables removed)

-- Geometry
local screenW, screenH
local rectangles = {}

-- (hoveredIndex removed)

--------------------------------------------------
-- Helpers
--------------------------------------------------
local function worldToScreen(x, y)
    return (x - camera.x) * camera.scale, (y - camera.y) * camera.scale
end

local function screenToWorld(x, y)
    return x / camera.scale + camera.x, y / camera.scale + camera.y
end

--------------------------------------------------
-- Love callbacks
--------------------------------------------------
function love.load()
    -- Seed RNG for rectangles
    math.randomseed(os.time())

    -- Create window
    love.window.setMode(800, 600, { resizable = false })
    screenW, screenH = love.graphics.getDimensions()

    -- Generate random rectangles across the world
    for i = 1, RECT_COUNT do
        local w = math.random(RECT_MIN_SIZE, RECT_MAX_SIZE)
        local h = math.random(RECT_MIN_SIZE, RECT_MAX_SIZE)
        local x = math.random(0, WORLD_WIDTH  - w)
        local y = math.random(0, WORLD_HEIGHT - h)
        table.insert(rectangles, { x = x, y = y, w = w, h = h })
    end

    -- Initialize camera at origin
    camera.x, camera.y = 0, 0
    camera.scale      = 1
end

function love.update(dt)
    -- No per-frame updates necessary
    clampCamera()
end

function love.draw()
    -- Apply camera transform for world rendering
    love.graphics.push()
    love.graphics.scale(camera.scale)
    love.graphics.translate(-camera.x, -camera.y)

    --------------------------------------------------
    -- Draw background rectangles (grey outlines)
    --------------------------------------------------
    love.graphics.setColor(0.3, 0.6, 0.9, 0.2) -- light bluish fill
    for _, r in ipairs(rectangles) do
        love.graphics.rectangle("fill", r.x, r.y, r.w, r.h)
        love.graphics.setColor(0.1, 0.3, 0.5)
        love.graphics.setLineWidth(2)
        love.graphics.rectangle("line", r.x, r.y, r.w, r.h)
        love.graphics.setColor(0.3, 0.6, 0.9, 0.2)
    end

    --------------------------------------------------
    -- Draw tooltip (still in world space)
    --------------------------------------------------
    love.graphics.pop() -- remove camera transform

    --------------------------------------------------
    -- UI overlay (debug/help)
    --------------------------------------------------
    love.graphics.setColor(1, 1, 1)
    love.graphics.print("Right-drag to pan | Mouse wheel to zoom", 10, 10)
end

function love.mousepressed(x, y, button)
    if button == 2 then -- right: begin camera drag
        isDragging  = true
        dragStartX  = x
        dragStartY  = y
        camStartX   = camera.x
        camStartY   = camera.y
    end
end

function love.mousereleased(_, _, button)
    if button == 2 then
        isDragging = false
    end
end

function love.mousemoved(_, _, dx, dy)
    if isDragging then
        -- convert screen delta to world delta based on scale
        camera.x = camera.x - dx / camera.scale
        camera.y = camera.y - dy / camera.scale
        clampCamera()
    end
end

-- Helper to keep camera within world bounds considering scale
function clampCamera()
    local maxX = math.max(0, WORLD_WIDTH  - screenW / camera.scale)
    local maxY = math.max(0, WORLD_HEIGHT - screenH / camera.scale)
    camera.x = math.max(0, math.min(camera.x, maxX))
    camera.y = math.max(0, math.min(camera.y, maxY))
end

function love.wheelmoved(_, dy)
    if dy ~= 0 then
        -- Zoom towards mouse position
        local mx, my = love.mouse.getPosition()
        local worldXBefore, worldYBefore = screenToWorld(mx, my)

        local zoomFactor = 1 + dy * 0.1
        local newScale   = math.max(0.3, math.min(3, camera.scale * zoomFactor))

        camera.scale = newScale

        -- Adjust camera so the point under cursor stays fixed after zoom
        local worldXAfter, worldYAfter = worldXBefore, worldYBefore
        camera.x = worldXAfter - mx / camera.scale
        camera.y = worldYAfter - my / camera.scale

        clampCamera()
    end
end
