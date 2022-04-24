local nw = require "nodeworks"
local card_select = require "card_select"
local mock_battle = require "mock_battle"

function love.load()
    world = nw.ecs.world()
    world:push(mock_battle)

    local a = {}
    a[{}] = 5
    a[10] = 3
    a[0] = 1
    a[1] = 2
    a[4] = 4

    for key, value in pairs(a) do print(key, value) end
end


function love.keypressed(key)
    if key == "escape" then love.event.quit() end




    world:emit("keypressed", key)
end

function love.update(dt)
    world:emit("update", dt):spin()
    --collectgarbage()
end

function love.draw()
    world:emit("draw"):spin()
    world:emit("draw:ui"):spin()
end
