local nw = require "nodeworks"
local game = require "game"
local mechanics = require "mechanics"
local minion = require "minion"

return function(ctx)
    ctx.game = game(ctx)

    local draw = ctx:listen("draw")
        :foreach(function() ctx.game:draw() end)

    local update = ctx:listen("update")
        :foreach(function(dt) ctx.game:update(dt) end)

    ctx.game:battle_loop()
end
