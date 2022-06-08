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

local layout_gui = require "ui.layout_render"

local box_gui = inherit(layout_gui)

function box_gui.init()
    local state = layout_gui.init(0.032)

    local layout = {
        box = spatial(100, 100, 100, 100)
    }

    return layout_gui.update_layout(state, layout)
end

function box_gui.draw_element(ctx, state, rect)
    gfx.setColor(1, 1, 1)
    gfx.rectangle("line", rect:unpack())
end

function box_gui.draw(ctx, state)
    layout_gui.draw(ctx, state, box_gui.draw_element)
end

function box_gui.mousepressed(ctx, state, x, y)
    local box = state.layout.box

    local layout = {
        box = spatial(box.x, box.y, x - box.x, y - box.y)
    }

    return layout_gui.update_layout(state, layout)
end

function love.load()
    world = nw.ecs.world()
    world:push(mock_battle)

    local s1 = spatial(1, 2, 3, 4)
    local s2 = spatial(5, 6, 7, 8)

    bgui = gui(box_gui)
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

    bgui("mousepressed", x, y)
end

function love.update(dt)
    world:emit("update", dt):spin()
    --collectgarbage()
    bgui:update(dt)
end

function love.draw()
    world:emit("draw"):spin()
    world:emit("draw:ui"):spin()

    bgui:draw()
end

function love.log(...)
    world:emit("log", ...)
end
