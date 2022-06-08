--require "lovedebug"

function class(c)
    local c = c or {}
    c.__index = c
    return c
end

function instance(c)
    c.__index = c
    return setmetatable({}, c)
end

function inherit(c, this)
    local i = setmetatable(this or {}, c)
    i.__index = i
    return i
end

love.graphics.setDefaultFilter("nearest", "nearest")

local nw = require "nodeworks"
local mock_battle = require "mock_battle"
--local particle_scene = require "particle_scene"


function love.load()
    world = nw.ecs.world()
    world:push(mock_battle)

    local s1 = spatial(1, 2, 3, 4)
    local s2 = spatial(5, 6, 7, 8)
    print(ease.linear(0.5, s1, s2 - s1, 1))
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

function love.log(...)
    world:emit("log", ...)
end
