--require "lovedebug"

function class()
    local c = {}
    c.__index = c
    return c
end

local nw = require "nodeworks"
local mock_battle = require "mock_battle"

function love.load()
    gfx.setDefaultFilter("nearest", "nearest")
    world = nw.ecs.world()
    world:push(mock_battle)
end


function love.keypressed(key)
    if key == "escape" then love.event.quit() end

    world:emit("keypressed", key)
end

function love.mousemoved(x, y, dx, dy)
    world:emit("mousemoved", x, y, dx, dy)
end

function love.mousepressed(x, y, button, isTouch)
    world:emit("mousepressed", x, y, button)
end

function love.update(dt)
    world:emit("update", dt):spin()
    --collectgarbage()
end

function love.draw()
    world:emit("draw"):spin()
    world:emit("draw:ui"):spin()
end
