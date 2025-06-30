-- main.lua
-- Entry point that delegates Love2D callbacks to a simple scene manager

local Scene = require('scene')
local menu_scene = require('menu')

function love.load()
    Scene.switch(menu_scene)
        end

function love.update(dt)
    Scene.update(dt)
end

function love.draw()
    Scene.draw()
end

function love.mousepressed(x, y, button)
    Scene.mousepressed(x, y, button)
end

function love.keypressed(key)
    Scene.keypressed(key)
end