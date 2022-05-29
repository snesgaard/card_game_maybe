local nw = require "nodeworks"
local game = require "game.game"
local mechanics = require "mechanics"
local minion = require "minion"
local cards = require "cards"
local component = require "component"
local constants = require "game.constants"
local masters = require "game.masters"

return function(ctx)
    ctx.game = game(ctx)

    local draw = ctx:listen("draw")
        :foreach(function() ctx.game:draw() end)

    local update = ctx:listen("update")
        :foreach(function(dt) ctx.game:update(dt) end)

    local player = {
        deck = List.duplicate(cards.skills.shovel, 5)
            + List.duplicate(cards.skills.potion, 5)
            + List.duplicate(cards.minions.fireskull, 5),
    }

    ctx.game:setup_battle(masters.gravedigger)
    ctx.game:battle_loop()
end
