local nw = require "nodeworks"
local card_select = require "card_select"
local mock_battle = require "mock_battle"

function love.load()
    world = nw.ecs.world()
    world:push(nw.system.tween):push(mock_battle)
end

function love.keypressed(key)
    if key == "escape" then love.event.quit() end
    world:emit("keypressed", key)
end

function love.update(dt)
    world:emit("update", dt):resolve()
end

function love.draw()
    world:emit("draw"):resolve()
end
