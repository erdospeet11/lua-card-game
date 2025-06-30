-- main.lua

-- Number of circles to draw
local NUM_CIRCLES = 7
-- Radius of each circle (in pixels)
local CIRCLE_RADIUS = 25
-- Thickness of the connecting line
local LINE_THICKNESS = 6
-- Speed at which the white fill progresses (unit: fraction per second)
local PROGRESS_SPEED = 0.25

-- Animation state
local filledSegments = 0        -- number of fully completed segments (between circles)
local segmentProgress = 0       -- progress (0..1) within the current segment
local animating = false         -- whether the current segment is being animated
local hoveredIndex = nil        -- index of the circle currently under the mouse (if any)

-- Tooltip appearance
local TOOLTIP_OFFSET = 10       -- vertical distance from top of circle to tooltip
local TOOLTIP_PADDING = 4       -- padding around text inside tooltip box
-- Margin from the left & right edges before the first/last circle
local HORIZONTAL_MARGIN = 60

-- Screen dimensions (will be filled in love.load)
local screenW, screenH
-- Pre-calculated positions for the circles
local circlePositions = {}

function love.load()
    -- Set the window size. Feel free to tweak these values.
    love.window.setMode(800, 600, { resizable = false })

    -- Cache the screen dimensions
    screenW, screenH = love.graphics.getDimensions()

    -- y-coordinate for the center line & circles
    local centerY = screenH / 2

    -- x-coordinate for the first and last circles
    local firstX = HORIZONTAL_MARGIN
    local lastX  = screenW - HORIZONTAL_MARGIN

    -- Distance between the centers of consecutive circles
    step = (lastX - firstX) / (NUM_CIRCLES - 1)

    -- Pre-compute the (x, y) of every circle
    circlePositions = {}
    for i = 0, NUM_CIRCLES - 1 do
        local x = firstX + i * step
        table.insert(circlePositions, { x = x, y = centerY })
    end
end

function love.draw()
    local centerY = screenH / 2
    if #circlePositions >= 2 then
        local xLeft  = circlePositions[1].x
        local xRight = circlePositions[#circlePositions].x
        local lineLength = xRight - xLeft

        -- Draw the underlying grey line
        love.graphics.setColor(0.5, 0.5, 0.5) -- grey
        love.graphics.setLineWidth(LINE_THICKNESS)
        love.graphics.line(xLeft, centerY, xRight, centerY)

        -- Overlay the white portion according to filled segments + in-progress fraction
        love.graphics.setColor(1, 1, 1)

        local whiteFraction = (filledSegments + segmentProgress) / (NUM_CIRCLES - 1)
        whiteFraction = math.min(whiteFraction, 1)
        local progressX = xLeft + lineLength * whiteFraction
        love.graphics.line(xLeft, centerY, progressX, centerY)
    end

    -- Draw the circles, transitioning from grey to white based on progress
    for idx, pos in ipairs(circlePositions) do
        if idx == 1 or (idx - 1) <= filledSegments then
            love.graphics.setColor(1, 1, 1)
        else
            love.graphics.setColor(0.5, 0.5, 0.5)
        end
        love.graphics.circle("fill", pos.x, pos.y, CIRCLE_RADIUS)
    end

    -- Draw tooltip if hovering a circle
    if hoveredIndex then
        local pos = circlePositions[hoveredIndex]
        local label = tostring(hoveredIndex)
        local font = love.graphics.getFont()
        local textW = font:getWidth(label)
        local textH = font:getHeight()
        local boxW = textW + TOOLTIP_PADDING * 2
        local boxH = textH + TOOLTIP_PADDING * 2
        local boxX = pos.x - boxW / 2
        local boxY = pos.y - CIRCLE_RADIUS - TOOLTIP_OFFSET - boxH

        -- Background (semi-transparent dark)
        love.graphics.setColor(0, 0, 0, 0.7)
        love.graphics.rectangle("fill", boxX, boxY, boxW, boxH, 4, 4)

        -- Border (white)
        love.graphics.setColor(1, 1, 1)
        love.graphics.setLineWidth(1)
        love.graphics.rectangle("line", boxX, boxY, boxW, boxH, 4, 4)

        -- Text
        love.graphics.print(label, boxX + TOOLTIP_PADDING, boxY + TOOLTIP_PADDING)
    end
end

function love.update(dt)
    if animating then
        segmentProgress = math.min(segmentProgress + PROGRESS_SPEED * dt, 1)
        if segmentProgress >= 1 then
            -- Segment finished
            segmentProgress = 0
            animating = false
            filledSegments = filledSegments + 1
        end
    end

    -- Hover detection for tooltip
    local mx, my = love.mouse.getPosition()
    hoveredIndex = nil
    for idx, pos in ipairs(circlePositions) do
        local dx, dy = mx - pos.x, my - pos.y
        if dx * dx + dy * dy <= CIRCLE_RADIUS * CIRCLE_RADIUS then
            hoveredIndex = idx
            break
        end
    end
end

function love.mousepressed(_, _, button)
    -- Start animating the next segment on left-click, if available
    if button == 1 and not animating and filledSegments < NUM_CIRCLES - 1 then
        animating = true
        segmentProgress = 0
    end
end 