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

function decorate(dst, src)
    for key, val in pairs(src) do
        dst[key] = dst[key] or val
    end

    return dst
end

love.graphics.setDefaultFilter("nearest", "nearest")

nw = require "nodeworks"
constants = require "constants"
component = require "component"
drawable = require "drawable"
Gamestate = require "gamestate"
require("decorator"):apply()

Frame.slice_to_pos = Spatial.centerbottom

function love.load()
    world = nw.ecs.world()
    world:push(require "system.render")

    local gamestate = Gamestate.create()
    local hand = list()
    for i = 1, 8 do table.insert(hand, gamestate:entity()) end
    gamestate:player():set(component.hand, hand)

    world:emit("shown_gamestate", gamestate)
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
end

function love.draw()
    world:emit("draw"):spin()
    world:emit("draw:ui"):spin()
end
