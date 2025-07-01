local scene = {}

scene.current = nil

function scene.switch(new_scene, ...)
    -- exit on old scene
    if scene.current and scene.current.exit then
        scene.current.exit()
    end

    scene.current = new_scene
    -- enter on new scene
    if scene.current and scene.current.enter then
        scene.current.enter(...)
    end
end

function scene.update(dt)
    if scene.current and scene.current.update then
        scene.current.update(dt)
    end
end

function scene.draw()
    if scene.current and scene.current.draw then
        scene.current.draw()
    end
end

function scene.mousepressed(x, y, button)
    if scene.current and scene.current.mousepressed then
        scene.current.mousepressed(x, y, button)
    end
end

function scene.mousereleased(x, y, button)
    if scene.current and scene.current.mousereleased then
        scene.current.mousereleased(x, y, button)
    end
end

function scene.keypressed(key)
    if scene.current and scene.current.keypressed then
        scene.current.keypressed(key)
    end
end

function scene.wheelmoved(x, y)
    if scene.current and scene.current.wheelmoved then
        scene.current.wheelmoved(x, y)
    end
end

function scene.textinput(text)
    if scene.current and scene.current.textinput then
        scene.current.textinput(text)
    end
end

return scene 